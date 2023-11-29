import csv
import config
import re
import unicodedata

from minicons import utils as mu
from constructions import AANN


def read_csv_dict(path):
    data = []
    with open(path, "r") as f:
        reader = csv.DictReader(f)
        for line in reader:
            data.append(line)
    return data

def roundup(x):
    return x if x % 1000 == 0 else x + 1000 - x % 1000

def read_file(path):
    """TODO: make read all"""
    return [unicodedata.normalize("NFKD", i.strip()) for i in open(path, encoding="utf-8").readlines() if i.strip() != ""]

def read_babylm(path):
    """TODO: make read all"""
    return [unicodedata.normalize("NFKD", i.strip()) for i in open(path, encoding="utf-8").readlines()]


def belongingness(tup1, tup2):
    """is tup1 contained in tup2?"""
    assert tup1[0] <= tup1[1] and tup2[0] <= tup2[1]

    if tup2[0] <= tup1[0] and tup2[1] >= tup1[1]:
        return True
    else:
        return False


def left_only(sentence, construction):
    left, right = mu.character_span(sentence, construction)
    return sentence[:left].strip(), sentence[left:right]


def reconstruct(left, middle, right, left_only=False):
    if left_only:
        concat_pieces = [left, middle]
    else:
        concat_pieces = [left, middle, right]
    string = " ".join(concat_pieces).strip()
    return re.sub(r" {2,}", " ", string)


def construction_pieces(sentence, construction):
    left, right = mu.character_span(sentence, construction)
    return sentence[:left], sentence[left:right], sentence[right:]


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
            if belongingness(cs, construction_span)
        ][0]

    if sentence == construction == token_span:
        return "", sentence
    else:
        return (
            sentence[: selected_span[0] - 1],
            sentence[selected_span[0] : selected_span[1]],
        )

def parse_from_csv(instance):
    return AANN(instance['DT'], instance['ADJ'], instance['NUMERAL'], instance['NOUN'])

def segment(instances, extractor, editor=None, only_construction=False):
    full_length, prefixes, continuations = [], [], []
    for instance in instances:
        parsed = parse_from_csv(instance)
        if editor is not None:
            parsed = editor(parsed)
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
