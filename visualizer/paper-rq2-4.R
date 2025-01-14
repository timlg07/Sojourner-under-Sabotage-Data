library(jsonlite)
library(ggstats)
library(ggplot2)
library(ggdark)
library(dplyr)
library(purrr)
library(reshape2)

source("./visualizer/utils.R")

if (!exists("outputDir")) outputDir <- "./visualizer/out/"
if (!exists("presentationDir")) presentationDir <- "./visualizer/out/"

#==============================================================================#
# RQ2 - How did the students perform in testing activities?                    #
#==============================================================================#

# (4) Target mutant killed per component --------------------------------------#

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

plot <- ggplot(data = levelNumbers(percentages), aes(x = componentName, y = percentage, fill = type)) +
  theme_minimal() +
  geom_bar(stat = "identity", position = "stack") +
  labs(#title = "Percentage of destroyed or alarm events per component",
    x = element_blank(), y = element_blank(), fill = "Result") +
  scale_y_continuous(labels = scales::percent_format(scale = 1)) +
  scale_fill_manual(values = c("#ddd", colors[1]), labels = c("Destroyed (Mutant not detected)", "Alarm (Mutant detected)")) +
  theme(legend.position = "bottom")
plot + geom_text(aes(label = count), size = 3, position = position_stack(vjust = .5))
ggsave(filename = paste0(outputDir, "paper/rq2_4_target_mutant_killed.png"), width = 6, height = 4)
