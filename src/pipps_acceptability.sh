#!/bin/bash

declare -a lrs=(1e-3 1e-4 3e-4)

declare -a models=(babylm counterfactual-babylm-pipps_and_keys_to_it_all_removal counterfactual-babylm-pipps_removal counterfactual-babylm-keys_to_pipps_all)

for lr in ${lrs[@]}
do
    for model in ${models[@]}
    do
        # echo kanishka/smolm-autoreg-bpe-${model}-${lr} -b 128 -a data/mahowald-${mode}
        python src/pipps_acceptability.py -m kanishka/smolm-autoreg-bpe-${model}-${lr} -d cuda:2

        python src/pipps_acceptability.py -m kanishka/smolm-autoreg-bpe-${model}-seed_1024-${lr} -d cuda:2

        python src/pipps_acceptability.py -m kanishka/smolm-autoreg-bpe-${model}-seed_211-${lr} -d cuda:2

    done
done