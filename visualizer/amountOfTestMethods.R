library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

source("./visualizer/utils.R")

if (!exists("outputDir")) outputDir <- "./visualizer/out/"
if (!exists("presentationDir")) presentationDir <- "./visualizer/out/"

methods <- fromJSON(txt = "./visualizer/r_json/amountOfTestMethods_r.json", flatten = TRUE) %>%
  select(user, componentName, value = testAnnotations)

methods_total <- methods %>%
  summarise(total = sum(value)) %>%
  pull()

methods_per_component_total <- methods %>%
  group_by(componentName) %>%
  summarise(total = sum(value))

methods_per_component_avg <- methods %>%
  group_by(componentName) %>%
  summarise(avg = mean(value))

methods_per_component_avg_avg <- methods_per_component_avg %>%
  summarise(avg = mean(avg)) %>%
  pull()

methods_per_user_total <- methods %>%
  group_by(user) %>%
  summarise(total = sum(value))

methods_per_user_total_avg <- methods_per_user_total %>%
  summarise(avg = mean(total)) %>%
  pull()

plot <- ggplot(data = levelNumbers(methods_per_component_avg), aes(x = componentName, y = avg)) +
  theme_minimal() +
  geom_bar(stat = "identity", fill = "#B8A0F8") +
  labs(#title = "Average amount of test methods per component",
       x = NULL, y = "Average amount of test methods per class") +
  geom_text(aes(label = paste("Total:", methods_per_component_total %>%
    filter(componentName == as.character(componentName)) %>%
    pull(total))), vjust = 1.5, size = 3, color = "white")
plot + geom_text(aes(label = paste("Average:", round(avg, 1))), vjust = -0.5, size = 3)
ggsave(paste0(outputDir, "amount_of_test_methods_per_component.png"), width = 5, height = 3.5)

plot_dark <- plot + theme(text = element_text(colour = "white"),
                          axis.text = element_text(colour = "white"),
                          axis.ticks = element_line(colour = "#888888"),
                          panel.grid = element_line(colour = "#888888")) +
  geom_text(aes(label = paste("Average:", round(avg, 1))), vjust = -0.5, size = 3, color = "white")
plot_dark
ggsave(paste0(presentationDir, "amount_of_test_methods_per_component_dark.png"), plot_dark, width = 5, height = 3.5)
