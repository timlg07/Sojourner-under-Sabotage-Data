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

# (5) Correlation between coverage and target mutant killed -------------------#
coverage <- fromJSON(txt = "./visualizer/r_json/coverageAtActivation_r.json", flatten = TRUE) %>%
  filter(componentName != "ReactorLog")

destroyed_or_alarm <- fromJSON(txt = "./visualizer/r_json/destroyedOrAlarm_r.json", flatten = TRUE) %>%
  filter(componentName != "ReactorLog")


cov_and_result <- destroyed_or_alarm
cov_and_result$destroyed <- ifelse(cov_and_result$value == "destroyed", 1, 0)
cov_and_result$alarm <- ifelse(cov_and_result$value == "alarm", 1, 0)
cov_and_result <- cov_and_result[, c("user", "destroyed", "alarm")] %>%
  group_by(user) %>%
  summarise(destroyed = sum(destroyed), alarm = sum(alarm))
coverage_per_player <- coverage %>%
  group_by(user) %>%
  summarise(fraction = mean(fraction))
cov_and_result <- inner_join(coverage_per_player, cov_and_result, by = "user")


set.seed(42)
plot <- ggplot(data = cov_and_result, aes()) +
  theme_minimal() +
  geom_point(aes(x = fraction, y = destroyed, color = "Destroyed"), pch = 20, alpha = .5, size = 6, position = position_jitter(width = 0, height = 0.05)) +
  geom_smooth(aes(x = fraction, y = destroyed, color = "Destroyed"), method = "lm", se = FALSE, formula = y ~ x) +
  geom_point(aes(x = fraction, y = alarm, color = "Alarm"), pch = 20, alpha = .5, size = 6, position = position_jitter(width = 0, height = 0.05)) +
  geom_smooth(aes(x = fraction, y = alarm, color = "Alarm"), method = "lm", se = FALSE, formula = y ~ x) +
  labs(x = "Average test coverage", y = "Number of events", color = "Event result") +
  scale_color_manual(values = colors[c(3, 5)], labels = c("Alarm (Mutant detected)", "Destroyed (Mutant not detected)")) +
  scale_x_continuous(labels = scales::percent_format(scale = 100)) +
  scale_y_continuous(breaks = seq(0, 13, 1), minor_breaks = numeric(0)) +
  theme(legend.position = "bottom")
plot
ggsave(filename = paste0(outputDir, "paper/rq2_5_coverage_vs_target_killed_regression__per_player.png"), width = 6, height = 4)
