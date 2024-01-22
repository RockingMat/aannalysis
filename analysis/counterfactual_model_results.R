library(tidyverse)
library(glue)
library(fs)
library(ggstance)

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

scores %>% count(model)

scores %>% count(suffix)

scores %>%
  filter(idx %in% good_ids) %>%
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
  group_by(suffix, seed, train_construction, target_construction) %>%
  summarize(
    default_preference = mean(default_nan_score > construction_score),
    order_swap = mean(construction_score > order_swap_score),
    no_article = mean(construction_score > no_article_score),
    no_modifier = mean(construction_score > no_modifier_score),
    no_numeral = mean(construction_score > no_numeral_score),
    overall = mean(construction_score > order_swap_score & construction_score > no_article_score & construction_score > no_modifier_score & construction_score > no_numeral_score)
  )

scores %>% 
  filter(idx %in% good_ids) %>%
  group_by(model, seed, suffix, target_construction) %>%
  summarize(
    good = mean(construction_score),
    good_ste = 1.96 * plotrix::std.error(construction_score),
    order_swap = mean(order_swap_score),
    no_article = mean(no_article_score),
    no_modifier = mean(no_modifier_score),
    no_numeral = mean(no_numeral_score)
  ) %>% 
  mutate(
    lr = str_extract(model, "\\de-\\d"),
    suffix = str_remove(suffix, "-\\de-\\d.csv"),
    model = str_remove(model, "-\\de-\\d")
  ) %>% 
  inner_join(best_models) %>%
  ggplot(aes(target_construction, good)) +
  geom_point() +
  geom_errorbar(aes(ymin = good - good_ste, ymax = good + good_ste), width = 0.3) +
  facet_wrap(~model, scales = "free_x") +
  theme_bw(base_size = 15, base_family = "Times") +
  labs(
    x = "Eval Construction",
    y = "Good logprob"
  )


model_scores <- scores %>% 
  filter(idx %in% good_ids) %>%
  select(-train_construction) %>%
  pivot_longer(construction_score:no_numeral_score, names_to = "surface_form", values_to = "logprob") %>%
  mutate(
    lr = str_extract(model, "\\de-\\d"),
    suffix = str_remove(suffix, "-\\de-\\d.csv"),
    model = str_remove(model, "-\\de-\\d")
  ) %>% 
  inner_join(best_models)

model_scores <- scores %>% 
  filter(idx %in% good_ids) %>%
  select(-train_construction) %>%
  mutate(
    lr = str_extract(model, "\\de-\\d"),
    suffix = str_remove(suffix, "-\\de-\\d.csv"),
    model = str_remove(model, "-\\de-\\d")
  ) %>%
  inner_join(unigram_scores %>% select(idx, suffix, ngram_score = construction_score), by = c("idx", "suffix")) %>%
  mutate(construction_score = construction_score - ngram_score) %>% 
  select(-ngram_score) %>%
  pivot_longer(construction_score:no_numeral_score, names_to = "surface_form", values_to = "logprob") %>%
  inner_join(best_models)

avg_model_scores <- model_scores %>%
  group_by(model, seed, suffix, target_construction, surface_form) %>%
  summarize(
    ste = 1.96 * plotrix::std.error(logprob),
    logprob = mean(logprob)
  )

avg_model_scores %>%
  filter(model %in% c("smolm-aann", "smolm-indef-anan", "smolm-indef-naan-rerun")) %>%
  mutate(
    model = str_remove(model, "-rerun"),
    train_construction = str_remove(model, "(smolm-indef-|smolm-)"),
    suffix = str_remove(suffix, "counterfactual-") %>% str_remove("-indef") %>% str_remove("-rerun"),
    surface_form = str_remove(surface_form, "_score"),
    surface_form = factor(
      surface_form, 
      levels = rev(c("construction", "order_swap", "no_modifier", "no_numeral", "no_article", "default_nan")),
      labels = rev(c("Well-formed", "Order Swap", "No Modifier", "No Numeral", "No Article", "Default NAN"))
    )
  ) %>%
  # filter(target_construction == train_construction, surface_form != "Default NAN") %>%
  filter(surface_form != "Default NAN") %>%
  ggplot(aes(logprob, surface_form, color = surface_form, shape = suffix)) +
  geom_point(size = 2) +
  # geom_errorbarh(aes(xmin = logprob - ste, xmax = logprob + ste), height = 0.3,show.legend = FALSE) +
  # facet_wrap(~target_construction, ncol=1) +
  facet_grid(suffix ~ target_construction) +
  scale_color_brewer(palette = "Dark2") +
  # scale_shape_discrete() +
  theme_bw(base_size = 15, base_family = "Times") +
  theme(
    legend.position = "none",
    axis.text = element_text(color = "black")
  ) +
  labs(
    x = "Log-prob (95% CI)",
    y = "Suface Form"
  )

