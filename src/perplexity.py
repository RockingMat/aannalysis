import argparse

from evaluate import load
from utils import read_file

def main(args):
    model = args.model
    test_file = args.test_file

    test_sentences = read_file(test_file)

    # print(len(test_sentences), test_sentences[0])

    perplexity = load("perplexity", module_type="metric")
    results = perplexity.compute(predictions=test_sentences, model_id=model, batch_size=64, device="cuda")

    print(round(results["mean_perplexity"], 2))

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str, required=True)
    parser.add_argument("--test_file", type=str, default="/home/km55359/rawdata/babylm_data/babylm_dev/babylm_dev.txt")
    args = parser.parse_args()
    main(args)
