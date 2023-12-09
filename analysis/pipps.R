library(tidyverse)

pipps_results <- fs::dir_ls("data/results/pipps/") %>%
  keep(str_detect(., "csv")) %>%
  map_df(read_csv, .id = "model") %>%
  mutate(
    model = str_remove(model, "data/results/pipps/"),
    model = str_remove(model, ".csv")
  )

pipps_results %>%
  pivot_longer(pipp_filler_gap:no_filler_gap, names_to = "measure", values_to="surprisal") %>%
  group_by(model, preposition, embedding, measure) %>%
  summarize(
    cl = 1.96 * plotrix::std.error(surprisal),
    mean_surprisal = mean(surprisal)
  ) %>%
  ungroup() %>%
  mutate(
    measure = factor(measure, levels = rev(c("pipp_filler_gap", "no_filler_gap", "filler_no_gap", "pp_no_filler_no_gap")))
  ) %>%
  filter(is.na(embedding)) %>%
  ggplot(aes(mean_surprisal, measure)) +
  geom_col() +
  geom_errorbarh(aes(xmin = mean_surprisal-cl, xmax=mean_surprisal+cl)) + 
  facet_wrap(model~preposition)
