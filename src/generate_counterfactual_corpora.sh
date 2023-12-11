#!/bin/bash

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual_babylm_aann_indef_removal.txt \
    --counterfactual_type removal

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual_babylm_aann_all_det_removal.txt \
    --aann_path data/babylm-aanns/aanns_all_det_all.csv \
    --counterfactual_type removal 

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual_babylm_aann_indef_articles_with_pl_nouns_removal.txt \
    --counterfactual_type removal \
    --excess_path data/babylm-analysis/indef_articles_with_pl_nouns.csv
