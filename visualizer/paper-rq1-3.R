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

# (3) Results of the test executions ------------------------------------------#

attempts <- fromJSON(txt = "./visualizer/r_json/attemptsUntilActivation_r.json", flatten = TRUE)

avg_per_component <- attempts %>%
  splitDataByTestGroup() %>%
  group_by(componentName, group) %>%
  summarise(avg_errors = mean(errors), avg_fails = mean(fails), avg_successes = mean(successes),
            total = avg_errors + avg_fails + avg_successes)

avg_per_component_melted <- avg_per_component %>%
  melt(id = c("componentName", "group", "total"))

plot <- ggplot(data = levelNumbers(avg_per_component_melted), aes(
  x = group,
  group = interaction(group, variable),
  y = value / total
)) +
  theme_minimal() +
  geom_bar(aes(fill = variable), position = "stack", stat = 'identity') +
  geom_bar(aes(fill = variable), position = "stack", stat = 'identity') +
  geom_bar(aes(fill = variable), position = "stack", stat = 'identity') +
  labs(#title = "Average errors, fails and successes of test run attempts per component",
    x = element_blank(), y = "Average", fill = "Result: ") +
  scale_fill_manual(values = c(colors[7], colors[12], colors[2]),
                    labels = c("Compilation\nerror", "Runtime/Assertion\nerror", "Tests\npassed")) +
  scale_y_continuous(labels = scales::percent_format(scale = 100)) +
  scale_x_discrete(labels = c("SE", "ST")) +

  # using $variable inside color= is buggy when using facet_grid, so do it twice i I guess
  # geom_text(aes(label = ifelse(variable == "avg_errors",
  #               ifelse(value > 0, paste0(
  #                 round(value / total * 100, 0),
  #                 " %\n(",
  #                 round(value, 1), ")"
  #               ), ''), element_blank())),
  #           color = "white",
  #           position = position_stack(vjust = 0.5), size = 3) +
  # geom_text(aes(label = ifelse(variable != "avg_errors",
  #               ifelse(value > 0, paste0(
  #                 round(value / total * 100, 0),
  #                 " %\n(",
  #                 round(value, 1), ")"
  #               ), ''), element_blank())),
  #           color = "black",
  #           position = position_stack(vjust = 0.5), size = 3) +

  theme(legend.position = "bottom") +
  facet_grid(~ componentName, switch = "x") +
  theme(panel.spacing.x = grid::unit(0, "mm"),
        strip.placement = "outside",
        strip.background = element_blank(),
  )
plot
ggsave(filename = paste0(outputDir, "paper/rq1_3_combined_attempts_until_activation_avg_per_component.png"),
       width = 4.714, height = 3.3)


pwt_data <- attempts %>%
  levelNumbers() %>%
  splitDataByTestGroup()
pwt_data <- pwt_data %>%
  sort_by(pwt_data$componentName)
component_names <- unique(pwt_data$componentName)
res <- "RQ1.3: Attempts until activation\n  1. Errors\n"
for (cn in component_names) {
  pwt_data_cn <- pwt_data %>% filter(cn == componentName)
  pwt_res <- pairwise.wilcox.test(
    pwt_data_cn$errors,
    pwt_data_cn$group,
    p.adjust.method = "none",
    distribution = "exact"
  )

  res <- (paste0(res, "    ", cn, ": p-value = ", pwt_res$p.value, "\n"))
}

res <- paste0(res, "  2. Fails\n")
for (cn in component_names) {
  pwt_data_cn <- pwt_data %>% filter(cn == componentName)
  pwt_res <- pairwise.wilcox.test(
    pwt_data_cn$fails,
    pwt_data_cn$group,
    p.adjust.method = "none",
    distribution = "exact"
  )

  res <- (paste0(res, "    ", cn, ": p-value = ", pwt_res$p.value, "\n"))
}

res <- paste0(res, "  3. Successes\n")
for (cn in component_names) {
  pwt_data_cn <- pwt_data %>% filter(cn == componentName)
  pwt_res <- pairwise.wilcox.test(
    pwt_data_cn$successes,
    pwt_data_cn$group,
    p.adjust.method = "none",
    distribution = "exact"
  )

  res <- (paste0(res, "    ", cn, ": p-value = ", pwt_res$p.value, "\n"))
}

cat(res)
