library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

if (!exists("outputDir")) outputDir <- "./visualizer/out/"

time_testing <- fromJSON(txt = "./visualizer/r_json/timeUntilActivation_r.json", flatten = TRUE) %>%
  filter(value != "not finished") %>%
  mutate(value = as.numeric(value)) %>%
  filter(value < 55) # continued playing at home

avg_per_user <- time_testing %>%
  group_by(user) %>%
  summarise(avg_time = mean(value))

total_testing_per_user <- time_testing %>%
  group_by(user) %>%
  summarise(total_time = sum(value))

avg_time_spent_testing <- mean(time_testing$value)
print(paste("Average time spent testing:", avg_time_spent_testing))

time_debugging <- fromJSON(txt = "./visualizer/r_json/attemptsUntilFixed_summary_r.json", flatten = TRUE) %>%
  filter(deltaTime != "not fixed") %>%
  mutate(value = as.numeric(deltaTime)) %>%
  filter(value < 55) %>% # continued playing at home
  select(user, componentName, deltaTime)

total_debugging_per_user <- time_debugging %>%
  group_by(user) %>%
  summarise(total_time = sum(deltaTime))


ggplot() +
  geom_boxplot(data = total_testing_per_user, aes(y = total_time, x = "test"), color = "grey", alpha = 0.5) +
  geom_point(data = total_testing_per_user, aes(y = total_time, x = "test")) +
  geom_boxplot(data = total_debugging_per_user, aes(y = total_time, x = "debug"), color = "grey", alpha = 0.5) +
  geom_point(data = total_debugging_per_user, aes(y = total_time, x = "debug")) +
  labs(title = "Total time spent on a task per user", x = "Task", y = "Time spent in minutes")
