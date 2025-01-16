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

# per component
plot <- ggplot(data = mutation_score_per_component, aes(
  x = componentName,
  y = score,
  fill = group,
  group = interaction(componentName, group)
)) +
  theme_minimal() +
  geom_bar(stat = "identity", position = position_dodge(preserve = "single")) +
  labs(
    title = element_blank(), #"Mutation score per component",
    x = element_blank(), #"Component",
    y = "Mutation coverage"
  ) +
  scale_y_continuous(labels = scales::percent_format(scale = 100)) +
  scale_fill_manual(values = colors[1:2], labels = c("ST", "SE"))
plot
ggsave(filename = paste0(outputDir, "paper/rq2_1_mutation_score_per_component_bar.png"), width = 10, height = 8)

ggplot(data = mutation_score, aes(
  x = componentName, y = score,
  fill = group,
  group = interaction(componentName, group)
)) +
  theme_minimal() +
  geom_violin(color = "transparent", alpha = .5, width = 1.25, position = position_dodge(width = 1, preserve = "single")) +
  geom_boxplot(width = .2, position = position_dodge(preserve = "single", width = 1), color = "white") +
  labs(x = element_blank(), y = "Mutation coverage") +
  scale_y_continuous(labels = scales::percent_format(scale = 100)) +
  scale_fill_manual(values = colors[1:2], labels = c("ST", "SE")) +
  scale_color_manual(values = colors[1:2], labels = c("ST", "SE"))
ggsave(filename = paste0(outputDir, "paper/rq2_1_mutation_score_per_component_violin.png"), width = 11, height = 8)



#==============================================================================#
# Only current data points                                                     #
#==============================================================================#

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

survey_users <- loadSurveyData() %>%
  select(user = Username) %>%
  distinct()

mutation_score <- mutation_score %>%
  inner_join(survey_users, by = "user")

# filter out components with only one data point:
mutation_score <- mutation_score %>%
  group_by(componentName) %>%
  filter(n() > 1) %>%
  ungroup()

# Group by component and user
mutation_score_per_user <- mutation_score %>%
  group_by(user) %>%
  summarise(
    total = sum(total),
    killed = sum(killed),
    survived = sum(survived),
    no_coverage = sum(no_coverage)
  ) %>%
  mutate(score = killed / total)

mutation_score_per_component <- mutation_score %>%
  group_by(componentName) %>%
  summarise(
    total = sum(total),
    killed = sum(killed),
    survived = sum(survived),
    no_coverage = sum(no_coverage)
  ) %>%
  mutate(score = killed / total)

# plot per component
ggplot(data = mutation_score_per_component, aes(x = componentName, y = score)) +
  theme_minimal() +
  geom_bar(stat = "identity", fill = colors[1]) +
  labs(
    title = element_blank(), #"Mutation score per component",
    x = element_blank(), #"Component",
    y = "Mutation coverage"
  ) +
  scale_y_continuous(labels = scales::percent_format(scale = 100)) +
  geom_text(aes(label = ifelse(score > 0, paste0(round(score * 100, 0), " %"), '')),
            position = position_stack(vjust = 0.5), size = 3, color = "black")
# ggsave(filename = paste0(outputDir, "paper/rq2_1_mutation_score_per_component_bar.png"), width = 10, height = 8)

ggplot(data = mutation_score, aes(x = componentName, y = score)) +
  theme_minimal() +
  geom_violin(color = "transparent", fill = colors[1], alpha = .5) +
  geom_boxplot(width = .1, color = colors[5], fill = "white") +
  labs(x = element_blank(), y = "Mutation coverage") +
  scale_y_continuous(labels = scales::percent_format(scale = 100))
# ggsave(filename = paste0(outputDir, "paper/rq2_1_mutation_score_per_component_violin.png"), width = 10, height = 8)

# relation coverage
coverage <- fromJSON(txt = "./visualizer/r_json/coverageAtActivation_r.json", flatten = TRUE) %>%
  group_by(user) %>%
  summarise(coveredLines = sum(coveredLines), totalLines = sum(totalLines)) %>%
  mutate(fraction = coveredLines / totalLines)
mutation_score_vs_coverage <- inner_join(mutation_score_per_user, coverage, by = "user")

plot <- ggplot(data = mutation_score_vs_coverage, aes(x = fraction, y = score)) +
  theme_minimal() +
  geom_point(color = colors[1]) +
  labs(
    title = element_blank(), #"Mutation score vs. coverage",
    x = "Line Coverage",
    y = "Mutation Coverage"
  ) +
  scale_y_continuous(labels = scales::percent_format(scale = 100)) +
  scale_x_continuous(labels = scales::percent_format(scale = 100)) +
  geom_smooth(method = "lm", se = FALSE, color = colors[2])
#plot
#ggsave(filename = paste0(outputDir, "paper/rq2_1_mutation_score_vs_line_coverage.png"), width = 10, height = 5)
