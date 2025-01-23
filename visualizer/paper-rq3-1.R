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

for_group <- "1_SE"
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
