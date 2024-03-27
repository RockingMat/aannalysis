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
  "counterfactual-babylm-measure_nouns_as_singular", "1e-4",
  "counterfactual-babylm-random_removal", "3e-4",
  "counterfactual-babylm-only_other_det_removal", "1e-3",
  "counterfactual-babylm-only_indef_articles_with_pl_nouns_removal", "1e-3",
  "counterfactual-babylm-only_measure_nps_as_singular_removal", "1e-3",
  "counterfactual-babylm-only_random_removal", "1e-3",
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

human_data %>%
  filter(adjclass %in% c("quant", "qual", "stubborn", "color")) %>% 
  inner_join(aanns) %>%
  group_by(NUMERAL, NOUN, nounclass, adjclass) %>%
  summarize(
    rating = mean(rating)
  ) %>% View()

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

# scores %>% count(model, seed)

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

llama_scores <- scores %>%
  filter(idx %in% good_ids, str_detect(model, "llama")) %>%
  filter(target_construction == "aann") %>%
  mutate(
    correct = construction_score > order_swap_score & 
      construction_score > no_article_score & 
      construction_score > no_numeral_score & 
      construction_score > no_modifier_score
  )

llama_scores %>%
  select(idx, correct) %>%
  inner_join(mahowald_meta) %>%
  group_by(adjclass, nounclass) %>%
  summarize(
    n = n(),
    acc = mean(correct)
  ) %>%
  write_csv("data/results/llama2_aanns_breakdown.csv")

# llama_scores %>%
#   inner_join(all_corruptions) %>%
#   select(idx, cons)

llama_pairwise_scores <- llama_scores %>%
  select(-model, -default_nan_score, -seed, -train_construction, -correct, -target_construction, -suffix) %>%
  pivot_longer(order_swap_score:no_numeral_score, names_to = "corruption", values_to = "corruption_score") %>%
  mutate(corruption = str_remove(corruption, "_score"))

pairwise <- all_corruptions %>%
  select(-sentence, -prefixes, -default_ann) %>%
  pivot_longer(order_swap:no_numeral, names_to = "corruption", values_to = "corrupted_construction") %>%
  select(idx, corruption, aann, corrupted_construction)

llama_pairwise_scores %>%
  inner_join(pairwise) %>%
  mutate(
    diff = construction_score - corruption_score
  ) %>%
  select(idx, corruption, aann, corrupted_construction, diff) %>%
  write_csv("data/results/llama2_aanns.csv")

# %>%
  # select(idx, sentence, correct)

write_csv(llama, "data/results/llama2_aanns.csv")

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


# model_scores %>% count(suffix)

logprobs <- scores %>%
  # filter(idx %in% good_ids) %>%
  select(-train_construction) %>%
  mutate(
    lr = str_extract(model, "\\de-\\d"),
    suffix = str_remove(suffix, "-\\de-\\d.csv"),
    model = str_remove(model, "-\\de-\\d")
  ) %>% 
  inner_join(best_models)

slor_values <- logprobs %>%
  inner_join(unigram_scores %>% select(-model) %>% rename_with(function(x) {str_c("ngram_", x)}, ends_with("score")), by = c("idx", "suffix")) %>%
  mutate(
    construction_score = construction_score - ngram_construction_score,
    default_nan_score = default_nan_score - ngram_default_nan_score,
    order_swap_score = order_swap_score - ngram_order_swap_score,
    no_article_score = no_article_score - ngram_no_article_score,
    no_modifier_score = no_modifier_score - ngram_no_modifier_score,
    no_numeral_score = no_numeral_score - ngram_no_numeral_score,
  )

slor_values %>% count(suffix)

both = bind_rows(
  logprobs %>% 
    filter(model == "smolm-indef-naan-rerun", seed == 42, target_construction == "naan") %>%
    mutate(model = "logprob-naan"),
  slor_values %>% filter(model == "smolm-indef-naan-rerun", seed == 42, target_construction == "naan") %>%
    mutate(model = "slor-naan")
) %>%
  mutate(
    correct = construction_score > order_swap_score & 
      construction_score > no_article_score & 
      construction_score > no_numeral_score & 
      construction_score > no_modifier_score
  )

both %>%
  filter(model == "logprob-naan") %>%
  select(model, idx, logprob_correct = correct) %>%
  inner_join(
    both %>%
      filter(model == "slor-naan") %>%
      select(model, idx, slor_correct = correct),
    by = c("idx")
  ) %>%
  filter(logprob_correct != slor_correct)

