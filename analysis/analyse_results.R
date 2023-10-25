library(tidyverse)
library(broom)

dir = "mahowald"

mahowald_meta <- read_csv("data/mahowald/aanns_meta.csv")
all_corruptions <- read_csv(glue::glue("data/{dir}/aanns_corruption.csv"))

aanns <- read_csv(glue::glue("data/{dir}/aanns_good.csv"))

human_data <- read_csv("data/mturk_ratings_20231004.csv") %>%
  inner_join(aanns) %>%
  inner_join(mahowald_meta) %>%
  select(idx, adjclass, numclass, nounclass, sentence, rating=answer)

results <- fs::dir_ls(glue::glue("data/results/{dir}/")) %>%
  discard(str_detect(., "construction|sentences")) %>%
  map_df(read_csv, .id = "model") %>%
  mutate(
    model = str_remove(model, ".csv"),
    model = str_remove(model, "data/results/"),
    model = str_remove(model, "(_home_shared_|facebook_)"),
    model = str_remove(model, "mahowald/"),
  )
  # %>%
  # separate(model, into = c("model", "sequence_type"), sep = "_") %>%
  # pivot_longer(order_swap:noun_number, values_to = "log_prob", names_to = "corruption")

# results %>%
#   group_by(model, sequence_type, corruption) %>%
#   summarize(
#     accuracy = mean(good > log_prob)
#   ) %>%
#   ggplot(aes(model, accuracy, color = corruption, fill = corruption)) +
#   geom_col(position="dodge", width = 0.8) +
#   facet_wrap(~sequence_type) +
#   scale_color_brewer(palette = "Dark2", aesthetics = c("color", "fill")) +
#   theme_bw(base_size = 16, base_family = "Times") +
#   theme(
#     legend.position = "top",
#     panel.grid = element_blank()
#   ) +
#   labs(
#     x = "Model", 
#     y = "Accuracy",
#     color = "Corruption",
#     fill = "Corruption"
#   )

minmax_scale <- function(x, range=c(0,1)) {
  return ((x - min(x))/(max(x) - min(x)) * (range[2] - range[1])) + range[1]
}

results %>%
  inner_join(aanns) %>%
  inner_join(mahowald_meta) %>%
  inner_join(human_data) %>%
  mutate(
    adjclass=str_remove(adjclass, "adj-"),
    nounclass=str_remove(nounclass, "noun-"),
    adjclass=case_when(
      adjclass %in% c("neg", "pos") ~ "qual",
      TRUE ~ adjclass
    )
  ) %>%
  group_by(model, adjclass, nounclass) %>%
  mutate(
    construction_score = minmax_scale(construction_score),
    rating = minmax_scale(rating),
    construction_score = case_when(
      construction_score == 0.0 ~ construction_score + 0.05,
      TRUE ~ construction_score
    ),
    rating = case_when(
      rating == 0.0 ~ rating + 0.05,
      TRUE ~ rating
    )
  ) %>%
  # nest() %>%
  # mutate(
  #   cor = map(data, function(x) {
  #     tidy(cor.test(x$construction_score - x$default_ann_corruption_score, x$rating, method="pearson"))
  #   })
  # ) %>% select(-data) %>%
  # unnest(cor) %>% View()
  summarize(
    rating = mean(rating),
    score = mean(construction_score)
  ) %>%
  ungroup() %>%
  pivot_longer(rating:score, names_to = "rating_type", values_to = "rating") %>%
  mutate(rating_type=case_when(rating_type=="rating" ~ "human",TRUE~"model")) %>%
  ggplot(aes(adjclass, rating, color=rating_type, fill=rating_type, shape = rating_type)) +
  # geom_col(position="dodge") + 
  geom_point(size = 2) +
  facet_grid(model~nounclass) +
  theme(legend.position = "top")


results %>%
  # filter(str_detect(model, "smolm-autoreg-bpe-babylm")) %>%
  mutate(
    model = str_remove(model, "mahowald/"),
    contains_aann = !str_detect(model, "no_aann")
  ) %>%
  inner_join(human_data) %>%
  group_by(model, adjclass) %>%
  nest() %>%
  mutate(
    cor = map(data, function(x) {
      tidy(cor.test(x$construction_score - x$default_ann_corruption_score, x$rating, method="pearson"))
    })
  ) %>%
  select(-data) %>%
  unnest(cor) %>% View()

pencils = results %>%
  inner_join(aanns) %>%
  inner_join(mahowald_meta) %>%
  inner_join(human_data) %>%
  filter(model == "text-davinci-003", NOUN == "pencils") %>%
  select(construction_score, construction, ADJ, rating)

cor.test(pencils$construction_score, pencils$rating)

