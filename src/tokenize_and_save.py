import argparse
import utils
import re
import pathlib

from transformers import AutoTokenizer
from tqdm import tqdm

def main(args):
    # read corpus
    corpus = utils.read_file(args.corpus)

    # tokenize corpus
    tokenizer = AutoTokenizer.from_pretrained(args.model)

    to_save = []
    for sentence in tqdm(corpus):
        words = tokenizer.tokenize(sentence)
        to_save.append(" ".join(words))

    pathlib.Path(args.output_dir).mkdir(parents=True, exist_ok=True)

    output_file = re.search(r"(?<=smolm-autoreg-bpe-)(.*)(?=-\de-\d)", args.model).group(0)

    with open(f"{args.output_dir}/{output_file}.txt", "w") as f:
        for sentence in to_save:
            f.write(f"{sentence}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--corpus", type=str, required=True, help="Path to corpus file")
    parser.add_argument("--model", type=str, required=True, help="Model name")
    parser.add_argument("--output_dir", type=str, required=True, help="Output directory")
    args = parser.parse_args()
    main(args)
 