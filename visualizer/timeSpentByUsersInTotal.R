library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

source("./visualizer/utils.R")

if (!exists("outputDir")) outputDir <- "./visualizer/out/"
if (!exists("presentationDir")) presentationDir <- "./visualizer/out/"

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

# build everything in one df
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
      stat_summary(fun = mean, geom = "text", aes(label = paste("average:\n", round(..y.., 0), "min")), vjust = -.25, color = "black")
  }

  return(plot)
}

plot <- plot_time_spent(total_time)
plot
ggsave(filename = paste0(outputDir, "time_spent_on_tasks.png"), plot, width = 5, height = 4)
plot_dark <- plot_time_spent(total_time, show_mean = FALSE) + theme(
  text = element_text(colour = "white"),
  axis.text = element_text(colour = "white"),
  axis.ticks = element_line(colour = "#888888"),
  panel.grid = element_line(colour = "#888888"))
plot_dark
ggsave(filename = paste0(presentationDir, "time_spent_on_tasks_dark.png"), plot = plot_dark, width = 5, height = 4)

# restrict to only people who reached level 4
level_reached <- fromJSON(txt = "./visualizer/r_json/levelReached_r.json", flatten = TRUE)
users_that_reached_level4 <- level_reached %>%
  filter(value > 3) %>%
  select(user)
total_time_level4 <- inner_join(total_time, users_that_reached_level4, by = "user")

plot <- plot_time_spent(total_time_level4, box_plot_scale = .08)
plot
ggsave(filename = paste0(outputDir, "time_spent_on_tasks_level4+.png"), plot, width = 5, height = 4)
plot_dark <- plot_time_spent(total_time_level4, box_plot_scale = .08, show_mean = FALSE) + theme(
  text = element_text(colour = "white"),
  axis.text = element_text(colour = "white"),
  axis.ticks = element_line(colour = "#888888"),
  panel.grid = element_line(colour = "#888888"))
plot_dark
ggsave(filename = paste0(presentationDir, "time_spent_on_tasks_level4+_dark.png"), plot = plot_dark, width = 5, height = 4)

# find users that are in level_reached, but not in the total_time df
users_not_in_total_time <- level_reached %>%
  anti_join(total_time, by = "user")
# (they're not included as they haven't activated a single test -> no data)


# load survey data
survey <- loadSurveyData() %>%
  select(user = "Username", gender = "Gender", java = "Experience.with.Java", programming = "Experience.with.programming..any.language.")
total_time_demographics <- merge(total_time, survey, by = "user")

# male vs female time spent
plot <- plot_time_spent(total_time_demographics %>% filter(gender == "Male") %>% select(user, test, debug, other))
plot <- plot_time_spent(total_time_demographics %>% filter(gender == "Female") %>% select(user, test, debug, other))
# no real difference
