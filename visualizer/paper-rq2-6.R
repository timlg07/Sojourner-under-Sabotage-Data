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

# (6) Test smells -------------------------------------------------------------#
smells <- fromJSON(txt = "./visualizer/r_json/testSmellDetectorOutput_r.json", flatten = TRUE)
smells <- levelNumbers(smells)

smells_melted <- melt(smells, id = c("componentName", "user")) %>%
  filter(value > 0) %>%
  filter(variable != "NumberOfMethods")

smells_melted_total <- smells_melted %>%
  group_by(variable) %>%
  summarise(value = sum(value)) %>%
  mutate(total = sum(value)) %>%
  mutate(percentage = value / total * 100) %>%
  select(variable, value, percentage) %>%
  # sort by value
  arrange(desc(value)) %>%
  mutate(variable = factor(variable, levels = unique(variable)))

smells_melted_by_component_total <- smells_melted %>%
  splitDataByTestGroup() %>%
  group_by(componentName, variable, group) %>%
  summarise(value = sum(value)) %>%
  # add percentage values
  mutate(total = sum(value)) %>%
  mutate(percentage = value / total * 100) %>%
  # sort variables by smells_melted_total value (-> same order & colors as pie chart)
  inner_join(smells_melted_total %>% select(variable, var_total = value), by = "variable") %>%
  arrange(desc(var_total)) %>%
  select(-var_total) %>%
  mutate(variable = factor(variable, levels = unique(variable)))

smells_melted_by_component_mean <- smells_melted %>%
  group_by(componentName, variable) %>%
  summarise(value = mean(value)) %>%
  # add percentage values
  mutate(total = sum(value)) %>%
  mutate(percentage = value / total * 100)


ggplot(data = smells_melted_by_component_total, aes(
  x = group,
  y = value,
  fill = variable,
  group = variable
)) +
  theme_minimal() +
  geom_bar(stat = "identity", position = "stack") +
  labs(x = element_blank(), y = "Number of Test Smells", fill = "Test\nSmell\nType  ") +
  # geom_text(aes(label = ifelse(percentage >= 3 & value > 9,
  #                              paste0(round(percentage, 0), "% (", round(value, 0), ")"),
  #                              '')),
  #           size = 3, position = position_stack(vjust = .5), color = "black") +
  scale_fill_manual(values = colors[-c(5, 6, 7)]) +

  scale_x_discrete(labels = c("SE", "ST")) +
  facet_grid(~ componentName, switch = "x") +
  theme(panel.spacing.x = grid::unit(2, "mm"),
        strip.placement = "outside",
        strip.background = element_blank(),
        legend.position = "bottom",
        legend.justification = "left",
        legend.text = element_text(size = 8),
        legend.title = element_text(size = 10),
  )

ggsave(paste0(outputDir, "paper/rq2_6_combined_test_smells_per_level.png"), width = 6.14, height = 4.3)


pwt_data <- smells_melted %>%
  splitDataByTestGroup() %>%
  sort_by(smells_melted$componentName) %>%
  group_by(componentName, group, user) %>%
  summarise(value = sum(value))

component_names <- unique(pwt_data$componentName)
res <- "RQ2.6: Number of Test Smells\n"
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
