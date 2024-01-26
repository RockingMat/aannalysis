import config
import csv
import json
import os
import utils

# read materials
pipps = []
i = 0
with open("data/pipps/materials.txt") as f:
    materials = f.read().splitlines()
    for preposition in config.PREPOSITIONS:
        for embedding in config.EMBEDDINGS:
            for item_num, mat in enumerate(materials):
                obj = {
                    "idx": i,
                    "item_num": item_num+1,
                    "preposition": preposition,
                    "embedding": embedding,
                    "pipp_filler_gap": {"sentence": "", "target": ""},
                    "pp_no_filler_no_gap": {"sentence": "", "target": ""},
                    "filler_no_gap": {"sentence": "", "target": ""},
                    "no_filler_gap": {"sentence": "", "target": ""},
                }
                item = utils.item(mat, preposition=preposition, embedding=embedding)
                for k, v in item.items():
                    obj[config.CONDITION2COLUMN[k]]["sentence"] = v[0]
                    obj[config.CONDITION2COLUMN[k]]["target"] = v[1]

                pipps.append(obj)
                i += 1

# write materials to jsonl file
# with open("data/pipps/materials.jsonl", "w") as f:
#     for pipp in pipps:
#         f.write(json.dumps(pipp) + "\n")
                
pipps_annotated = []
for file in os.listdir("data/pipps/"):
    if file.endswith(".csv") and "pipps-" in file:
        with open("data/pipps/" + file) as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row['PiPP'] == "1" or row['PiPP'] == "T":
                    pipps_annotated.append(row['sentence'])