both %>%
  filter(idx == 59) %>% View()

slor_values %>%
  filter(suffix == "babylm", target_construction == "aann", seed == 1024) %>%
  inner_join(human_data) %>%
  # mutate(
  #   construction_score = (construction_score - min(construction_score))/(max(construction_score) - min(construction_score))
  # ) %>%
  group_by(adjclass, nounclass) %>%
  summarize(
    ste = 1.96 * plotrix::std.error(construction_score),
    slor = mean(construction_score)
  ) %>%
  ggplot(aes(adjclass, slor, color = adjclass, fill = adjclass)) +
  geom_point(size = 3, shape = 21) +
  scale_color_brewer(palette = "Dark2", aesthetics = c("color", "fill")) +
  facet_wrap(~nounclass, nrow = 1, scales = "free_x") +
  theme_bw(base_size = 15, base_family = "Times") +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

slor_results <- scores %>%
  filter(idx %in% good_ids) %>%
  select(-train_construction) %>%
  mutate(
    lr = str_extract(model, "\\de-\\d"),
    suffix = str_remove(suffix, "-\\de-\\d.csv"),
    model = str_remove(model, "-\\de-\\d")
  ) %>% 
  inner_join(best_models) %>%
  inner_join(unigram_scores %>% select(-model) %>% rename_with(function(x) {str_c("ngram_", x)}, ends_with("score")), by = c("idx", "suffix")) %>%
  mutate(
    construction_score = construction_score - ngram_construction_score,
    order_swap_score = order_swap_score - ngram_order_swap_score,
    no_article_score = no_article_score - ngram_no_article_score,
    no_modifier_score = no_modifier_score - ngram_no_modifier_score,
    no_numeral_score = no_numeral_score - ngram_no_numeral_score,
  ) %>%
  group_by(model, suffix, seed, target_construction) %>%
  summarize(
    accuracy = mean(
      construction_score > order_swap_score & 
        construction_score > no_article_score & 
        construction_score > no_numeral_score & 
        construction_score > no_modifier_score
    )
  )

slor_results %>%
  filter(model %in% c("smolm-aann", "smolm-indef-anan", "smolm-indef-naan-rerun", "smolm-indef-removal")) %>%
  mutate(
    train_condition = case_when(
      model == "smolm-aann" ~ "AANN",
      model == "smolm-indef-anan" ~ "ANAN",
      model == "smolm-indef-naan-rerun" ~ "NAAN",
      TRUE ~ "No AANN"
    ),
    train_condition = factor(
      train_condition, 
      levels = c("AANN", "No AANN", "ANAN", "NAAN"),
      # labels = c(
      #   "<span style='font-size: 11pt;'>AANN</span>",
      #   "<span style='font-size: 11pt;'>No AANN</span>",
      #   "<span style='font-size: 11pt;'>ANAN</span>",
      #   "<span style='font-size: 11pt;'>NAAN</span>"
      # )
    ),
    eval_condition = case_when(
      model == "smolm-aann" ~ "aann",
      model == "smolm-indef-anan" ~ "anan",
      model == "smolm-indef-naan-rerun" ~ "naan",
      TRUE ~ "aann"
    ),
    eval_condition = factor(
      eval_condition,
      levels = c("aann", "anan", "naan"), 
      labels = c("AANN", "ANAN", "NAAN")
    ),
    target_construction = str_to_upper(target_construction),
  ) %>%
  ggplot(aes(train_condition, accuracy, color = train_condition, fill = train_condition, shape = train_condition)) +
  geom_point(size = 3, alpha = 0.7) +
  geom_hline(yintercept = 0.0625, linetype = "dashed") +
  geom_hline(
    data = results %>% 
      filter(str_detect(suffix, "gpt2"), target_construction == "aann") %>%
      select(-train_construction) %>%
      mutate(target_construction = "AANN"),
    aes(yintercept = overall),
    linetype = "dotted",
    color = "firebrick"
  ) +
  geom_hline(
    data = results %>% 
      filter(str_detect(suffix, "Llama"), target_construction == "aann") %>%
      select(-train_construction) %>%
      mutate(target_construction = "AANN"),
    aes(yintercept = overall),
    linetype = "dotted",
    color = "steelblue"
  ) +
  # geom_text(x = "NAAN", y = 0.87, label = "LLama-2-7B", data=tibble(target_construction="AANN")) +
  geom_text(
    data = tibble(
      train_condition = "NAAN",
      accuracy = 0.9,
      target_construction="AANN"
    ),
    label = "Llama-2-7B",
    color = "steelblue",
    family = "Times",
    size = 3.5
  ) +
  geom_text(
    data = tibble(
      train_condition = "NAAN",
      accuracy = 0.73,
      target_construction="AANN"
    ),
    label = "GPT-2 XL",
    color = "firebrick",
    family = "Times",
    size = 3.5
  ) +
  facet_wrap(~target_construction) +
  # scale_color_brewer(palette = "Dark2", aesthetics = c("color", "fill"), direction = -1) +
  scale_color_manual(values = c("#7570b3","#d95f02","#e7298a","#1b9e77"), aesthetics = c("color", "fill")) +
  scale_shape_manual(values = c(21, 22, 23, 24)) +
  scale_y_continuous(limits = c(0, 1.0)) +
  theme_bw(base_size = 16, base_family="Times") +
  theme(
    legend.position = "none",
    panel.grid = element_blank(),
    axis.text = element_text(color = "black"),
    axis.text.x = element_text(color = "black", size = 11)
    # axis.text.x = element_markdown(color = "black")
  ) +
  labs(
    x = "Train Condition",
    y = "Accuracy\n(3 LM runs)"
  )

