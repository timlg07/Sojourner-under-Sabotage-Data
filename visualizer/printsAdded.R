library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

if (!exists("outputDir")) outputDir <- "./visualizer/out/"

prints <- fromJSON(txt = "./visualizer/r_json/printsAddedPerComponent_r.json", flatten = TRUE)
prints_non_zero <- prints %>%
  filter(maxPrints > 0)

users_who_added_prints <- prints_non_zero %>%
  group_by(user) %>%
  summarise(count = sum(maxPrints)) %>%
  arrange(desc(count)) %>%
  mutate(user = as.character(user)) %>%
  mutate(user = factor(user, levels = unique(user)))

prints_per_component_total <- prints_non_zero %>%
  group_by(componentName) %>%
  summarise(total = sum(maxPrints))

ggplot(data = prints_per_component_total, aes(x = componentName, y = total)) +
  theme_minimal() +
  geom_bar(stat = "identity") +
  labs(x = "Component", y = "Total amount of prints added") +
  geom_text(aes(label = paste("Total:", total)), vjust = 1.5, size = 3, color = "white")
ggsave(paste0(outputDir, "prints_added_per_component.png"), width = 6, height = 4)
