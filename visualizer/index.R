main <- function(libPaths = .libPaths(), rDir = "visualizer/", entry = "index.R", outputDir = "./") {
  # add user library path (not loaded when called from nodeJS)
  .libPaths(libPaths)

  # required for the %>% operator
  library(dplyr)

  # support paths without trailing slash
  if (!endsWith(outputDir, "/")) {
    outputDir <- paste0(outputDir, "/")
  }

  # prohibit generation of the Rplots.pdf
  pdf(NULL)

  # execute all R files in the directory
  list.files(path = rDir, pattern = ".+\\.R") %>%
    lapply(function(file) {
      if (file != entry) {
        source(paste0(rDir, file), local = TRUE)
      }
    })
}
