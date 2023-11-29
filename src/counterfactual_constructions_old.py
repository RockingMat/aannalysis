"""
Script that takes in input corpus, replaces the aann construction with its counterfactual counterparts and outputs the resulting corpus.
"""

import argparse
import csv
import glob
import re
import random
import utils

import numpy as np
import pandas as pd

from tqdm import tqdm
from collections import defaultdict, Counter
from transformers import AutoTokenizer, pipeline
from torch.utils.data import DataLoader
from minicons import scorer

from constructions import AANN
import editors
import extractors

"""
Arguments:

corpus
corruption type (anan, naan)
"""


def main(args):
    corpus_dir = args.corpus_dir
    postag_dir = args.postag_dir
    aanns = utils.read_csv_dict(f"{corpus_dir}/aanns/aann_data.csv")

    corpus = {}

    print(list(glob.glob(f"{postag_dir}/*.train")))

    for file in glob.glob(f"{postag_dir}/*.train"):
        corpus_name = re.split(r"(/|.train)", file)[-3]
        sents = utils.read_babylm(f"{corpus_dir}/{corpus_name}.train")
        corpus[corpus_name] = sents

    aann_ids = defaultdict(list)
    for a in aanns:
        aann_ids[a["source"]].append(int(a["sentence_idx"]))

    aann_ids = dict(aann_ids)

    replacement_funcs = {"anan": editors.anan, "naan": editors.naan}

    aann_replacements = defaultdict(dict)

    for a in aanns:
        aann = utils.parse_instance(a)
        counterfactual = replacement_funcs[args.counterfactual_type](
            aann
        ).string
        aann_replacements[a["source"]][int(a["sentence_idx"])] = counterfactual

    aann_replacements = dict(aann_replacements)

    # print(corpus)

    replaced_corpus = []

    strategy = "replace"
    # strategy = "remove"
    tokens_lost = 0
    num_replaced = 0

    for k, v in tqdm(corpus.items()):
        for i, utterance in enumerate(v):
            if strategy == "replace":
                if i in aann_replacements[k].keys():
                    replacement = aann_replacements[k][i]

                    # utterance_tokens = count_tokens(utterance)[0]
                    # replacement_tokens = count_tokens(replacement)[0]
                    # loss = utterance_tokens - replacement_tokens
                    # tokens_lost += loss

                    num_replaced += 1

                    replaced_corpus.append(replacement)
                else:
                    replaced_corpus.append(utterance)
            if strategy == "remove":
                if i in aann_ids[k]:
                    continue
                    # loss = count_tokens(utterance)[0]
                    # tokens_lost += loss
                else:
                    replaced_corpus.append(utterance)

    print(f"LEN: {len(replaced_corpus)}. REPLACEMENTS: {num_replaced}")

    # print(list(aann_replacements.items())[:10])
    full_corpus = replaced_corpus
    with open(
        f"{corpus_dir}/{args.outfilename}_{args.counterfactual_type}.txt", "w"
    ) as f:
        for line in full_corpus:
            f.write(f"{line}\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--corpus_dir",
        type=str,
        default="/home/km55359/rawdata/babylm_data/babylm_100M/",
        help="Directory of corpus to be corrupted",
    )
    parser.add_argument(
        "--postag_dir",
        type=str,
        default="/home/km55359/rawdata/babylm_data/postags_100M/",
        help="Directory of corpus to be corrupted",
    )
    parser.add_argument(
        "--counterfactual_type",
        type=str,
        default="anan",
        help="Type of counterfactual to be generated",
    )
    parser.add_argument(
        "--outfilename",
        type=str,
        default="babylm_100M_aann_counterfactual",
        help="Name of output file",
    )
    args = parser.parse_args()

    main(args)
