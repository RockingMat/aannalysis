library(tidyverse)

pipps_raw <- read_csv("data/pipps/materials.jsonl")

potts_raw <- read_csv("~/projects/pipps/results/potts_pipps_results.csv")

pipps_results <- fs::dir_ls("data/results/pipps/") %>%
  keep(str_detect(., "csv")) %>%
  map_df(read_csv, .id = "model") %>%
  mutate(
    model = str_remove(model, "data/results/pipps/"),
    model = str_remove(model, ".csv")
  )

pipps_long <- pipps_results %>%
  select(-idx) %>%
  pivot_longer(pipp_filler_gap:no_filler_gap, names_to = "condition", values_to = "target_surprisal")

pipps_long %>%
  inner_join(potts_raw %>% rename(potts_surprisal = target_surprisal)) %>%
  mutate(diff = target_surprisal - potts_surprisal)

pipps_results %>%
  group_by(model, preposition, embedding) %>%
  summarize(
    pipp_test = mean(pipp_filler_gap < no_filler_gap),
    other_test = mean(pp_no_filler_no_gap < filler_no_gap)
  )

pipps_results %>%
  # filter(model != "gpt2") %>%
  pivot_longer(pipp_filler_gap:no_filler_gap, names_to = "condition", values_to="surprisal") %>%
  group_by(model, preposition, embedding, condition) %>%
  summarize(
    cl = 1.96 * plotrix::std.error(surprisal),
    mean_surprisal = mean(surprisal)
  ) %>%
  ungroup() %>%
  mutate(
    condition = factor(condition, levels = rev(c("pipp_filler_gap", "no_filler_gap", "filler_no_gap", "pp_no_filler_no_gap"))),
    embedding = case_when(
      is.na(embedding) ~ "No",
      TRUE ~ "Yes"
    )
  ) %>%
  filter(model == "gpt2-large") %>%
  # filter(is.na(embedding), model == "gpt2-large") %>%
  ggplot(aes(mean_surprisal, condition, color = embedding, fill = embedding)) +
  geom_col() +
  geom_errorbarh(aes(xmin = mean_surprisal-cl, xmax=mean_surprisal+cl), height = 0.3, color="black") + 
  facet_grid(preposition~embedding)
