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
gglikert(all) +
  scale_fill_manual(values = colors[-1]) +
  theme(legend.position = "bottom", legend.justification = "left")
ggsave(filename = paste0(outputDir, "paper/rq4_1_survey_likert_plots.png"), width = 11, height = 9)


# (2) Combined plots from both datasets ---------------------------------------#
surveySE <- loadSurveySEData() %>%
  mutate(across(everything(), ~factor(.x, levels = likert_levels_all)))
surveyST <- loadSurveySTData() %>%
  mutate(across(everything(), ~factor(.x, levels = likert_levels_all)))
combined <- mutate(surveySE, dataset = "SE") %>%
  bind_rows(mutate(surveyST, dataset = "ST"))
gglikert(
  combined,
  include = colnames(surveySE),
  #`I enjoyed playing Sojourner under Sabotage `:`Debugging got easier from room to room `,
  y = "group",
  facet_rows = vars(.question),
  add_labels = FALSE
) +
  facet_wrap(~.question, ncol = 1) +
  scale_fill_manual(values = colors[-1]) +
  theme(legend.position = "bottom") +
  # change facet background color
  theme(
    strip.background = element_rect(fill = rgb(0.9, 0.9, 0.9, 1)),
    strip.text = element_text(color = "black", size = 11)
  )
ggsave(filename = paste0(outputDir, "paper/rq4_2_survey_likert_plots_combined.png"), width = 9, height = 13)