# 8.74, 2.94
ggsave("paper/counterfactualaccuracies.pdf", height = 3.06, width = 9.17, dpi = 300, device=cairo_pdf)

# kyle plot


slor_results %>%
  filter(model %in% c("smolm-aann", "smolm-indef-anan", "smolm-indef-naan-rerun", "smolm-indef-removal", "smolm-measure_nouns_as_singular", "smolm-random_removal")) %>%
  mutate(
    train_condition = case_when(
      model == "smolm-aann" ~ "AANN",
      model == "smolm-indef-anan" ~ "ANAN",
      model == "smolm-indef-naan-rerun" ~ "NAAN",
      model == "smolm-measure_nouns_as_singular" ~ "AANN - NNS as singular",
      model == "smolm-random_removal" ~ "AANN - random removal",
      TRUE ~ "No AANN"
    ),
    train_condition = factor(
      train_condition, 
      levels = c("AANN", "No AANN", "ANAN", "NAAN", "AANN - NNS as singular", "AANN - random removal"),
      # labels = c(
      #   "<span style='font-size: 11pt;'>AANN</span>",
      #   "<span style='font-size: 11pt;'>No AANN</span>",
      #   "<span style='font-size: 11pt;'>ANAN</span>",
      #   "<span style='font-size: 11pt;'>NAAN</span>"
      # )
    ),
    eval_condition = case_when(
      model == "smolm-aann" ~ "aann",
      model == "smolm-indef-anan" ~ "anan",
      model == "smolm-indef-naan-rerun" ~ "naan",
      TRUE ~ "aann"
    ),
    eval_condition = factor(
      eval_condition,
      levels = c("aann", "anan", "naan"), 
      labels = c("AANN", "ANAN", "NAAN")
    ),
    target_construction = str_to_upper(target_construction),
  ) %>%
  filter(target_construction == eval_condition) %>%
  mutate(
    train = case_when(
      train_condition == "No AANN" ~ "Remove AANNs",
      train_condition == "ANAN" ~ "Replace AANNs\nwith ANANs",
      train_condition == "NAAN" ~ "Replace AANNs\nwith NAANs",
      train_condition == "AANN" ~ "AANN (as is)",
      train_condition == "AANN - random removal" ~ "Control\n(random removal)",
      TRUE ~ "Remove cases with\nA few days/\nfive days is a lot"
    )
  ) %>%
  ggplot(aes(train, accuracy, color = train_condition, fill = train_condition, shape = train_condition)) +
  geom_point(size = 3, alpha = 0.7) +
  # stat_summary(geom = "point", size = 3, alpha = 0.7) +
  geom_hline(yintercept = 0.0625, linetype = "dashed") +
  # facet_wrap(~target_construction) +
  scale_color_brewer(palette = "Dark2", aesthetics = c("color", "fill")) +
  scale_shape_manual(values = c(21, 22, 23, 24, 25, 8)) +
  scale_y_continuous(limits = c(0, 0.8)) +
  theme_bw(base_size = 16, base_family="Times") +
  theme(
    legend.position = "none",
    panel.grid = element_blank(),
    axis.text = element_text(color = "black"),
    axis.text.x = element_text(color = "black", size = 11)
    # axis.text.x = element_markdown(color = "black")
  ) +
  labs(
    x = "Manipulation",
    y = "Accuracy on Construction\n(Across 3 runs)"
  )

