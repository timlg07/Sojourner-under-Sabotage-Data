library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

if (!exists("outputDir")) outputDir <- "./visualizer/out/"

debugging <- fromJSON(txt = "./visualizer/r_json/attemptsUntilFixed_summary_r.json", flatten = TRUE) %>%
  filter(deltaTime != "not fixed") %>%
  mutate(deltaTime = as.numeric(deltaTime)) %>%
  filter(deltaTime < 55) # continued playing at home

debugging_per_component <- debugging %>%
  group_by(componentName) %>%
  summarise(avg_time = mean(deltaTime), avg_mod = mean(modifications),
            avg_exc = mean(executions), avg_hid = mean(hiddenTestsAdded))

debugging_per_component_melted <- melt(debugging_per_component, id = "componentName")

ggplot(data = debugging_per_component_melted, aes(x = componentName, group = variable, y = value)) +
  geom_line(aes(color = variable)) +
  geom_point(aes(color = variable)) +
  labs(title = "Average time, amount of modifications, executions and\nhidden tests added until the component was fixed",
       x = "Component", y = "Average time spent debugging in minutes", color = "Type of metric") +
  scale_color_manual(values = c("red", "orange", "green", "blue"), labels = c("Time", "Modifications", "Executions", "Hidden tests added")) +
  scale_y_continuous(sec.axis = sec_axis(~., name = "Amount", breaks = seq(0, 10, 1)), breaks = seq(0, 10, 1))
ggsave(filename = paste0(outputDir, "debugging_performance_per_component.png"), width = 10, height = 5)

averages <- debugging %>%
  summarise(avg_time = mean(deltaTime), avg_mod = mean(modifications),
            avg_exc = mean(executions), avg_hid = mean(hiddenTestsAdded))
