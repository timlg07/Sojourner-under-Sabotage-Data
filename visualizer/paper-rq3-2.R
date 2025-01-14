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
# RQ3 - How did the students perform in debuggin activities?                   #
#==============================================================================#

# (2) Amount of prints added --------------------------------------------------#

prints <- fromJSON(txt = "./visualizer/r_json/printsAddedPerComponent_r.json", flatten = TRUE)
prints_non_zero <- prints %>%
  filter(maxPrints > 0)

prints_per_component_total <- prints %>% # use prints_non_zero to exclude components with no prints
  group_by(componentName) %>%
  summarise(total = sum(maxPrints))

plot <- ggplot(data = levelNumbers(prints_per_component_total), aes(x = componentName, y = total)) +
  theme_minimal() +
  geom_bar(stat = "identity", fill = colors[1]) +
  labs(x = element_blank(), y = "Number of prints added") +
  scale_y_continuous(breaks = seq(0, 100, 1)) +
  geom_text(aes(label = paste("Total:", total)), vjust = 2, size = 3, color = "white")
plot
ggsave(paste0(outputDir, "paper/rq3_2_prints_added_per_component.png"), width = 6, height = 4)
