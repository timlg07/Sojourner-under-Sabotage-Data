library(jsonlite)
library(ggplot2)
library(ggdark)
library(dplyr)
library(purrr)
library(reshape2)

source("./visualizer/utils.R")

if (!exists("outputDir")) outputDir <- "./visualizer/out/"
if (!exists("presentationDir")) presentationDir <- "./visualizer/out/"

## -- Load performance data ---------------------------------
coverage <- fromJSON(txt = "./visualizer/r_json/coverageAtActivation_r.json", flatten = TRUE) %>%
  select(user, componentName, coverage = fraction) %>%
  group_by(user) %>%
  summarise(coverage = mean(coverage))
destroyed_or_alarm <- fromJSON(txt = "./visualizer/r_json/destroyedOrAlarm_r.json", flatten = TRUE) %>%
  select(user, componentName, result = value) %>%
  group_by(user) %>%
  summarise(result = sum(result == "alarm") / n())
smells <- fromJSON(txt = "./visualizer/r_json/testSmellDetectorOutput_r.json", flatten = TRUE)
smells_total <- smells %>%
  melt(id = c("componentName", "user")) %>%
  # sum up everything except NumberOfMethods
  ## filter(variable != "NumberOfMethods") %>%
  filter(!is.na(value)) %>%
  group_by(user) %>%
  # (sum of all values) / (NumberOfMethods)
  summarise(smells = sum(value[variable != "NumberOfMethods"]) / sum(value[variable == "NumberOfMethods"]))
attempts_activation <- fromJSON(txt = "./visualizer/r_json/attemptsUntilActivation_r.json", flatten = TRUE) %>%
  group_by(user) %>%
  summarise(errors_until_activation = mean(errors),
            fails_until_activation = mean(fails),
            successes_until_activation = mean(successes))
attempts_first_pass <- fromJSON(txt = "./visualizer/r_json/attemptsUntilFirstPass_r.json", flatten = TRUE) %>%
  filter(success) %>%
  group_by(user) %>%
  summarise(errors_until_first_pass = mean(errors),
            fails_until_first_pass = mean(fails))
time_activation <- fromJSON(txt = "./visualizer/r_json/timeUntilActivation_r.json", flatten = TRUE) %>%
  filter(value != "not finished") %>%
  mutate(value = as.numeric(value)) %>%
  filter(value < 55) %>% # continued playing at home
  select(user, componentName, time_until_activation = value) %>%
  group_by(user) %>%
  summarise(time_until_activation = mean(time_until_activation))
time_first_pass <- fromJSON(txt = "./visualizer/r_json/timeUntilFirstPass_r.json", flatten = TRUE) %>%
  filter(value != "not finished") %>%
  mutate(value = as.numeric(value)) %>%
  filter(value < 55) %>% # continued playing at home
  select(user, componentName, time_until_first_pass = value) %>%
  group_by(user) %>%
  summarise(time_until_first_pass = mean(time_until_first_pass))
debugging <- fromJSON(txt = "./visualizer/r_json/attemptsUntilFixed_summary_r.json", flatten = TRUE) %>%
  filter(deltaTime != "not fixed") %>%
  mutate(deltaTime = as.numeric(deltaTime)) %>%
  filter(deltaTime < 55) %>% # continued playing at home
  select(user, componentName, deltaTime, modifications, executions, hiddenTestsAdded) %>%
  group_by(user) %>%
  summarise(debugging_time = mean(deltaTime),
            debugging_modifications = mean(modifications),
            debugging_hidden_tests_added = mean(hiddenTestsAdded))
level_reached <- fromJSON(txt = "./visualizer/r_json/levelReached_r.json", flatten = TRUE) %>%
  select(user, level_reached = value)

## -- Load survey data ---------------------------------
survey <- read.csv("./visualizer/survey.csv")
course_of_study <- survey %>%
  select(courseOfStudy = What.is.your.course.of.study., user = Username) %>%
  filter(courseOfStudy != "")
experience <- survey %>%
  select(java = "Experience.with.Java", programming = "Experience.with.programming..any.language.", user = Username)
gender <- survey %>%
  select(gender = Gender, user = Username)

