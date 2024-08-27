library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

source("./visualizer/utils.R")

if (!exists("outputDir")) outputDir <- "./visualizer/out/"
if (!exists("presentationDir")) presentationDir <- "./visualizer/out/"

debugging <- fromJSON(txt = "./visualizer/r_json/attemptsUntilFixed_summary_r.json", flatten = TRUE) %>%
  filter(deltaTime != "not fixed") %>%
  mutate(deltaTime = as.numeric(deltaTime)) %>%
  filter(deltaTime < 55) %>% # continued playing at home
  select(user, componentName, deltaTime, modifications, executions, hiddenTestsAdded)

debugging %>% group_by(modifications) %>% summarise(count = n()) %>% arrange(desc(count))

debugging_per_component <- debugging %>%
  group_by(componentName) %>%
  summarise(avg_time = mean(deltaTime), avg_mod = mean(modifications),
            avg_exc = mean(executions), avg_hid = mean(hiddenTestsAdded))

debugging_per_component_melted <- melt(debugging_per_component, id = "componentName")

ggplot(data = debugging_per_component_melted, aes(x = componentName, group = variable, y = value)) +
  theme_minimal() +
  geom_line(aes(color = variable)) +
  geom_point(aes(color = variable)) +
  labs(#title = "Average time, amount of modifications, executions and hidden tests added until the component was fixed",
       x = "Component", y = "Average time spent debugging in minutes", color = "Type of metric") +
  scale_color_manual(values = c("red", "orange", "green", "blue"), labels = c("Time", "Modifications", "Executions", "Hidden tests added")) +
  scale_y_continuous(sec.axis = sec_axis(~., name = "Amount", breaks = seq(0, 10, 1)), breaks = seq(0, 10, 1))
ggsave(filename = paste0(outputDir, "debugging_performance_per_component.png"), width = 12, height = 5)

averages <- debugging %>%
  summarise(avg_time = mean(deltaTime), avg_mod = mean(modifications),
            avg_exc = mean(executions), avg_hid = mean(hiddenTestsAdded))

totals <- debugging %>%
  summarise(total_time = sum(deltaTime), total_mod = sum(modifications),
            total_exc = sum(executions), total_hid = sum(hiddenTestsAdded))

debugging_melted <- melt(debugging, id = c("componentName", "user")) %>%
  filter(variable != "executions")
plot <- ggplot(data = levelNumbers(debugging_melted), aes(x = componentName, y = value, color = variable, group = interaction(componentName, variable))) +
  theme_minimal() +
  #geom_violin() +
  geom_boxplot(width = .5) +
  #geom_smooth(method = "loess",se = FALSE, formula = y ~ x, aes(group = variable), linetype = "dashed", size = .5) +
  #geom_point()+
  labs(#title = "Time spent debugging per component",
       x = element_blank(), y = "Time spent in minutes", fill = "Type of metric", group = "Type of metric") +
  scale_color_manual(values = c(colors[8], colors[11], colors[7]), labels = c("Time", "Modifications", "Hidden tests added"), name = "Type of metric") +
  scale_y_continuous(sec.axis = sec_axis(~., name = "Amount", breaks = seq(0, 100, 2)), breaks = seq(0, 100, 2))
plot
ggsave(filename = paste0(outputDir, "debugging_performance_per_component_boxplots.png"), width = 7, height = 4)
ggsave(filename = paste0(presentationDir, "debugging_performance_per_component_boxplots_dark.png"), plot + ggdark::dark_theme_minimal() + theme(plot.background = element_rect(color = NA)), width = 7, height = 4)
