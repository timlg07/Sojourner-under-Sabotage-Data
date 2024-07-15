library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

if (!exists("outputDir")) outputDir <- "./visualizer/out/"

attempts <- fromJSON(txt = "./visualizer/r_json/attemptsUntilFirstPass_r.json", flatten = TRUE) %>%
  filter(success) %>%
  select(user, componentName, errors, fails)

avg_per_user <- attempts %>%
  group_by(user) %>%
  summarise(avg_errors = mean(errors), avg_fails = mean(fails))

sum_all <- attempts %>%
  summarise(sum_errors = sum(errors), sum_fails = sum(fails))
avg_all <- attempts %>%
  summarise(avg_errors = mean(errors), avg_fails = mean(fails))

avg_per_component <- attempts %>%
  group_by(componentName) %>%
  summarise(avg_errors = mean(errors), avg_fails = mean(fails))

sum_per_component <- attempts %>%
  group_by(componentName) %>%
  summarise(sum = sum(errors) + sum(fails))

avg_total_per_component <- attempts %>%
  group_by(componentName) %>%
  summarise(avg_total = mean(errors + fails))

ggplot(data = avg_per_component, aes(x = componentName, group = 1)) +
  geom_line(color = "red", aes(y = avg_errors)) +
  geom_line(color = "orange", aes(y = avg_fails)) +
  labs(title = "Average errors & fails per component", x = "Component", y = "Average")

users <- nrow(avg_per_user)
avg_per_component_melted <- melt(avg_per_component, id = "componentName")
plot <- ggplot(data = avg_per_component_melted, aes(x = componentName, y = value, fill = variable, group = variable)) +
  geom_area(position = "stack") +
  scale_fill_manual(values = c("red", "orange"), labels = c("Errors", "Fails")) +
  labs(title = paste0("Average errors & fails per user & component (total users: ", users, ")"), x = "Component", y = "Average attempts", fill = "Type", group = "Type")
plot

ggsave(filename = paste0(outputDir, "attemptsUntilFirstPass_avg_per_component.png"), plot, width = 10, height = 5)


level_reached <- fromJSON(txt = "./visualizer/r_json/levelReached_r.json", flatten = TRUE)
users_that_reached_level4 <- level_reached %>%
  filter(value > 3) %>%
  select(user)
avg_per_component_only_users_that_reached_level4 <- attempts %>%
  inner_join(users_that_reached_level4, by = "user") %>%
  filter(componentName != "ReactorLog") %>%
  group_by(componentName) %>%
  summarise(avg_errors = mean(errors), avg_fails = mean(fails))
amount_of_users_that_reached_level4 <- nrow(users_that_reached_level4)
avg_per_component_only_users_that_reached_level4_melted <- melt(avg_per_component_only_users_that_reached_level4, id = "componentName")

avg_per_component_only_users_that_reached_level4_total <- attempts %>%
  inner_join(users_that_reached_level4, by = "user") %>%
  filter(componentName != "ReactorLog") %>%
  group_by(componentName) %>%
  summarise(avg_total = mean(errors + fails))

plot <- ggplot(data = avg_per_component_only_users_that_reached_level4_melted, aes(x = componentName)) +
  geom_area(position = "stack", aes(y = value, fill = variable, group = variable)) +
  scale_fill_manual(values = c("red", "orange"), labels = c("Errors", "Fails")) +
  # geom_bar(stat = "identity", fill = "blue", color = "blue", alpha = .5, data = avg_per_component_only_users_that_reached_level4_total, aes(x = componentName, y = avg_total, color = "blue")) +
  labs(title = paste0("Average errors & fails per user & component for the ", amount_of_users_that_reached_level4, " users that reached level 4"),
       x = "Component", y = "Average attempts", fill = "Type", group = "Type")
plot
ggsave(filename = paste0(outputDir, "attemptsUntilFirstPass_avg_per_component_only_users_that_reached_level4.png"), plot, width = 10, height = 5)


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

nn <- attempts %>%
  filter(user %in% users_that_reached_level4$user) %>%
  filter(componentName != "ReactorLog") %>%
  group_by(user, componentName) %>%
  summarise(total = errors + fails)

m <- nn %>%
  mutate(componentIndex = sapply(componentName, component_name_to_index)) %>%
  arrange(componentIndex)

contingency_table <- xtabs (~ nn$componentName + nn$total)
contingency_table

m_no_cryo <- m %>%
  filter(componentName != "CryoSleep")

# perform Chi-Square test
result <- chisq.test(contingency_table)

# summarize Chi-Square test results
summary(result)
print(paste0("Chi-Square test p-value: ", result$p.value))
#library(ggpubr)
#ggpubr::ggballoonplot(as.data.frame(contingency_table))
#ggpubr::ggballoonplot(as.data.frame(result$result))


plot <- ggplot(data = m, aes(x = componentIndex, y = total)) +
  geom_boxplot(aes(x = componentName), alpha = 0.25, color = "gray") +
  labs(title = "Attempts per component for users that reached level 4", x = "Component", y = "Attempts") +
  geom_point(aes(x = componentName)) +
  # geom_smooth(se = FALSE, color = "blue") +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE, color = "red")
plot
ggsave(filename = paste0(outputDir, "attemptsUntilFirstPass_trend.png"), plot, width = 10, height = 8)

plot <- ggplot(data = m_no_cryo, aes(x = componentName, y = total)) +
  # geom_boxplot(aes(x = componentName), alpha = 0.25, color = "gray") +
  labs(title = "Attempts per component for users that reached level 4", x = "Component", y = "Attempts") +
  geom_point(aes(x = componentName)) +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE, color = "red", aes(x = componentIndex - 1), linetype = "dashed") +
  geom_smooth(se = FALSE, color = "blue", aes(x = componentIndex - 1))
plot
ggsave(filename = paste0(outputDir, "attemptsUntilFirstPass_trend_no_cryo.png"), plot, width = 10, height = 8)

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
print(paste0("Residual Standard Error = ", sigma(model)))
print(paste0("R-squared = ", summary_model$r.squared))


# Check assumptions
# Residuals vs Fitted plot
ggplot(model, aes(.fitted, .resid)) +
  geom_point() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(title = "Residuals vs Fitted",
       x = "Fitted values",
       y = "Residuals")

# Normal Q-Q plot
qqnorm(resid(model))
qqline(resid(model), col = "red")

# Scale-Location plot (Homoscedasticity)
ggplot(model, aes(.fitted, sqrt(abs(.stdresid)))) +
  geom_point() +
  geom_smooth(se = FALSE) +
  labs(title = "Scale-Location",
       x = "Fitted values",
       y = "Sqrt(|Standardized residuals|)")

# Optional: Plot the data and the regression line
ggplot(df, aes(x = componentIndex, y = total)) +
  geom_point() +
  geom_smooth(method = "lm", col = "blue") +
  labs(title = "Linear Regression of Total vs ComponentIndex",
       x = "Component Index",
       y = "Total")
