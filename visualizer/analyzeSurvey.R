library(ggstats)
library(ggplot2)
library(ggdark)
library(dplyr)
library(purrr)
library(reshape2)

source("./visualizer/utils.R")

if (!exists("outputDir")) outputDir <- "./visualizer/out/"
if (!exists("presentationDir")) presentationDir <- "./visualizer/out/"

survey <- loadSurveyData()

# ---- PLOT --- Course of study ----
course_of_study <- survey %>%
  filter(courseOfStudy != "") %>%
  group_by(courseOfStudy) %>%
  summarise(n = n()) %>%
  arrange(desc(n)) %>%
  mutate(courseOfStudy = factor(courseOfStudy, levels = courseOfStudy)) %>%
  mutate(percentage = n / sum(n) * 100) %>%
  mutate(courseOfStudy = paste0(formatC(100 - round(percentage, 0), 2, flag = '0'), "__", # just there for the ordering
                                courseOfStudy, " (", round(percentage, 0), " %)")) # actual name
plot <- ggplot(data = course_of_study, aes(x = "", fill = courseOfStudy, y = n)) +
  theme_minimal() +
  geom_bar(stat = "identity") +
  coord_polar("y", start = 0, clip = "on") +
  labs(title = element_blank(), x = element_blank(), y = element_blank(), fill = "Course of study") +
  theme(panel.grid = element_blank(), axis.ticks = element_blank(), axis.text.x = element_blank()) +
  geom_text(aes(label = ifelse(percentage > 5, paste(round(percentage, 0), "%"), '')), position = position_stack(vjust = 0.5)) +
  scale_fill_manual(values = colors[-1],
                    labels = course_of_study %>% # remove order prefix
                      mutate(courseOfStudy = gsub("\\d+__", '', courseOfStudy)) %>%
                      mutate(courseOfStudy = gsub("Informatik", 'Computer Science', courseOfStudy)) %>%
                      mutate(courseOfStudy = gsub("Wirtschaftsinformatik", 'Business Informatics', courseOfStudy)) %>%
                      mutate(courseOfStudy = gsub("Lehramt", 'Education', courseOfStudy)) %>%
                      mutate(courseOfStudy = gsub("Education \\(Education\\)", 'Education', courseOfStudy)) %>%
                      pull(courseOfStudy))
plot
plot <- ggplot(data = course_of_study, aes(x = n, fill = courseOfStudy, y = "")) +
  theme_minimal() +
  geom_bar(stat = "identity") +
  labs(title = element_blank(), x = element_blank(), y = element_blank(), fill = "Course of study") +
  geom_text(aes(label = ifelse(percentage > 5, paste(round(percentage, 0), "%"), '')), position = position_stack(vjust = 0.5)) +
  scale_fill_manual(values = colors[-1],
                    labels = course_of_study %>% # remove order prefix
                      mutate(courseOfStudy = gsub("\\d+__", '', courseOfStudy)) %>%
                      mutate(courseOfStudy = gsub("Informatik", 'Computer Science', courseOfStudy)) %>%
                      mutate(courseOfStudy = gsub("Wirtschaftsinformatik", 'Business Informatics', courseOfStudy)) %>%
                      mutate(courseOfStudy = gsub("Lehramt", 'Education', courseOfStudy)) %>%
                      mutate(courseOfStudy = gsub("Education \\(Education\\)", 'Education', courseOfStudy)) %>%
                      pull(courseOfStudy))
plot
ggsave(filename = paste0(outputDir, "course_of_study.png"), width = 6, height = 3)

plot_dark <- plot + theme(text = element_text(colour = "white")) #, plot.background = element_rect(fill = "black"))
ggsave(filename = paste0(presentationDir, "course_of_study_dark.png"), plot = plot_dark, width = 6, height = 4)
# ----

# ---- PLOT --- Gender ------------
gender <- survey %>%
  group_by(Gender) %>%
  summarise(n = n()) %>%
  arrange(desc(n)) %>%
  mutate(Gender = factor(Gender, levels = Gender)) %>%
  mutate(percentage = n / sum(n) * 100) %>%
  mutate(.gender = paste0(Gender, " (", round(percentage, 0), " %)"))
ggplot(data = gender, aes(x = "", fill = Gender, y = n)) +
  theme_minimal() +
  geom_bar(stat = "identity") +
  coord_polar("y", start = 0, clip = "on") +
  labs(title = element_blank(), x = element_blank(), y = element_blank(), fill = "Gender") +
  theme(panel.grid = element_blank(), axis.ticks = element_blank(), axis.text.x = element_blank()) +
  geom_text(aes(label = paste0(Gender, "\n", round(percentage, 0), " %  (", n, ")")), position = position_stack(vjust = 0.5), color = "#444444") +
  scale_fill_manual(values = colors)
ggplot(data = gender, aes(x = n, fill = Gender, y = "")) +
  theme_minimal() +
  geom_bar(stat = "identity") +
  labs(title = element_blank(), x = element_blank(), y = element_blank(), fill = "Gender") +
  geom_text(
    aes(label = ifelse (percentage > 5, paste0(Gender, "\n", round(percentage, 0), " %  (", n, ")"), "")),
    position = position_stack(vjust = 0.5), color = "#444444") +
  scale_fill_manual(values = c(colors[c(2,1)], rgb(.7,.7,.75)))
ggsave(filename = paste0(outputDir, "gender.png"), width = 5, height = 2)
# ----

