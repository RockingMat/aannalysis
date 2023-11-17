import csv
import torch

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
    "kanishka/aann-detector", quantization_config=bnb_config, device_map="cuda:0", device="auto"
)

# print(lm.logits(["the family spent a beautiful five days in austin.", "the boys spent an eventful few days in the city."], probs=False).argmax(1))

sents = []
with open("../babylm_sents.txt", "r") as f:
    for line in f:
        # sent = line.strip()
        sents.append(line.strip())

print(len(sents))

filtered_sents = []
filtered_idxes = []

dl = DataLoader(sents, batch_size=4096, shuffle=False, num_workers=0)
for batch in tqdm(dl):
    tokenized = detector.tokenizer(batch)
    for i, tokens in enumerate(tokenized["input_ids"]):
        if len(tokens) <= 512:
            filtered_sents.append(batch[i])
            filtered_idxes.append(i)

print("Number of sents after filtering: ", len(filtered_sents))

dl = DataLoader(filtered_sents, batch_size=50, shuffle=False, num_workers=0)

labels = []
for batch in tqdm(dl):
    labels.extend(detector.logits(batch, probs=False).argmax(1).tolist())

aanns = []
for i, label in enumerate(labels):
    if label == 1:
        aanns.append((filtered_idxes[i], filtered_sents[i]))

print("Number of AANNs found using the classifier: ", len(aanns))

with open("data/babylm-analysis/detected_aann_sents.csv", "w") as f:
    writer = csv.writer(f)
    writer.writerow(["idx", "sentence"])
    writer.writerows(aanns)