model_scores <- scores %>% 
  filter(idx %in% good_ids) %>%
  select(-train_construction) %>%
  mutate(
    lr = str_extract(model, "\\de-\\d"),
    suffix = str_remove(suffix, "-\\de-\\d.csv"),
    model = str_remove(model, "-\\de-\\d")
  ) %>%
  # inner_join(unigram_scores %>% select(idx, suffix, ngram_score = construction_score), by = c("idx", "suffix")) %>%
  inner_join(unigram_scores %>% select(-model) %>% rename_with(function(x) {str_c("ngram_", x)}, ends_with("score")), by = c("idx", "suffix")) %>%
  mutate(
    construction_score = construction_score - ngram_construction_score,
    order_swap_score = order_swap_score - ngram_order_swap_score,
    no_article_score = no_article_score - ngram_no_article_score,
    no_modifier_score = no_modifier_score - ngram_no_modifier_score,
    no_numeral_score = no_numeral_score - ngram_no_numeral_score,
  ) %>%
  select(-starts_with("ngram")) %>%
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

avg_model_scores %>%
  filter(model %in% c("smolm-aann", "smolm-indef-anan", "smolm-indef-naan-rerun", "smolm-indef-removal")) %>%
  mutate(
    train_condition = case_when(
      model == "smolm-aann" ~ "AANN",
      model == "smolm-indef-anan" ~ "ANAN",
      model == "smolm-indef-naan" ~ "NAAN",
      TRUE ~ "No AANN"
    ),
    eval_condition = case_when(
      model == "smolm-aann" ~ "aann",
      model == "smolm-indef-anan" ~ "anan",
      model == "smolm-indef-naan" ~ "naan",
      TRUE ~ "aann"
    ),
    eval_condition = factor(eval_condition, levels = c("aann", "anan", "naan"))
  ) %>%
  filter(target_construction == eval_condition) %>%
  mutate(
    # suffix = str_remove(suffix, "counterfactual-") %>% str_remove("-indef") %>% str_remove("-rerun"),
    surface_form = str_remove(surface_form, "_score"),
    surface_form = factor(
      surface_form, 
      # levels = rev(c("construction", "order_swap", "no_modifier", "no_numeral", "no_article", "default_nan")),
      # labels = rev(c("Well-formed", "Order Swap", "No Modifier", "No Numeral", "No Article", "Default NAN"))
      levels = c("construction", "order_swap", "no_modifier", "no_numeral", "no_article", "default_nan"),
      labels = c("Well-formed", "Order Swap", "No Modifier", "No Numeral", "No Article", "Default NAN")
    )
  ) %>%
  ggplot(aes(surface_form, logprob))

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

avg_model_scores <- model_scores %>%
  group_by(model, suffix, target_construction, surface_form) %>%
  summarize(
    ste = 1.96 * plotrix::std.error(logprob),
    logprob = mean(logprob)
  )

bigram_slors <- bigram_scores %>%
  inner_join(unigram_scores %>% select(-model) %>% rename_with(function(x) {str_c("ngram_", x)}, ends_with("score")), by = c("idx", "suffix")) %>%
  mutate(
    construction_score = construction_score - ngram_construction_score,
    default_nan_score = default_nan_score - ngram_default_nan_score,
    order_swap_score = order_swap_score - ngram_order_swap_score,
    no_article_score = no_article_score - ngram_no_article_score,
    no_modifier_score = no_modifier_score - ngram_no_modifier_score,
    no_numeral_score = no_numeral_score - ngram_no_numeral_score,
  ) %>%
  filter(idx %in% good_ids) %>%
  select(-starts_with("ngram")) %>%
  pivot_longer(construction_score:no_numeral_score, names_to = "surface_form", values_to = "logprob")

avg_bigram_slors <- bigram_slors %>%
  group_by(model, suffix, surface_form) %>%
  summarize(
    ste = 1.96 * plotrix::std.error(logprob),
    logprob = mean(logprob)
  )

