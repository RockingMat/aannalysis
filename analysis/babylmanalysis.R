library(tidyverse)
library(patchwork)
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


unigrams %>%
  arrange(-count) %>%
  mutate(
    rank = row_number() # already sorted
  ) %>%
  filter(rank <= 100000)  %>%
  ggplot(aes(rank, count)) +
  geom_line() +
  scale_y_log10(labels = scales::label_log(digits = 2), breaks = scales::breaks_log(base = 10, n = 7)) +
  scale_x_log10(labels = scales::label_log(digits = 2), breaks = scales::breaks_log(base = 10, n = 6)) + 
  theme_minimal() +
  theme(
    panel.grid = element_blank(),
    axis.text = element_blank(),
    axis.title = element_blank()
  )

ggsave("paper/figure1-zipf.svg", device = "svg", height = 3.31, width = 4.61, dpi=300)

  
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

# babylm_aanns <- read_csv("data/babylm-aanns/aanns_indef_all.csv")
babylm_aanns <- read_csv("data/babylm-aanns/aanns_new_decomposed.csv") %>%
  rename(construction = sentence)

babylm_aanns %>%
  count(ADJ, sort=TRUE) %>%
  mutate(
    rank = row_number() # already sorted
  ) %>%
  ggplot(aes(rank, n)) +
  geom_line() +
  scale_x_log10(labels = scales::label_log(digits = 2)) +
  scale_y_log10(labels = scales::label_log(digits = 2)) +
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
  
lowercased_babylm_aanns <- babylm_aanns %>%
  mutate_at(vars(construction, ADJ, NUMERAL, NOUN), .funs = str_to_lower) %>%
  rename(sentence_idx = idx)
  
low_variability_aanns <- lowercased_babylm_aanns %>%
  count(ADJ, NUMERAL, NOUN, sort=TRUE) %>%
  mutate(
    percent = cumsum(n)/sum(n)
  ) %>%
  filter(percent <= 0.50)

high_variability_aanns <- lowercased_babylm_aanns %>%
  count(ADJ, NUMERAL, NOUN, sort=TRUE) %>%
  mutate(
    percent = cumsum(n)/sum(n)
  ) %>%
  filter(percent > 0.50)

low_variability_instances <- lowercased_babylm_aanns %>%
  inner_join(low_variability_aanns)

low_variability_instances %>% 
  # write_csv("data/babylm-aanns/aanns_indef_all_prototypical_new.csv")
  write_csv("data/babylm-aanns/aanns_low_variability_all.csv")

high_variability_instances <- lowercased_babylm_aanns %>%
  inner_join(high_variability_aanns)

high_variability_instances %>% 
  write_csv("data/babylm-aanns/aanns_high_variability_all.csv")


## diversity in terms of adjective

adj_low_variability <- lowercased_babylm_aanns %>%
  count(ADJ,sort=TRUE) %>%
  mutate(
    percent = cumsum(n)/sum(n)
  ) %>%
  filter(percent <= 0.50)

adj_high_variability <- lowercased_babylm_aanns %>%
  count(ADJ,sort=TRUE) %>%
  mutate(
    percent = cumsum(n)/sum(n)
  ) %>%
  filter(percent > 0.50)

numeral_low_variability <- lowercased_babylm_aanns %>%
  count(NUMERAL,sort=TRUE) %>%
  mutate(
    percent = cumsum(n)/sum(n)
  ) %>%
  filter(percent <= 0.50)

numeral_high_variability <- lowercased_babylm_aanns %>%
  count(NUMERAL,sort=TRUE) %>%
  mutate(
    percent = cumsum(n)/sum(n)
  ) %>%
  filter(percent > 0.50)

bind_rows(
  lowercased_babylm_aanns %>%
    count(NUMERAL, sort=TRUE) %>% 
    mutate(
      percent = cumsum(n)/sum(n),
      variability = case_when(
        percent <= 0.5 ~ "low",
        TRUE ~ "high"
      )
    ) %>%
    mutate(value = NUMERAL, slot = "numeral") %>% 
    select(-NUMERAL),
  lowercased_babylm_aanns %>%
    count(ADJ, sort=TRUE) %>%
    mutate(
      percent = cumsum(n)/sum(n),
      variability = case_when(
        percent <= 0.5 ~ "low",
        TRUE ~ "high"
      )
    ) %>%
    mutate(value = ADJ, slot = "adjective") %>% 
    select(-ADJ),
  lowercased_babylm_aanns %>%
    count(NOUN, sort=TRUE) %>%
    mutate(
      percent = cumsum(n)/sum(n),
      variability = case_when(
        percent <= 0.5 ~ "low",
        TRUE ~ "high"
      )
    ) %>%
    mutate(value = NOUN, slot = "noun") %>% 
    select(-NOUN)
) %>%
  ggplot(aes(log(n), color = variability, fill = variability)) +
  geom_density() +
  facet_wrap(~slot)



noun_low_variability <- lowercased_babylm_aanns %>%
  count(NOUN,sort=TRUE) %>%
  mutate(
    percent = cumsum(n)/sum(n)
  ) %>%
  filter(percent <= 0.50)

