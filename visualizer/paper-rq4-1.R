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
# RQ4 - How did the students perceive SuS?                                     #
#==============================================================================#

# (1) Likert plots -------------------------------------------------------------#
survey <- loadSurveyData()

likert_levels_all <- c(
  "Fully disagree",
  "Partially disagree",
  "Neither agree nor disagree",
  "Partially agree",
  "Fully agree"
)
all <- survey %>%
  select(starts_with("Please.specify.your.level.of.agreement")) %>%
  rename_with(~gsub("Please\\.specify\\.your\\.level\\.of\\.agreement\\.+", "", .x)) %>%
  rename_with(~gsub("\\.+", " ", .x)) %>%
  rename_with(~gsub("learned practised", "learned/practised", .x)) %>%
  mutate(across(everything(), ~factor(.x, levels = likert_levels_all)))
# add numbers to all questions
colnames(all) <- sprintf("(Q%02d) %s", seq(1, 14), colnames(all))
gglikert(all) + scale_fill_manual(values = colors[-1])
ggsave(filename = paste0(outputDir, "paper/rq4_1_survey_likert_plots.png"), width = 9, height = 9)
