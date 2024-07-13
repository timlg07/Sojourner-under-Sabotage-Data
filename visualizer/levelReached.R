library(jsonlite)
library(ggplot2)
library(dplyr)

if (!exists("outputDir")) outputDir <- "./"

level_reached <- fromJSON(txt="./visualizer/r_json/levelReached_r.json", flatten=TRUE)

# group by level and count the amount of players
level_reached_amount <- level_reached %>%
  group_by(value) %>%
  summarise(count = n())

level_played_by <- level_reached_amount
for (i in seq_len(nrow(level_reached_amount))) {
  level_played_by$count[i] <- sum(level_reached_amount$count[i:nrow(level_reached_amount)])
}

plot <- ggplot(level_reached_amount, aes(x = value, y = count)) +
  geom_bar(stat = "identity") +
  labs(title = "highest level reached by players", x = "Level", y = "Amount of players") +
  theme_minimal()
plot
ggsave(paste0(outputDir, "level_reached.png"), plot, width = 15, height = 10, units = "cm", dpi = 300, limitsize = FALSE, device = "png")

plot <- ggplot(level_played_by, aes(x = value, y = count)) +
  geom_bar(stat = "identity") +
  labs(title = "amount of players that played level x", x = "Level", y = "Amount of players") +
  theme_minimal()
plot
ggsave(paste0(outputDir, "level_played_by.png"), plot, width = 15, height = 10, units = "cm", dpi = 300, limitsize = FALSE, device = "png")
