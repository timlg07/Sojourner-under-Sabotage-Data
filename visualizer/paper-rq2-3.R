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

# (3) Number of tests written per component -----------------------------------#

methods <- fromJSON(txt = "./visualizer/r_json/amountOfTestMethods_r.json", flatten = TRUE) %>%
  select(user, componentName, value = testAnnotations)


methods_per_component_avg <- methods %>%
  group_by(componentName) %>%
  summarise(avg = mean(value))

methods_per_component_total <- methods %>%
  group_by(componentName) %>%
  summarise(total = sum(value))

plot <- ggplot(data = levelNumbers(methods_per_component_avg), aes(x = componentName, y = avg)) +
  theme_minimal() +
  geom_bar(stat = "identity", fill = "#B8A0F8") +
  labs(#title = "Average amount of test methods per component",
    x = element_blank(), y = "Average number of tests") +
  geom_text(aes(label = paste("Total:", methods_per_component_total %>%
    filter(componentName == as.character(componentName)) %>%
    pull(total))), vjust = 1.5, size = 3, color = "white")
plot + geom_text(aes(label = paste("Average:", round(avg, 1))), vjust = -0.5, size = 3)
ggsave(paste0(outputDir, "paper/rq2_3_amount_of_test_methods_per_component.png"), width = 5, height = 3.5)
