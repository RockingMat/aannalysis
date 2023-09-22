# CORRUPTION_TYPES = ["default_ann", "order_swap", "no_article", "no_modifier", "noun_number"]
CORRUPTION_TYPES = ["default_ann", "order_swap", "no_article", "no_modifier", "no_numeral"]

ADJ_PATTERN = r'((?=(JJR|JJS|JJ|RB|CC))(.*)(JJR|JJS|JJ))|JJR|JJS|JJ'
NUM_PATTERN = r'(?:(?:CD|CC|TO)\s+){2,}CD|CD'