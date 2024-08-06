component_name_to_index <- function(component_name) {
  switch(component_name,
         "CryoSleep" = return(1),
         "Engine" = return(2),
         "GreenHouse" = return(3),
         "Kitchen" = return(4),
         "ReactorLog" = return(5),
  )
}

levelNumbers <- function(d) {
  d_ <- d
  for (i in 1:nrow(d)) {
    name <- as.character(d_$componentName[i])
    num <- component_name_to_index(name)
    d_$componentName[i] <- paste0("Level ",num, "\n(", name, ")")
  }
  return(d_)
}

colors <- c(
  "#B8A0F8FF", # theme color
  "#83DDE0FF", "#28ADA8FF", "#3F86BCFF", "#7A3A9AFF", "#392682FF", # paletteer_d("vapoRwave::jazzCup")
  "#AD282DFF", # complementary of 3
  "#639ECBFF", # monochromatic of 4
  "#37D1CBFF", # monochromatic of 3
  "#E0F8A0FF", # complementary of 1
  "#9470F5FF", # monochromatic of 0
  "#F59470FF", # triadic of previous
  "#70F594FF"  # triadic of previous
)
colors_likert <- c(
  colors[5], colors[1], colors[2], colors[3], colors[4]
)

# visualize all colors
color_guide <- ggplot(data = data.frame(x = 1:length(colors), y = 1), aes(x = x, y = y, fill = as.factor(x))) +
  theme_void() +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = colors, name = "Color")
# color_guide