## -- Merge data ---------------------------------
performance <- merge(coverage, destroyed_or_alarm, by = "user") %>%
  merge(smells_total, by = "user") %>%
  merge(attempts_activation, by = "user") %>%
  merge(attempts_first_pass, by = "user") %>%
  merge(time_activation, by = "user") %>%
  merge(time_first_pass, by = "user") %>%
  merge(debugging, by = "user") %>%
  merge(level_reached, by = "user") %>%
  ## merge(course_of_study, by = "user") %>%
  merge(experience, by = "user") %>%
  merge(gender, by = "user")

## -- Visualize performance ---------------------------------
# metrics:
# - time_until_first_pass
# - time_until_activation
# - errors_until_first_pass
# - fails_until_first_pass
# - errors_until_activation
# - fails_until_activation
# - successes_until_activation
# - coverage (fraction)
# - result (fraction of alarms)
# - smells (smells per method)
# - level_reached

# 1) Gender ------------------------------------------------
# 1.1) smells
plot <- ggplot(data = performance, aes(x = gender, y = smells)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  labs(x = "Gender", y = "Average Amount of Test Smells per Method")
plot
ggsave(paste0(outputDir, "smells_by_gender.png"), width = 6, height = 4)
t.test(performance$smells ~ performance$gender)
# Shapiro-Wilk test for normality
shapiro.test(performance$smells[performance$gender == "Male"])
shapiro.test(performance$smells[performance$gender == "Female"])

hist(performance$smells[performance$gender == "Male"], main="Histogram of Data", xlab="Values", ylab="Frequency", col="lightblue", border="black")
hist(performance$smells[performance$gender == "Female"], main="Histogram of Data", xlab="Values", ylab="Frequency", col="lightblue", border="black")

# Q-Q plot to visually inspect normality
qqnorm(performance$smells[performance$gender == "Male"], main="Q-Q Plot of Data", xlab="Theoretical Quantiles", ylab="Sample Quantiles", col="blue", pch=19)
qqline(performance$smells[performance$gender == "Male"], col="red")
qqnorm(performance$smells[performance$gender == "Female"], main="Q-Q Plot of Data", xlab="Theoretical Quantiles", ylab="Sample Quantiles", col="blue", pch=19)
qqline(performance$smells[performance$gender == "Female"], col="red")

# Kolmogorov-Smirnov test for normality
ks.test(performance$smells[performance$gender == "Male"], "pnorm", mean=mean(performance$smells[performance$gender == "Male"]), sd=sd(performance$smells[performance$gender == "Male"]))
ks.test(performance$smells[performance$gender == "Female"], "pnorm", mean=mean(performance$smells[performance$gender == "Female"]), sd=sd(performance$smells[performance$gender == "Female"]))

# 1.2) time_until_first_pass
plot <- ggplot(data = performance, aes(x = gender, y = time_until_first_pass)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  labs(x = "Gender", y = "Average Time until First Pass")
plot
ggsave(paste0(outputDir, "time_until_first_pass_gender.png"), width = 6, height = 4)
t.test(performance$time_until_first_pass ~ performance$gender)
# 1.3) time_until_activation
plot <- ggplot(data = performance, aes(x = gender, y = time_until_activation)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1]) +
  labs(x = "Gender", y = "Average Time until Activation")
plot
#ggsave(paste0(outputDir, "time_until_activation.png"), width = 6, height = 4)
t.test(performance$time_until_activation ~ performance$gender)
# 1.4.1) errors_until_first_pass
plot <- ggplot(data = performance, aes(x = gender, y = errors_until_first_pass)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1]) +
  labs(x = "Gender", y = "Average Errors until First Pass")
plot
#ggsave(paste0(outputDir, "errors_until_first_pass.png"), width = 6, height = 4)
t.test(performance$errors_until_first_pass ~ performance$gender)
# 1.4.2) fails_until_first_pass
plot <- ggplot(data = performance, aes(x = gender, y = fails_until_first_pass)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1]) +
  labs(x = "Gender", y = "Average Fails until First Pass")
