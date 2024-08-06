library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

source("./visualizer/utils.R")

if (!exists("outputDir")) outputDir <- "./visualizer/out/"
if (!exists("presentationDir")) presentationDir <- "./visualizer/out/"

## -- Load data ---------------------------------
coverage <- fromJSON(txt = "./visualizer/r_json/coverageAtActivation_r.json", flatten = TRUE) %>%
  filter(componentName != "ReactorLog")

destroyed_or_alarm <- fromJSON(txt = "./visualizer/r_json/destroyedOrAlarm_r.json", flatten = TRUE) %>%
  filter(componentName != "ReactorLog")


## -- Visualize coverage alone -------------------
ggplot(data = coverage, aes(x = componentName, y = fraction)) +
  theme_minimal() +
  geom_violin() +
  labs(x = "Component", y = "Coverage at activation")
ggsave(filename = paste0(outputDir, "coverage_at_activation.png"), width = 12, height = 8)


## -- Visualize coverage depending on component & result ---
cov_vs_doa <- merge(coverage, destroyed_or_alarm, by = c("user", "componentName")) %>%
  select(user, componentName, coverage = fraction, result = value)

ggplot(data = cov_vs_doa %>% filter(componentName != "Kitchen"), aes(x = interaction(componentName, result), y = coverage)) +
  theme_minimal() +
  geom_violin(aes(fill = result), alpha = .5) +
  #geom_boxplot(width = .15, alpha = .25, fill = "white", color = "white") +
  geom_point(position = position_jitter(width = 0.08, height = 0), fill = "transparent", color = "black", pch = 21, size = 3) +
  labs(y = "Coverage at activation", x = "Component / Destroyed or alarm") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  scale_fill_manual(values = c("green", "red"), labels = c("Alarm", "Destroyed"))
ggsave(filename = paste0(outputDir, "coverage_vs_destroyed_or_alarm_per_component.png"), width = 12, height = 8)

# -- cov vs result -------------------------------
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
  labs(x = "Test coverage", y = "Amount of events", color = "Result") +
  scale_color_manual(values = colors[c(3, 7)], labels = c("Alarm", "Destroyed")) +
  scale_y_continuous(breaks = seq(0, 13, 1), minor_breaks = numeric(0))
plot
ggsave(filename = paste0(outputDir, "coverage_vs_destroyed_or_alarm_regression.png"), width = 6, height = 4)
plot_dark <- plot + theme(text = element_text(colour = "white"),
                          axis.text = element_text(colour = "white"),
                          axis.ticks = element_line(colour = "#888888"),
                          panel.grid = element_line(colour = "#888888"))
plot_dark
ggsave(filename = paste0(presentationDir, "coverage_vs_destroyed_or_alarm_regression_dark.png"), plot = plot_dark, width = 6, height = 4)

d <- lm(destroyed ~ fraction, data = cov_and_result)
ds <- summary(d)
ds$coefficients

a <- lm(alarm ~ fraction, data = cov_and_result)
as <- summary(a)
as$coefficients

# --- Average values ----------------------------
avg_cov_per_comp <- coverage %>%
  group_by(componentName) %>%
  summarise(avg_cov = mean(fraction))
avg_cov_total <- coverage %>%
  summarise(avg_cov = mean(fraction)) %>%
  pull(avg_cov)
