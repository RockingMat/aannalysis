library(tidyverse)
librayr(tidytext)

unigrams <- read_csv("data/babylm-analysis/babylm-unigrams.csv")
 
# unigrams %>%
#   filter(str_detect(word, "[[:punct:]]")) |> View()

power_law = function(x) {
  x^-2.5
}

unigrams %>%
  arrange(-count) %>%
  mutate(
    rank = row_number() # already sorted
  ) %>%
  ggplot(aes(rank, count)) +
  geom_line(color = "#920353") +
  scale_y_log10(labels = scales::label_log(digits = 2), breaks = scales::breaks_log(base = 10, n = 7)) +
  scale_x_log10(labels = scales::label_log(digits = 2), breaks = scales::breaks_log(base = 10, n = 6)) + 
  theme_bw(base_size = 17, base_family = "Times") +
  theme(
    axis.text = element_text(color = "black") 
  ) +
  labs(
    x = "Rank",
    y = "Count"
  )
  
mahowald <- read_csv("data/mahowald-aann/mahowald-aanns-unseen_good.csv")

mahowald_adj <- mahowald %>%
  distinct(ADJ) %>%
  rename(adj = ADJ) %>%
  inner_join(unigrams %>% rename(adj=word))

mahowald_adj %>%
  arrange(-count) %>%
  mutate(
    rank = row_number()
  ) %>%
  ggplot(aes(rank, count)) +
  geom_line() +
  # scale_x_log10(labels = scales::label_log(digits = 2)) +
  # scale_y_log10(labels = scales::label_log(digits = 2)) +
  theme_bw(base_size = 15, base_family = "Times") +
  ggtitle("Count vs rank for Mahowald (2023)\nadjectives in BabyLM")