noun_high_variability <- lowercased_babylm_aanns %>%
  count(NOUN,sort=TRUE) %>%
  mutate(
    percent = cumsum(n)/sum(n)
  ) %>%
  filter(percent > 0.50)


adj_high_variability_instances <- lowercased_babylm_aanns %>%
  inner_join(adj_high_variability)

adj_low_variability_instances <- lowercased_babylm_aanns %>%
  inner_join(adj_low_variability)

numeral_high_variability_instances <- lowercased_babylm_aanns %>%
  inner_join(numeral_high_variability)

numeral_low_variability_instances <- lowercased_babylm_aanns %>%
  inner_join(numeral_low_variability)

noun_high_variability_instances <- lowercased_babylm_aanns %>%
  inner_join(noun_high_variability)

noun_low_variability_instances <- lowercased_babylm_aanns %>%
  inner_join(noun_low_variability)

adj_high_variability_instances %>%
  arrange(-n) %>%
  head(min(nrow(adj_high_variability_instances), nrow(adj_low_variability_instances))) %>%
  write_csv("data/babylm-aanns/aanns_high_variability_adj.csv")

adj_low_variability_instances %>%
  arrange(-n) %>%
  head(min(nrow(adj_high_variability_instances), nrow(adj_low_variability_instances))) %>%
  write_csv("data/babylm-aanns/aanns_low_variability_adj.csv")

numeral_high_variability_instances %>%
  arrange(-n) %>%
  head(min(nrow(numeral_high_variability_instances), nrow(numeral_low_variability_instances))) %>%
  write_csv("data/babylm-aanns/aanns_high_variability_numeral.csv")

numeral_low_variability_instances %>%
  arrange(-n) %>%
  head(min(nrow(numeral_high_variability_instances), nrow(numeral_low_variability_instances))) %>%
  write_csv("data/babylm-aanns/aanns_low_variability_numeral.csv")

noun_high_variability_instances %>%
  arrange(-n) %>%
  head(min(nrow(noun_high_variability_instances), nrow(noun_low_variability_instances))) %>%
  write_csv("data/babylm-aanns/aanns_high_variability_noun.csv")

noun_low_variability_instances %>%
  arrange(-n) %>%
  head(min(nrow(noun_high_variability_instances), nrow(noun_low_variability_instances))) %>%
  write_csv("data/babylm-aanns/aanns_low_variability_noun.csv")


p1 <- bind_rows(
  low_variability_instances %>% 
    summarize(
      ADJ = n_distinct(ADJ),
      NUMERAL = n_distinct(NUMERAL),
      NOUN = n_distinct(NOUN),
      AANN = n_distinct(construction),
    ) %>%
    mutate(
      aann_type = "Low"
    ),
  high_variability_instances %>% 
    summarize(
      ADJ = n_distinct(ADJ),
      NUMERAL = n_distinct(NUMERAL),
      NOUN = n_distinct(NOUN),
      AANN = n_distinct(construction)
    ) %>%
    mutate(
      aann_type = "High"
    )
) %>%
  pivot_longer(ADJ:AANN, names_to = "category", values_to = "freq") %>%
  mutate(
    category = factor(category, levels = c("ADJ", "NUMERAL", "NOUN", "AANN"))
  ) %>%
  filter(category != "AANN") %>%
  ggplot(aes(category, freq, color = aann_type, fill = aann_type)) +
  geom_col(position = "dodge") +
  scale_color_manual(aesthetics = c("color", "fill"), values=c("#0174BE", "#FFB534")) +
  theme_bw(base_size=16, base_family = "Times") +
  theme(
    legend.position = "top",
    panel.grid = element_blank(),
    axis.text = element_text(color = "black")
  ) +
  labs(
    y = "# of unique slot fillers",
    color = "Variability",
    fill = "Variability",
    x = "Category"
  )

p1
ggsave("paper/variability_freqs.pdf", dpi = 300, height = 3.63, width = 4.0, device=cairo_pdf)

p2 <- bind_rows(
  non_prototypical_instances %>% 
    count(ADJ, NUMERAL, NOUN) %>% 
    ungroup() %>% 
    summarize(freq = mean(n)) %>%
    mutate(
      variability = "High"
    ),
  prototypical_instances %>% 
    count(ADJ, NUMERAL, NOUN) %>% 
    ungroup() %>% 
    summarize(freq = mean(n)) %>%
    mutate(
      variability = "Low"
    )
) %>%
  ggplot(aes(variability, freq, color = variability, fill = variability)) +
  geom_col() +
  scale_color_manual(aesthetics = c("color", "fill"), values=c("#0174BE", "#FFB534")) +
  theme_bw(base_size=16, base_family = "Times") +
  theme(
    legend.position = "top",
    panel.grid = element_blank(),
    axis.text = element_text(color = "black"),
    # axis.title.x = element_blank()
  ) +
  labs(
    y = "Frequency per instance",
    color = "Variability",
    fill = "Variability",
    x = "Variability"
  )

p1 + p2 + plot_layout(guides = "collect", widths = c(2,1)) & theme(legend.position = "top")

ggsave("paper/variability_freq.pdf", height = 3.70, width = 6.65, dpi = 300, device=cairo_pdf)

# 6.65w, 3.70h

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




