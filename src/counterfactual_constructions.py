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
from datasets import load_dataset
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

    if args.counterfactual_type in ["anan", "naan", "removal"]:
        aanns = utils.read_csv_dict(args.aann_path)
        aanns_alldet = utils.read_csv_dict(args.aann_all_det_path)
        if args.excess_path:
            excess = utils.read_csv_dict(args.excess_path)

        if args.secondary_excess_path:
            secondary_excess = utils.read_csv_dict(args.secondary_excess_path)

        if args.ignore_path:
            ignore = utils.read_csv_dict(args.ignore_path)

        if args.add_back_path:
            add_back = utils.read_csv_dict(args.add_back_path)

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

        if args.secondary_excess_path:
            print("Storing excess ids...")
            # excess_ids = [int(e["sentence_idx"]) for e in excess]
            secondary_excess_ids = defaultdict(lambda : False)
            for a in secondary_excess:
                secondary_excess_ids[int(a["sentence_idx"])] = True
        else:
            secondary_excess_ids = defaultdict(lambda : False)

        if args.add_back_path:
            print("Storing add-back ids...")
            add_back_ids = [int(a["sentence_idx"]) for a in add_back]
            # set back add_back_ids in all id storage dicts to false
            for a in add_back_ids:
                aann_ids[a] = False
                excess_ids[a] = False
                secondary_excess_ids[a] = False

        if args.ignore_path:
            print("Storing ignore ids...")
            ignore_ids = defaultdict(lambda : False)
            for a in ignore:
                ignore_ids[int(a["sentence_idx"])] = True
        else:
            ignore_ids = defaultdict(lambda : False)

        # 

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
            if aann_ids[idx] or excess_ids[idx] or secondary_excess_ids[idx]:
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
            if not aanns_alldet_ids[i] and not excess_ids[i] and not secondary_excess_ids[i] and not ignore_ids[i]:
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

    elif args.counterfactual_type in ["anan", "naan"]:
        # counterfactuals...
        replacement_funcs = {"anan": editors.anan, "naan": editors.naan}
        replacements = defaultdict(str)
        print("Generating counterfactuals...")
        
        LOST_TOKENS = 0
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
            elif excess_ids[idx]:
                lost_tokens = count_tokens(sentence, tokenizer)
                LOST_TOKENS += lost_tokens[0]
            else:
                corpus.append(sentence)

        print(f"Tokens lost: {LOST_TOKENS}.\n\nUpsampling from non-aann sents:\n")

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
        # addition
        addition_path = args.addition_path
        addition_sents = utils.read_csv_dict(addition_path)
        addition_sents = [a["sentence"] for a in addition_sents]
        if args.secondary_addition_path is not None:
            secondary_addition_path = args.secondary_addition_path
            secondary_addition_sents = utils.read_csv_dict(secondary_addition_path)
            secondary_addition_sents = [a["sentence"] for a in secondary_addition_sents]
        if args.num_additions == -1:
            corpus = sentences + addition_sents
        else:
            random.seed(42)
            random.shuffle(addition_sents)
            addition_sents = addition_sents[:args.num_additions]
            if args.secondary_addition_path is not None:
                random.shuffle(secondary_addition_sents)
                secondary_addition_sents = secondary_addition_sents[:args.num_secondary_additions]
                corpus = sentences + addition_sents + secondary_addition_sents
            else:
                corpus = sentences + addition_sents


    print("Writing to file...")
    with open(args.output_path, "w") as f:
        for sentence in tqdm(corpus):
            f.write(sentence + "\n")

    print("Pushing to hub...")
    
    VAL_FILE = "../rawdata/babylm_data/babylm_dev/babylm_dev.txt"

    data_files = {}
    dataset_args = {}
    data_files["train"] = args.output_path
    data_files["validation"] = VAL_FILE
    dataset_args["keep_linebreaks"] = True
    raw_datasets = load_dataset(
        "text",
        data_files=data_files,
        # token=model_args.token,
        **dataset_args,
    )

    raw_datasets.push_to_hub(f"kanishka/{args.output_path.split('/')[-1].replace('.txt', '')}")

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
        help="type of counterfactual to generate (anan, naan, removal, addition)",
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
    parser.add_argument(
        "--secondary_excess_path",
        type=str,
        help="path to file containing otherer excess sentences we do not want.",
    )
    parser.add_argument(
        "--addition_path",
        type=str,
        help="path to file containing sentences that we want to add.",
    )
    parser.add_argument(
        "--num_additions",
        type=int,
        help="number of sentences to add",
        default=2000
    )
    parser.add_argument(
        "--secondary_addition_path",
        type=str,
        help="path to secondary file containing sentences that we want to add.",
        default=None
    )
    parser.add_argument(
        "--num_secondary_additions",
        type=int,
        help="number of secondary sentences to add",
        default=None
    )
    parser.add_argument(
        "--ignore_path",
        type=str,
        help="path to file containing sentences that we want to ignore.",
    )
    parser.add_argument(
        "--add_back_path",
        type=str,
        help="path to file containing sentences that we want to add back.",
    )

    args = parser.parse_args()
    main(args)
