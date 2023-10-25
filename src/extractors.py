from constructions import AANN

def non_article_region(aann):
    return AANN("", aann.adjective, aann.numeral, aann.noun)


def numeral_noun_region(aann):
    return AANN("", "", aann.numeral, aann.noun)


def just_noun_region(aann):
    return AANN("", "", "", aann.noun)
