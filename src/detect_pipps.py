import csv
import torch
import utils
import glob

from minicons import supervised
from torch.utils.data import DataLoader
from tqdm import tqdm
from transformers import BitsAndBytesConfig

bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_use_double_quant=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.bfloat16,
)

detector = supervised.SupervisedHead(
    "cgpotts/pipp-finder-bert-base-cased",
    quantization_config=bnb_config,
    device_map="cuda:2",
    device="auto",
)

# # print(lm.logits(["the family spent a beautiful five days in austin.", "the boys spent an eventful few days in the city."], probs=False).argmax(1))

# sents = []
# with open("../babylm_sents.txt", "r") as f:
#     for line in f:
#         # sent = line.strip()
#         sents.append(line.strip())

sents = []
train_files = glob.glob('/home/km55359/rawdata/books1/epubtxt/*.txt')
for file in train_files:
    sents.extend(utils.read_file(file))

# print(len(sents))
    
# pre filter sentences that work with the regex
regex_filtered_sents = []
for i, sent in enumerate(tqdm(sents)):
    if utils.is_pipp(sent):
        regex_filtered_sents.append((i, sent))

filtered_sents = []
filtered_idxes = []

dl = DataLoader(regex_filtered_sents, batch_size=4096, shuffle=False, num_workers=0)
for batch in tqdm(dl):
    ids, sentences = batch
    ids = ids.tolist()
    tokenized = detector.tokenizer(sentences)
    for i, (idx, tokens) in enumerate(zip(ids, tokenized["input_ids"])):
        if len(tokens) <= 512:
            filtered_sents.append(sentences[i])
            filtered_idxes.append(idx)

print("Number of sents after filtering: ", len(filtered_sents))

dl = DataLoader(filtered_sents, batch_size=50, shuffle=False, num_workers=4)

labels = []
for batch in tqdm(dl):
    labels.extend(detector.logits(batch, probs=False).argmax(1).tolist())

pipps= []
for i, label in enumerate(labels):
    if label == 1:
        pipps.append((filtered_idxes[i], filtered_sents[i]))

# with open("data/babylm-analysis/detected_pipps_sents.csv", "r") as f:
#     reader = csv.DictReader(f)
#     for row in reader:
#         pipps.append((int(row["idx"]), row["sentence"]))

# pipps_final = []
# for idx, sent in pipps:
#     if utils.is_pipp(sent):
#         pipps_final.append((idx, sent))
# print("Number of PiPPs found using the classifier: ", len(aanns))


# with open("data/babylm-analysis/detected_pipps_sents.csv", "w") as f:
with open("data/pipps/openbooks_pipps_sents.csv", "w") as f:
    writer = csv.writer(f)
    writer.writerow(["idx", "sentence"])
    writer.writerows(pipps)
