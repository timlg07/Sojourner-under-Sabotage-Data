library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

if (!exists("outputDir")) outputDir <- "./visualizer/out/"

coverage <- fromJSON(txt = "./visualizer/r_json/coverageAtActivation_r.json", flatten = TRUE) %>%
  filter(componentName != "ReactorLog")

ggplot(data = coverage, aes(x = componentName, y = fraction)) +
  geom_violin() +
  labs(x = "Component", y = "Coverage at activation")
ggsave(filename = paste0(outputDir, "coverage_at_activation.png"), width = 12, height = 8)

destroyed_or_alarm <- fromJSON(txt = "./visualizer/r_json/destroyedOrAlarm_r.json", flatten = TRUE) %>%
  filter(componentName != "ReactorLog")

cov_vs_doa <- merge(coverage, destroyed_or_alarm, by = c("user", "componentName")) %>%
  select(user, componentName, coverage = fraction, result = value)

ggplot(data = cov_vs_doa %>% filter(componentName != "Kitchen"), aes(x = interaction(componentName, result), y = coverage)) +
  geom_violin(aes(fill = result), alpha = .5) +
  #geom_boxplot(width = .15, alpha = .25, fill = "white", color = "white") +
  geom_point(position = position_jitter(width = 0.08, height = 0), fill = "transparent", color = "black", pch = 21, size = 3) +
  labs(y = "Coverage at activation", x = "Component / Destroyed or alarm") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  scale_fill_manual(values = c("green", "red"), labels = c("Alarm", "Destroyed"))
ggsave(filename = paste0(outputDir, "coverage_vs_destroyed_or_alarm.png"), width = 12, height = 8)
