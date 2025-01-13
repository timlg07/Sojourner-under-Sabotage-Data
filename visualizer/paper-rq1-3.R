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
# RQ1 - How do students engage with SuS?                                       #
#==============================================================================#

# (3) Results of the test executions ------------------------------------------#

attempts <- fromJSON(txt = "./visualizer/r_json/attemptsUntilActivation_r.json", flatten = TRUE)

avg_per_component <- attempts %>%
  group_by(componentName) %>%
  summarise(avg_errors = mean(errors), avg_fails = mean(fails), avg_successes = mean(successes),
            total = avg_errors + avg_fails + avg_successes)

avg_per_component_melted <- melt(avg_per_component, id = c("componentName", "total"))

plot <- ggplot(data = levelNumbers(avg_per_component_melted), aes(x = componentName, group = variable, y = value / total)) +
  theme_minimal() +
  geom_bar(aes(fill = variable), position = "stack", stat = 'identity') +
  geom_bar(aes(fill = variable), position = "stack", stat = 'identity') +
  geom_bar(aes(fill = variable), position = "stack", stat = 'identity') +
  labs(#title = "Average errors, fails and successes of test run attempts per component",
    x = element_blank(), y = "Average", fill = "Result") +
  scale_fill_manual(values = c(colors[7], colors[12], colors[2]), labels = c("Compilation error", "Runtime/Assertion error", "Tests passed")) +
  scale_y_continuous(labels = scales::percent_format(scale = 100)) +
  geom_text(aes(label = ifelse(value > 0, paste0(round(value / total * 100, 0), " %\n(", round(value, 1), ")"), '')),
            color = ifelse(avg_per_component_melted$variable != "avg_errors", "black", "white"),
            position = position_stack(vjust = 0.5), size = 3)
plot
ggsave(filename = paste0(outputDir, "paper/rq1_3_attempts_until_activation_avg_per_component.png"), width = 10, height = 5)
