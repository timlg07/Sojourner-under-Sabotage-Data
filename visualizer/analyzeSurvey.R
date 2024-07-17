library(ggstats)
library(ggplot2)
library(dplyr)
library(purrr)
library(reshape2)

if (!exists("outputDir")) outputDir <- "./visualizer/out/"

survey <- read.csv("./visualizer/survey.csv") %>%
  select(courseOfStudy = What.is.your.course.of.study., everything())

# ---- PLOT --- Course of study ----
course_of_study <- survey %>%
  filter(courseOfStudy != "") %>%
  group_by(courseOfStudy) %>%
  summarise(n = n()) %>%
  arrange(desc(n)) %>%
  mutate(courseOfStudy = factor(courseOfStudy, levels = courseOfStudy)) %>%
  mutate(percentage = n / sum(n) * 100) %>%
  mutate(courseOfStudy = paste0(courseOfStudy, " (", round(percentage, 0), " %)"))
ggplot(data = course_of_study, aes(x = "", fill = courseOfStudy, y = n)) +
  geom_bar(stat = "identity") +
  coord_polar("y", start = 0, clip = "on") +
  labs(title = element_blank(), x = element_blank(), y = element_blank(), fill = "Course of study") +
  theme(panel.grid = element_blank(), axis.ticks = element_blank(), axis.text.x = element_blank()) +
  geom_text(aes(label = ifelse(percentage > 5, paste(round(percentage, 0), "%"), '')), position = position_stack(vjust = 0.5), color = "white") +
  scale_fill_manual(values = c("#00d070", "#ff9e49", "#579ad6", "#f0e442", "#0072b2", "#d55e00", "#cc79a7"))
ggsave(filename = paste0(outputDir, "course_of_study.png"), width = 12, height = 6)
# ----

# ---- PLOT --- Gender ------------
gender <- survey %>%
  group_by(Gender) %>%
  summarise(n = n()) %>%
  arrange(desc(n)) %>%
  mutate(Gender = factor(Gender, levels = Gender)) %>%
  mutate(percentage = n / sum(n) * 100) %>%
  mutate(Gender = paste0(Gender, " (", round(percentage, 0), " %)"))
ggplot(data = gender, aes(x = "", fill = Gender, y = n)) +
  geom_bar(stat = "identity") +
  coord_polar("y", start = 0, clip = "on") +
  labs(title = element_blank(), x = element_blank(), y = element_blank(), fill = "Gender") +
  theme(panel.grid = element_blank(), axis.ticks = element_blank(), axis.text.x = element_blank()) +
  geom_text(aes(label = n), position = position_stack(vjust = 0.5), color = "#444444") +
  scale_fill_manual(values = c("pink", "lightblue"))
ggsave(filename = paste0(outputDir, "gender.png"), width = 12, height = 6)
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
gglikert(experience) +
  scale_fill_viridis_d(option = "plasma")
ggsave(filename = paste0(outputDir, "experience_with_programming_likert.png"), width = 12, height = 6)
# as bar chart
ggplot(experience, aes(y = Java)) +
  geom_bar(width = .5) +
  theme_minimal() +
  labs(title = "Experience with Java", y = "Experience", x = "Players")
ggsave(filename = paste0(outputDir, "experience_with_programming_bar.png"), width = 12, height = 6)
# ----

# ---- PLOT --- other likert plots ------------
likert_levels_all <- survey %>%
  select(ex = "Please.specify.your.level.of.agreement...Debugging.got.easier.from.room.to.room.") %>%
  pull(ex) %>%
  unique()
all <- survey %>%
  select(starts_with("Please.specify.your.level.of.agreement")) %>%
  rename_with(~gsub("Please\\.specify\\.your\\.level\\.of\\.agreement\\.+", "", .x)) %>%
  rename_with(~gsub("\\.", " ", .x)) %>%
  mutate(across(everything(), ~factor(.x, levels = likert_levels_all)))
gglikert(all)
ggsave(filename = paste0(outputDir, "likert_plots.png"), width = 20, height = 30)
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
ggsave(filename = paste0(outputDir, "age.png"), width = 12, height = 6)
# heatmap
age_counts <- age %>%
  group_by(Age) %>%
  summarise(n = n()) %>%
  arrange(Age)
ggplot(age_counts, aes(x = Age, y = 1, fill = n)) +
  geom_tile() +
  ylab("") +
  scale_fill_viridis_c(option = "plasma")
# values
avg_age <- age %>%
  summarise(avg_age = mean(as.numeric(as.character(Age)))) %>%
  pull(avg_age)
# ----