final_bigram_slors <- avg_bigram_slors %>%
  filter(!str_detect(model, "prototypical")) %>%
  filter(surface_form == "construction_score") %>% 
  mutate(
    # logprob = logprob/log(2),
    suffix = str_remove(suffix, "(counterfactual-babylm-indef-|counterfactual-babylm-)") %>%
      str_remove("aann-"),
    suffix = factor(
      suffix,
      levels = c("babylm", "no_prototypical", "prototypical_only", "adj_num_freq_balanced", "all_det_removal", "removal", "indef_articles_with_pl_nouns-removal", "measure_nouns_as_singular", "random_removal", "only_random_removal", "only_other_det_removal", "only_indef_articles_with_pl_nouns_removal", "only_measure_nps_as_singular_removal"),
      labels = c("Unablated", "No Prototypical\nAANNs", "Prototypical\nAANNs only", "A/An Adj-Num\nFreq Balanced", "No DT-ANNs", "No AANNs", "No A few/couple/\ndozen/etc. NNS", "No Measure\nNNS as Singular", "Random\nRemoval", "Onlyrandom\nRemoval", "onlyNo DT-ANNs", "onlyNo A few/couple/\ndozen/etc. NNS", "onlyNo Measure\nNNS as Singular")
    ),
    suffix = fct_reorder(suffix, logprob)
  )


paired_bigram_slors <- bind_rows(
  final_bigram_slors %>% filter(str_detect(suffix, "(only|Random|Unablated)")) %>% mutate(condition = "AANNs seen\nduring training", suffix = str_remove(suffix, "only")),
  final_bigram_slors %>% filter(!str_detect(suffix, "(only|Random|Unablated)")) %>% mutate(condition = "AANNs removed\nfrom training", suffix = str_replace(suffix, "Onlyr", "R")),
) %>%
  mutate(
    suffix = factor(suffix, levels = rev(c("Unablated", "No Prototypical\nAANNs", "Prototypical\nAANNs only", "No AANNs", "No DT-ANNs", "No A few/couple/\ndozen/etc. NNS", "No Measure\nNNS as Singular", "A/An Adj-Num\nFreq Balanced", "Random\nRemoval")))
  )

paired_bigram_slors %>%
  ggplot(aes(logprob, suffix, shape = condition, color = condition, fill = condition)) +
  geom_vline(aes(xintercept=logprob), data = final_bigram_slors %>% filter(suffix=="Unablated"), linetype = "dotted") +
  # ggplot(aes(logprob, suffix, shape = condition)) +
  geom_point(size=3) +
  # geom_point(aes(group = seed), size=2, position = position_dodge(width=0.5), alpha = 0.2) +
  # geom_point(aes(group = seed), size=2, color = "black", fill = "black", position = position_dodge(width=0.5), alpha = 0.2) +
  geom_linerange(aes(xmax = logprob + ste, xmin = logprob - ste)) +
  # geom_linerange(aes(group = seed, xmax = logprob + ste, xmin = logprob - ste), color = "black", position=position_dodge(width=0.5), alpha = 0.2) +
  # stat_summary(geom = "point", fun = mean, size = 3) +
  # stat_summary(geom = "point", fun = mean, color = "#d95f02", fill = "#d95f02", size = 3) +
  # stat_summary(fun.data = mean_se,  geom = "linerange") +
  scale_shape_manual(values = c(23, 24)) +
  scale_x_continuous(breaks = scales::pretty_breaks(6)) +
  scale_color_brewer(aesthetics = c("color", "fill"), palette = "Dark2") +
  theme_bw(base_size = 15, base_family = "Times") +
  theme(
    axis.title.y = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.text = element_text(color = "black"),
    legend.position = "top"
    # axis.text.y = element_text(angle=15)
  ) +
  labs(
    color = "Condition",
    fill = "Condition",
    shape = "Condition",
    x = "SLOR (95% CI)"
  )

ggsave("paper/bigram_slors.pdf", width = 5.97, height = 4.94, dpi = 300, device = cairo_pdf)


