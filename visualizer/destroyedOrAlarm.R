library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

if (!exists("outputDir")) outputDir <- "./visualizer/out/"

destroyed_or_alarm <- fromJSON(txt = "./visualizer/r_json/destroyedOrAlarm_r.json", flatten = TRUE) %>%
  mutate(value = as.character(value))

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
  geom_bar(stat = "identity", position = "stack") +
  labs(title = "Percentage of destroyed or alarm events per component", x = "Component", y = "Percentage", fill = "Result") +
  scale_fill_manual(values = c("grey", "#00d070"), labels = c("Destroyed", "Alarm")) +
  geom_text(aes(label = count), size = 3, position = position_stack(vjust = .5))
ggsave(filename = paste0(outputDir, "destroyed_or_alarm_percentage.png"), width = 10, height = 5)

ggplot(data = percentages, aes(x = componentName, y = count, fill = type)) +
  geom_bar(stat = "identity", position = "stack") +
  labs(title = "Amount of destroyed or alarm events per component", x = "Component", y = "Amount", fill = "Result") +
  scale_fill_manual(values = c("grey", "#00d070"), labels = c("Destroyed", "Alarm")) +
  geom_text(aes(label = paste(round(percentage, 0), "%")), size = 3, position = position_stack(vjust = .5))

