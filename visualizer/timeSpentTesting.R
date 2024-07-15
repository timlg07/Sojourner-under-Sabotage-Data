library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

if (!exists("outputDir")) outputDir <- "./visualizer/out/"

time_testing <- fromJSON(txt = "./visualizer/r_json/timeUntilActivation_r.json", flatten = TRUE) %>%
  filter(value != "not finished") %>%
  mutate(value = as.numeric(value)) %>%
  filter(value < 55) # continued playing at home

avg_per_user <- time_testing %>%
  group_by(user) %>%
  summarise(avg_time = mean(value))

total_testing_per_user <- time_testing %>%
  group_by(user) %>%
  summarise(total_time = sum(value))

avg_time_spent_testing <- mean(time_testing$value)
print(paste("Average time spent testing:", avg_time_spent_testing))

time_debugging <- fromJSON(txt = "./visualizer/r_json/attemptsUntilFixed_summary_r.json", flatten = TRUE) %>%
  filter(deltaTime != "not fixed") %>%
  mutate(value = as.numeric(deltaTime)) %>%
  filter(value < 55) %>% # continued playing at home
  select(user, componentName, deltaTime)

total_debugging_per_user <- time_debugging %>%
  group_by(user) %>%
  summarise(total_time = sum(deltaTime))

plot_time_spent <- function (total_time_df) {
  total_time_melted <- melt(total_time_df, id = "user")

  plot <- ggplot(data = total_time_melted, aes(x = variable, y = value, fill = variable, group = variable)) +
    geom_violin(alpha = .75, color = "transparent") +
    geom_boxplot(width = .15, color = "white") +
    labs(title = "Total time spent on each type of tasks per user",
         x = "Type of tasks", y = "Time spent in minutes", fill = "Type of tasks", group = "Type of tasks") +
    scale_fill_manual(values = c("#00d070", "#ff9e49", "#579ad6"), labels = c("Testing", "Debugging", "Other")) +
    expand_limits(y = 0) +
    theme(legend.position = "none") +
    # display mean value at the center of the boxplot
    stat_summary(fun = mean, geom = "point", size = 1, color = "black") +
    stat_summary(fun = mean, geom = "text", aes(label = paste("average:\n", round(..y.., 0), "min")), vjust = -.25)
  return(plot)
}

# build everything in one df
total_time <- inner_join(total_testing_per_user, total_debugging_per_user, by = "user")
total_time$test <- total_time$total_time.x
total_time$debug <- total_time$total_time.y
total_time$other <- 60 - total_time$test - total_time$debug
total_time <- total_time[, c("user", "test", "debug", "other")]


plot <- plot_time_spent(total_time)
plot
ggsave(filename = paste0(outputDir, "timeSpentOnTasks.png"), plot, width = 10, height = 8)

# restrict to only people who reached level 4
level_reached <- fromJSON(txt = "./visualizer/r_json/levelReached_r.json", flatten = TRUE)
users_that_reached_level4 <- level_reached %>%
  filter(value > 3) %>%
  select(user)
total_time <- inner_join(total_time, users_that_reached_level4, by = "user")

# plot_time_spent(total_time)