final_slors <- avg_model_scores %>%
  ungroup() %>%
  filter(!str_detect(model, "(naan|anan)"), target_construction == "aann") %>%
  filter(!str_detect(model, "prototypical")) %>%
  filter(surface_form == "construction_score") %>% 
  mutate(
    # logprob = logprob/log(2),
    suffix = str_remove(suffix, "(counterfactual-babylm-indef-|counterfactual-babylm-)") %>%
      str_remove("aann-"),
    suffix = factor(
      suffix,
      levels = c("babylm", "no_prototypical", "prototypical_only", "adj_num_freq_balanced", "all_det_removal", "removal", "indef_articles_with_pl_nouns-removal", "measure_nouns_as_singular", "random_removal", "only_random_removal", "only_other_det_removal", "only_indef_articles_with_pl_nouns_removal", "only_measure_nps_as_singular_removal"),
      labels = c("Unablated", "No Prototypical\nAANNs", "Prototypical\nAANNs only", "A/An Adj-Num\nFreq Balanced", "No DT-ANNs", "No AANNs", "No A few/couple/\ndozen/etc. NNS", "No Measure\nNNS as Singular", "Random\nRemoval", "Onlyrandom\nRemoval", "onlyNo DT-ANNs", "onlyNo A few/couple/\ndozen/etc. NNS", "onlyNo Measure\nNNS as Singular")
    ),
    suffix = fct_reorder(suffix, logprob)
  )

# final_slors %>% 

paired_final_slors <- bind_rows(
  final_slors %>% filter(str_detect(suffix, "(only|Random|Unablated)")) %>% mutate(condition = "AANNs seen\nduring training", suffix = str_remove(suffix, "only")),
  final_slors %>% filter(!str_detect(suffix, "(only|Random|Unablated)")) %>% mutate(condition = "AANNs removed\nfrom training", suffix = str_replace(suffix, "Onlyr", "R")),
) %>%
  mutate(
    suffix = factor(suffix, levels = rev(c("Unablated", "No Prototypical\nAANNs", "Prototypical\nAANNs only", "No AANNs", "No DT-ANNs", "No A few/couple/\ndozen/etc. NNS", "No Measure\nNNS as Singular", "A/An Adj-Num\nFreq Balanced", "Random\nRemoval")))
  )

paired_final_slors %>%
  ggplot(aes(logprob, suffix, shape = condition, color = condition, fill = condition)) +
  geom_vline(aes(xintercept=logprob), data = final_slors %>% filter(suffix=="Unablated"), linetype = "dotted") +
  # ggplot(aes(logprob, suffix, shape = condition)) +
  geom_point(size=3) +
  # geom_point(aes(group = seed), size=2, position = position_dodge(width=0.5), alpha = 0.2) +
  # geom_point(aes(group = seed), size=2, color = "black", fill = "black", position = position_dodge(width=0.5), alpha = 0.2) +
  geom_linerange(aes(xmax = logprob + ste, xmin = logprob - ste)) +
  # geom_linerange(aes(group = seed, xmax = logprob + ste, xmin = logprob - ste), color = "black", position=position_dodge(width=0.5), alpha = 0.2) +
  # stat_summary(geom = "point", fun = mean, size = 3) +
  # stat_summary(geom = "point", fun = mean, color = "#d95f02", fill = "#d95f02", size = 3) +
  # stat_summary(fun.data = mean_se,  geom = "linerange") +
  scale_shape_manual(values = c(23, 24)) +
  scale_x_continuous(breaks = scales::pretty_breaks(6), limits = c(1.2, 2.2)) +
  scale_color_brewer(aesthetics = c("color", "fill"), palette = "Dark2") +
  theme_bw(base_size = 15, base_family = "Times") +
  theme(
    axis.title.y = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.text = element_text(color = "black"),
    legend.position = "top"
    # axis.text.y = element_text(angle=15)
  ) +
  labs(
    color = "Condition",
    fill = "Condition",
    shape = "Condition",
    x = "SLOR (95% CI, 3 LM Runs)"
  )

# 5.41, 4.90
# 5.09, 4.09
# 5.94/4.97
ggsave("paper/hypotheses_slors.pdf", width = 5.97, height = 4.94, dpi = 300, device = cairo_pdf)

