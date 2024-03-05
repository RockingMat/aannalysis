import argparse
import config
import inflect
import os
import pathlib
import re
import torch
import utils
import editors
import extractors

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


def compute_scores(lm, data, batch_size, num_workers, modifier=None):
    scores = []

    full, prefixes, continuations = utils.segment(data, lambda x: x, modifier)
    dl = DataLoader(full, batch_size=batch_size, num_workers=num_workers)

    for batch in tqdm(dl):
        scores.extend(lm.compute_stats(lm.prepare_text(batch), return_tensors=True))

    return scores


def segment_and_score(lm, scores, **kwargs):
    full, prefixes, continuations = utils.segment(**kwargs)
    encoded, offset = lm.prime_text(prefixes, continuations)
    offset = [0 if o < 0 else o for o in offset]
    mean_scores = [torch.mean(score[n:]).item() for score, n in zip(scores, offset)]
    return mean_scores


def main(args):
    os.environ["TOKENIZERS_PARALLELISM"] = "false"
    model_name = args.model
    batch_size = args.batch_size
    device = args.device
    n_workers = args.n_workers

    model_name = (
        model_name.replace("../smolm/models/", "")
        .replace("kanishka/", "")
        .replace("/", "_")
        .replace("meta-llama/", "")
    )

    aann_dir = args.aann_dir.split("data")[-1].strip("/")
    pathlib.Path(args.results_dir).mkdir(parents=True, exist_ok=True)
    pathlib.Path(f"{args.results_dir}/{aann_dir}").mkdir(parents=True, exist_ok=True)

    # load model
    lm = scorer.IncrementalLMScorer(args.model, device=device)

    constructions = utils.read_csv_dict(f"{args.aann_dir}/corruption.csv")

    results = defaultdict(list)
    results["idx"] = [c["idx"] for c in constructions]

    columns = [
        "construction",
        "default_nan",
        "order_swap",
        "no_article",
        "no_modifier",
        "no_numeral",
    ]

    constructions_dl = DataLoader(
        constructions, batch_size=batch_size, num_workers=n_workers
    )
    for batch in tqdm(constructions_dl):

        for col in columns:
            results[f"{col}_score"].extend(
                lm.conditional_score(batch["prefix"], batch[col])
            )

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
    parser.add_argument(
        "--batch_size",
        "-b",
        type=int,
        default=8,
        help="batch size for scoring",
    )
    parser.add_argument(
        "--device",
        type=str,
        default="cuda:0",
        help="device for scoring",
    )
    parser.add_argument(
        "--n_workers",
        type=int,
        default=0,
        help="number of workers for scoring",
    )
    args = parser.parse_args()

    main(args)
