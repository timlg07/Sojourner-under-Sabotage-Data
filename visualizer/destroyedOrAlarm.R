library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

if (!exists("outputDir")) outputDir <- "./visualizer/out/"

destroyed_or_alarm <- fromJSON(txt = "./visualizer/r_json/destroyedOrAlarm_r.json", flatten = TRUE) %>%
  mutate(value = as.character(value))

overall <- destroyed_or_alarm %>%
  group_by(value) %>%
  summarise(count = n()) %>%
  mutate(percentage = count / sum(count) * 100)

counts <- destroyed_or_alarm %>%
  group_by(componentName, value) %>%
  summarise(count = n())

sums <- counts %>%
  group_by(componentName) %>%
  mutate(total = sum(count))

percentages <- merge(sums, counts, by = c("componentName", "value")) %>%
  mutate(percentage = count.y / total * 100) %>%
  select(componentName, type = value, percentage, count = count.y) %>%
  mutate(type = ifelse(type == "destroyed", "1 Destroyed", "2 Alarm"))

ggplot(data = percentages, aes(x = componentName, y = percentage, fill = type)) +
  theme_minimal() +
  geom_bar(stat = "identity", position = "stack") +
  labs(#title = "Percentage of destroyed or alarm events per component",
       x = "Component", y = "Percentage", fill = "Result") +
  scale_fill_manual(values = c("grey", "#00d070"), labels = c("Destroyed", "Alarm")) +
  geom_text(aes(label = count), size = 3, position = position_stack(vjust = .5))
ggsave(filename = paste0(outputDir, "destroyed_or_alarm_percentage.png"), width = 10, height = 5)

ggplot(data = percentages, aes(x = componentName, y = count, fill = type)) +
  geom_bar(stat = "identity", position = "stack") +
  labs(title = "Amount of destroyed or alarm events per component", x = "Component", y = "Amount", fill = "Result") +
  scale_fill_manual(values = c("grey", "#00d070"), labels = c("Destroyed", "Alarm")) +
  geom_text(aes(label = paste(round(percentage, 0), "%")), size = 3, position = position_stack(vjust = .5))


counts_per_person <- destroyed_or_alarm %>%
  group_by(user, value) %>%
  summarise(count = n()) %>%
  mutate(value = ifelse(value == "destroyed", "1 Destroyed", "2 Alarm")) %>%
  mutate(user = as.character(user)) %>%
  arrange(desc(count)) %>%
  mutate(user = factor(user, levels = unique(user)))

time_spent_testing <- fromJSON(txt = "./visualizer/r_json/timeUntilActivation_r.json", flatten = TRUE) %>%
  filter(value != "not finished") %>%
  mutate(value = as.numeric(value)) %>%
  filter(value < 55) %>% # continued playing at home
  group_by(user) %>%
  summarise(total_time = sum(value)) %>%
  mutate(user = as.character(user)) %>%
  arrange(desc(total_time)) %>%
  mutate(user = factor(user, levels = unique(user)))

ggplot(data = time_spent_testing, aes(x = user, y = total_time)) +
  geom_line(aes(group = 1)) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  labs(title = "Total time spent testing per user", x = "User", y = "Time in minutes") +
  geom_bar(stat = "identity", position = "stack", data = counts_per_person, aes(x = user, y = 10 * count, fill = value)) +
  scale_fill_manual(values = c("grey", "#00d070"), labels = c("Destroyed", "Alarm")) +
  scale_y_continuous(sec.axis = sec_axis(~. / 10, name = "Amount of destroyed or alarm events"))


# unmelt destroyed / alarm as columns
time_and_results <- counts_per_person
time_and_results$destroyed <- ifelse(time_and_results$value == "1 Destroyed", time_and_results$count, 0)
time_and_results$alarm <- ifelse(time_and_results$value == "2 Alarm", time_and_results$count, 0)
time_and_results <- time_and_results[, c("user", "destroyed", "alarm")] %>%
  group_by(user) %>%
  summarise(destroyed = sum(destroyed), alarm = sum(alarm))

# merge in one df
time_and_results <- inner_join(time_spent_testing, time_and_results, by = "user")

ggplot(data = time_and_results, aes(x = total_time, y = destroyed, color = "Destroyed")) +
  theme_minimal() +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, formula = y ~ x) +
  geom_point(aes(x = total_time, y = alarm, color = "Alarm")) +
  geom_smooth(aes(x = total_time, y = alarm, color = "Alarm"), method = "lm", se = FALSE, formula = y ~ x) +
  labs(#title = "Total time spent testing vs. amount of destroyed or alarm events",
         x = "Time spent in minutes", y = "Amount of events", color = "Result") +
  scale_color_manual(values = c( "blue","red"), labels = c("Alarm","Destroyed"))
ggsave(filename = paste0(outputDir, "time_spent_testing_vs_destroyed_or_alarm.png"), width = 10, height = 5)

# check if significant using linear regression
d <- lm(destroyed ~ total_time, data = time_and_results)
ds <- summary(d)
ds$coefficients

a <- lm(alarm ~ total_time, data = time_and_results)
as <- summary(a)
as$coefficients
