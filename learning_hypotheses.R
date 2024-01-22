library(tidyverse)
library(glue)
library(fs)

dir = "mahowald-aann"

model_meta <- read_csv("data/results/babylm_lms.csv")

best_models <- tribble(
  ~suffix,~lr,
  "babylm", "1e-3",
  "counterfactual-babylm-indef-naan-rerun", "1e-3",
  "counterfactual-babylm-indef-anan", "3e-4",
  "counterfactual-babylm-aann-prototypical_only", "1e-3",
  "counterfactual-babylm-aann-no_prototypical", "3e-4",
  "counterfactual-babylm-adj_num_freq_balanced", "1e-4",
  "counterfactual-babylm-indef_articles_with_pl_nouns-removal", "3e-4",
  "counterfactual-babylm-indef-naan-non-num", "1e-4",
  "counterfactual-babylm-all_det_removal", "1e-3",
  "counterfactual-babylm-indef-removal", "1e-4",
  "counterfactual-babylm-measure_nouns_as_singular", "1e-4"
)

train_constructions <- read_csv("data/results/target_constructions.csv")
mahowald_meta <- read_csv(glue("data/{dir}/aanns_meta.csv"))
all_corruptions <- read_csv(glue("data/{dir}/aanns_corruption.csv"))

unseen <- read_csv("data/mahowald-aann/mahowald-aanns-unseen_good.csv") %>%
  pull(idx)

aanns <- read_csv(glue("data/{dir}/mahowald-aanns-unseen_good.csv"))

human_data <- read_csv("data/mturk_ratings_20231004.csv") %>%
  inner_join(aanns) %>%
  inner_join(mahowald_meta) %>%
  select(idx, adjclass, numclass, nounclass, sentence, rating=answer) %>%
  mutate(
    adjclass = str_remove(adjclass, "adj-"),
    nounclass = str_remove(nounclass, "noun-"),
    adjclass=case_when(
      adjclass %in% c("neg", "pos") ~ "qual",
      TRUE ~ adjclass
    ),
    adjclass = factor(adjclass, levels=c("quant", "ambig", "qual", "human", "color", "stubborn"))
  )

good_ids <- human_data %>%
  filter(rating > 7) %>%
  pull(idx)

unigram_scores <- dir_ls("results/unigrams/") %>%
  keep(str_detect(., "csv")) %>%
  map_df(read_csv, .id = "model") %>%
  mutate(
    model = str_remove(model, "results/unigrams/"),
    model = str_remove(model, ".csv"),
    suffix = model
  )

unigram_scores <- bind_rows(
  unigram_scores,
  unigram_scores %>% filter(model == "babylm") %>% mutate(model = "babylm-naan", suffix="counterfactual-babylm-indef-naan-rerun"),
  unigram_scores %>% filter(model == "babylm") %>% mutate(model = "babylm-anan", suffix="counterfactual-babylm-indef-anan"),
)

bigram_scores <- dir_ls("results/bigrams/") %>%
  keep(str_detect(., "csv")) %>%
  map_df(read_csv, .id = "model") %>%
  mutate(
    model = str_remove(model, "results/bigrams/"),
    model = str_remove(model, ".csv"),
    suffix = model
  )

scores <- dir_ls("results/", recurse = TRUE, regexp = "mahowald-") %>%
  keep(str_detect(., "csv")) %>%
  map_df(read_csv, .id = "model") %>% 
  mutate(
    construction = str_extract(model, "(?<=mahowald-)(.*)(?=/)"),
    suffix = str_remove(model, "results/mahowald-(naan|anan|aann)/smolm-autoreg-bpe-"),
    suffix = str_remove(suffix, "-\\de-\\d.csv"),
    suffix = str_remove(suffix, "-seed_\\d{3,4}"),
    seed = case_when(
      str_detect(model, "seed") ~ as.numeric(str_extract(model, "(?<=seed_)(.*)(?=-\\de)")),
      TRUE ~ 42
    ),
    model = str_replace(model, "-seed_\\d{3,4}-", "-"),
    model = str_remove(model, ".csv"),
    model = str_remove(model, "results/"),
    model = str_remove(model, "autoreg-bpe-babylm-"),
    model = str_remove(model, "autoreg-bpe-counterfactual-babylm-"),
    model = str_remove(model, "aann-"),
    model = str_remove(model, "no_aann"),
    model = str_remove(model, "mahowald-(aann|naan|anan)/"),
    model = case_when(
      str_detect(model, "smolm-1e-3") ~ "smolm-aann-1e-3",
      str_detect(model, "smolm-1e-4") ~ "smolm-aann-1e-4",
      str_detect(model, "smolm-3e-4") ~ "smolm-aann-3e-4",
      TRUE ~ model
    ),
    # model = str_remove(model, "-\\de-\\d"),
    train_construction = str_extract(model, "(?<=-)(.*)") %>% str_remove("(counterfactual-)") %>% str_remove("indef-") %>% str_remove("-\\de-\\d") %>% str_replace("all-det-removal", "no-det-ann") %>% str_replace("infilling|removal", "none")
  ) %>% 
  rename(
    target_construction = construction
  )

