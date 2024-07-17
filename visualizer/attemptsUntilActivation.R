library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

if (!exists("outputDir")) outputDir <- "./visualizer/out/"

attempts <- fromJSON(txt = "./visualizer/r_json/attemptsUntilActivation_r.json", flatten = TRUE)

avg_per_user <- attempts %>%
  group_by(user) %>%
  summarise(avg_errors = mean(errors), avg_fails = mean(fails), avg_successes = mean(successes))

sum_all <- attempts %>%
  summarise(sum_errors = sum(errors), sum_fails = sum(fails), sum_successes = sum(successes))
avg_all <- attempts %>%
  summarise(avg_errors = mean(errors), avg_fails = mean(fails), avg_successes = mean(successes))

attempts_total_avg <- attempts %>%
  summarise(avg_total = mean(errors + fails + successes))

avg_per_component <- attempts %>%
  group_by(componentName) %>%
  summarise(avg_errors = mean(errors), avg_fails = mean(fails), avg_successes = mean(successes),
            total = avg_errors + avg_fails + avg_successes)

sum_per_component <- attempts %>%
  group_by(componentName) %>%
  summarise(sum = sum(errors) + sum(fails) + sum(successes))

avg_total_per_component <- attempts %>%
  group_by(componentName) %>%
  summarise(avg_total = mean(errors + fails + successes))

ggplot(data = avg_per_component, aes(x = componentName, group = 1)) +
  geom_line(color = "red", aes(y = avg_errors)) +
  geom_line(color = "orange", aes(y = avg_fails)) +
  geom_line(color = "green", aes(y = avg_successes)) +
  labs(title = "Average errors, fails and successes per component", x = "Component", y = "Average")

users <- nrow(avg_per_user)
avg_per_component_melted <- melt(avg_per_component, id = c("componentName", "total"))
ggplot(data = avg_per_component_melted, aes(x = componentName, y = value, fill = variable, group = variable)) +
  geom_area(position = "stack") +
  scale_fill_manual(values = c("red", "orange", "green"), labels = c("Errors", "Fails", "Successes")) +
  labs(title = paste0("Average errors, fails and successes per user & component (total users: ", users, ")"), x = "Component", y = "Average attempts", fill = "Type", group = "Type")
ggsave(filename = paste0(outputDir, "attemptsUntilActivation_avg_per_component.png"), width = 10, height = 5)

# same plot, but stretched to percentages
ggplot(data = avg_per_component_melted, aes(x = componentName, group = variable, y = value / total)) +
  geom_bar(aes(fill = variable), position = "stack", stat = 'identity') +
  geom_bar(aes(fill = variable), position = "stack", stat = 'identity') +
  geom_bar(aes(fill = variable), position = "stack", stat = 'identity') +
  labs(title = "Average errors, fails and successes of test run attempts per component", x = "Component", y = "Average", fill = "Result") +
  scale_fill_manual(values = c("red", "orange", "green"), labels = c("Compilation error", "Runtime/Assertion error", "Tests passed")) +
  scale_y_continuous(labels = scales::percent_format(scale = 100)) +
  geom_text(aes(label = ifelse(value > 0, round(value, 1), '')), position = position_stack(vjust = 0.5), size = 3)
ggsave(filename = paste0(outputDir, "attempts_until_activation_avg_per_component_percentages.png"), width = 8, height = 5)

level_reached <- fromJSON(txt = "./visualizer/r_json/levelReached_r.json", flatten = TRUE)
users_that_reached_level4 <- level_reached %>%
  filter(value > 3) %>%
  select(user)
avg_per_component_only_users_that_reached_level4 <- attempts %>%
  inner_join(users_that_reached_level4, by = "user") %>%
  filter(componentName != "ReactorLog") %>%
  group_by(componentName) %>%
  summarise(avg_errors = mean(errors), avg_fails = mean(fails), avg_successes = mean(successes))
amount_of_users_that_reached_level4 <- nrow(users_that_reached_level4)
avg_per_component_only_users_that_reached_level4_melted <- melt(avg_per_component_only_users_that_reached_level4, id = "componentName")

avg_per_component_only_users_that_reached_level4_total <- attempts %>%
  inner_join(users_that_reached_level4, by = "user") %>%
  filter(componentName != "ReactorLog") %>%
  group_by(componentName) %>%
  summarise(avg_total = mean(errors + fails + successes))

