library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

source("./visualizer/utils.R")

if (!exists("outputDir")) outputDir <- "./visualizer/out/"
if (!exists("presentationDir")) presentationDir <- "./visualizer/out/"

time <- fromJSON(txt = "./visualizer/r_json/timeUntilActivation_r.json", flatten = TRUE) %>%
  filter(value != "not finished") %>%
  mutate(value = as.numeric(value))

avg_per_component <- time %>%
  group_by(componentName) %>%
  summarise(avg_time = mean(value))

avg_per_user <- time %>%
  group_by(user) %>%
  summarise(avg_time = mean(value))

users <- nrow(avg_per_user)
avg_per_component_melted <- melt(avg_per_component, id = "componentName")
ggplot(data = levelNumbers(avg_per_component_melted), aes(x = componentName, y = value, fill = variable, group = variable)) +
  theme_minimal() +
  geom_line() +
  labs(title = paste0("Average time until activation per user & component (total users: ", users, ")"), x = "Component", y = "Average time", fill = "Type", group = "Type")
ggsave(filename = paste0(outputDir, "timeUntilActivation_avg_per_component.png"), width = 10, height = 5)


level_reached <- fromJSON(txt = "./visualizer/r_json/levelReached_r.json", flatten = TRUE)
users_that_reached_level4 <- level_reached %>%
  filter(value > 3) %>%
  select(user)
avg_per_component_only_users_that_reached_level4 <- time %>%
  inner_join(users_that_reached_level4, by = "user") %>%
  filter(componentName != "ReactorLog") %>%
  group_by(componentName) %>%
  summarise(avg_time = mean(value))
amount_of_users_that_reached_level4 <- nrow(users_that_reached_level4)

avg_per_component_only_users_that_reached_level4_total <- time %>%
  inner_join(users_that_reached_level4, by = "user") %>%
  filter(componentName != "ReactorLog") %>%
  group_by(componentName) %>%
  summarise(avg_time = mean(value))

ggplot(data = levelNumbers(avg_per_component_only_users_that_reached_level4), aes(x = componentName, y = avg_time, group = 1)) +
  theme_minimal() +
  geom_line() +
  # geom_bar(stat = "identity", fill = "blue", color = "blue", alpha = .5, data = avg_per_component_only_users_that_reached_level4_total, aes(x = componentName, y = avg_total, color = "blue")) +
  labs(title = paste0("Average time per user & component for the ", amount_of_users_that_reached_level4, " users that reached level 4"),
       x = "Component", y = "Average time", fill = "Type", group = "Type") +
  expand_limits(y = 0)
ggsave(filename = paste0(outputDir, "timeUntilActivation_avg_per_component_only_users_that_reached_level4.png"), width = 10, height = 5)




nn <- time %>%
  filter(user %in% users_that_reached_level4$user) %>%
  filter(componentName != "ReactorLog") %>%
  # only keep users that have data for all components present
  group_by(user) %>%
  filter(n() == 4)

m <- nn %>%
  mutate(componentIndex = sapply(componentName, component_name_to_index)) %>%
  arrange(componentIndex)

contingency_table <- xtabs (~ nn$componentName + nn$value)
contingency_table

# perform Chi-Square test
result <- chisq.test(contingency_table)

# summarize Chi-Square test results
summary(result)
#library(ggpubr)
#ggpubr::ggballoonplot(as.data.frame(contingency_table))
#ggpubr::ggballoonplot(as.data.frame(result$result))


ggplot(data = levelNumbers(m), aes(x = componentIndex, y = value)) +
  theme_minimal() +
  geom_boxplot(aes(x = componentName), alpha = 0.66, color = colors[5], fill = colors[1]) +
  labs(#title = "time per component for users that reached level 4",
       x = "Component", y = "time in min") +
  #geom_point() +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, color = colors[3]) +
  expand_limits(y = 0)
ggsave(filename = paste0(outputDir, "time_until_activation_trend.png"), width = 10, height = 8)

res <- lm(m$value ~ m$componentIndex)


model <- lm(value ~ componentIndex, data = m)
summary_model <- summary(model)
# Extract the slope (coefficient of componentIndex) and p-value
slope <- summary_model$coefficients["componentIndex", "Estimate"]
p_value <- summary_model$coefficients["componentIndex", "Pr(>|t|)"]
# Check if the slope is negative and the p-value is significant
print(paste0("Slope: ", slope, ", p-value: ", p_value))
if (slope < 0 && p_value < 0.05) {
  print("There is a significant downward linear trend.")
} else {
  print("There is no significant downward linear trend.")
}
print(paste0("Residual Standard Error = ", sigma(model)))
print(paste0("R-squared = ", summary_model$r.squared))
