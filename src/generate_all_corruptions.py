import argparse
import config
import editors
import extractors
import utils
import pathlib

import pandas as pd

from constructions import AANN
from functools import reduce


def compose(*functions):
    """compose functions"""
    return reduce(lambda f, g: lambda x: f(g(x)), functions, lambda x: x)


def main(args):
    aann_dir = args.aann_dir
    mode = args.mode
    good = utils.read_csv_dict(f"{aann_dir}/aanns_good.csv")

    full, prefixes, continuations = utils.segment(good, lambda x: x)

    pathlib.Path(f"data/mahowald-{mode}").mkdir(parents=True, exist_ok=True)

    if mode != "aann":
        order_swap_good = []
        for aann in good:
            replacement_aann = aann.copy()
            parsed_aann = utils.parse_instance(aann)
            parsed_construction = parsed_aann.string
            corrupted_construction = config.CONSTRUCTION_ORDER[mode](
                parsed_aann
            )
            corrupted_construction_string = corrupted_construction.string
            sentence = replacement_aann["sentence"]
            replacement_aann.update(
                {
                    "sentence": sentence.replace(
                        parsed_construction, corrupted_construction_string
                    ),
                    "construction": corrupted_construction_string,
                    "DT": corrupted_construction.article,
                    "ADJ": corrupted_construction.adjective,
                    "NUMERAL": corrupted_construction.numeral,
                    "NOUN": corrupted_construction.noun,
                    # "pattern": config.ORDER_SWAP_PATTERN[mode]
                }
            )
            order_swap_good.append(replacement_aann)

        order_swap_good = pd.DataFrame(order_swap_good)
        order_swap_good.to_csv(
            f"data/mahowald-{mode}/good.csv", index=False
        )

    results = {
        "idx": [aann["idx"] for aann in good],
        "sentence": [aann["sentence"] for aann in good],
        "prefix": prefixes,
    }

    EDITORS = {
        "construction": lambda x: x,
        "default_nan": editors.default_nan,
        "order_swap": editors.corrupt_order,
        "no_article": editors.corrupt_article,
        "no_modifier": editors.corrupt_modifier,
        "no_numeral": editors.corrupt_numeral,
    }

    for edit, editor in EDITORS.items():
        if edit == "default_nan":
            if mode != "naan":
                editor = compose(
                    config.CONSTRUCTION_ORDER[mode],
                    config.CONSTRUCTION_ORDER[mode],
                    editor,
                )
            else:
                editor = editor
        else:
            editor = compose(config.CONSTRUCTION_ORDER[mode], editor)

        full, prefixes, continuations = utils.segment(
            good, lambda x: x, editor=editor
        )

        results[edit] = continuations

        if args.debug:
            print(edit, results[edit][:5])

    if args.debug:
        print({k: len(v) for k, v in results.items()})

    results_df = pd.DataFrame(results)

    results_df.to_csv(
        f"data/mahowald-{mode}/corruption.csv", index=False
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--aann_dir", type=str, default="data/mahowald-aann/")
    parser.add_argument("--mode", type=str, default="aann")
    parser.add_argument("--debug", action="store_true")

    args = parser.parse_args()
    main(args)
