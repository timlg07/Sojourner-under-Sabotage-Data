library(jsonlite)
library(ggplot2)
library(dplyr)

level_reached <- fromJSON(txt="levelReached.json", flatten=TRUE)
keyval_to_df <- function(x) {
  data.frame(key = names(x), value = unlist(x), stringsAsFactors = FALSE)
}
level_reached_df <- keyval_to_df(level_reached)

# group by level
level_reached_amount <- level_reached_df %>%
  group_by(value) %>%
  summarise(count = n())

plot <- ggplot(level_reached_amount, aes(x = value, y = count)) +
  geom_bar(stat = "identity") +
  labs(title = "highest level reached by players", x = "Level", y = "Amount of players") +
  theme_minimal()
plot
ggsave(paste0(outputDir, "level_reached.png"), plot, width = 15, height = 10, units = "cm", dpi = 300, limitsize = FALSE, device = "png")

