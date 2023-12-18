#!/bin/bash

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual_babylm_aann_indef_removal.txt \
#     --counterfactual_type removal

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual_babylm_aann_all_det_removal.txt \
#     --aann_path data/babylm-aanns/aanns_all_det_all.csv \
#     --counterfactual_type removal 

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual_babylm_aann_indef_articles_with_pl_nouns_removal.txt \
#     --counterfactual_type removal \
#     --excess_path data/babylm-analysis/indef_articles_with_pl_nouns.csv

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual_babylm_aann_excess_adj_removal.txt \
#     --counterfactual_type removal \
#     --excess_path data/babylm-analysis/adjs_to_remove.csv

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual_babylm_prototypical_only.txt \
#     --aann_path data/babylm-aanns/aanns_indef_all_non_prototypical.csv \
#     --counterfactual_type removal

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual_babylm_without_prototypical.txt \
#     --aann_path data/babylm-aanns/aanns_indef_all_prototypical.csv \
#     --counterfactual_type removal

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual_babylm_naan_non_num.txt \
#     --aann_path data/babylm-aanns/aanns_indef_non_num.csv \
#     --counterfactual_type naan

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual_babylm_naan_num.txt \
#     --aann_path data/babylm-aanns/aanns_indef_num.csv \
#     --counterfactual_type naan

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual-babylm-aanns_indef_non_num_removal.txt \
    --aann_path data/babylm-aanns/aanns_indef_non_num.csv \
    --counterfactual_type removal


