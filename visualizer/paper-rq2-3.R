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
  select(user, componentName, value = testAnnotations) %>%
  levelNumbers() %>%
  splitDataByTestGroup()


# methods_per_component_avg <- methods %>%
#   group_by(componentName) %>%
#   summarise(avg = mean(value))
#
# methods_per_component_total <- methods %>%
#   group_by(componentName) %>%
#   summarise(total = sum(value))
#
# plot <- ggplot(data = levelNumbers(methods_per_component_avg), aes(x = componentName, y = avg)) +
#   theme_minimal() +
#   geom_bar(stat = "identity", fill = "#B8A0F8") +
#   labs(#title = "Average amount of test methods per component",
#     x = element_blank(), y = "Average number of tests") +
#   geom_text(aes(label = paste("Total:", methods_per_component_total %>%
#     filter(componentName == as.character(componentName)) %>%
#     pull(total))), vjust = 1.5, size = 3, color = "white")
# plot + geom_text(aes(label = paste("Average:", round(avg, 1))), vjust = -0.5, size = 3)

#violins
ggplot(data = methods, aes(
  x = group,
  y = value,
  fill = group,
  color = group
)) +
  theme_minimal() +
  geom_violin(color = "transparent", alpha = .5) +
  geom_boxplot(width = .1) +
  labs(x = element_blank(), y = "Number of tests") +
  scale_y_continuous(breaks = seq(0, 20, 1)) +
  scale_fill_manual(values = colors[1:2]) +
  scale_color_manual(values = colors[c(5,4)]) +

  scale_x_discrete(labels = c("SE", "ST")) +
  facet_grid(~ componentName, switch = "x") +
  theme(panel.spacing.x = grid::unit(2, "mm"),
        strip.placement = "outside",
        strip.background = element_blank(),
        legend.position = "none"
  )

ggsave(paste0(outputDir, "paper/rq2_3_combined_number_of_test_methods_per_component_per_user_per_component.png"),
       width = 4.714, height = 3.3)



pwt_data <- methods %>%
  splitDataByTestGroup() %>%
  sort_by(methods$componentName)
component_names <- unique(pwt_data$componentName)
res <- "RQ2.3: Number of Test Methods\n"
for (cn in component_names) {
  pwt_data_cn <- pwt_data %>% filter(cn == componentName)
  pwt_res <- pairwise.wilcox.test(
    pwt_data_cn$value,
    pwt_data_cn$group,
    p.adjust.method = "none",
    distribution = "exact"
  )

  res <- (paste0(res, "    ", cn, ": p-value = ", pwt_res$p.value, "\n"))
}

cat(res)
