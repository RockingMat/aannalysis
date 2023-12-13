import os

from datasets import load_dataset

VAL_FILE = "../rawdata/babylm_data/babylm_dev/babylm_dev.txt"

for file in os.listdir("data/training_data/"):
    if file.endswith(".txt"):
        path = os.path.join("data/training_data/", file)
        data_files = {}
        dataset_args = {}
        data_files["train"] = path
        data_files["validation"] = VAL_FILE
        dataset_args["keep_linebreaks"] = True
        raw_datasets = load_dataset(
            "text",
            data_files=data_files,
            # token=model_args.token,
            **dataset_args,
        )

        raw_datasets.push_to_hub(f"kanishka/{file.replace('.txt', '')}")
        print(f"Pushed {file} to hub")