plot
#ggsave(paste0(outputDir, "fails_until_first_pass.png"), width = 6, height = 4)
t.test(performance$fails_until_first_pass ~ performance$gender)
# 1.5) detection rate
plot <- ggplot(data = performance, aes(x = gender, y = result)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  labs(x = "Gender", y = "Average Detection Rate")
plot
t.test(performance$result ~ performance$gender)
# 1.6) level reached
plot <- ggplot(data = performance, aes(x = gender, y = level_reached)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  labs(x = "Gender", y = "Level Reached")
plot
ggsave(paste0(outputDir, "level_reached_by_gender_violins.png"), width = 6, height = 4)
level_reached_gender <- performance %>%
  select(level_reached, gender) %>%
  group_by(level_reached, gender) %>%
  summarise(count = n())
plot <- ggplot(data = level_reached_gender, aes(x = level_reached, y = count, group = gender)) +
  theme_minimal() +
  geom_bar(stat = "identity", position = "dodge", aes(fill = gender)) +
  # geom_text(aes(label = count), position = position_dodge(width = .9), vjust = -.5) +
  scale_fill_manual(values = colors[1:2]) +
  labs(x = "Level Reached", y = "Amount of Participants")
plot
ggsave(paste0(outputDir, "level_reached_by_gender_barplot.png"), width = 6, height = 4)
# Calculate counts and proportions
level_reached_gender_proportion <- performance %>%
  select(level_reached, gender) %>%
  group_by(level_reached, gender) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(gender) %>%
  mutate(proportion = count / sum(count))
level_reached_gender_proportion_avg <- performance %>%
  group_by(gender) %>%
  summarise(average_level = mean(level_reached))
plot <- ggplot(data = level_reached_gender_proportion, aes(x = level_reached, y = proportion,
                                                           group = gender, fill = gender)) +
  theme_minimal() +
  geom_area(position = "identity", alpha = 0.5) +
  geom_line(aes(color = gender), size = 1) +
  geom_point(aes(color = gender), size = 3) +
  scale_fill_manual(values = colors[c(1, 2)]) +
  scale_color_manual(values = colors[c(5, 3)]) +
  geom_vline(data = level_reached_gender_proportion_avg, aes(xintercept = average_level, color = gender),
             linetype = "dashed", size = 1) +
  labs(x = "Level Reached", y = "Proportion of Participants") +
  theme(legend.position = "top")
plot
ggsave(paste0(outputDir, "level_reached_by_gender_area.png"), width = 6, height = 4)
#level_reached_gender_means <- ddply(performance, "gender", summarise, grp.mean=mean(level_reached))
#plot <- ggplot(data = performance, aes(x = as.numeric(level_reached), fill = gender)) +
#  theme_minimal() +
#  geom_density(alpha = .5) +
#  scale_fill_manual(values = colors[1:2]) +
#  geom_vline(data = level_reached_gender_means, aes(xintercept = grp.mean, color = gender), linetype = "dashed") +
#  labs(x = "Level Reached", y = "Density")
# plot
t.test(performance$level_reached ~ performance$gender)
# 1.7) debugging
# 1.7.1) debugging time
plot <- ggplot(data = performance, aes(x = gender, y = debugging_time)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1]) +
  labs(x = "Gender", y = "Average Time spent Debugging")
plot
t.test(performance$debugging_time ~ performance$gender)
# 1.7.2) debugging modifications
plot <- ggplot(data = performance, aes(x = gender, y = debugging_modifications)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1]) +
  labs(x = "Gender", y = "Average Amount of Modifications")
plot
t.test(performance$debugging_modifications ~ performance$gender)
# 1.7.3) debugging hidden tests added
plot <- ggplot(data = performance, aes(x = gender, y = debugging_hidden_tests_added)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1]) +
  labs(x = "Gender", y = "Average Amount of Hidden Tests Added")
plot
t.test(performance$debugging_hidden_tests_added ~ performance$gender)
# 1.8) coverage
plot <- ggplot(data = performance, aes(x = gender, y = coverage)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1]) +
  labs(x = "Gender", y = "Average Coverage")
plot
t.test(performance$coverage ~ performance$gender)


# 2) Experience with Programming --------------------------------
# 2.0) sort
likert_levels_experience <- c(
  "< 3 months",
  ">= 3 months &&\n < 6 months",
  ">= 6 months &&\n < 1 year",
  ">= 1 year &&\n < 3 years",
  ">= 3 years"
)
performance_nl <- performance %>%
  mutate(across(c(java, programming), function(s) gsub("&&", "&&\n", s)))
