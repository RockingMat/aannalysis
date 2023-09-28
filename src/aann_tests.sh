#!/bin/bash

declare -a models=(../smolm/models/smolm-autoreg-bpe-seed_444 ../smolm/models/smolm-autoreg-bpe-babylm-1e-3 gpt2 gpt2-medium gpt2-large babylm/opt-125m-strict)

# python src/aann_tests.py -m kanishka/smolm-autoreg-bpe-seed_444 -b 128

for model in ${models[@]}
do
    # openbooks
    # python src/aann_tests.py -m ${model} -b 128

    # mahowald
    python src/aann_tests.py -m ${model} -b 128 -a data/mahowald/
done