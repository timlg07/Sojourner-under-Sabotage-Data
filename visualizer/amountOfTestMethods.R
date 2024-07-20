library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

if (!exists("outputDir")) outputDir <- "./visualizer/out/"

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

ggplot(data = methods_per_component_avg, aes(x = componentName, y = avg)) +
  theme_minimal() +
  geom_bar(stat = "identity") +
  labs(title = "Average amount of test methods per component", x = "Component", y = "Average amount of test methods per class") +
  geom_text(aes(label = paste("Average:", round(avg, 1))), vjust = -0.5, size = 3) +
  geom_text(aes(label = paste("Total:", methods_per_component_total %>%
    filter(
      componentName == as.character(componentName)) %>%
    pull(total))), vjust = 1.5, size = 3, color = "white")
ggsave(paste0(outputDir, "amount_of_test_methods_per_component.png"), width = 6, height = 4)