slor <- function(mode = "unigram") {
  if(mode == "unigram") {
    ngrams = unigram_scores
  }
  else {
    ngrams = bigram_scores
  }
  
  scores %>% 
    filter(idx %in% good_ids) %>%
    select(-train_construction) %>%
    ungroup() %>%
    # filter(!str_detect(model, "(naan|anan)"), target_construction == "aann") %>%
    filter(!str_detect(model, "-non-num"), target_construction == "aann") %>%
    mutate(
      lr = str_extract(model, "\\de-\\d"),
      suffix = str_remove(suffix, "-\\de-\\d.csv"),
      model = str_remove(model, "-\\de-\\d")
    ) %>%
    inner_join(best_models) %>%
    inner_join(ngrams %>% select(idx, suffix, ngram_score = construction_score), by = c("idx", "suffix")) %>%
    mutate(construction_score = construction_score - ngram_score) %>% 
    select(-ngram_score) %>%
    select(model, seed, suffix, idx, construction_score, order_swap_score, no_article_score, no_modifier_score, no_numeral_score) %>%
    mutate(
      suffix = str_remove(suffix, "(counterfactual-babylm-indef-|counterfactual-babylm-)") %>%
        str_remove("aann-") %>% str_remove("-rerun"),
      suffix = factor(
        suffix,
        levels = c("babylm", "naan", "anan", "no_prototypical", "prototypical_only", "adj_num_freq_balanced", "all_det_removal", "removal", "indef_articles_with_pl_nouns-removal", "measure_nouns_as_singular"),
        labels = c("BabyLM", "BabyLM-NAAN", "BabyLM-ANAN", "No Prototypical\nAANNs", "Prototypical\nAANNs only", "Adj-Num Freq\nBalanced", "No DT ANN", "No AANN", "No Indef articles\nw/Pl Nouns", "No Measure Nouns\nas Singular")
      )
    )
}

slor() %>% count(suffix)

avg_slors <- function(mode = "unigram") {
  slors = slor(mode)
  slors %>%
    group_by(model, seed, suffix) %>%
    summarize(
      ste = 1.96 * plotrix::std.error(construction_score),
      score = mean(construction_score)
    ) %>%
    ungroup() %>%
    mutate(
      suffix = fct_reorder(suffix, score)
    )
}

bind_rows(
  avg_slors("unigram") %>% mutate(ngram = "unigram"),
  # avg_slors("bigram") %>% mutate(ngram = "bigram")
) %>%
  # filter(seed == 42) %>%
  filter(!str_detect(model, "(anan|naan)")) %>%
  ggplot(aes(score, suffix, group = ngram)) +
  geom_point(size=2.5, color = "black", alpha = 0.2) +
  stat_summary(geom = "point", fun = mean, color = "#d95f02", shape = 17, size = 2.3) +
  # geom_linerange(aes(xmax = score + ste, xmin = score - ste), color = "#d95f02") +
  scale_x_continuous(breaks = scales::pretty_breaks(6)) +
  facet_wrap(~ngram, scales="free_x") +
  theme_bw(base_size = 15, base_family = "Times") +
  theme(
    axis.title.y = element_blank()
    # axis.text.y = element_text(angle=15)
  ) +
  labs(
    x = "SLOR (95% CI)"
  )

bigram_scores %>%
  filter(idx %in% good_ids) %>%
  select(model, suffix, idx, construction_score) %>%
  mutate(
    suffix = str_remove(suffix, "(counterfactual-babylm-indef-|counterfactual-babylm-)") %>%
      str_remove("aann-"),
    suffix = factor(
      suffix,
      levels = c("babylm", "no_prototypical", "prototypical_only", "adj_num_freq_balanced", "all_det_removal", "removal", "indef_articles_with_pl_nouns-removal", "measure_nouns_as_singular"),
      labels = c("BabyLM", "No Prototypical\nAANNs", "Prototypical\nAANNs only", "Adj-Num Freq\nBalanced", "No DT ANN", "No AANN", "No Indef articles\nw/Pl Nouns", "No Measure Nouns\nas Singular")
    )
  ) %>%
  group_by(model, suffix) %>%
  summarize(
    ste = 1.96 * plotrix::std.error(construction_score),
    score = mean(construction_score)
  ) %>%
  ungroup() %>%
  mutate(
    suffix = fct_reorder(suffix, score)
  ) %>%
  ggplot(aes(score, suffix)) +
  geom_point(size=2, color = "#d95f02") +
  geom_linerange(aes(xmax = score + ste, xmin = score - ste), color = "#d95f02") +
  scale_x_continuous(breaks = scales::pretty_breaks(6)) +
  theme_bw(base_size = 15, base_family = "Times") +
  theme(
    axis.title.y = element_blank()
    # axis.text.y = element_text(angle=15)
  ) +
  labs(
    x = "Log prob (95% CI)"
  )
  

