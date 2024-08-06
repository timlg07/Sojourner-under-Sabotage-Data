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
# paletteer_d("vapoRwave::jazzCup") -> #83DDE0FF #28ADA8FF #3F86BCFF #7A3A9AFF #392682FF
colors <- c("#B8A0F8", "#83DDE0FF", "#28ADA8FF", "#3F86BCFF", "#7A3A9AFF", "#392682FF")