# ---- PLOT --- Experience with Programming ------------
# likert plots of Experience.with.Java
experience <- survey %>%
  select(Java = "Experience.with.Java", Programming = "Experience.with.programming..any.language.")
# get programmatically (wrong order)
# likert_levels_experience <- experience %>% pull(Java) %>% unique()
# for (val in likert_levels_experience) { print(val) }
likert_levels_experience <- c(
  "< 3 months",
  ">= 3 months && < 6 months",
  ">= 6 months && < 1 year",
  ">= 1 year && < 3 years",
  ">= 3 years"
)
experience <- experience %>%
  mutate(across(everything(), ~factor(.x, levels = likert_levels_experience)))
plot <- gglikert(experience) +
  scale_fill_manual(values = colors[-1]) +
  theme(axis.text.y = element_text(angle = 90, hjust = .5))
plot
ggsave(filename = paste0(outputDir, "experience_with_programming_likert.png"), width = 10, height = 3)
plot_dark <- plot + ggdark::dark_theme_minimal() + theme(plot.background = element_rect(color = NA))
plot_dark
ggsave(filename = paste0(presentationDir, "experience_with_programming_likert_dark.png"), width = 10, height = 3)
# as bar chart
ggplot(experience, aes(y = Java)) +
  theme_minimal() +
  geom_bar(width = .5) +
  labs(title = "Experience with Java", y = "Experience", x = "Players")
ggsave(filename = paste0(outputDir, "experience_with_programming_bar.png"), width = 10, height = 3)
# ----

# ---- PLOT --- other likert plots ------------
likert_levels_all <- c(
  "Fully disagree",
  "Partially disagree",
  "Neither agree nor disagree",
  "Partially agree",
  "Fully agree"
)
all <- survey %>%
  select(starts_with("Please.specify.your.level.of.agreement")) %>%
  rename_with(~gsub("Please\\.specify\\.your\\.level\\.of\\.agreement\\.+", "", .x)) %>%
  rename_with(~gsub("\\.+", " ", .x)) %>%
  rename_with(~gsub("learned practised", "learned/practised", .x)) %>%
  mutate(across(everything(), ~factor(.x, levels = likert_levels_all)))
  # add numbers to all questions
colnames(all) <- sprintf("(Q%02d) %s", seq(1, 14), colnames(all))
gglikert(all) + scale_fill_manual(values = colors[-1])
ggsave(filename = paste0(outputDir, "likert_plots.png"), width = 9, height = 9)
# Plot improvement questions
gglikert(all, 13:14, labels_color = "white") + scale_fill_manual(values = colors[-1]) + ggdark::dark_theme_minimal() + theme(plot.background = element_rect(color = NA))
ggsave(filename = paste0(presentationDir, "likert_plots_13-14_dark.png"), width = 9, height = 2)
# Plot general perception
gglikert(all, 1:4, labels_color = "white") + scale_fill_manual(values = colors[-1]) + ggdark::dark_theme_minimal() + theme(plot.background = element_rect(color = NA))
ggsave(filename = paste0(presentationDir, "likert_plots_1-4_dark.png"), width = 9, height = 4)
# Plot testing/debugging perception
gglikert(all, 5:9, labels_color = "white") + scale_fill_manual(values = colors[-1]) + ggdark::dark_theme_minimal() + theme(plot.background = element_rect(color = NA))
ggsave(filename = paste0(presentationDir, "likert_plots_5-10_dark.png"), width = 9, height = 5)
# ----

# ---- PLOT --- Age as likert plot ------------
age <- survey %>%
  select(Age)
likert_levels_age <- age %>%
  mutate(Age = as.character(Age)) %>%
  pull(Age) %>%
  unique() %>%
  sort()
age <- tibble(Age = age$Age) %>% # defactorize using tibble
  mutate(across(everything(), ~factor(.x, levels = likert_levels_age)))
gglikert(age)
ggsave(filename = paste0(outputDir, "age_likert.png"), width = 10, height = 3)
# heatmap
age_counts <- age %>%
  group_by(Age) %>%
  summarise(n = n()) %>%
  arrange(Age)
ggplot(age_counts, aes(x = Age, y = 1, fill = n)) +
  geom_tile() +
  ylab("") +
  scale_fill_viridis_c(option = "plasma")
# bar chart
plot <- ggplot(age_counts, aes(x = Age, y = n)) +
  theme_minimal() +
  geom_bar(stat = "identity", fill = "#B8A0F8") +
  ylab("Students") +
  xlab("Age") +
  scale_y_continuous(breaks = seq(0, 12, 2)) +
  scale_x_discrete(limits = factor(c(seq(18, 27, 1), '...', 38)))
plot
ggsave(filename = paste0(outputDir, "age.png"), width = 10, height = 3)
plot_dark <- plot + theme(text = element_text(colour = "white"),
                          axis.text = element_text(colour = "white"),
                          axis.ticks = element_line(colour = "#888888"),
                          panel.grid = element_line(colour = "#888888"))
plot_dark
ggsave(filename = paste0(presentationDir, "age_dark.png"), width = 10, height = 4)
# values
avg_age <- age %>%
  summarise(avg_age = mean(as.numeric(as.character(Age)))) %>%
  pull(avg_age)
median_age <- age %>%
  summarise(median_age = median(as.numeric(as.character(Age)))) %>%
  pull(median_age)
# ----



