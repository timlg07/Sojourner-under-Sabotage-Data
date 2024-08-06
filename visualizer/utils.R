levelNumbers <- function (d) {
  d_numbered <- d
  last <- ""
  ii <- 0
  for (i in seq_len(nrow(d))) {
    if (d$componentName[i] != last) {
      last <- d$componentName[i]
      ii <- ii + 1
    }
    d_numbered$componentName[i] <- paste0("Level ", ii, "\n(", as.character(d$componentName[i]), ")")
  }
  return(d_numbered)
}

colors <- c(
  "#B8A0F8FF", # theme color
  "#83DDE0FF", "#28ADA8FF", "#3F86BCFF", "#7A3A9AFF", "#392682FF", # paletteer_d("vapoRwave::jazzCup")
  "#AD282DFF", # complementary of 3
  "#639ECBFF", # monochromatic of 4
  "#37D1CBFF", # monochromatic of 3
  "#E0F8A0FF", # complementary of 1
  "#9470F5FF"  # monochromatic of 0
)
