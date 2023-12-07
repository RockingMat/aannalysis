import spacy
import utils

from collections import defaultdict
from joblib import Parallel, delayed
from multiprocessing import Manager
from tqdm import tqdm

from spacy.tokens import Doc

corpus = utils.read_file("/home/km55359/rawdata/babylm_data/babylm_100M/sents/babylm_sents.txt")

model = spacy.load("en_core_web_sm")

def get_children_flatten(token, depth=0, dep=False):
    children = []
    for child in token.children:
        if dep:
            children.append((child.text.lower(), child.dep_, depth, child.i))
        else:
            children.append(child.text.lower())
        children.extend(get_children_flatten(child, depth+1, dep))
    return children

# mini_corpus = corpus[:100000]
idx = 0
docs = model.pipe(corpus, batch_size=2048)
indef_articles_with_pl_nouns = []
for doc in tqdm(docs):
    for token in doc:
        if token.tag_ == "NNS" or token.tag_ == "NNPS":
            children = get_children_flatten(token, dep=True)
            if len(children) >= 1:
                for child in children:
                    # check for specific determiners and the fact that their indices are less than that of the noun:
                    if child[0] in ["a", "an", "another"] and child[3] < token.i:
                        found = True
                        indef_articles_with_pl_nouns.append(
                            (
                                idx,
                                token.text,
                                token.i,
                                child[0],
                                child[1],
                                child[2],
                                child[3],
                            )
                        )
                        break
            else:
                pass
    idx += 1

# write to csv
import csv
with open("data/babylm-analysis/indef_articles_with_pl_nouns.csv", "w") as f:
    writer = csv.writer(f)
    writer.writerow(["sentence_idx", "noun", "noun_idx", "article", "article_dep", "dep_depth", "article_idx"])
    for row in indef_articles_with_pl_nouns:
        writer.writerow(row)