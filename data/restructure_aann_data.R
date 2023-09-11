library(tidyverse)

data1 <- read_csv("data/aann-public/gpt3_data/sents_adjs_20221004.csv") %>%
  rename(id = `...1`)
data2 <- read_csv("data/aann-public/gpt3_data/sents_adjs_20221004_2.csv") %>%
  rename(id = `...1`)

bind_rows(data1, data2) %>%
  mutate(
    id = row_number()
  ) %>%
  write_csv("data/aanns_mahowald2023.csv")
  
