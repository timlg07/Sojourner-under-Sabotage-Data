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

# (2) Coverage per component --------------------------------------------------#

coverage <- fromJSON(txt = "./visualizer/r_json/coverageAtActivation_r.json", flatten = TRUE)

ggplot(data = levelNumbers(coverage), aes(x = componentName, y = fraction)) +
  theme_minimal() +
  geom_violin(fill = colors[1], width = 1, color = colors[1]) +
  geom_boxplot(width = .1, fill = "white", color = colors[5]) +
  scale_y_continuous(labels = scales::percent_format(scale = 100), limits = c(0.5, 1)) +
  labs(x = element_blank(), y = "Coverage at activation")
ggsave(filename = paste0(outputDir, "paper/rq2_2_coverage_at_activation_per_component.png"), width = 12, height = 8)
