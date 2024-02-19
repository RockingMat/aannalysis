import json
import re
import pathlib
import csv
import utils

from minicons import scorer
from tqdm import tqdm

from collections import defaultdict

def find_and_split(sentence, target, condition):
    if target == ".":
        search_query = "\."
    elif target == ",":
        search_query = ","
    else:
        search_query = fr"\b{target}\b"
    if "pipp" in condition or condition == "no_filler_gap":
        search_index = 0
    else:
        search_index = -1
    search_results = list(re.finditer(search_query, sentence))[search_index].span()
    # print(search_results)
    return sentence[:search_results[0]].strip(), target

def write_to_csv(results, filename):
    with open(filename, 'w') as f:
        writer = csv.writer(f)
        writer.writerow(['idx', 'item_num', 'preposition', 'embedding', 'pipp_filler_gap', 'pp_no_filler_no_gap', 'filler_no_gap', 'no_filler_gap'])
        for result in results:
            writer.writerow([result['idx'], result['item_num'], result['preposition'], result['embedding'], result['pipp_filler_gap']['score'], result['pp_no_filler_no_gap']['score'], result['filler_no_gap']['score'], result['no_filler_gap']['score']])

def main(args):
    pipps = utils.read_jsonl('data/pipps/materials.jsonl')

    pipps_organized = defaultdict(list)

    pipps_embedding_organized = defaultdict(list)

    for pipp in pipps:
        if pipp['embedding'] == "":
            pipps_organized[pipp['preposition']].append(pipp)
        else:
            pipps_embedding_organized[pipp['preposition']].append(pipp)

    model = args.model

    lm = scorer.IncrementalLMScorer(model, args.device)

    model_name = (
            model.replace("../smolm/models/", "")
            .replace("kanishka/", "")
            .replace("/", "_")
        )

    for pipp in tqdm(pipps):
        for key in pipp:
            if key not in ['idx', 'item_num', 'embedding', 'preposition']:
                sentence = pipp[key]['sentence']
                target = pipp[key]['target']
                prefix, query = find_and_split(sentence, target, condition=key)
                if target == "." or target == ",":
                    sep = ""
                else:
                    sep = " "
                score = lm.conditional_score(prefix, query, separator=sep, reduction = lambda x: -x.mean(0).item(), base_two=True)
                pipp[key]['score'] = score[0]

    pathlib.Path('data/results/pipps/').mkdir(parents=True, exist_ok=True)
    write_to_csv(pipps, f'data/results/pipps/{model_name}.csv')

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", "-m", type=str, required=True)
    parser.add_argument("--device", "-d", type=str, default="cuda")
    args = parser.parse_args()
    main(args)