bind_rows(
  paired_bigram_slors %>% mutate(LM = "Bigram LM"),
  paired_final_slors %>% mutate(LM = "OPT LM")
) %>%
  mutate(condition = str_replace(condition, "\n", " ")) %>%
  ggplot(aes(logprob, suffix, shape = condition, color = condition, fill = condition)) +
  geom_vline(aes(xintercept=logprob), data = final_slors %>% filter(suffix=="Unablated") %>% mutate(LM="OPT LM"), linetype = "dotted") +
  geom_vline(aes(xintercept=logprob), data = final_bigram_slors %>% filter(suffix=="Unablated") %>% mutate(LM="Bigram LM"), linetype = "dotted") +
  # ggplot(aes(logprob, suffix, shape = condition)) +
  geom_point(size=3) +
  # geom_point(aes(group = seed), size=2, position = position_dodge(width=0.5), alpha = 0.2) +
  # geom_point(aes(group = seed), size=2, color = "black", fill = "black", position = position_dodge(width=0.5), alpha = 0.2) +
  geom_linerange(aes(xmax = logprob + ste, xmin = logprob - ste)) +
  # geom_linerange(aes(group = seed, xmax = logprob + ste, xmin = logprob - ste), color = "black", position=position_dodge(width=0.5), alpha = 0.2) +
  # stat_summary(geom = "point", fun = mean, size = 3) +
  # stat_summary(geom = "point", fun = mean, color = "#d95f02", fill = "#d95f02", size = 3) +
  # stat_summary(fun.data = mean_se,  geom = "linerange") +
  facet_wrap(~ LM, scales = "free_x") +
  scale_shape_manual(values = c(23, 24)) +
  scale_x_continuous(breaks = scales::pretty_breaks(6)) +
  scale_color_brewer(aesthetics = c("color", "fill"), palette = "Dark2") +
  theme_bw(base_size = 15, base_family = "Times") +
  theme(
    axis.title.y = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.text = element_text(color = "black"),
    legend.position = "top"
    # axis.text.y = element_text(angle=15)
  ) +
  labs(
    color = "Condition",
    fill = "Condition",
    shape = "Condition",
    x = "SLOR (95% CI, 3 OPT LM runs)"
  )

ggsave("paper/bigram_vs_opt_lm_slors.pdf", width = 8.52, height = 4.47, dpi = 300, device=cairo_pdf)


avg_model_scores %>% 
  ungroup() %>%
  filter(!str_detect(model, "(naan|anan)"), target_construction == "aann") %>%
  # filter(!str_detect(model, "prototypical")) %>%
  filter(surface_form == "construction_score") %>% 
  mutate(
    # logprob = logprob/log(2),
    suffix = str_remove(suffix, "(counterfactual-babylm-indef-|counterfactual-babylm-)") %>%
      str_remove("aann-"),
    suffix = factor(
      suffix,
      levels = rev(c("babylm", "no_prototypical", "prototypical_only", "adj_num_freq_balanced", "all_det_removal", "removal", "indef_articles_with_pl_nouns-removal", "measure_nouns_as_singular")),
      labels = rev(c("Unablated", "High Variability\nAANNs", "Low Variability\nAANNs", "A/An Adj-Num\nFreq Balanced", "No DT-ANNs", "No AANNs", "No Indef articles\nw/ Measure NNS", "No Measure\nNNS as Singular"))
    ),
    # suffix = fct_reorder(suffix, logprob)
  ) %>%
  filter(suffix %in% c("Unablated", "No AANNs", "Low Variability\nAANNs", "High Variability\nAANNs")) %>%
  ggplot(aes(logprob, suffix)) +
  # geom_point(aes(group = seed), size=2, color = "#7570b3", fill = "#7570b3", position = position_dodge(width=0.5), alpha = 0.2, shape = 21) +
  geom_point( size=3, color = "#7570b3", fill = "#7570b3", shape = 21) +
  geom_vline(aes(xintercept=logprob), data = final_slors %>% filter(suffix=="Unablated"), linetype = "dotted") +
  # geom_linerange(aes(group = seed, xmax = logprob + ste, xmin = logprob - ste), color = "black", position=position_dodge(width=0.5), alpha = 0.2) +
  geom_linerange(aes(xmax = logprob + ste, xmin = logprob - ste), color = "#7570b3") +
  # stat_summary(geom = "point", fun = mean, color = "#7570b3", fill = "#7570b3", shape = 21, size = 3) +
  scale_x_continuous(breaks = scales::pretty_breaks(6), limits = c(1.8, 2.3)) +
  theme_bw(base_size = 15, base_family = "Times") +
  theme(
    axis.title.y = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.text = element_text(color = "black"),
    # axis.text.y = element_text(angle=15)
  ) +
  labs(
    x = "SLOR (95% CI, 3 LM Runs)"
  )

# 5.26, 4.02
# 5.09, 2.56
ggsave("paper/variability.pdf", height = 2.56, width = 5.09, dpi = 300, device=cairo_pdf)


# Simplified plot for talk

