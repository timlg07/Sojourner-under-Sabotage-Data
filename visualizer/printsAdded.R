library(jsonlite)
library(ggplot2)
library(ggdark)
library(dplyr)
library(purrr)
library(reshape2)

source("./visualizer/utils.R")

if (!exists("outputDir")) outputDir <- "./visualizer/out/"
if (!exists("presentationDir")) presentationDir <- "./visualizer/out/"

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

plot <- ggplot(data = levelNumbers(prints_per_component_total), aes(x = componentName, y = total)) +
  theme_minimal() +
  geom_bar(stat = "identity", fill = colors[1]) +
  labs(x = element_blank(), y = "Total amount of prints added") +
  geom_text(aes(label = paste("Total:", total)), vjust = 2, size = 3, color = "white")
plot
ggsave(paste0(outputDir, "prints_added_per_component.png"), width = 6, height = 4)
plot_dark <- plot + ggdark::dark_theme_minimal() + theme(plot.background = element_rect(color = NA))
ggsave(paste0(presentationDir, "prints_added_per_component_dark.png"), plot_dark, width = 6, height = 4)