experience_java_performance <- performance_nl %>%
  mutate(across(java, ~factor(.x, levels = likert_levels_experience))) %>%
  arrange(java)
experience_programming_performance <- performance_nl %>%
  mutate(across(programming, ~factor(.x, levels = likert_levels_experience))) %>%
  arrange(programming)
# 2.1.1) smells java
plot <- ggplot(data = experience_java_performance, aes(x = java, y = smells)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1]) +
  #geom_smooth(method = "lm", se = FALSE, color = "red", aes(x = as.numeric(java), y = smells)) +
  labs(x = "Experience with Java", y = "Average Amount of Test Smells per Method")
plot
d <- lm(smells ~ as.numeric(java), data = experience_java_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
# 2.1.2) smells programming
plot <- ggplot(data = experience_programming_performance, aes(x = programming, y = smells)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1]) +
  #geom_smooth(method = "lm", se = FALSE, color = "red", aes(x = as.numeric(programming), y = smells)) +
  labs(x = "Experience with Programming", y = "Average Amount of Test Smells per Method")
plot
d <- lm(smells ~ as.numeric(programming), data = experience_programming_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
# 2.2.1) level reached java
plot <- ggplot(data = experience_java_performance, aes(x = java, y = level_reached)) +
  theme_minimal() +
  #geom_boxplot(color = "black", fill = colors[1]) +
  #geom_point(color = "black", size = 3, position = position_jitter(width = 0.1, height = 0)) +
  geom_violin(fill = colors[1], alpha = .4, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(java), y = level_reached)) +
  labs(x = "Experience with Java", y = "Average Level Reached")
plot
ggsave(paste0(outputDir, "level_reached_by_java.png"), width = 6, height = 4)
d <- lm(level_reached ~ as.numeric(java), data = experience_java_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
paste("slope: ", ds$coefficients[2, 1], " p-value: ", ds$coefficients[2, 4])
# 2.2.2) level reached programming
plot <- ggplot(data = experience_programming_performance, aes(x = programming, y = level_reached)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  #geom_point(color = "black", size = 3, position = position_jitter(width = 0.1, height = 0)) +
  geom_violin(fill = colors[1], alpha = .4, color = "transparent", width = 1.2) +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(programming), y = level_reached)) +
  labs(x = "Experience with Programming", y = "Average Level Reached")
plot
ggsave(paste0(outputDir, "level_reached_by_programming.png"), width = 6, height = 4)
d <- lm(level_reached ~ as.numeric(programming), data = experience_programming_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
paste("slope: ", ds$coefficients[2, 1], " p-value: ", ds$coefficients[2, 4])
# 2.3.1) detection rate java
plot <- ggplot(data = experience_java_performance, aes(x = java, y = result)) +
  theme_minimal() +
  # geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .75, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(java), y = result)) +
  labs(x = "Experience with Java", y = "Average Detection Rate")
plot
# 2.3.2) detection rate programming
plot <- ggplot(data = experience_programming_performance, aes(x = programming, y = result)) +
  theme_minimal() +
  # geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .75, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(programming), y = result)) +
  labs(x = "Experience with Programming", y = "Average Detection Rate")
plot
# 2.4.1) time until first pass java
plot <- ggplot(data = experience_java_performance, aes(x = java, y = time_until_first_pass)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(java), y = time_until_first_pass)) +
  labs(x = "Experience with Java", y = "Average Time until First Pass")
plot
ggsave(paste0(outputDir, "time_until_first_pass_by_java.png"), width = 6, height = 4)
d <- lm(time_until_first_pass ~ as.numeric(java), data = experience_java_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
paste("slope: ", ds$coefficients[2, 1], " p-value: ", ds$coefficients[2, 4])
# 2.4.2) time until first pass programming
plot <- ggplot(data = experience_programming_performance, aes(x = programming, y = time_until_first_pass)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(programming), y = time_until_first_pass)) +
  labs(x = "Experience with Programming", y = "Average Time until First Pass")
