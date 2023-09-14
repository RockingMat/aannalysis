library(tidyverse)

results <- fs::dir_ls("data/results/") %>%
  map_df(read_csv, .id = "model") %>%
  mutate(
    model = str_remove(model, ".csv"),
    model = str_remove(model, "data/results/"),
    model = str_remove(model, "(_home_shared_|facebook_)"),
  ) %>%
  separate(model, into = c("model", "sequence_type"), sep = "_") %>%
  pivot_longer(order_swap:noun_number, values_to = "log_prob", names_to = "corruption")

results %>%
  group_by(model, sequence_type, corruption) %>%
  summarize(
    accuracy = mean(good > log_prob)
  ) %>%
  ggplot(aes(model, accuracy, color = corruption, fill = corruption)) +
  geom_col(position="dodge", width = 0.8) +
  facet_wrap(~sequence_type) +
  scale_color_brewer(palette = "Dark2", aesthetics = c("color", "fill")) +
  theme_bw(base_size = 16, base_family = "Times") +
  theme(
    legend.position = "top",
    panel.grid = element_blank()
  ) +
  labs(
    x = "Model", 
    y = "Accuracy",
    color = "Corruption",
    fill = "Corruption"
  )
