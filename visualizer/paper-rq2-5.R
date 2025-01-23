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

# (5) Correlation between coverage and target mutant killed -------------------#
coverage <- fromJSON(txt = "./visualizer/r_json/coverageAtActivation_r.json", flatten = TRUE) %>%
  group_by(user) %>%
  filter(n() > 1) %>%
  ungroup()

destroyed_or_alarm <- fromJSON(txt = "./visualizer/r_json/destroyedOrAlarm_r.json", flatten = TRUE) %>%
  group_by(user) %>%
  filter(n() > 1) %>%
  ungroup()


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

cov_and_result <- cov_and_result %>% splitDataByTestGroup()
cov_and_result_SE <- cov_and_result %>% filter(group == "SE")
cov_and_result_ST <- cov_and_result %>% filter(group == "ST")

set.seed(42)
plot_cov_vs_result <- function(data)
  ggplot(data = data, aes()) +
    theme_minimal() +
    geom_point(aes(x = fraction, y = destroyed, color = "Destroyed"), pch = 20, alpha = .5, size = 6, position = position_jitter(width = 0, height = 0.05)) +
    geom_point(aes(x = fraction, y = alarm, color = "Alarm"), pch = 20, alpha = .5, size = 6, position = position_jitter(width = 0, height = 0.05)) +

    stat_poly_line(aes(x = fraction, y = destroyed, color = "Destroyed"), method = "lm", se = FALSE, formula = y ~ x) +
    stat_poly_eq(aes(x = fraction, y = destroyed, color = "Destroyed",
                     label = paste(..rr.label.., ..p.value.label.., sep = "*`,`~")),
                 label.y = 0.85, label.x = 0.5) +

    stat_poly_line(aes(x = fraction, y = alarm, color = "Alarm"), method = "lm", se = FALSE, formula = y ~ x) +
    stat_poly_eq(aes(x = fraction, y = alarm, color = "Alarm",
                     label = paste(..rr.label.., ..p.value.label.., sep = "*`,`~")),
                 label.y = 0.075, label.x = 0.5) +

    labs(x = "Average test coverage", y = "Number of events", color = "Event result") +
    scale_color_manual(values = colors[c(3, 5)], labels = c("Alarm (Mutant detected)", "Destroyed (Mutant not detected)")) +
    scale_x_continuous(labels = scales::percent_format(scale = 100)) +
    scale_y_continuous(breaks = seq(0, 13, 1), minor_breaks = numeric(0)) +
    theme(legend.position = "bottom")

plot_cov_vs_result(cov_and_result_SE)
ggsave(filename = paste0(outputDir, "paper/rq2_5_coverage_vs_target_killed_regression__SE.png"),
       width = 4.714, height = 3.3)

plot_cov_vs_result(cov_and_result_ST)
ggsave(filename = paste0(outputDir, "paper/rq2_5_coverage_vs_target_killed_regression__ST.png"),
       width = 4.714, height = 3.3)


pwt_data <- cov_and_result
res <- "RQ2.5: Result (mutant detected or not)\n  1. Alarm triggered / mutant detected\n"

pwt_res <- pairwise.wilcox.test(
  pwt_data$alarm,
  pwt_data$group,
  p.adjust.method = "none",
  distribution = "exact"
)

res <- (paste0(res, "    p-value = ", pwt_res$p.value, "\n"))
res <- paste0(res, "  2. Destroyed / mutant not detected\n")

pwt_res <- pairwise.wilcox.test(
  pwt_data$destroyed,
  pwt_data$group,
  p.adjust.method = "none",
  distribution = "exact"
)

res <- (paste0(res, "    p-value = ", pwt_res$p.value, "\n"))
cat(res)

