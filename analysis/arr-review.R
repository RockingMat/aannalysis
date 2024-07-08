library(tidyverse)
library(yardstick)
library(glue)
library(fs)
library(ggstance)
library(patchwork)

# annotated <- read_csv("~/Downloads/permissed_sampled_annotated_with_pipeline_predictions.csv") %>%
#   mutate(
#     aann = case_when(is.na(aann) ~ 0, TRUE~aann),
#     aann = case_when(span == "a season eight years" ~ 0, TRUE ~ aann),
#     aann = case_when(str_detect(span, "an estimated 182 persons") ~ 1, TRUE ~ aann),
#     aann = case_when(str_detect(span, "a fucking few minutes") ~ 1, TRUE ~ aann),
#     aann = case_when(str_detect(span, "a season-high 19 points") ~ 1, TRUE ~ aann),
#     aann = case_when(str_detect(span, "a long and two shorts") ~ 1, TRUE ~ aann),
#     aann = case_when(str_detect(span, "a great many more people") ~ 1, TRUE ~ aann),
#     aann = factor(aann, levels = c(1,0)),
#     og_detected = factor(og_detected, levels = c(1,0)),
#     current_detected = factor(current_detected, levels = c(1,0)),
#     dep_parse_detected = factor(dep_parse_detected, levels = c(1,0)),
#     current_with_dt_detected = factor(current_with_dt_detected, levels = c(1,0))
#   ) 
# 
# annotated %>%
#   write_csv("~/Downloads/permissed_sampled_annotated_with_predictions.csv")

# annotated <- read_csv("~/Downloads/permissed_sampled_annotated_old1k_new_regex.csv") %>%
annotated <- read_csv("~/Downloads/permissed_sampled_annotated_test1_1k_final_regex.csv") %>%
  mutate(
    aann = factor(aann, levels = c(1,0)),
    og_detected = factor(og_detected, levels = c(1,0)),
    current_detected = factor(current_detected, levels = c(1,0)),
    dep_parse_detected = factor(dep_parse_detected, levels = c(1,0)),
    current_with_dt_detected = factor(current_with_dt_detected, levels = c(1,0)),
    final_detected = factor(final_detected, levels = c(1,0))
  )

og_recall = recall_vec(annotated$aann, annotated$og_detected)
current_recall = recall_vec(annotated$aann, annotated$current_detected)
dep_parse_recall = recall_vec(annotated$aann, annotated$dep_parse_detected)
current_dt_recall = recall_vec(annotated$aann, annotated$current_with_dt_detected)
final_recall = recall_vec(annotated$aann, annotated$final_detected)

og_precision = precision_vec(annotated$aann, annotated$og_detected)
current_precision = precision_vec(annotated$aann, annotated$current_detected)
dep_parse_precision = precision_vec(annotated$aann, annotated$dep_parse_detected)
current_dt_precision = precision_vec(annotated$aann, annotated$current_with_dt_detected)
final_precision = precision_vec(annotated$aann, annotated$final_detected)

precision_vec(annotated$aann, annotated$og_detected)

annotated %>%
  filter(aann == 1 & dep_parse_detected != 1) %>%
  count(span)

annotated %>%
  filter(aann == 1 & og_detected != 1) %>%
  count(span)

annotated %>%
  filter(aann == 1 & current_detected != 1) %>%
  count(span)

## new results!

dir = "mahowald-aann"

model_meta <- read_csv("data/results/babylm_lms.csv")

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
  "counterfactual-babylm-old_union_new_regex_aanns_removal", "1e-3",
  "counterfactual-babylm-new_regex_aanns_removal", "1e-3",
  "counterfactual_babylm_naans_new", "1e-3",
  "counterfactual_babylm_anans_new", "1e-3",
  "counterfactual_babylm_300_naans_new", "1e-3",
  "counterfactual_babylm_300_anans_new", "1e-3",
)

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

unigram_scores %>%
  count(model)


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
  count(model) %>%
  View()


slor_results %>%
  # filter(model %in% c("smolm-aann", "smolm-indef-anan", "smolm-indef-naan-rerun", "smolm-indef-removal")) %>%
  filter(model %in% c("smolm-aann", "smolm-new_regex_aanns_removal", "smolm-autoreg-bpe-counterfactual_babylm_anans_new", "smolm-autoreg-bpe-counterfactual_babylm_naans_new")) %>%
  mutate(
    train_condition = case_when(
      model == "smolm-aann" ~ "AANN",
      # model == "smolm-indef-anan" ~ "ANAN",
      model == "smolm-autoreg-bpe-counterfactual_babylm_anans_new" ~ "ANAN",
      # model == "smolm-indef-naan-rerun" ~ "NAAN",
      model == "smolm-autoreg-bpe-counterfactual_babylm_naans_new" ~ "NAAN",
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
      # model == "smolm-indef-anan" ~ "anan",
      # model == "smolm-indef-naan-rerun" ~ "naan",
      model == "smolm-autoreg-bpe-counterfactual_babylm_anans_new" ~ "anan",
      model == "smolm-autoreg-bpe-counterfactual_babylm_naans_new" ~ "naan",
      TRUE ~ "aann"
    ),
    eval_condition = factor(
      eval_condition,
      levels = c("aann", "anan", "naan"), 
      labels = c("Test = AANN", " Test = ANAN", "Test = NAAN")
    ),
    target_construction = str_to_upper(target_construction),
  ) %>%
  ggplot(aes(train_condition, accuracy, color = train_condition, fill = train_condition, shape = train_condition)) +
  geom_hline(yintercept=0, linetype = "dotdash", color = "gray") +
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
  geom_curve(
    xend = 3.1, yend = 0.14, 
    x = 2.7, y = 0.001, 
    curvature = -0.3, 
    arrow = arrow(length = unit(2, "mm")), 
    data = tibble(train_condition="AANN", target_construction="AANN"),
    color = "grey"
  ) +
  geom_text(
    data = tibble(
      train_condition = "AANN",
      accuracy = 0.14,
      target_construction="AANN"
    ),
    x = 3.8,
    label = "2 & 4-gram",
    color = "darkgrey",
    family = "Times",
    size = 4
  ) +
  geom_curve(
    xend = 1.6, yend = 0.14, 
    x = 2, y = 0.063, 
    curvature = 0.3, 
    arrow = arrow(length = unit(2, "mm")), 
    data = tibble(train_condition="AANN", target_construction="AANN"),
    color = "black"
  ) +
  geom_text(
    data = tibble(
      train_condition = "AANN",
      accuracy = 0.14,
      target_construction="AANN"
    ),
    x = 1.1,
    label = "Chance",
    color = "black",
    family = "Times",
    size = 4
  ) +
  # annotation_label = annotate(
  #   geom = "label",
  #   x = 7.53, y = 0.35,
  #   label = str_wrap("Chance Performance", width = 25),
  #   hjust = "left",
  #   family = "Times",
  #   fontface = "italic",
  #   lineheight = 1,
  #   size = 5
  # )
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

ggsave("paper/counterfactualaccuracies-new.pdf", height = 3.06, width = 9.17, dpi = 300, device=cairo_pdf)
