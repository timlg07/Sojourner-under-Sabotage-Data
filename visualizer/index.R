main <- function(libPaths = .libPaths(), rDir = "visualizer/", entry = "index.R", outputDir = "./") {
  # add user library path (not loaded when called from nodeJS)
  .libPaths(libPaths)

  library(dplyr)
  library(maps)

  # List files and source each
  list.files(path = rDir, pattern = ".+\\.R") %>%
    lapply(function(file) {
      if (file != entry) {
        source(paste0(rDir, file), local = TRUE)
      }
    })
}
