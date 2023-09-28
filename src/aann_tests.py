"""
Test #1: Non article regions for default ANN, AANN, Order Swap, and No Article
id, construction, ann lp, aann lp, order swap lp, article lp

Test #2: Just noun region for AANN and No numeral
id, construction, aann lp, no numeral lp

Test #3: Numeral Noun region for AANN and No adjective
id, construction, aann lp(nn|lc), non adjective lp(nn|lc)

Overall: construction | left
id, construction, ann, aann, order_swap, no_article, no_modifier, no numeral

Strategy
load all constructions and corruption/extraction things DONE

compute stats for AANN, token-wise store:
{id: X, construction lp: X, non-article-region: X, just_noun: X, numeral noun: X}

load default ANN, compute stats for full sentence until construction, store:
{id: X, construction lp: X, non-article-region: X}

load corruption, compute stats for full sentence until construction part, store:
{id: X, construction lp: X, region-specific: X}

"""
import argparse
import config
import inflect
import os
import pathlib
import re
import torch
import utils

import pandas as pd

from collections import defaultdict
from dataclasses import dataclass
from minicons import scorer
from minicons import utils as mu
from torch.utils.data import DataLoader
from tqdm import tqdm


inflector = inflect.engine()


@dataclass
class AANN:
    article: str
    adjective: str
    numeral: str
    noun: str

    def __post_init__(self):
        self.string = re.sub(
            r"\s{2,}",
            " ",
            f"{self.article} {self.adjective} {self.numeral} {self.noun}",
        ).strip()


def parse_aann(string, pattern):
    tokens = string.split()
    adj_span = re.search(config.ADJ_PATTERN, pattern).group(0)
    num_span = re.search(config.NUM_PATTERN, pattern).group(0)

    adjs_idx = mu.find_pattern(adj_span.split(), pattern.split())
    nums_idx = mu.find_pattern(num_span.split(), pattern.split())

    parsed = AANN(
        tokens[0],
        " ".join(tokens[adjs_idx[0] : adjs_idx[1]]),
        " ".join(tokens[nums_idx[0] : nums_idx[1]]),
        " ".join(tokens[nums_idx[1] :]),
    )
    return parsed


def parse_instance(aann):
    return parse_aann(aann["construction"], aann["pattern"])


def construction_pieces(sentence, construction):
    left, right = mu.character_span(sentence, construction)
    return sentence[:left], sentence[left:right], sentence[right:]


def reconstruct(left, middle, right, left_only=False):
    if left_only:
        concat_pieces = [left, middle]
    else:
        concat_pieces = [left, middle, right]
    string = " ".join(concat_pieces).strip()
    return re.sub(r" {2,}", " ", string)


def left_only(sentence, construction):
    left, right = mu.character_span(sentence, construction)
    return sentence[:left].strip(), sentence[left:right]


def default_ann(aann):
    return AANN("", aann.numeral, aann.adjective, aann.noun)


def corrupt_order(aann):
    article = inflector.a(aann.numeral.split(" ")[0]).split(" ")[0]
    return AANN(article, aann.numeral, aann.adjective, aann.noun)


def corrupt_article(aann):
    return AANN("", aann.adjective, aann.numeral, aann.noun)


def corrupt_modifier(aann):
    article = inflector.a(aann.numeral.split(" ")[0]).split(" ")[0]
    return AANN(article, "", aann.numeral, aann.noun)


def corrupt_numeral(aann):
    return AANN(aann.article, aann.adjective, "", aann.noun)


def corrupt_noun_num(aann):
    noun = inflector.singular_noun(aann.noun.split(" ")[-1])
    return AANN(aann.article, aann.adjective, aann.numeral, noun)


# extractors implemented as aann corruptors.
def non_article_region(aann):
    return AANN("", aann.adjective, aann.numeral, aann.noun)


def numeral_noun_region(aann):
    return AANN("", "", aann.numeral, aann.noun)


def just_noun_region(aann):
    return AANN("", "", "", aann.noun)


def left_context(sentence, construction, token_span):
    candidate_spans = [it.span() for it in re.finditer(token_span, sentence)]
    if len(candidate_spans) == 1:
        selected_span = candidate_spans[0]
    else:
        try:
            construction_span = re.search(construction, sentence).span()
        except:
            construction_span = re.search(
                re.escape(construction), sentence
            ).span()
        selected_span = [
            cs
            for cs in candidate_spans
            if utils.belongingness(cs, construction_span)
        ][0]

    if sentence == construction == token_span:
        return "", sentence
    else:
        return (
            sentence[: selected_span[0] - 1],
            sentence[selected_span[0] : selected_span[1]],
        )


