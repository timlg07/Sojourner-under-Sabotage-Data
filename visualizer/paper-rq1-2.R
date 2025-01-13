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
total_time <- total_time[, c("user", "test", "debug", "other")]

plot_time_spent <- function (total_time_df, box_plot_scale = .15, show_mean = TRUE) {
  total_time_melted <- melt(total_time_df, id = "user")

  plot <- ggplot(data = total_time_melted, aes(x = variable, y = value, fill = variable, group = variable)) +
    theme_minimal() +
    geom_violin(alpha = .5, color = "transparent") +
    geom_boxplot(width = box_plot_scale, color = "white") +
    labs(#title = paste0("Total time spent on each type of tasks per user (", nrow(total_time_df), " users considered)"),
      x = "Type of tasks", y = "Time spent in minutes", fill = "Type of tasks", group = "Type of tasks") +
    scale_fill_manual(values = colors[c(3, 1, 4)], labels = c("Testing", "Debugging", "Other")) +
    expand_limits(y = 0) +
    theme(legend.position = "none")

  if (show_mean) {
    # show mean value at the center of the boxplot
    plot <- plot +
      stat_summary(fun = mean, geom = "point", size = 1, color = "black") +
      stat_summary(fun = mean, geom = "text", aes(label = paste("average:\n", round(after_stat(y), 0), "min")), vjust = -.25, color = "black")
  }

  return(plot)
}

plot <- plot_time_spent(total_time)
plot
ggsave(filename = paste0(outputDir, "paper/rq1_2_time_spent_on_tasks.png"), plot, width = 5, height = 4)
