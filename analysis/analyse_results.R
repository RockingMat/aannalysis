library(tidyverse)

all_corruptions <- read_csv("data/openbooks/aann_corruption.csv")

aanns <- read_csv("data/openbooks/aanns_good.csv")

results <- fs::dir_ls("data/results/") %>%
  discard(str_detect(., "construction|sentences")) %>%
  map_df(read_csv, .id = "model") %>%
  mutate(
    model = str_remove(model, ".csv"),
    model = str_remove(model, "data/results/"),
    model = str_remove(model, "(_home_shared_|facebook_)"),
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

results %>%
  group_by(model) %>%
  summarize(
    default_ann = mean(default_ann_region_score > order_swap_region_score),
    order_swap = mean(non_article_region_score > order_swap_region_score),
    order_article = mean(non_article_region_score > no_article_region_score),
    test1_nodefault = mean(non_article_region_score > order_swap_region_score & 
                             non_article_region_score > no_article_region_score),
    test1 = mean(
      non_article_region_score > order_swap_region_score & 
      default_ann_region_score > order_swap_region_score & 
      non_article_region_score > no_article_region_score
    ),
    test2 = mean(
      just_noun_score > no_numeral_region_score
    ),
    test3 = mean(
      numeral_noun_score > no_modifier_region_score
    )
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
  inner_join(aanns) %>% 
  count(model, ADJ) %>%
  inner_join(aanns %>%
               count(ADJ) %>% rename(N = n)) %>%
  mutate(proportion = n/N) %>% View()

aanns
