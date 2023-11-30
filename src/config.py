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