def segment(instances, extractor, corruptor=None, only_construction=False):
    full_length, prefixes, continuations = [], [], []
    for instance in instances:
        parsed = parse_instance(instance)
        if corruptor is not None:
            parsed = corruptor(parsed)
            left, construction, right = construction_pieces(
                instance["sentence"], instance["construction"]
            )
            sentence = reconstruct(left, parsed.string, right)
            construction = parsed.string
        else:
            sentence = instance["sentence"]
            construction = instance["construction"]

        predicted_item = extractor(parsed)

        if only_construction:
            sentence = construction

        p, c = left_context(sentence, construction, predicted_item.string)
        prefixes.append(p)
        continuations.append(c)
        full_length.append((p + " " + c).strip())
    return full_length, prefixes, continuations


def compute_scores(lm, data, batch_size, num_workers, modifier=None):
    scores = []

    full, prefixes, continuations = segment(data, lambda x: x, modifier)
    dl = DataLoader(full, batch_size=batch_size, num_workers=num_workers)

    for batch in tqdm(dl):
        scores.extend(
            lm.compute_stats(lm.prepare_text(batch), return_tensors=True)
        )

    return scores


def segment_and_score(lm, scores, **kwargs):
    full, prefixes, continuations = segment(**kwargs)
    encoded, offset = lm.prime_text(prefixes, continuations)
    offset = [0 if o < 0 else o for o in offset]
    mean_scores = [
        torch.mean(score[n:]).item() for score, n in zip(scores, offset)
    ]
    return mean_scores


def main(args):
    os.environ["TOKENIZERS_PARALLELISM"] = "false"
    model_name = args.model
    batch_size = args.batch_size
    device = args.device
    n_workers = args.n_workers

    model_name = model_name.replace("../smolm/models/", "").replace(
        "kanishka/", ""
    ).replace("/", "_")

    aann_dir = args.aanns_dir.split("data")[-1].strip("/")
    pathlib.Path(args.results_dir).mkdir(parents=True, exist_ok=True)
    pathlib.Path(f"{args.results_dir}/{aann_dir}").mkdir(
        parents=True, exist_ok=True
    )

    results_prefix = f"{args.results_dir}/{aann_dir}/{model_name}"

    # load model
    lm = scorer.IncrementalLMScorer(args.model, device=device)

    good = utils.read_csv_dict(f"{args.aanns_dir}/aanns_good.csv")

    good_scores = compute_scores(lm, good, batch_size, n_workers)

    results = {
        "idx": [aann["idx"] for aann in good],
        "construction_score": segment_and_score(
            lm, good_scores, instances=good, extractor=lambda x: x
        ),
        "non_article_region_score": segment_and_score(
            lm, good_scores, instances=good, extractor=non_article_region
        ),
        "numeral_noun_score": segment_and_score(
            lm, good_scores, instances=good, extractor=numeral_noun_region
        ),
        "just_noun_score": segment_and_score(
            lm, good_scores, instances=good, extractor=just_noun_region
        ),
    }

    EXTRACTORS_AND_MODIFIERS = {
        "default_ann": (non_article_region, default_ann),
        "order_swap": (non_article_region, corrupt_order),
        "no_article": (non_article_region, corrupt_article),
        "no_modifier": (numeral_noun_region, corrupt_modifier),
        "no_numeral": (just_noun_region, corrupt_numeral),
    }

    for modification, (
        extractor,
        modifier,
    ) in EXTRACTORS_AND_MODIFIERS.items():
        print(f"Processing {modification}...")
        # construction level
        scores = compute_scores(lm, good, batch_size, n_workers, modifier)

        region_scores = segment_and_score(
            lm, scores, instances=good, extractor=extractor, corruptor=modifier
        )
        corruption_scores = segment_and_score(
            lm, scores, instances=good, extractor=lambda x: x
        )

        results[f"{modification}_corruption_score"] = corruption_scores
        results[f"{modification}_region_score"] = region_scores

    print({k: len(v) for k, v in results.items()})

    results_df = pd.DataFrame(results)
    results_df.to_csv(f"{results_prefix}.csv", index=False)


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