avg_model_scores %>%
  filter(model %in% c("smolm-aann", "smolm-indef-anan", "smolm-indef-naan-rerun")) %>%
  mutate(
    model = str_remove(model, "-rerun"),
    train_construction = str_remove(model, "(smolm-indef-|smolm-)"),
    suffix = str_remove(suffix, "counterfactual-") %>% str_remove("-indef") %>% str_remove("-rerun"),
    surface_form = str_remove(surface_form, "_score"),
    surface_form = factor(
      surface_form, 
      # levels = rev(c("construction", "order_swap", "no_modifier", "no_numeral", "no_article", "default_nan")),
      # labels = rev(c("Well-formed", "Order Swap", "No Modifier", "No Numeral", "No Article", "Default NAN"))
      levels = c("construction", "order_swap", "no_modifier", "no_numeral", "no_article", "default_nan"),
      labels = c("Well-formed", "Order Swap", "No Modifier", "No Numeral", "No Article", "Default NAN")
    )
  ) %>%
  # filter(target_construction == train_construction, surface_form != "Default NAN") %>%
  filter(surface_form != "Default NAN") %>%
  ggplot(aes(logprob, target_construction, color=suffix, fill=suffix)) +
  geom_point(position = position_dodge(width=0.9), alpha = 0.5) +
  # geom_linerange(aes(ymin=logprob-ste, ymax=logprob+ste), position=position_dodge(width=0.9)) +
  # geom_linerangeh(aes(xmin=logprob-ste, xmax=logprob+ste), position=position_dodge(width=0.9)) +
  facet_wrap(~surface_form,nrow=1) +
  scale_color_brewer(palette = "Dark2", aesthetics = c("fill", "color")) +
  # scale_shape_discrete() +
  theme_bw(base_size = 15, base_family = "Times") +
  theme(
    legend.position = "top",
    axis.text = element_text(color = "black")
  )

model_scores %>%
  filter(model %in% c("smolm-aann", "smolm-indef-anan", "smolm-indef-naan-rerun")) %>%
  mutate(
    model = str_remove(model, "-rerun"),
    train_construction = str_remove(model, "(smolm-indef-|smolm-)"),
    suffix = str_remove(suffix, "counterfactual-") %>% str_remove("-indef") %>% str_remove("-rerun"),
    surface_form = str_remove(surface_form, "_score"),
    surface_form = factor(
      surface_form, 
      levels = rev(c("construction", "order_swap", "no_modifier", "no_numeral", "no_article", "default_nan")),
      labels = rev(c("Good", "Order Swap", "No Modifier", "No Numeral", "No Article", "Default NAN"))
    )
  ) %>%
  # filter(target_construction == train_construction, surface_form != "Default NAN") %>%
  filter(surface_form != "Default NAN") %>%
  ggplot(aes(logprob, surface_form, color = surface_form)) +
  geom_boxplot() +
  # facet_wrap(~suffix, ncol=1) +
  facet_grid(suffix ~ target_construction) +
  scale_color_brewer(palette = "Dark2") +
  # scale_shape_discrete() +
  theme_bw(base_size = 15, base_family = "Times") +
  theme(
    legend.position = "none",
    axis.text = element_text(color = "black")
  ) +
  labs(
    x = "Log-prob (95% CI)",
    y = "Suface Form"
  )

avg_model_scores %>% 
  ungroup() %>%
  filter(!str_detect(model, "(naan|anan)"), target_construction == "aann") %>%
  filter(surface_form == "construction_score") %>% 
  mutate(
    # logprob = logprob/log(2),
    suffix = str_remove(suffix, "(counterfactual-babylm-indef-|counterfactual-babylm-)") %>%
      str_remove("aann-"),
    suffix = factor(
      suffix,
      levels = c("babylm", "no_prototypical", "prototypical_only", "adj_num_freq_balanced", "all_det_removal", "removal", "indef_articles_with_pl_nouns-removal", "measure_nouns_as_singular"),
      labels = c("BabyLM", "No Prototypical\nAANNs", "Prototypical\nAANNs only", "Adj-Num Freq\nBalanced", "No DT ANN", "No AANN", "No Indef articles\nw/Pl Nouns", "No Measure Nouns\nas Singular")
    ),
    suffix = fct_reorder(suffix, logprob)
  ) %>%
  ggplot(aes(logprob, suffix)) +
  geom_point(size=2, color = "#d95f02") +
  geom_linerange(aes(xmax = logprob + ste, xmin = logprob - ste), color = "#d95f02") +
  scale_x_continuous(breaks = scales::pretty_breaks(6)) +
  theme_bw(base_size = 15, base_family = "Times") +
  theme(
    axis.title.y = element_blank()
    # axis.text.y = element_text(angle=15)
  ) +
  labs(
    x = "SLOR (95% CI)"
  )
  

results %>%
  mutate(
    lr = str_extract(suffix, "\\de-\\d"),
    suffix = str_remove(suffix, "-\\de-\\d.csv")
  ) %>% 
  inner_join(best_models) %>% View()

results %>%
  select(suffix, train_construction, target_construction, overall) %>%
  pivot_wider(names_from = target_construction, values_from = overall) %>%
  mutate(
    lr = str_extract(suffix, "\\de-\\d"),
    suffix = str_remove(suffix, "-\\de-\\d.csv")
  ) %>% 
  inner_join(best_models) %>% View()
  write_csv("paper/results12182023.csv")
# %>%
  # filter(str_detect(model, "smolm-indef-naan"))

human_data %>% 
  mutate(judgment = case_when(rating > 7 ~ "good", TRUE ~ "bad")) %>% 
  inner_join(scores) %>% 
  group_by(suffix, judgment) %>% 
  summarize(logprob = mean(construction_score), ste = 1.96 * plotrix::std.error(construction_score)) %>% 
  mutate(
    lr = str_extract(suffix, "\\de-\\d"),
    suffix = str_remove(suffix, "-\\de-\\d.csv")
  ) %>% 
  inner_join(best_models) %>%
  ggplot(aes(logprob, suffix, group = judgment, color = judgment)) +
  geom_point(dodge=position_dodge2(width=0.9)) +
  geom_errorbarh(aes(xmin = logprob-ste, xmax = logprob+ste))
  

scores %>%
  filter(target_construction == "aann") %>%
  inner_join(human_data) %>%
  group_by(model) %>%
  summarize(
    default_acc = mean(default_nan_score > no_article_score)
  )
