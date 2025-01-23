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
# RQ3 - How did the students perform in debuggin activities?                   #
#==============================================================================#

# (1) Amount of tries, additional bugs introduced -----------------------------#

for_group <- "SE"
for_group_name <- gsub("\\d_", "", for_group)

debugging <- fromJSON(txt = "./visualizer/r_json/attemptsUntilFixed_summary_r.json", flatten = TRUE) %>%
  filter(deltaTime != "not fixed") %>%
  mutate(deltaTime = as.numeric(deltaTime)) %>%
  filter(deltaTime < 55) %>% # continued playing at home
  splitDataByTestGroup() %>%
  filter(group == for_group) %>%
  select(user, componentName, deltaTime, modifications, executions, hiddenTestsAdded)

debugging %>% group_by(modifications) %>% summarise(count = n()) %>% arrange(desc(count))

debugging_melted <- melt(levelNumbers(debugging), id = c("componentName", "user")) %>%
  filter(variable != "executions")
ggplot(data = debugging_melted, aes(x = componentName, y = value, color = variable, fill = variable, group = interaction(componentName, variable))) +
  theme_minimal() +
  geom_boxplot(width = .5) +
  labs(x = element_blank(), y = "Time spent in minutes", fill = "Type of metric", group = "Type of metric") +
  scale_color_manual(values = c(colors[4], colors[5], colors[7]), labels = c("Time", "Modifications", "Hidden tests added"), name = "Type of metric") +
  scale_fill_manual(values = c(colors[2], colors[1], colors[12]), labels = c("Time", "Modifications", "Hidden tests added"), name = "Type of metric") +
  scale_y_continuous(sec.axis = sec_axis(~., name = "Number of modifications/hidden tests", breaks = seq(0, 100, 2)), breaks = seq(0, 100, 2)) +
  theme(legend.position = "bottom")
ggsave(filename = paste0(outputDir, "paper/rq3_1_debugging_performance_per_component_boxplots__",for_group_name,".png"),
       width = 4.714, height = 3.3)

# m. wh. test
pwt_data <- fromJSON(txt = "./visualizer/r_json/attemptsUntilFixed_summary_r.json", flatten = TRUE) %>%
  filter(deltaTime != "not fixed") %>%
  mutate(deltaTime = as.numeric(deltaTime)) %>%
  filter(deltaTime < 55) %>% # continued playing at home
  splitDataByTestGroup() %>%
  select(user, componentName, deltaTime, modifications, hiddenTestsAdded, group) %>%
  levelNumbers()

pwt_data <- pwt_data %>%
  sort_by(pwt_data$componentName)
component_names <- unique(pwt_data$componentName)
res <- "RQ3.1: Debugging Performance\n  1. delta Time\n"

for (cn in component_names) {
  pwt_data_cn <- pwt_data %>% filter(cn == componentName)
  pwt_res <- pairwise.wilcox.test(
    pwt_data_cn$deltaTime,
    pwt_data_cn$group,
    p.adjust.method = "none",
    distribution = "exact"
  )

  res <- (paste0(res, "    ", cn, ": p-value = ", pwt_res$p.value, "\n"))
}

res <- paste0(res, "  2. Modifications\n")
for (cn in component_names) {
  pwt_data_cn <- pwt_data %>% filter(cn == componentName)
  pwt_res <- pairwise.wilcox.test(
    pwt_data_cn$modifications,
    pwt_data_cn$group,
    p.adjust.method = "none",
    distribution = "exact"
  )

  res <- (paste0(res, "    ", cn, ": p-value = ", pwt_res$p.value, "\n"))
}

res <- paste0(res, "  3. Hidden Tests Added\n")
for (cn in component_names) {
  pwt_data_cn <- pwt_data %>% filter(cn == componentName)
  pwt_res <- pairwise.wilcox.test(
    pwt_data_cn$hiddenTestsAdded,
    pwt_data_cn$group,
    p.adjust.method = "none",
    distribution = "exact"
  )

  res <- (paste0(res, "    ", cn, ": p-value = ", pwt_res$p.value, "\n"))
}

cat(res)
