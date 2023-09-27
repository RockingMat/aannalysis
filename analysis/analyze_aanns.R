library(tidyverse)

aanns <- read_csv("data/openbooks/aanns_good.csv")

aanns |>
  distinct(ADJ) |>View()
  write_csv("data/openbooks/adjectives_isolation.csv")

aanns |>
  distinct(NOUN) |>
  write_csv("data/openbooks/nouns_isolation.csv")
