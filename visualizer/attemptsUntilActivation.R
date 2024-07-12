library(jsonlite)
library(ggplot2)
library(dplyr)
library(purrr)

if (!exists("outputDir")) outputDir <- "./"

attempts <- fromJSON(txt="./visualizer/attemptsUntilActivation_r.json", flatten=TRUE)

