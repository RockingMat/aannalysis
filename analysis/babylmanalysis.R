library(tidyverse)
# librayr(tidytext)

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

babylm_aanns <- read_csv("data/babylm-aanns/aanns_indef_all.csv")

babylm_aanns %>%
  count(ADJ, sort=TRUE) %>%
  mutate(
    rank = row_number() # already sorted
  ) %>%
  ggplot(aes(rank, n)) +
  geom_line() +
  # scale_x_log10(labels = scales::label_log(digits = 2)) +
  # scale_y_log10(labels = scales::label_log(digits = 2)) +
  theme_bw(base_size = 15, base_family = "Times") +
  ggtitle("Count vs rank for adjectives\nin BabyLM AANNs")

deciles <- babylm_aanns %>%
  count(ADJ, sort = TRUE) %>%
  mutate(percent = cumsum(n)/sum(n)) %>%
  mutate(
    decile = ntile(n, 100),
    ADJ = fct_reorder(ADJ, n)
  )
  
babylm_aanns %>%
  mutate(construction = str_to_lower(construction)) %>%
  count(ADJ, NUMERAL, NOUN, sort=TRUE) %>%
  mutate(
    percent = cumsum(n)/sum(n)
  ) %>%
  filter(percent <= 0.50) %>% View()
  count(NUMERAL, sort=TRUE)
  
# prototypical ids
  
prototypical_aanns <- babylm_aanns %>%
  # mutate(construction = str_to_lower(construction)) %>%
  mutate_at(vars(construction, ADJ, NUMERAL, NOUN), .funs = str_to_lower) %>%
  count(ADJ, NUMERAL, NOUN, sort=TRUE) %>%
  mutate(
    percent = cumsum(n)/sum(n)
  ) %>%
  filter(percent <= 0.50)

prototypical_instances <- babylm_aanns %>%
  mutate_at(vars(construction, ADJ, NUMERAL, NOUN), .funs = str_to_lower) %>%
  inner_join(prototypical_aanns)

prototypical_instances %>% 
  write_csv("data/babylm-aanns/aanns_indef_all_prototypical.csv")

non_prototypical_instances <- babylm_aanns %>%
  mutate_at(vars(construction, ADJ, NUMERAL, NOUN), .funs = str_to_lower) %>%
  anti_join(prototypical_aanns)

non_prototypical_instances %>% 
  write_csv("data/babylm-aanns/aanns_indef_all_non_prototypical.csv")

babylm_aanns %>%
  count(ADJ, NUMERAL, sort = TRUE) %>%
  mutate(percent = cumsum(n)/sum(n))

babylm_aanns %>%
  count(NUMERAL, sort = TRUE) %>%
  mutate(percent = cumsum(n)/sum(n))

babylm_aanns %>%
  count(ADJ, NUMERAL, sort = TRUE) %>%
  mutate(percent = cumsum(n)/sum(n)) %>%
  mutate(
    decile = ntile(n, 10),
  ) %>% View()

babylm_aanns %>%
  count(ADJ, sort = TRUE) %>%
  mutate(rank = row_number()) %>%
  ggplot(aes(rank, n)) +
  geom_line() +
  scale_x_log10(labels = scales::label_log(digits = 2)) +
  scale_y_log10(labels = scales::label_log(digits = 2)) +
  theme_bw(base_size = 15, base_family = "Times")

deciles %>%
  head(50) %>%
  ggplot(aes(ADJ, log10(n))) +
  geom_col(color = "maroon", fill = "maroon", width = 0.8) +
  scale_y_continuous(expand = c(0,0.12)) +
  theme_bw(base_size = 15, base_family = "Times") +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 90, hjust = 0.95, vjust=0.2),
    axis.text = element_text(color = "black")
  )


# prototypes

stats <- babylm_aanns %>%
  mutate(construction = str_to_lower(construction)) %>%
  select(sentence_idx, ADJ, NUMERAL, NOUN) %>%
  add_count(ADJ, name = "adj_count") %>%
  add_count(NUMERAL, name = "num_count") %>%
  add_count(NOUN, name = "noun_count") %>%
  # add_count(ADJ, NUMERAL, NOUN, name = "construction_count") %>%
  mutate(
    adj_count = adj_count/nrow(.),
    num_count = num_count/nrow(.),
    noun_count = noun_count/nrow(.),
    # construction_count = construction_count/nrow(.)
  ) %>%
  select(-sentence_idx) %>%
  distinct() %>%
  mutate(
    construction_idx = row_number()
  )

bind_rows(
  stats %>% select(-ADJ, -NUMERAL, -NOUN), 
  stats %>%
    select(-ADJ, -NUMERAL, -NOUN) %>%
    summarize_all(mean) %>%
    mutate(construction_idx = 0)
) %>%
  pivot_longer(adj_count:noun_count, names_to = "feature", values_to = "value") %>%
  widyr::pairwise_dist(construction_idx, feature, value, method = "euclidean") %>%
  filter(item1 == 0) %>%
  arrange(distance) %>%
  inner_join(stats %>% select(item2 = construction_idx, ADJ, NUMERAL, NOUN)) %>%
  mutate(
    sim = exp(-2*distance)
  )

bind_rows(
  stats %>% select(-ADJ, -NUMERAL, -NOUN), 
  stats %>%
    select(-ADJ, -NUMERAL, -NOUN) %>%
    summarize_all(max) %>%
    mutate(construction_idx = 0)
) %>%
  pivot_longer(adj_count:noun_count, names_to = "feature", values_to = "value") %>%
  widyr::pairwise_dist(construction_idx, feature, value, method = "manhattan") %>%
  filter(item1 == 0) %>%
  arrange(distance) %>%
  inner_join(stats %>% select(item2 = construction_idx, ADJ, NUMERAL, NOUN)) %>%
  mutate(
    sim = exp(-2*distance)
  ) %>% View()