plot
ggsave(paste0(outputDir, "time_until_first_pass_by_programming.png"), width = 6, height = 4)
d <- lm(time_until_first_pass ~ as.numeric(programming), data = experience_programming_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
paste("slope: ", ds$coefficients[2, 1], " p-value: ", ds$coefficients[2, 4])
# 2.5.1) errors until first pass java
plot <- ggplot(data = experience_java_performance, aes(x = java, y = errors_until_first_pass)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(java), y = errors_until_first_pass)) +
  labs(x = "Experience with Java", y = "Average Errors until First Pass")
plot
d <- lm(errors_until_first_pass ~ as.numeric(java), data = experience_java_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
paste("slope: ", ds$coefficients[2, 1], " p-value: ", ds$coefficients[2, 4])
# 2.5.2) errors until first pass programming
plot <- ggplot(data = experience_programming_performance, aes(x = programming, y = errors_until_first_pass)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(programming), y = errors_until_first_pass)) +
  labs(x = "Experience with Programming", y = "Average Errors until First Pass")
plot
d <- lm(errors_until_first_pass ~ as.numeric(programming), data = experience_programming_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
paste("slope: ", ds$coefficients[2, 1], " p-value: ", ds$coefficients[2, 4])

# 2.6.1) time until activation java
plot <- ggplot(data = experience_java_performance, aes(x = java, y = time_until_activation)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(java), y = time_until_activation)) +
  labs(x = "Experience with Java", y = "Average Time until Activation")
plot
ggsave(paste0(outputDir, "time_until_activation_by_java.png"), width = 6, height = 4)
d <- lm(time_until_activation ~ as.numeric(java), data = experience_java_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
paste("slope: ", ds$coefficients[2, 1], " p-value: ", ds$coefficients[2, 4])
# 2.6.2) time until activation programming
plot <- ggplot(data = experience_programming_performance, aes(x = programming, y = time_until_activation)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(programming), y = time_until_activation)) +
  # add averages as geom_text:
  geom_text(data = experience_programming_performance %>%
    group_by(programming) %>%
    summarise(avg = mean(time_until_activation)),
            aes(x = as.numeric(programming), y = avg, label = round(avg, 2)),
            vjust = -1, hjust = 0) +
  labs(x = "Experience with Programming", y = "Average Time until Activation")
plot
ggsave(paste0(outputDir, "time_until_activation_by_programming.png"), width = 6, height = 4)
d <- lm(time_until_activation ~ as.numeric(programming), data = experience_programming_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
paste("slope: ", ds$coefficients[2, 1], " p-value: ", ds$coefficients[2, 4])

# 2.8.1) fails until first pass java
plot <- ggplot(data = experience_java_performance, aes(x = java, y = fails_until_first_pass)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(java), y = fails_until_first_pass)) +
  labs(x = "Experience with Java", y = "Average Fails until First Pass")
plot
d <- lm(fails_until_first_pass ~ as.numeric(java), data = experience_java_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
# 2.8.2) fails until first pass programming
plot <- ggplot(data = experience_programming_performance, aes(x = programming, y = fails_until_first_pass)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(programming), y = fails_until_first_pass)) +
  labs(x = "Experience with Programming", y = "Average Fails until First Pass")
plot
d <- lm(fails_until_first_pass ~ as.numeric(programming), data = experience_programming_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")

# 2.9.1) successes until activation java
plot <- ggplot(data = experience_java_performance, aes(x = java, y = successes_until_activation)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(java), y = successes_until_activation)) +
  labs(x = "Experience with Java", y = "Average Successes until Activation")
plot
d <- lm(successes_until_activation ~ as.numeric(java), data = experience_java_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
# 2.9.2) successes until activation programming
plot <- ggplot(data = experience_programming_performance, aes(x = programming, y = successes_until_activation)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(programming), y = successes_until_activation)) +
  labs(x = "Experience with Programming", y = "Average Successes until Activation")
plot
d <- lm(successes_until_activation ~ as.numeric(programming), data = experience_programming_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")

# 2.10.1) fails until activation java
plot <- ggplot(data = experience_java_performance, aes(x = java, y = fails_until_activation)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(java), y = fails_until_activation)) +
  labs(x = "Experience with Java", y = "Average Fails until Activation")
