"""
Query a bunch of autoregressive LMs for their knowledge of aanns.
"""

import argparse
import config
import csv
import pathlib
import os
import utils

import pandas as pd

from collections import defaultdict
from minicons import scorer
from torch.utils.data import DataLoader
from tqdm import tqdm


def sentence_log_probs(lm, dataset, sequence_column, batch_size, num_workers):
    dl = DataLoader(dataset, batch_size=batch_size, num_workers=num_workers)
    sequence_scores = []
    for i, batch in enumerate(tqdm(dl)):
        sequences = batch[sequence_column]
        try:
            scores = lm.sequence_score(sequences)
        except:
            print(i, sequences[:10])
            break
        sequence_scores.extend(scores)

    return sequence_scores


def main(args):
    os.environ["TOKENIZERS_PARALLELISM"] = "false"
    model_name = args.model
    batch_size = args.batch_size
    device = args.device
    n_workers = args.n_workers

    results_prefix = f"{args.results_dir}/{model_name.replace('/', '_')}"
    pathlib.Path(args.results_dir).mkdir(parents=True, exist_ok=True)

    # load model
    lm = scorer.IncrementalLMScorer(model_name, device=device)

    # load good.
    good = utils.read_csv_dict(f"{args.aanns_dir}/aanns_good.csv")

    full_sentence_results = defaultdict(list)
    construction_only_results = defaultdict(list)

    [full_sentence_results["idx"].append(aann["idx"]) for aann in good]
    [construction_only_results["idx"].append(aann["idx"]) for aann in good]

    # compute good log_probs
    full_sentence_results["good"] = sentence_log_probs(
        lm, good, "sentence", batch_size, n_workers
    )

    construction_only_results["good"] = sentence_log_probs(
        lm, good, "construction", batch_size, n_workers
    )

    # compute bad log_probs
    for corruption in config.CORRUPTION_TYPES:
        print(f"Corruption: {corruption}")
        bad_data = utils.read_csv_dict(
            f"{args.aanns_dir}/aanns_{corruption}.csv"
        )
        print(f"Full sentences")
        full_sentence_results[corruption] = sentence_log_probs(
            lm, bad_data, "corrupted_sentence", batch_size, n_workers
        )

        print(f"Construction only")
        construction_only_results[corruption] = sentence_log_probs(
            lm, bad_data, "corrupted_construction", batch_size, n_workers
        )

    full_sentence_results = pd.DataFrame(full_sentence_results)
    construction_only_results = pd.DataFrame(construction_only_results)

    full_sentence_results.to_csv(
        f"{results_prefix}_full-sentences.csv", index=False
    )
    construction_only_results.to_csv(
        f"{results_prefix}_construction-only.csv", index=False
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", "-m", type=str, default="gpt2")
    parser.add_argument("--batch_size", "-b", type=int, default=64)
    parser.add_argument("--device", "-d", type=str, default="cuda:0")
    parser.add_argument("--n_workers", "-n", type=int, default=8)
    parser.add_argument(
        "--aanns_dir", "-a", type=str, default="data/openbooks/"
    )
    parser.add_argument(
        "--results_dir", "-r", type=str, default="data/results/"
    )
    args = parser.parse_args()

    main(args)
