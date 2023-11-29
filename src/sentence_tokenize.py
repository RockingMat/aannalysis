import argparse
import glob
import pathlib
import re
import utils

from joblib import Parallel, delayed
from multiprocessing import Manager
from nltk.tokenize import sent_tokenize
from tqdm import tqdm

DIR = "/home/km55359/rawdata/babylm_data/babylm_100M/"
corpus = {}

# print(list(glob.glob(DIR)))

for file in glob.glob(f"{DIR}/*.train"):
    corpus_name = re.split(r"(/|.train)", file)[-3]
    sents = utils.read_file(f"{DIR}/{corpus_name}.train")
    corpus[corpus_name] = sents

manager = Manager()
sentences = manager.list()


def sentence_tokenize(lst):
    for item in lst:
        sentences.extend(sent_tokenize(item))
    return


def sentence_tokenize_parallel(lst):
    pbar = tqdm(lst)
    _ = Parallel(n_jobs=10)(delayed(sentence_tokenize)(f) for f in pbar)
    return


sentence_tokenize_parallel(corpus.values())

pathlib.Path(f"{DIR}/sents/").mkdir(parents=True, exist_ok=True)

with open(f"{DIR}/sents/babylm_sents.txt", "w") as f:
    for sent in sentences:
        f.write(sent)
        f.write("\n")
