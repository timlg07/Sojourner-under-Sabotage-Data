library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

if (!exists("outputDir")) outputDir <- "./visualizer/out/"

## -- Load data ---------------------------------
smells <- fromJSON(txt = "./visualizer/r_json/testSmellDetectorOutput_r.json", flatten = TRUE)
## ----------------------------------------------

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
  group_by(componentName, variable) %>%
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

plot_smells <- function(data) {
  return(
    ggplot(data = data, aes(x = componentName, y = value, fill = variable, group = variable)) +
      geom_bar(stat = "identity", position = "stack") +
      labs(x = "Component", y = "Amount of Test Smells", fill = "Test Smell Type") +
      geom_text(aes(label = ifelse(percentage >= 2 & value > 1,
                                   paste0(round(percentage, 0), "% (", round(value, 0), ")"),
                                   '')),
                size = 3, position = position_stack(vjust = .5))
  )
}

plot_smells(smells_melted_by_component_total)
ggsave(paste0(outputDir, "test_smells_per_component.png"), width = 10, height = 5)
plot_smells(smells_melted_by_component_mean)

# pie chart
ggplot(data = smells_melted_total, aes(x = "", y = value, fill = variable)) +
  theme_minimal() +
  theme(panel.grid = element_blank(), axis.ticks = element_blank(), axis.text.x = element_blank()) +
  geom_bar(stat = "identity") +
  coord_polar("y") +
  geom_text(aes(label = ifelse(percentage > 6,
                               paste0(variable, "\n", round(percentage, 0), "%", "  (", value, ")"),
                               '')),
            position = position_stack(vjust = .5)) +
  labs(x = "", y = "", fill = "Test Smell Type")
ggsave(paste0(outputDir, "test_smells_total_pie.png"), width = 6, height = 4)


smells_melted_by_user <- smells_melted %>%
  group_by(user, variable) %>%
  summarise(value = sum(value)) %>%
  group_by(variable) %>%
  summarise(value = mean(value))

smells_melted_by_test_suite <- smells_melted %>%
  group_by(variable) %>%
  summarise(value = mean(value)) %>%
  mutate(total = sum(value)) %>%
  mutate(percentage = value / total * 100) %>%
  select(variable, value, percentage) %>%
  arrange(desc(value)) %>%
  mutate(variable = factor(variable, levels = unique(variable)))

ggplot(data = smells_melted_by_test_suite, aes(x = "", y = value, fill = variable)) +
  theme_minimal() +
  theme(panel.grid = element_blank(), axis.ticks = element_blank(), axis.text.x = element_blank()) +
  geom_bar(stat = "identity") +
  coord_polar("y") +
  geom_text(aes(label = ifelse(percentage > 6,
                               paste0(ifelse(variable == "Magic Number Test", "\n\n\n",
                                             ifelse(variable == "Redundant Assertion", "", "\n")),
                                      variable, " ", round(percentage, 0), "%", "  (", round(value, 0), ")"),
                               '')),
            position = position_stack(vjust = 0.5), vjust = .5) +
  labs(x = "", y = "", fill = "Test Smell Type")

total_amount_of_smells <- smells_melted_total %>%
  summarise(value = sum(value)) %>%
  pull()

amount_of_test_methods_per_component <- smells %>%
  group_by(componentName) %>%
  summarise(avg_per_user = mean(NumberOfMethods), total = sum(NumberOfMethods))
