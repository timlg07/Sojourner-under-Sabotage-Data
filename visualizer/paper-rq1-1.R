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

# (1) Time spent on each level ------------------------------------------------#

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

times <- merge(time_testing, time_debugging, by = c("user", "componentName"), all = TRUE) %>%
  mutate(test = ifelse(is.na(test), 0, test),
         debug = ifelse(is.na(debug), 0, debug)) %>%
  select(user, componentName, test, debug)
  # uncomment to include total time
  # %>% mutate(total = test + debug)

plot_time_spent <- function(time_df, box_plot_scale = .5, test_group) {
  time_df <- time_df %>% filterDataByTestGroup(test_groups[test_group])
  df_melted <- melt(levelNumbers(time_df), id = c("user", "componentName")) %>%
    mutate(variable = ifelse(variable == "test", "1 Testing", ifelse(variable == "debug","2 Debugging", "3 Total"))) %>%
    filter(value > 0)

  user_count <- time_df %>%
    select(user) %>%
    distinct() %>%
    nrow()

  plot <- ggplot(data = df_melted, aes(x = componentName, y = value, color = variable, fill = variable, group = interaction(componentName, variable))) +
    theme_minimal() +
    geom_boxplot(width = box_plot_scale) +
    stat_summary(fun = mean, geom = "text", color="black", aes(
      label = "",#paste("\naverage:", round(..y.., 0), "min\n"),
      vjust = ifelse(variable == "1 Testing", 0.1, 0.9)
    ), hjust = 0.5, angle = 90) +
    scale_fill_manual(values = colors[c(2,1,3)], labels = c("Testing", "Debugging", "Total")) +
    scale_color_manual(values = colors[c(4,5,3)], labels = c("Testing", "Debugging", "Total")) +
    expand_limits(y = 40) +
    labs(title = element_blank(), #paste0("Total time spent on each type of tasks per component \n(", user_count, " players considered)"),
         x = element_blank(),#"Level",
         y = "Time spent in minutes",
         fill = "Type of tasks",
         color = "Type of tasks",
         group = "Type of tasks") +
    theme(legend.position = "bottom")
  return(plot)
}

do_plot <- function (for_group) {
  plot <- plot_time_spent(times, test_group = for_group)
  ggsave(filename = paste0(outputDir, "paper/rq1_1_time_spent_per_component__",for_group,".png"), plot,
         width = 4.714, height = 3.3)
}

do_plot("SE")
do_plot("ST")
