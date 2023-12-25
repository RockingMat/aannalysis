import argparse
import inflect
import os
import pathlib
import utils
import kenlm

import numpy as np
import pandas as pd

from collections import defaultdict
from tqdm import tqdm
from functools import reduce
from unigramlm import UnigramLM
from transformers import AutoTokenizer

def compose(*functions):
    """compose functions"""
    return reduce(lambda f, g: lambda x: f(g(x)), functions, lambda x: x)

inflector = inflect.engine()


def main(args):
    os.environ["TOKENIZERS_PARALLELISM"] = "false"
    model_name = args.model

    model_name = model_name.split("/")[-1].split(".")[0]

    aann_dir = args.aann_dir.split("data")[-1].strip("/")

    # load model
    if args.unigram:
        lm = UnigramLM(args.model)
        lm.load_counts()
        pathlib.Path(args.results_dir).mkdir(parents=True, exist_ok=True)
        pathlib.Path(f"{args.results_dir}/unigrams").mkdir(
            parents=True, exist_ok=True
        )
    else:
        lm = kenlm.Model(args.model)
        tokenizer = AutoTokenizer.from_pretrained(f"kanishka/smolm-autoreg-bpe-{model_name}-1e-4")
        pathlib.Path(args.results_dir).mkdir(parents=True, exist_ok=True)
        pathlib.Path(f"{args.results_dir}/bigrams").mkdir(
            parents=True, exist_ok=True
        )

    constructions = utils.read_csv_dict(f"{args.aann_dir}/corruption.csv")

    results = defaultdict(list)
    results['idx'] = [c['idx'] for c in constructions]

    columns = ['construction', 'default_nan', 'order_swap', 'no_article', 'no_modifier', 'no_numeral']

    for construction in tqdm(constructions):
        for col in columns:
            # print(f"{col}: {construction['prefix'] +  ' ' + construction[col]}")
            if args.unigram:
                score = lm.sentence_log_prob(" " + construction[col])
            else:
                tokenized = tokenizer.tokenize(" " + construction[col])
                scores = [p[0] for p in lm.full_scores(" ".join(tokenized))]
                score = np.mean(scores)

            results[f"{col}_score"].append(score)

    results = dict(results)
    results = pd.DataFrame(results)
    if args.unigram:
        results.to_csv(f"{args.results_dir}/unigrams/{model_name}.csv", index=False)
    else:
        results.to_csv(f"{args.results_dir}/bigrams/{model_name}.csv", index=False)


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
        default="models/babylm.csv",
        help="path to model",
    )
    parser.add_argument(
        "--results_dir",
        type=str,
        default="results",
        help="path to results directory",
    )
    parser.add_argument(
        "--unigram",
        action="store_true",
        help="whether to use unigram model",
    )
    args = parser.parse_args()

    main(args)
