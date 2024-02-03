library(tidyverse)
library(ggstance)

levels = rev(c("pipp_filler_gap", "no_filler_gap", "filler_no_gap", "pp_no_filler_no_gap"))
labels = rev(c("PiPP (Filler/Gap)", "No Filler/Gap", "Filler/No Gap", "PP (No Filler/No Gap)"))

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

diffs <- pipps_long %>%
  inner_join(potts_raw %>% rename(potts_surprisal = target_surprisal)) %>%
  mutate(diff = potts_surprisal - target_surprisal)

pipps_results %>%
  filter(model %in% c("smolm-autoreg-bpe-babylm-1e-3", "smolm-autoreg-bpe-counterfactual-babylm-pipps_removal-1e-3", "smolm-autoreg-bpe-counterfactual-babylm-pipps_and_keys_to_it_all_removal-1e-3", "smolm-autoreg-bpe-counterfactual-babylm-pipps_and_keys_to_it_all_10k-3e-4")) %>%
  # filter(model %in% c("smolm-autoreg-bpe-babylm-1e-3", "smolm-autoreg-bpe-counterfactual-babylm-pipps_removal-1e-3", "smolm-autoreg-bpe-counterfactual-babylm-pipps_and_keys_to_it_all_removal-1e-3", "smolm-autoreg-bpe-counterfactual-babylm-keys_to_pipps_all-1e-4", "smolm-autoreg-bpe-counterfactual-babylm-keys_to_pipps_2913-3e-4", "smolm-autoreg-bpe-counterfactual-babylm-keys_to_pipps_2913-1e-3", "smolm-autoreg-bpe-counterfactual-babylm-keys_to_pipps_all-1e-3", "smolm-autoreg-bpe-counterfactual-babylm-pipps_and_keys_to_it_all_10k-3e-4", "smolm-autoreg-bpe-counterfactual-babylm-pipps_and_keys_to_it_all_10k-1e-4", "smolm-autoreg-bpe-counterfactual-babylm-pipps_and_keys_to_it_all_10k-1e-3", "smolm-autoreg-bpe-counterfactual-babylm-pipps_10k-3e-4", "smolm-autoreg-bpe-counterfactual-babylm-pipps_10k-1e-4", "smolm-autoreg-bpe-counterfactual-babylm-pipps_10k-1e-3")) %>%
  pivot_longer(pipp_filler_gap:no_filler_gap, names_to = "condition", values_to="surprisal") %>%
  group_by(model, preposition, embedding, condition) %>%
  summarize(
    cl = 1.96 * plotrix::std.error(surprisal),
    mean_surprisal = mean(surprisal)
  ) %>% View()

pipps_results %>%
  group_by(model, preposition, embedding) %>%
  summarize(
    pipp_test = mean(pipp_filler_gap < no_filler_gap),
    other_test = mean(pp_no_filler_no_gap < filler_no_gap),
    overall = mean(pipp_filler_gap < no_filler_gap & pp_no_filler_no_gap < filler_no_gap)
  ) %>% View()
  filter(model %in% c("smolm-autoreg-bpe-babylm-1e-3", "smolm-autoreg-bpe-counterfactual-babylm-keys_to_pipps_all-1e-4", "smolm-autoreg-bpe-counterfactual-babylm-keys_to_pipps_2913-3e-4")) %>%
  select(model, preposition, embedding, overall) %>%
  mutate(
    model = case_when(
      str_detect(model, "pipps_2913") ~ "w/Double Keys",
      str_detect(model, "pipps_all") ~ "w/All Keys",
      TRUE ~ "Base BabyLM"
    ),
    model = factor(model, levels = rev(c("Base BabyLM", "w/Double Keys", "w/All Keys"))),
    embedding = case_when(
      is.na(embedding) ~ "Single-clause",
      TRUE ~ "Multi-clause"
    ),
    embedding = factor(embedding, levels = c("Single-clause", "Multi-clause")),
    preposition = factor(preposition, levels = c("though", "as", "asas"))
  ) %>%
  ggplot(aes(overall, model)) +
  geom_point(size = 2.5) +
  facet_grid(preposition ~ embedding) +
  theme_bw(base_size = 15, base_family = "Times") +
  theme(
    legend.position = "None",
    axis.title.y = element_blank()
  )
  

# potts_raw %>%

plot_pipps <- function(data, lm, title) {
  data %>%
    group_by(model, preposition, embedding, condition) %>%
    summarize(
      cl = 1.96 * plotrix::std.error(surprisal),
      mean_surprisal = mean(surprisal)
    ) %>%
    ungroup() %>%
    mutate(
      condition = factor(condition, levels = levels, labels = labels),
      embedding = case_when(
        is.na(embedding) ~ "Single-clause",
        TRUE ~ "Multi-clause"
      ),
      embedding = factor(embedding, levels = c("Single-clause", "Multi-clause")),
      preposition = factor(preposition, levels = c("though", "as", "asas"))
    ) %>%
    filter(model == lm) %>%
    # filter(model == "smolm-autoreg-bpe-babylm-1e-3") %>%
    # filter(is.na(embedding), model == "gpt2-large") %>%
    ggplot(aes(mean_surprisal, condition, color = embedding, fill = embedding)) +
    geom_col() +
    geom_errorbarh(aes(xmin = mean_surprisal-cl, xmax=mean_surprisal+cl), height = 0.3, color="black") + 
    scale_x_continuous(limits = c(0, 20)) +
    facet_grid(preposition~embedding) +
    theme_bw(base_size = 15, base_family = "Times") +
    theme(
      legend.position = "None",
      axis.title.y = element_blank()
    ) +
    labs(
      x = "Surprisal (bits)",
      title=title
    )
}

pipps_results %>%
  pivot_longer(pipp_filler_gap:no_filler_gap, names_to = "condition", values_to="surprisal") %>%
  plot_pipps("gpt2-large", "Kanishka's Results")

ggsave("analysis/misra-pipps.pdf", height = 7, width = 6, device=cairo_pdf)

potts_raw %>% 
  rename(surprisal = target_surprisal) %>%
  plot_pipps("gpt2-large", "Chris' Results")

ggsave("analysis/potts-pipps.pdf", height = 7, width = 6, device=cairo_pdf)

pipps_results %>%
  pivot_longer(pipp_filler_gap:no_filler_gap, names_to = "condition", values_to="surprisal") %>%
  plot_pipps("smolm-autoreg-bpe-counterfactual-babylm-keys_to_pipps_all-1e-4", "All keys to it all")

diffs %>%
  mutate(
    condition = factor(condition, levels = levels, labels = labels),
    embedding = case_when(
      is.na(embedding) ~ "Single-clause",
      TRUE ~ "Multi-clause"
    ),
    embedding = factor(embedding, levels = c("Single-clause", "Multi-clause")),
    preposition = factor(preposition, levels = c("though", "as", "asas"))
  ) %>%
  group_by(preposition, embedding, condition) %>%
  summarize(
    ste = 1.96 * plotrix::std.error(diff),
    diff = mean(diff)
  ) %>%
  ggplot(aes(diff, condition)) + 
  geom_point() +
  geom_linerangeh(aes(xmin = diff - ste, xmax = diff+ste)) +
  facet_grid(preposition ~ embedding) +
  theme_bw(base_size = 15, base_family = "Times") +
  theme(
    legend.position = "None",
    axis.title.y = element_blank()
  ) +
  labs(
    x = "Delta Surprisal",
  )

ggsave("analysis/potts-misra-diff.pdf", height = 7, width = 6, device=cairo_pdf)
