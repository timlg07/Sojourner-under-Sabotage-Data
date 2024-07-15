library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

if (!exists("outputDir")) outputDir <- "./visualizer/out/"

time_testing <- fromJSON(txt = "./visualizer/r_json/timeUntilActivation_r.json", flatten = TRUE) %>%
  filter(value != "not finished") %>%
  mutate(value = as.numeric(value)) %>%
  filter(value < 55) %>% # continued playing at home
  select(user, componentName, test = value)

time_debugging <- fromJSON(txt = "./visualizer/r_json/attemptsUntilFixed_summary_r.json", flatten = TRUE) %>%
  filter(deltaTime != "not fixed") %>%
  mutate(value = as.numeric(deltaTime)) %>%
  filter(value < 55) %>% # continued playing at home
  select(user, componentName, debug = deltaTime)

# build everything in one df
times <- merge(time_testing, time_debugging, by = c("user", "componentName"), all = TRUE) %>%
  mutate(test = ifelse(is.na(test), 0, test),
         debug = ifelse(is.na(debug), 0, debug)) %>%
  filter(componentName != "ReactorLog") %>% # only 1 data point
  select(user, componentName, test, debug)


plot_time_spent <- function(time_df, box_plot_scale = .15) {
  df_melted <- melt(time_df, id = c("user", "componentName")) %>%
    mutate(variable = ifelse(variable == "test", "1 Testing", "2 Debugging"))

  user_count <- time_df %>%
    select(user) %>%
    distinct() %>%
    nrow()

  plot <- ggplot(data = df_melted, aes(x = componentName, y = value, fill = variable, group = interaction(componentName, variable))) +
    geom_boxplot() +
    stat_summary(fun = mean, geom = "text", aes(label = paste("\naverage:", round(..y.., 1), "min\n"), vjust = ifelse(variable == "1 Testing", 0.1, 0.9)), hjust = 0.5, angle = 90) +
    scale_fill_manual(values = c("#00d070", "#ff9e49"), labels = c("Testing", "Debugging")) +
    # expand_limits(y = 45) +
    labs(title = paste0("Total time spent on each type of tasks per user and component \n(", user_count, " users considered)"),
         x = "Level", y = "Time spent in minutes", fill = "Type of tasks", group = "Type of tasks")
  return(plot)
}


plot <- plot_time_spent(times)
plot
ggsave(filename = paste0(outputDir, "time_spent_per_component.png"), plot, width = 12, height = 8)

average_testing_time <- mean(times %>% filter(test > 0) %>% select(test) %>% unlist())
average_debugging_time <- mean(times %>% filter(debug > 0) %>% select(debug) %>% unlist())
minimum_testing_time <- min(times %>% filter(test > 0) %>% select(test) %>% unlist())
minimum_debugging_time <- min(times %>% filter(debug > 0) %>% select(debug) %>% unlist())
maximum_testing_time <- max(times %>% filter(test > 0) %>% select(test) %>% unlist())
maximum_debugging_time <- max(times %>% filter(debug > 0) %>% select(debug) %>% unlist())

# restrict to only people who reached level 4
level_reached <- fromJSON(txt = "./visualizer/r_json/levelReached_r.json", flatten = TRUE)
users_that_reached_level4 <- level_reached %>%
  filter(value > 3) %>%
  select(user)
times_level4 <- inner_join(times, users_that_reached_level4, by = "user")

plot <- plot_time_spent(times_level4, box_plot_scale = .08)
plot
ggsave(filename = paste0(outputDir, "time_spent_per_component_level4+.png"), plot, width = 12, height = 8)

users_not_reached_level4 <- level_reached %>%
  filter(value <= 3) %>%
  select(user)
times_not_level4 <- inner_join(times, users_not_reached_level4, by = "user")

plot <- plot_time_spent(times_not_level4, box_plot_scale = .08)
plot
ggsave(filename = paste0(outputDir, "time_spent_per_component_level1-3.png"), plot, width = 12, height = 8)
