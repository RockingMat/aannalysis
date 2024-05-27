"""
TODO: Implement corruption functions.
"""
import inflect
from constructions import AANN

inflector = inflect.engine()


def default_nan(aann):
    return AANN("", aann.numeral, aann.adjective, aann.noun)


def corrupt_order(aann):
    if aann.article.lower() in ["a", "an"]:
        article = inflector.a(aann.numeral.split(" ")[0]).split(" ")[0]
    else:
        article = aann.article
    return AANN(article, aann.numeral, aann.adjective, aann.noun)


def corrupt_article(aann):
    return AANN("", aann.adjective, aann.numeral, aann.noun)


def corrupt_modifier(aann):
    if aann.article.lower() in ["a", "an"]:
        article = inflector.a(aann.numeral.split(" ")[0]).split(" ")[0]
    else:
        article = aann.article
    return AANN(article, "", aann.numeral, aann.noun)


def corrupt_numeral(aann):
    return AANN(aann.article, aann.adjective, "", aann.noun)


def corrupt_noun_num(aann):
    noun = inflector.singular_noun(aann.noun.split(" ")[-1])
    return AANN(aann.article, aann.adjective, aann.numeral, noun)


def nnaa(aann):
    """reverses the AANN order"""
    if aann.article != "":
        article = "a"
    else:
        article = aann.article
    return AANN(aann.noun, aann.numeral, aann.adjective, article)


def naan(aann):
    """reverses the AANN order"""
    if aann.article.lower() in ["a", "an"]:
        try:
            article = inflector.a(aann.noun.split(" ")[0]).split(" ")[0]
        except:
            article = aann.article
    else:
        article = aann.article
    return AANN(aann.numeral, aann.adjective, article, aann.noun)


def anan(aann):
    """converts AANN --> ANAN"""
    if aann.article.lower() in ["a", "an"]:
        try:
            article = inflector.a(
                f"{aann.numeral} {aann.adjective}".strip().split(" ")[0]
            ).split(" ")[0]
        except:
            article = aann.article
    else:
        article = aann.article
    return AANN(article, aann.numeral, aann.adjective, aann.noun)
