import pandas as pd

from editors import nnaa, anan, naan

# CORRUPTION_TYPES = ["default_ann", "order_swap", "no_article", "no_modifier", "noun_number"]
CORRUPTION_TYPES = [
    "default_ann",
    "order_swap",
    "no_article",
    "no_modifier",
    "no_numeral",
]

ADJ_PATTERN = r"((?=(JJR|JJS|JJ|RB|CC))(.*)(JJR|JJS|JJ))|JJR|JJS|JJ"
NUM_PATTERN = r"(?:(?:CD|CC|TO)\s+){2,}CD|CD"

CONSTRUCTION_ORDER = {
    "aann": lambda x: x,
    "nnaa": lambda x: nnaa(x),
    "anan": lambda x: anan(x),
    "naan": lambda x: naan(x),
}

ORDER_SWAP_PATTERN = {
    "aann": "DT JJ CD NNS",
    "naan": "CD JJ DT NNS",
    "anan": "DT CD JJ NNS",
}

PREPOSITIONS = ["though", "as", "asas"]
EMBEDDINGS = ["", "they said that we knew that"]

CONDITION2COLUMN = {
    "PiPP (Filler/Gap)": "pipp_filler_gap",
    "PP (No Filler/No Gap)": "pp_no_filler_no_gap",
    "Filler/No Gap": "filler_no_gap",
    "No Filler/Gap": "no_filler_gap",
}

MODELS = {
    "babylm": "babylm",
    "indef-removal": "counterfactual-babylm-indef-removal",
    "all_det_removal": "counterfactual-babylm-all_det_removal",
    "indef-anan": "counterfactual-babylm-indef-anan",
    "indef-naan": "counterfactual-babylm-indef-naan",
    "indef-naan-rerun": "counterfactual-babylm-indef-naan-rerun",
    "indef-naan-non-num": "counterfactual-babylm-indef-naan-non-num",
    "indef-naan-only-num": "babylm-aann-counterfactual-naan",
    "indef-anan-only-num": "babylm-aann-counterfactual-naan",
    "prototypical-aann-only": "counterfactual-babylm-aann-prototypical_only",
    "no-prototypical-aann": "counterfactual-babylm-aann-no_prototypical",
    "adjnum-freq-balanced": "counterfactual-babylm-adj_num_freq_balanced",
    "indef-articles-with-pl-noun": "counterfactual-babylm-indef_articles_with_pl_nouns-removal",
    "measure-nouns-as-singular": "counterfactual-babylm-measure_nouns_as_singular",
    "random_removal": "counterfactual-babylm-random_removal",
    "only_other_det_removal": "counterfactual-babylm-only_other_det_removal",
    "only_measure_nps_as_singular_removal": "counterfactual-babylm-only_measure_nps_as_singular",
    "only_indef_articles_with_pl_nouns_removal": "counterfactual-babylm-only_indef_articles_with_pl_nouns_removal",
}

MODEL_PAIRS = [(k, v) for k, v in MODELS.items()]

# pd.DataFrame(MODEL_PAIRS, columns=["model", "suffix"]).to_csv(
#     index=False, path_or_buf="data/results/babylm_lms.csv"
# )

TARGET_CONSTRUCTIONS = {
    "babylm": "aann",
    "indef-removal": "none",
    "all_det_removal": "none",
    "indef-anan": "anan",
    "indef-naan": "naan",
    "indef-naan-rerun": "naan",
    "indef-naan-non-num": "naan",
    "indef-naan-only-num": "naan",
    "indef-anan-only-num": "anan",
    "prototypical-aann-only": "prototypical-aann",
    "no-prototypical-aann": "non-prototypical-aann",
    "adjnum-freq-balanced": "adjnum-freq-balanced",
    "indef-articles-with-pl-noun": "articles-with-pl-noun",
    "measure-nouns-as-singular": "measure-nouns-as-singular",
    "random_removal": "aann",
    "only_other_det_removal": "none",
    "only_measure_nps_as_singular_removal": "measure-nouns-as-singular",
    "only_indef_articles_with_pl_nouns_removal": "articles-with-pl-noun",
}

TARGET_CONSTRUCTIONS_PAIRS = [(k, v) for k, v in TARGET_CONSTRUCTIONS.items()]

# pd.DataFrame(
#     TARGET_CONSTRUCTIONS_PAIRS, columns=["model", "target_construction"]
# ).to_csv(index=False, path_or_buf="data/results/target_constructions.csv")
