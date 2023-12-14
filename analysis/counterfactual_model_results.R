library(tidyverse)
library(glue)
library(fs)

dir = "mahowald-aann"

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

scores <- dir_ls("results/", recurse = TRUE) %>%
  keep(str_detect(., "csv")) %>%
  map_df(read_csv, .id = "model") %>% 
  mutate(
    construction = str_extract(model, "(?<=mahowald-)(.*)(?=/)"),
    model = str_remove(model, ".csv"),
    model = str_remove(model, "results/"),
    model = str_remove(model, "autoreg-bpe-babylm-"),
    model = str_remove(model, "autoreg-bpe-counterfactual-babylm-"),
    model = str_remove(model, "aann-"),
    model = str_remove(model, "no_"),
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

scores %>% count(model)

scores %>%
  # filter(idx %in% good_ids) %>%
  filter(model == "smolm-aann-1e-3", target_construction=="aann") %>%
  inner_join(human_data) %>%
  mutate(
    construction_score = (construction_score - min(construction_score))/(max(construction_score) - min(construction_score))
  ) %>%
  group_by(adjclass, nounclass) %>%
  summarize(
    score = mean(construction_score)
  ) %>%
  ggplot(aes(adjclass, score)) +
  geom_point() +
  facet_wrap(~ nounclass, scales = "free_x")

human_data %>%
  mutate(
    rating = (rating - min(rating))/(max(rating) - min(rating))
  ) %>%
  # filter(idx %in% good_ids) %>%
  group_by(adjclass, nounclass) %>%
  summarize(
    score = mean(rating)
  ) %>%
  ggplot(aes(adjclass, score)) +
  geom_point() +
  facet_wrap(~ nounclass, scales = "free_x")

results <- scores %>% 
  filter(idx %in% good_ids) %>%
  group_by(model, train_construction, target_construction) %>%
  summarize(
    default_preference = mean(default_nan_score > construction_score),
    order_swap = mean(construction_score > order_swap_score),
    no_article = mean(construction_score > no_article_score),
    no_modifier = mean(construction_score > no_modifier_score),
    no_numeral = mean(construction_score > no_numeral_score),
    overall = mean(construction_score > order_swap_score & construction_score > no_article_score & construction_score > no_modifier_score & construction_score > no_numeral_score)
  )

results %>%
  select(model, train_construction, target_construction, overall) %>%
  pivot_wider(names_from = target_construction, values_from = overall) 
# %>%
  # filter(str_detect(model, "smolm-indef-naan"))


scores %>%
  filter(target_construction == "aann") %>%
  inner_join(human_data) %>%
  group_by(model) %>%
  summarize(
    default_acc = mean(default_nan_score > no_article_score)
  )
