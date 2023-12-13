"""
Args:
sentence_path: path to file containing sentences
output_path: path to file where output will be written
model_name: name of tokenizer that will be used
# keep excess path constant (idk why but thats just how it is.)
actually, just upsample sentences that do not contain aanns.
counterfactual_type: type of counterfactual to generate (anan, naan, remove)
aann_path: path to file containing AANNs (and ids)
aann_all_det_path: path to file containing all AANNs (all dets) (and ids)

Algo:
1. Read in sentences from file
2. if counterfactual_type == remove:
    remove AANNs from sentences, store loss in tokens using tokenizer
    sample excess tokens from openbooks # same amount as loss in tokens.
3. else:
    read in AANNs from file
    for each AANN:
        generate counterfactual -> add to sentence
        replace sentence with counterfactual-transformed sentence.
"""

import argparse
import csv
import glob
import re
import random
import utils

import numpy as np
import pandas as pd

from collections import defaultdict, Counter
from minicons import scorer
from spacy.lang.en import English
from torch.utils.data import DataLoader
from tqdm import tqdm
from transformers import AutoTokenizer, pipeline

from constructions import AANN
import editors
import extractors


def count_tokens(strings, tok):
    strings = [strings] if isinstance(strings, str) else strings
    tokenized = tok(strings)["input_ids"]
    return [len(t) - 1 for t in tokenized]


def main(args):
    nlp = English()
    spacy_tokenizer = nlp.tokenizer

    problem_idx = [87096, 2223754, 4806273]

    def _spacy_tokenize(string):
        return [t.text for t in spacy_tokenizer(string)]

    tokenizer = AutoTokenizer.from_pretrained(args.model_name)

    sentences = utils.read_file(args.sentence_path)
    aanns = utils.read_csv_dict(args.aann_path)
    aanns_alldet = utils.read_csv_dict(args.aann_all_det_path)
    if args.excess_path:
        excess = utils.read_csv_dict(args.excess_path)

    print("Storing AANN ids...")
    # aann_ids = [int(a["sentence_idx"]) for a in aanns]
    aann_ids = defaultdict(lambda : False)
    for a in aanns:
        aann_ids[int(a["sentence_idx"])] = True


    if args.excess_path:
        print("Storing excess ids...")
        # excess_ids = [int(e["sentence_idx"]) for e in excess]
        excess_ids = defaultdict(lambda : False)
        for a in excess:
            excess_ids[int(a["sentence_idx"])] = True
    else:
        excess_ids = defaultdict(lambda : False)

    print("Storing AANN all det ids...")
    # aanns_alldet_ids = [int(a["sentence_idx"]) for a in aanns_alldet]
    aanns_alldet_ids = defaultdict(lambda : False)
    for a in aanns_alldet:
        aanns_alldet_ids[int(a["sentence_idx"])] = True

    corpus = []
    if args.counterfactual_type == "removal":
        print("Storing non-AANN sentences...")
        # non_aann_sentences = [
        #     s for i, s in enumerate(tqdm(sentences)) if i not in aanns_alldet_ids
        # ]  # TODO: think more about this.

        # remove AANNs from sentences, store loss in tokens using tokenizer
        # sample excess tokens from openbooks # same amount as loss in tokens.
        LOST_TOKENS = 0
        for idx, sentence in enumerate(tqdm(sentences)):
            # if idx in aann_ids or idx in excess_ids:
            if aann_ids[idx] or excess_ids[idx]:
                lost_tokens = count_tokens(sentence, tokenizer)
                LOST_TOKENS += lost_tokens[0]
            else:
                corpus.append(sentence)

        print(f"Tokens lost: {LOST_TOKENS}.\n\nUpsampling from non-aann sents:\n")

        # offset by upsampling non aann sentences
        # heuristic = only process on first rounded to nearest 1000 sents
        # (guaranteed to have fewer the number of tokens of interest)
        excess_corpus = []
        tokens_added = 0

        upper_bound = utils.roundup(LOST_TOKENS)
        for i, utterance in enumerate(tqdm(sentences[:upper_bound])):
            # if i not in aanns_alldet_ids:
            if not aanns_alldet_ids[i] and not excess_ids[i]:
                if len(utterance) > 5:
                    tokens = tokenizer(utterance)["input_ids"][1:]
                    added = []
                    for t in tokens:
                        if tokens_added <= LOST_TOKENS:
                            added.append(t)
                            tokens_added += 1
                        else:
                            break
                    string = tokenizer.decode(added).strip()
                    if string != "":
                        excess_corpus.append(string)

        print("Excess corpus length:", len(excess_corpus))
        corpus.extend(excess_corpus)

    else:
        # counterfactuals...
        replacement_funcs = {"anan": editors.anan, "naan": editors.naan}
        replacements = defaultdict(str)
        print("Generating counterfactuals...")
        for entry in tqdm(aanns):
            a = entry.copy()
            if int(a['sentence_idx']) in problem_idx:
                a['sentence'] = a['sentence'].replace("\xa0", "")
                a['construction'] = a['construction'].replace("\xa0", "")
                a['pattern'] = a['pattern'].replace("CD CD", "CD")
            aann = utils.parse_instance(a)
            counterfactual = replacement_funcs[args.counterfactual_type](
                aann
            ).string
            recombined = " ".join(_spacy_tokenize(a['sentence']))
            replacement = recombined.replace(a['construction'], counterfactual)
            replacements[int(a["sentence_idx"])] = replacement

        for idx, sentence in enumerate(tqdm(sentences)):
            if idx in aann_ids:
                corpus.append(replacements[idx])
            else:
                corpus.append(sentence)

    print("Writing to file...")
    with open(args.output_path, "w") as f:
        for sentence in tqdm(corpus):
            f.write(sentence + "\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--sentence_path",
        type=str,
        help="path to file containing sentences",
        default="/home/km55359/rawdata/babylm_data/babylm_100M/sents/babylm_sents.txt"
    )
    parser.add_argument(
        "--output_path",
        type=str,
        help="path to file where output will be written",
    )
    parser.add_argument(
        "--model_name",
        type=str,
        help="name of tokenizer that will be used",
        default="kanishka/smolm-autoreg-bpe-babylm-1e-3"
    )
    parser.add_argument(
        "--counterfactual_type",
        type=str,
        help="type of counterfactual to generate (anan, naan, removal)",
    )
    parser.add_argument(
        "--aann_path",
        type=str,
        help="path to file containing AANNs (and ids)",
        default="data/babylm-aanns/aanns_indef_all.csv"
    )
    parser.add_argument(
        "--aann_all_det_path",
        type=str,
        help="path to file containing all AANNs (all dets) (and ids)",
        default="data/babylm-aanns/aanns_all_det_all.csv"
    )
    parser.add_argument(
        "--excess_path",
        type=str,
        help="path to file containing other excess sentences we do not want.",
    )

    args = parser.parse_args()
    main(args)
