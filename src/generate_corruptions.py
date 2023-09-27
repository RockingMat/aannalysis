import argparse
import config
import inflect
import re
import utils

import pandas as pd

from dataclasses import dataclass
from minicons import utils as mu

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

        try:
            p, c = left_context(sentence, construction, predicted_item.string)
        except:
            print(instance)
        prefixes.append(p)
        continuations.append(c)
        full_length.append((p + " " + c).strip())
    return full_length, prefixes, continuations


def main(args):

    good = utils.read_csv_dict(f"{args.aanns_dir}/aanns_good.csv")

    full, prefixes, continuations = segment(good, lambda x: x)

    results = {
        "idx": [aann["idx"] for aann in good],
        "sentence": [aann['sentence'] for aann in good],
        "prefixes": prefixes,
        "aann": continuations
    }

    MODIFIERS = {
        "default_ann": default_ann,
        "order_swap": corrupt_order,
        "no_article": corrupt_article,
        "no_modifier": corrupt_modifier,
        "no_numeral": corrupt_numeral,
    }

    for modification, modifier in MODIFIERS.items():
        print(f"Processing {modification}...")

        full, prefix, continuation = segment(good, lambda x: x, modifier)
        # construction level
        results[modification] = continuation

    print({k: len(v) for k, v in results.items()})

    results_df = pd.DataFrame(results)
    results_df.to_csv(f"{args.aanns_dir}/aanns_corruption.csv", index=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--aanns_dir", "-a", type=str, default="data/openbooks/"
    )
    args = parser.parse_args()

    main(args)