plot <- ggplot(data = avg_per_component_only_users_that_reached_level4_melted, aes(x = componentName)) +
  geom_area(position = "stack", aes(y = value, fill = variable, group = variable)) +
  scale_fill_manual(values = c("red", "orange", "green"), labels = c("Errors", "Fails", "Successes")) +
  # geom_bar(stat = "identity", fill = "blue", color = "blue", alpha = .5, data = avg_per_component_only_users_that_reached_level4_total, aes(x = componentName, y = avg_total, color = "blue")) +
  labs(title = paste0("Average errors, fails and successes per user & component for the ", amount_of_users_that_reached_level4, " users that reached level 4"),
       x = "Component", y = "Average attempts", fill = "Type", group = "Type")
plot
ggsave(filename = paste0(outputDir, "attemptsUntilActivation_avg_per_component_only_users_that_reached_level4.png"), plot, width = 10, height = 5)


# create contingency table of observed values
component_name_to_index <- function(component_name) {
  switch(component_name,
         "CryoSleep" = return(1),
         "Engine" = return(2),
         "GreenHouse" = return(3),
         "Kitchen" = return(4),
         "ReactorLog" = return(5),
  )
}

nnn <- attempts %>%
  filter(user %in% users_that_reached_level4$user) %>%
  filter(componentName != "ReactorLog") %>%
  # only keep users that have data for all components present
  group_by(user) %>%
  filter(n() == 4)

data_users_count <- nnn %>%
  group_by(componentName) %>%
  summarise(c = n()) %>%
  pull(c) %>%
  unique()

nn <- nnn %>%
  group_by(user, componentName) %>%
  summarise(total = errors + fails + successes)

m <- nn %>%
  mutate(componentIndex = sapply(componentName, component_name_to_index)) %>%
  arrange(componentIndex)

contingency_table <- xtabs(~nn$componentName + nn$total)
contingency_table

# perform Chi-Square test
result <- chisq.test(contingency_table)

# summarize Chi-Square test results
summary(result)
#library(ggpubr)
#ggpubr::ggballoonplot(as.data.frame(contingency_table))
#ggpubr::ggballoonplot(as.data.frame(result$result))


plot <- ggplot(data = m, aes(x = componentIndex, y = total)) +
  geom_boxplot(aes(x = componentName), alpha = 0.66, color = "gray") +
  labs(title = "Attempts per component for users that reached level 4", x = "Component", y = "Attempts") +
  geom_point() +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE, color = "red")
plot
ggsave(filename = paste0(outputDir, "attempts_until_activation_trend.png"), plot, width = 10, height = 8)

res <- lm(m$total ~ m$componentIndex)


model <- lm(total ~ componentIndex, data = m)
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

nnn_melted <- melt(nnn, id = c("user", "componentName"))
ggplot(data = nnn_melted, aes(x = componentName, y = value, color = variable, group = interaction(componentName, variable))) +
  geom_boxplot(width = .5) +
  geom_smooth(method = "lm", se = FALSE, formula = y ~ x, aes(group = variable), linetype = "dashed", size = .5) +
  labs(title = "Attempts per component for users that reached level 4", x = "Component", y = "Attempts",
       fill = "Type of metric", group = "Type of metric") +
  scale_color_manual(values = c("red", "blue", "orange"), labels = c("Errors", "Fails", "Successes")) +
  scale_y_continuous(sec.axis = sec_axis(~., name = "Amount", breaks = seq(0, 100, 2)), breaks = seq(0, 100, 2))

nnn <- nnn %>%
  mutate(componentIndex = sapply(componentName, component_name_to_index))
model_nnn <- lm(errors ~ componentIndex, data = nnn)
summary_model_nnn <- summary(model_nnn)
# Extract the slope (coefficient of componentIndex) and p-value
slope_nnn <- summary_model_nnn$coefficients["componentIndex", "Estimate"]
p_value_nnn <- summary_model_nnn$coefficients["componentIndex", "Pr(>|t|)"]
# Check if the slope is negative and the p-value is significant
print(paste0("Slope: ", slope_nnn, ", p-value: ", p_value_nnn))
if (slope_nnn < 0 && p_value_nnn < 0.05) {
  print("There is a significant downward linear trend.")
} else {
  print("There is no significant downward linear trend.")
}