plot
d <- lm(fails_until_activation ~ as.numeric(java), data = experience_java_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
# 2.10.2) fails until activation programming
plot <- ggplot(data = experience_programming_performance, aes(x = programming, y = fails_until_activation)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(programming), y = fails_until_activation)) +
  labs(x = "Experience with Programming", y = "Average Fails until Activation")
plot
d <- lm(fails_until_activation ~ as.numeric(programming), data = experience_programming_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")

# 2.11.1) errors until activation java
plot <- ggplot(data = experience_java_performance, aes(x = java, y = errors_until_activation)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(java), y = errors_until_activation)) +
  labs(x = "Experience with Java", y = "Average Errors until Activation")
plot
d <- lm(errors_until_activation ~ as.numeric(java), data = experience_java_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
# 2.11.2) errors until activation programming
plot <- ggplot(data = experience_programming_performance, aes(x = programming, y = errors_until_activation)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(programming), y = errors_until_activation)) +
  labs(x = "Experience with Programming", y = "Average Errors until Activation")
plot
d <- lm(errors_until_activation ~ as.numeric(programming), data = experience_programming_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")

# 2.12.1) coverage java
plot <- ggplot(data = experience_java_performance, aes(x = java, y = coverage)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(java), y = coverage)) +
  labs(x = "Experience with Java", y = "Average Coverage")
plot
d <- lm(coverage ~ as.numeric(java), data = experience_java_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
# 2.12.2) coverage programming
plot <- ggplot(data = experience_programming_performance, aes(x = programming, y = coverage)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(programming), y = coverage)) +
  labs(x = "Experience with Programming", y = "Average Coverage")
plot
d <- lm(coverage ~ as.numeric(programming), data = experience_programming_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")

# 2.7.1.1) debugging time java
plot <- ggplot(data = experience_java_performance, aes(x = java, y = debugging_time)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(java), y = debugging_time)) +
  labs(x = "Experience with Java", y = "Average Time spent Debugging")
plot
d <- lm(debugging_time ~ as.numeric(java), data = experience_java_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
# 2.7.1.2) debugging time programming
plot <- ggplot(data = experience_programming_performance, aes(x = programming, y = debugging_time)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(programming), y = debugging_time)) +
  labs(x = "Experience with Programming", y = "Average Time spent Debugging")
plot
d <- lm(debugging_time ~ as.numeric(programming), data = experience_programming_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
# 2.7.2.1) debugging modifications java
plot <- ggplot(data = experience_java_performance, aes(x = java, y = debugging_modifications)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(java), y = debugging_modifications)) +
  labs(x = "Experience with Java", y = "Average Amount of Modifications")
plot
d <- lm(debugging_modifications ~ as.numeric(java), data = experience_java_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
# 2.7.2.2) debugging modifications programming
plot <- ggplot(data = experience_programming_performance, aes(x = programming, y = debugging_modifications)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(programming), y = debugging_modifications)) +
  labs(x = "Experience with Programming", y = "Average Amount of Modifications")
plot
d <- lm(debugging_modifications ~ as.numeric(programming), data = experience_programming_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
# 2.7.3.1) debugging hidden tests added java
plot <- ggplot(data = experience_java_performance, aes(x = java, y = debugging_hidden_tests_added)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(java), y = debugging_hidden_tests_added)) +
  labs(x = "Experience with Java", y = "Average Amount of Hidden Tests Added")
plot
d <- lm(debugging_hidden_tests_added ~ as.numeric(java), data = experience_java_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
# 2.7.3.2) debugging hidden tests added programming
plot <- ggplot(data = experience_programming_performance, aes(x = programming, y = debugging_hidden_tests_added)) +
  theme_minimal() +
  geom_boxplot(color = "black", fill = colors[1], width = .1) +
  geom_violin(fill = colors[1], alpha = .33, color = "transparent") +
  geom_smooth(method = "lm", se = FALSE, color = colors[3], aes(x = as.numeric(programming), y = debugging_hidden_tests_added)) +
  labs(x = "Experience with Programming", y = "Average Amount of Hidden Tests Added")
plot
d <- lm(debugging_hidden_tests_added ~ as.numeric(programming), data = experience_programming_performance)
ds <- summary(d)
ds$coefficients
ifelse(ds$coefficients[2, 4] < 0.05, "Significant", "Not significant")
