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

unigram_scores <- bind_rows(
  unigram_scores,
  unigram_scores %>% filter(model == "babylm") %>% mutate(model = "babylm-naan", suffix="counterfactual-babylm-indef-naan-rerun"),
  unigram_scores %>% filter(model == "babylm") %>% mutate(model = "babylm-anan", suffix="counterfactual-babylm-indef-anan"),
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

# surface form plot
# specify models you care about and the target construction and it creates a plot that shows the logprobs of surface forms as estimated by the models

