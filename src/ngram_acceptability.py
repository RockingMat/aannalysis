import argparse
import config
import editors
import extractors
import inflect
import kenlm
import os
import pathlib
import re
import utils

import numpy as np
import pandas as pd

from collections import defaultdict
from dataclasses import dataclass
from minicons import scorer
from minicons import utils as mu
from torch.utils.data import DataLoader
from tqdm import tqdm
from functools import reduce

from constructions import AANN


def compose(*functions):
    """compose functions"""
    return reduce(lambda f, g: lambda x: f(g(x)), functions, lambda x: x)

inflector = inflect.engine()


def main(args):
    os.environ["TOKENIZERS_PARALLELISM"] = "false"
    model_name = args.model

    model_name = (
        model_name.replace("models/kenlm/build/babylm_", "")
        .replace("_trie.binary", "")
    )

    aann_dir = args.aann_dir.split("data")[-1].strip("/")
    pathlib.Path(args.results_dir).mkdir(parents=True, exist_ok=True)
    pathlib.Path(f"{args.results_dir}/{aann_dir}").mkdir(
        parents=True, exist_ok=True
    )

    # load model
    lm = kenlm.Model(args.model)

    constructions = utils.read_csv_dict(f"{args.aann_dir}/corruption.csv")

    results = defaultdict(list)
    results['idx'] = [c['idx'] for c in constructions]

    columns = ['construction', 'default_nan', 'order_swap', 'no_article', 'no_modifier', 'no_numeral']

    for construction in tqdm(constructions):
        for col in columns:
            # print(f"{col}: {construction['prefix'] +  ' ' + construction[col]}")
            scores = [p[0] for p in lm.full_scores(construction['prefix'] + " " + construction[col])]
            score = np.mean(scores)

            results[f"{col}_score"].append(score)

    results = dict(results)
    results = pd.DataFrame(results)
    results.to_csv(f"{args.results_dir}/{aann_dir}/{model_name}.csv", index=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--aann_dir",
        "-a",
        type=str,
        default="data/mahowald-aann/",
        help="path to aanns or their counterfactuals",
    )
    parser.add_argument(
        "--model",
        "-m",
        type=str,
        default="../smolm/models/gpt2",
        help="path to model",
    )
    parser.add_argument(
        "--results_dir",
        type=str,
        default="results",
        help="path to results directory",
    )
    args = parser.parse_args()

    main(args)
