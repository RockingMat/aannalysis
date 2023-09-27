library(tidyverse)

data1 <- read_csv("data/aann-public/gpt3_data/sents_adjs_20221004.csv") %>%
  rename(id = `...1`)
data2 <- read_csv("data/aann-public/gpt3_data/sents_adjs_20221004_2.csv") %>%
  rename(id = `...1`)

combined <- bind_rows(data1, data2) %>%
  mutate(
    id = row_number()
  )

combined %>%
  write_csv("data/mahowald/aanns_mahowald2023.csv")

combined %>% distinct(adj) %>% 
  mutate(
    adj_phrase = case_when(
      str_starts(adj, "[aeiou]") ~ glue::glue("an {adj}"),
      TRUE ~ glue::glue("a {adj}")
    )
  ) %>% View()

converted_format <- combined %>%
  mutate(
    source = "mahowald",
    DT = case_when(
      str_starts(adj, "[aeiou]") ~ "an",
      TRUE ~ "a"
    ),
    DT = case_when(
      str_starts(sent, as.character(glue::glue("An {adj}"))) ~ "An",
      str_starts(sent, as.character(glue::glue("A {adj}"))) ~ "A",
      TRUE ~ DT
    ),
    # test = str_starts(sent, as.character(glue::glue("An {adj}"))),
    # test2 = str_starts(sent, as.character(glue::glue("A {adj}"))),
    construction = glue::glue("{DT} {adj} {num} {noun}"),
    pattern = "DT JJ CD NNS",
  ) %>%
  select(
    idx = id,
    source,
    sentence = sent,
    construction,
    pattern,
    # test,
    # test2,
    DT,
    ADJ = adj,
    NUMERAL = num,
    NOUN = noun
  )

converted_format %>%
  write_csv("data/mahowald/aanns_good.csv")
