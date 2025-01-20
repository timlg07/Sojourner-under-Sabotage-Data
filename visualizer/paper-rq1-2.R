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
# RQ1 - How do students engage with SuS?                                       #
#==============================================================================#

# (2) Time spent on each type of task -----------------------------------------#

time_testing <- fromJSON(txt = "./visualizer/r_json/timeUntilActivation_r.json", flatten = TRUE) %>%
  filter(value != "not finished") %>%
  mutate(value = as.numeric(value)) %>%
  filter(value < 55) # continued playing at home

total_testing_per_user <- time_testing %>%
  group_by(user) %>%
  summarise(total_time = sum(value))

time_debugging <- fromJSON(txt = "./visualizer/r_json/attemptsUntilFixed_summary_r.json", flatten = TRUE) %>%
  filter(deltaTime != "not fixed") %>%
  mutate(value = as.numeric(deltaTime)) %>%
  filter(value < 55) %>% # continued playing at home
  select(user, componentName, deltaTime)

total_debugging_per_user <- time_debugging %>%
  group_by(user) %>%
  summarise(total_time = sum(deltaTime))

total_time <- inner_join(total_testing_per_user, total_debugging_per_user, by = "user")
total_time$test <- total_time$total_time.x
total_time$debug <- total_time$total_time.y
total_time$other <- 60 - total_time$test - total_time$debug
total_time <- total_time %>%
  filter(test + debug < 55) %>% # continued playing at home
  filter(test + debug > 25) # not finished playing
total_time <- total_time[, c("user", "test", "debug", "other")]

total_time_melted <- melt(total_time, id = "user") %>%
  splitDataByTestGroup()

plot <- ggplot(data = total_time_melted, aes(
  x = group,
  y = value,
  fill = variable,
  group = interaction(group, variable)
)) +
  theme_minimal() +
  geom_violin(alpha = .5, color = "transparent") +
  geom_boxplot(width = .15, color = "white") +
  labs(x = element_blank(), y = "Time spent in minutes", fill = "Type of tasks", group = "Type of tasks") +
  scale_fill_manual(values = colors[c(3, 1, 4)], labels = c("Testing", "Debugging", "Other")) +
  scale_x_discrete(labels = c("ST", "SE")) +
  expand_limits(y = 0) +
  theme(legend.position = "none")+
  facet_grid(~ variable, switch = "x", labeller = as_labeller(c(
    "test" = "Testing",
    "debug" = "Debugging",
    "other" = "Other"
  ))) +
  theme(panel.spacing.x = grid::unit(0, "mm"),
        strip.placement = "outside",
        strip.background = element_blank(),
  )


plot
ggsave(filename = paste0(outputDir, "paper/rq1_2_combined_time_spent_on_tasks.png"), plot, width = 5, height = 4)

# show mean value at the center of the boxplot
plot <- plot +
  stat_summary(fun = mean, geom = "point", size = 1, color = "black") +
  stat_summary(fun = mean, geom = "text", aes(label = paste("average:\n", round(after_stat(y), 0), "min")), vjust = -.25, color = "black")


plot
ggsave(filename = paste0(outputDir, "paper/rq1_2_combined_time_spent_on_tasks_with_mean.png"), plot, width = 5, height = 4)