accuracies <- results %>%
  inner_join(aanns) %>%
  inner_join(mahowald_meta) %>%
  inner_join(human_data) %>%
  filter(rating >= 7) %>%
  mutate(
    N = n(),
    default_preference = default_ann_region_score - non_article_region_score,
    default_nan_order_matters = default_ann_region_score - no_article_region_score,
    default_nan_article = default_ann_region_score - order_swap_region_score,
    core_aann_order_matters = non_article_region_score - order_swap_region_score,
    core_aann_article = construction_score - no_article_corruption_score,
    # default_preference = mean(default_ann_region_score > no_article_region_score),
    # default_ann = mean(default_ann_region_score > order_swap_region_score),
    # order_swap = mean(non_article_region_score > order_swap_region_score),
    # order_article = mean(non_article_region_score > no_article_region_score), # article
    # test1_nodefault = mean(non_article_region_score > order_swap_region_score &
    #                          non_article_region_score > no_article_region_score),
    # test1 = mean(
    #   non_article_region_score > order_swap_region_score &
    #   default_ann_region_score > order_swap_region_score &
    #   non_article_region_score > no_article_region_score
    # ),
    # test2 = mean(
    #   just_noun_score > no_numeral_region_score # presence of numeral
    # ),
    # test3 = mean(
    #   numeral_noun_score > no_modifier_region_score # presence of adjective
    # )
  ) %>%
  ungroup() %>%
  group_by(model) %>%
  summarize(
    default_preference_acc = mean(default_preference > 0),
    default_preference = mean(default_preference),
    default_nan_order_matters_acc = mean(default_nan_order_matters > 0),
    default_nan_order_matters = mean(default_nan_order_matters),
    default_nan_article_acc = mean(default_nan_article > 0),
    default_nan_article = mean(default_nan_article),
    core_aann_order_matters_acc = mean(core_aann_order_matters > 0),
    core_aann_order_matters = mean(core_aann_order_matters),
    core_aann_article_acc = mean(core_aann_article > 0),
    core_aann_article = mean(core_aann_article)
  )

accuracies %>% 
  filter(str_detect(model, "smolm-autoreg-bpe-babylm")) %>%
  mutate(
    contains_aann = !str_detect(model, "no_aann")
  ) %>%
  View()

results %>%
  filter(str_detect(model, "smolm-autoreg-bpe-babylm-no_aann")) %>%
  mutate(diff = (non_article_region_score - no_article_region_score)) %>%
  filter(diff < 0) %>%
  inner_join(aanns) %>%
  select(construction, diff) %>% View()
  

accuracies %>%
  group_by(model, adjclass) %>%
  summarize(
    std = 1.96 * plotrix::std.error(default_preference),
    default_preference = mean(default_preference)
  ) %>%
  mutate(
    model = str_remove(model, "mahowald/"),
    adjclass=str_remove(adjclass, "adj-")
  ) %>% 
  filter(!str_detect(model, "smolm")) %>%
  ggplot(aes(adjclass, default_preference, color=adjclass,fill=adjclass)) +
  geom_col() +
  geom_errorbar(aes(ymin = default_preference-std, ymax=default_preference+std), color = "black", width=0.3) +
  scale_color_brewer(palette = "Dark2", aesthetics = c("color", "fill")) +
  facet_wrap(~model,nrow=1) +
  theme_bw(base_size=16, base_family = "Times") +
  theme(
    legend.position="None",
    axis.text.x = element_text(angle = 20)
  )
  
bad_default_anns <- results %>%
  filter(default_ann_region_score > order_swap_region_score) %>%
  filter(model == "gpt2-large") %>%
  pull(idx)

all_corruptions %>%
  filter(idx %in% bad_default_anns) %>%
  select(idx, prefixes, aann, default_ann) %>%
  write_csv("data/openbooks/bad_default_anns.csv")

results %>%
  filter(default_ann_region_score < order_swap_region_score) %>% 
  inner_join(aanns) %>% View()
  count(model, ADJ) %>%
  inner_join(aanns %>% count(ADJ) %>% rename(N = n)) %>%
  mutate(proportion = n/N) %>%
  View()

  
# default preference: five beautiful days vs. a beautiful five days (just non-article region)
# 


results %>%
  inner_join(aanns) %>%
  inner_join(mahowald_meta) %>%
  filter(str_detect(model, "smolm-autoreg-bpe-babylm")) %>%
  mutate(
    model = str_remove(model, "mahowald/"),
    contains_aanns = !str_detect(model, "no_aann"),
    default_preference = default_ann_region_score - no_article_region_score,
    default_ann = default_ann_region_score - order_swap_region_score,
    order_swap = non_article_region_score - order_swap_region_score,
    order_article = (non_article_region_score - no_article_region_score), # article
    # test1_nodefault = mean(non_article_region_score - order_swap_region_score & 
    #                          non_article_region_score - no_article_region_score),
    # test1 = mean(
    #   non_article_region_score > order_swap_region_score & 
    #     default_ann_region_score > order_swap_region_score & 
    #     non_article_region_score > no_article_region_score
    # ),
    test2 = (
      just_noun_score - no_numeral_region_score # presence of numeral
    ),
    test3 = (
      numeral_noun_score - no_modifier_region_score # presence of adjective
    )
  ) %>%
  group_by(model, contains_aanns) %>%
  summarize(
    default_preference = mean(default_preference),
    default_ann = mean(default_ann),
    order_swap = mean(order_swap),
    order_article = mean(order_article),
    test2 = mean(test2),
    test3 = mean(test3)
  )
