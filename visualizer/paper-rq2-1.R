library(jsonlite)
library(ggstats)
library(ggplot2)
library(ggdark)
library(dplyr)
library(purrr)
library(reshape2)
library(ggpmisc)

source("./visualizer/utils.R")

if (!exists("outputDir")) outputDir <- "./visualizer/out/"
if (!exists("presentationDir")) presentationDir <- "./visualizer/out/"

#==============================================================================#
# RQ2 - How did the students perform in testing activities?                    #
#==============================================================================#

# (1) Mutation score per component --------------------------------------------#


# Load mutation data [ALL] ----------------------------------------------------#

pit_report <- read.csv("./visualizer/mutations.csv", header = FALSE, sep = ",")
pit_data <- pit_report %>%
  select(V2, V4, V5, V6) %>%
  mutate(
    # V2 = componentName.user
    user = as.character(gsub("\\..*", "", V2)),
    componentName = as.character(gsub(".*\\.", "", V2)),
    result = V6,
    lineNumber = V5,
    mutatedMethod = V4,
  ) %>%
  select(-V2, -V4, -V5, -V6)

mutation_score <- pit_data %>%
  group_by(componentName, user) %>%
  summarise(
    total = n(),
    killed = sum(result == "KILLED"),
    survived = sum(result == "SURVIVED"),
    no_coverage = sum(result == "NO_COVERAGE"),
    score = killed / total
  ) %>%
  levelNumbers()


# Intersect with current users ------------------------------------------------#

mutation_score <- mutation_score %>%
  splitDataByTestGroup() %>%
  # filter out components with only one data point:
  group_by(componentName, group) %>%
  filter(n() > 1) %>%
  ungroup()


# Group by component and user -------------------------------------------------#

mutation_score_per_user <- mutation_score %>%
  group_by(user) %>%
  summarise(
    total = sum(total),
    killed = sum(killed),
    survived = sum(survived),
    no_coverage = sum(no_coverage),
    group = first(group)
  ) %>%
  mutate(score = killed / total)

mutation_score_per_component <- mutation_score %>%
  group_by(componentName, group) %>%
  summarise(
    total = sum(total),
    killed = sum(killed),
    survived = sum(survived),
    no_coverage = sum(no_coverage)
  ) %>%
  mutate(score = killed / total)


# Plot ------------------------------------------------------------------------#

ggplot(data = mutation_score, aes(
  x = group,
  y = score,
  fill = group,
  color = group,
  group = interaction(componentName, group)
)) +
  theme_minimal() +
  geom_violin(color = "transparent", alpha = .5, width = 1) +
  geom_boxplot(width = .2) +
  labs(x = element_blank(), y = "Mutation coverage") +
  scale_y_continuous(labels = scales::percent_format(scale = 100)) +
  scale_fill_manual(values = colors[1:2], labels = c("SE", "ST")) +
  scale_color_manual(values = colors[c(5,4)], labels = c("SE", "ST")) +
  theme(legend.position = "bottom") +
  scale_x_discrete(labels = c("SE", "ST")) +
  facet_grid(~ componentName, switch = "x") +
  theme(panel.spacing.x = grid::unit(2, "mm"),
        strip.placement = "outside",
        strip.background = element_blank(),
        legend.position = "none"
  )
ggsave(filename = paste0(outputDir, "paper/rq2_1_combined_mutation_score_per_component_violin.png"), width = 11, height = 8)


# mutation score vs target killed regression -----------------------------------#

destroyed_or_alarm <- fromJSON(txt = "./visualizer/r_json/destroyedOrAlarm_r.json", flatten = TRUE) %>%
  group_by(user) %>%
  filter(n() > 1) %>%
  ungroup() %>%
  levelNumbers()

mutation_score_vs_target_killed <- merge(mutation_score, destroyed_or_alarm, by = c("user", "componentName"))

mutation_score_vs_target_killed_by_user <- mutation_score_vs_target_killed %>%
  group_by(user) %>%
  summarise(
    score = mean(score),
    alarm = sum(value == "alarm"),
    destroyed = sum(value == "destroyed"),
    group = first(group)
  )

mutation_score_vs_target_killed_by_user_ST <- mutation_score_vs_target_killed_by_user %>%
  filter(group == "2_ST")
mutation_score_vs_target_killed_by_user_SE <- mutation_score_vs_target_killed_by_user %>%
  filter(group == "1_SE")

plot_score_vs_result_regression <- function(data) {
  set.seed(42)
  ggplot(data = data) +
    theme_minimal() +
    geom_point(aes(x = score, y = destroyed, color = "Destroyed"), pch = 20, alpha = .5, size = 6, position = position_jitter(width = 0, height = 0.05)) +
    geom_point(aes(x = score, y = alarm, color = "Alarm"), pch = 20, alpha = .5, size = 6, position = position_jitter(width = 0, height = 0.05)) +

    stat_poly_line(aes(x = score, y = destroyed, color = "Destroyed"), method = "lm", se = FALSE, formula = y ~ x) +
    stat_poly_eq(aes(x = score, y = destroyed, color = "Destroyed",
                     label = paste(..rr.label.., ..p.value.label.., sep = "*`,`~")),
                 label.y = 0.85, label.x = 0.5) +

    stat_poly_line(aes(x = score, y = alarm, color = "Alarm"), method = "lm", se = FALSE, formula = y ~ x) +
    stat_poly_eq(aes(x = score, y = alarm, color = "Alarm",
                     label = paste(..rr.label.., ..p.value.label.., sep = "*`,`~")),
                 label.y = 0.075, label.x = 0.5) +

    labs(x = "Average mutation coverage", y = "Number of events", color = "Event result") +
    scale_color_manual(values = colors[c(3, 5)], labels = c("Alarm (Mutant detected)", "Destroyed (Mutant not detected)")) +
    scale_x_continuous(labels = scales::percent_format(scale = 100)) +
    scale_y_continuous(breaks = seq(0, 13, 1), minor_breaks = numeric(0)) +
    theme(legend.position = "bottom")
}

print("ST")
plot_score_vs_result_regression(mutation_score_vs_target_killed_by_user_ST)
ggsave(filename = paste0(outputDir, "paper/rq2_1_mutation_score_vs_target_killed_regression__ST.png"), width = 6, height = 4)

print("SE")
plot_score_vs_result_regression(mutation_score_vs_target_killed_by_user_SE)
ggsave(filename = paste0(outputDir, "paper/rq2_1_mutation_score_vs_target_killed_regression__SE.png"), width = 6, height = 4)
