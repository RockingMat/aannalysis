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
#     --counterfactual_type naan \
#     --excess_path data/babylm-aanns/aanns_indef_num.csv

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual_babylm_measure_nps_as_singular.txt \
#     --aann_path data/babylm-aanns/aanns_indef_all.csv \
#     --counterfactual_type removal \
#     --excess_path data/babylm-analysis/measure_nouns_with_singular_verbs.csv \
#     --secondary_excess_path data/babylm-analysis/indef_articles_with_pl_nouns.csv


# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual_babylm_naan_num.txt \
#     --aann_path data/babylm-aanns/aanns_indef_num.csv \
#     --counterfactual_type naan

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual-babylm-aanns_indef_non_num_removal.txt \
#     --aann_path data/babylm-aanns/aanns_indef_non_num.csv \
#     --counterfactual_type removal

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual_babylm_keys_to_pipps_2913.txt \
#     --counterfactual_type addition \
#     --addition_path data/pipps/openbooks_keys_to_pipps.csv \
#     --num_additions 2913

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual_babylm_keys_to_pipps_all.txt \
#     --counterfactual_type addition \
#     --addition_path data/pipps/openbooks_keys_to_pipps.csv \
#     --num_additions -1

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual_babylm_pipps_10k.txt \
#     --counterfactual_type addition \
#     --addition_path data/pipps/openbooks_pipps_sents.csv \
#     --num_additions 10000

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual_babylm_pipps_and_keys_to_it_all_10k.txt \
#     --counterfactual_type addition \
#     --addition_path data/pipps/openbooks_keys_to_pipps.csv \
#     --num_additions 10000 \
#     --secondary_addition_path data/pipps/openbooks_pipps_sents.csv \
#     --num_secondary_additions 10000

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual-babylm-pipps_removal.txt \
#     --aann_path data/babylm-analysis/detected_pipps_sents.csv \
#     --counterfactual_type removal

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual-babylm-pipps_and_keys_to_it_all_removal.txt \
#     --aann_path data/babylm-analysis/detected_pipps_sents.csv \
#     --excess_path data/babylm-analysis/keys_to_pipps.csv \
#     --counterfactual_type removal

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual-babylm-random_removal.txt \
    --aann_path data/babylm-analysis/random_removal.csv \
    --ignore_path data/babylm-analysis/all_hypotheses.csv \
    --counterfactual_type removal

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual-babylm-only_random_removal.txt \
    --aann_path data/babylm-analysis/random_removal.csv \
    --excess_path data/babylm-aanns/aanns_indef_all.csv \
    --ignore_path data/babylm-analysis/all_hypotheses.csv \
    --counterfactual_type removal 

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual-babylm-pipps-random_removal.txt \
#     --aann_path data/babylm-analysis/random_removal_pipps.csv \
#     --aann_all_det_path data/babylm-analysis/random_removal_pipps.csv \
#     --ignore_path data/babylm-analysis/all_hypotheses_pipps.csv \
#     --counterfactual_type removal

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual-babylm-only_other_det_removal.txt \
    --aann_path data/babylm-aanns/aanns_all_det_all.csv \
    --counterfactual_type removal \
    --add_back_path data/babylm-aanns/aanns_indef_all.csv

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual-babylm-only_indef_articles_with_pl_nouns_removal.txt \
    --aann_path data/babylm-analysis/indef_articles_with_pl_nouns.csv \
    --counterfactual_type removal \
    --add_back_path data/babylm-aanns/aanns_indef_all.csv

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual-babylm-only_measure_nps_as_singular_removal.txt \
    --aann_path data/babylm-analysis/indef_articles_with_pl_nouns.csv \
    --excess_path data/babylm-analysis/measure_nouns_with_singular_verbs.csv \
    --counterfactual_type removal \
    --add_back_path data/babylm-aanns/aanns_indef_all.csv

# python src/counterfactual_constructions.py \
#     --output_path data/training_data/counterfactual-babylm-old_union_new_regex_aanns_removal.txt \
#     --aann_path data/babylm-analysis/old_union_new_regex_aanns.csv \
#     --counterfactual_type removal 

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual-babylm-new_regex_aanns_removal.txt \
    --aann_path data/babylm-analysis/new_regex_aanns.csv \
    --counterfactual_type removal 

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual_babylm_measure_nps_as_singular_new.txt \
    --aann_path data/babylm-analysis/new_regex_aanns.csv \
    --counterfactual_type removal \
    --excess_path data/babylm-analysis/measure_nouns_with_singular_verbs.csv \
    --secondary_excess_path data/babylm-analysis/indef_articles_with_pl_nouns.csv

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual_babylm_aann_indef_articles_with_pl_nouns_removal_new.txt \
    --aann_path data/babylm-analysis/new_regex_aanns.csv \
    --counterfactual_type removal \
    --excess_path data/babylm-analysis/indef_articles_with_pl_nouns.csv

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual_babylm_aann_dtanns.txt \
    --aann_path data/babylm-analysis/new_regex_aanns.csv \
    --counterfactual_type removal \
    --excess_path data/babylm-analysis/dtanns.csv

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual_babylm_aann_high_variability_all.txt \
    --aann_path data/babylm-aanns/aanns_high_variability_all.csv\
    --counterfactual_type removal

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual_babylm_aann_low_variability_all.txt \
    --aann_path data/babylm-aanns/aanns_low_variability_all.csv\
    --counterfactual_type removal

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual_babylm_aann_high_variability_adj.txt \
    --aann_path data/babylm-aanns/aanns_high_variability_adj.csv\
    --counterfactual_type removal

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual_babylm_aann_low_variability_adj.txt \
    --aann_path data/babylm-aanns/aanns_low_variability_adj.csv\
    --counterfactual_type removal

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual_babylm_aann_high_variability_numeral.txt \
    --aann_path data/babylm-aanns/aanns_high_variability_numeral.csv\
    --counterfactual_type removal

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual_babylm_aann_low_variability_numeral.txt \
    --aann_path data/babylm-aanns/aanns_low_variability_numeral.csv\
    --counterfactual_type removal

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual_babylm_aann_high_variability_noun.txt \
    --aann_path data/babylm-aanns/aanns_high_variability_adj.csv\
    --counterfactual_type removal

python src/counterfactual_constructions.py \
    --output_path data/training_data/counterfactual_babylm_aann_low_variability_noun.txt \
    --aann_path data/babylm-aanns/aanns_low_variability_noun.csv\
    --counterfactual_type removal