avg_model_scores_all <- model_scores %>%
  group_by(model, suffix, target_construction, surface_form) %>%
  summarize(
    ste = 1.96 * plotrix::std.error(logprob),
    logprob = mean(logprob)
  )

avg_model_scores_all %>%
  ungroup() %>%
  filter(!str_detect(model, "(naan|anan)"), target_construction == "aann") %>%
  filter(!str_detect(model, "prototypical")) %>%
  filter(surface_form == "construction_score") %>% 
  mutate(
    # logprob = logprob/log(2),
    suffix = str_remove(suffix, "(counterfactual-babylm-indef-|counterfactual-babylm-)") %>%
      str_remove("aann-"),
    suffix = factor(
      suffix,
      levels = c("babylm", "no_prototypical", "prototypical_only", "adj_num_freq_balanced", "all_det_removal", "removal", "indef_articles_with_pl_nouns-removal", "measure_nouns_as_singular", "random_removal"),
      labels = c("A beautiful five weeks", "No Prototypical\nAANNs", "Prototypical\nAANNs only", "A/An Adj-Num\nFreq Balanced", "No DT-ANNs", "w/o A beautiful five weeks", "No Indef articles\nw/ Measure NNS", "w/o A few days &\nten months is a lot", "Control: Random removal")
    ),
    suffix = fct_reorder(suffix, logprob)
  ) %>% 
  filter(suffix %in% c("A beautiful five weeks", "w/o A beautiful five weeks", "w/o A few days &\nten months is a lot", "Control: Random removal")) %>%
  ggplot(aes(logprob, suffix)) +
  geom_point(size=3, color = "#d95f02", alpha = 0.8, shape = 19) +
  geom_linerange(aes(xmax = logprob + ste, xmin = logprob - ste), color = "#d95f02") +
  # stat_summary(geom = "point", fun = mean, color = "#d95f02", shape = 19, size = 3) +
  scale_x_continuous(breaks = scales::pretty_breaks(6)) +
  theme_bw(base_size = 15, base_family = "Times") +
  theme(
    axis.title.y = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.text = element_text(color = "black"),
    # axis.text.y = element_text(angle=15)
  ) +
  labs(
    # x = "SLOR (95% CI; 3 LM Runs)"
    x = "Likelihood of AANN-containing sentences"
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


slor_values %>%
  filter(suffix %in% c("babylm", "counterfactual-babylm-indef-removal"), target_construction == "aann") %>%
  inner_join(human_data) %>%
  filter(adjclass %in% c("quant", "qual", "stubborn", "color")) %>%
  group_by(suffix, nounclass, adjclass) %>%
  summarize(
    ste = 1.96 * plotrix::std.error(construction_score),
    slor = mean(construction_score)
  ) %>%
  ungroup() %>%
  mutate(
    model = factor(suffix, levels = c("babylm", "counterfactual-babylm-indef-removal"), labels = c("Unablated", "No AANN"))
  ) %>%
  ggplot(aes(adjclass, slor, color = model, fill = model, shape = adjclass)) +
  geom_point(size = 2) +
  geom_linerange(aes(ymin = slor-ste, ymax=slor+ste)) +
  geom_line(aes(group = model)) +
  # geom_col(position = position_dodge(0.9)) +
  scale_color_brewer(palette = "Dark2", aesthetics = c("color", "fill")) +
  scale_shape_manual(values = c(21, 22, 23, 24)) +
  facet_wrap(~ nounclass, nrow = 1, scales = "free_x") +
  theme_bw(base_size = 16, base_family = "Times") +
  theme(
    legend.position = "top",
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
    axis.title.x = element_blank()
  )

human_data %>%
  filter(adjclass %in% c("quant", "qual", "stubborn", "color")) %>%
  group_by(nounclass, adjclass) %>%
  summarize(
    ste = 1.96 * plotrix::std.error(rating),
    rating = mean(rating)
  ) %>%
  ggplot(aes(adjclass, rating, color = adjclass, fill = adjclass)) +
  # geom_point(size = 2) +
  geom_col(position = position_dodge(0.9)) +
  scale_color_brewer(palette = "Dark2", aesthetics = c("color", "fill")) +
  facet_wrap(~ nounclass, nrow = 1, scales = "free_x") +
  theme_bw(base_size = 16, base_family = "Times") +
  theme(
    legend.position = "top",
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
    axis.title.x = element_blank()
  )
  
mahowald_meta


