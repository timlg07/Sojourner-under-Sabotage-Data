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

coverage <- fromJSON(txt = "./visualizer/r_json/coverageAtActivation_r.json", flatten = TRUE) %>%
  levelNumbers() %>%
  splitDataByTestGroup()

ggplot(data = coverage, aes(x = group, y = fraction, fill = group, color = group)) +
  theme_minimal() +
  geom_violin(width = 1, alpha = .5, color = "transparent") +
  geom_boxplot(width = .2) +
  scale_fill_manual(values = colors[1:2]) +
  scale_color_manual(values = colors[c(5,4)]) +
  scale_y_continuous(labels = scales::percent_format(scale = 100), limits = c(0.5, 1)) +
  labs(x = element_blank(), y = "Coverage at activation") +
  scale_x_discrete(labels = c("SE", "ST")) +

  facet_grid(~ componentName, switch = "x") +
  theme(panel.spacing.x = grid::unit(2, "mm"),
        strip.placement = "outside",
        strip.background = element_blank(),
        legend.position = "none"
  )

ggsave(filename = paste0(outputDir, "paper/rq2_2_combined_coverage_at_activation_per_component.png"), width = 12, height = 8)



# ggplot(data = coverage, aes(
#   x = componentName, y = fraction,
#   fill = group,
#   group = interaction(componentName, group)
# )) +
#   theme_minimal() +
#   geom_violin(color = "transparent", alpha = .5, width = 1.25, position = position_dodge(width = 1, preserve = "single")) +
#   geom_boxplot(width = .2, position = position_dodge(preserve = "single", width = 1), color = "white") +
#   labs(x = element_blank(), y = "Coverage at activation") +
#   scale_y_continuous(labels = scales::percent_format(scale = 100), limits = c(0.5, 1)) +
#   scale_fill_manual(values = colors[1:2], labels = c("SE", "ST")) +
#   scale_color_manual(values = colors[1:2], labels = c("SE", "ST")) +
#   theme(legend.position = "bottom")
#
# ggsave(filename = paste0(outputDir, "paper/rq2_2_combined_coverage_at_activation_per_component__old_design.png"), width = 12, height = 8)
