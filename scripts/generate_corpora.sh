#!/bin/bash

declare -a modes=(removal anan naan)
declare -a aanns=(indef all_det)

for mode in ${modes[@]}
do
    for aann in ${aanns[@]}
    do
        echo "Mode: ${mode}, AANN: ${aann}"

        python src/counterfactual_constructions.py \
            --sentence_path /home/km55359/rawdata/babylm_data/babylm_100M/sents/babylm_sents.txt \
            --output_path data/training_data/counterfactual_babylm_aann_${aann}_${mode}.txt \
            --counterfactual_type ${mode} \
            --aann_path data/babylm-aanns/aanns_${aann}_all.csv \
            --aann_all_det_path data/babylm-aanns/aanns_all_det_all.csv
    done
done
