#!/bin/bash

python src/tokenize_and_save.py --corpus /home/km55359/rawdata/babylm_data/babylm_100M/sents/babylm_sents.txt \
    --output_dir models/tokenized/ \
    --model kanishka/smolm-autoreg-bpe-babylm-1e-3&

python src/tokenize_and_save.py --corpus data/training_data/counterfactual_babylm_aann_indef_removal.txt \
    --output_dir models/tokenized/ \
    --model kanishka/smolm-autoreg-bpe-counterfactual-babylm-indef-removal-1e-4&

python src/tokenize_and_save.py --corpus data/training_data/counterfactual_babylm_aann_all_det_removal.txt \
    --output_dir models/tokenized/ \
    --model kanishka/smolm-autoreg-bpe-counterfactual-babylm-all_det_removal-1e-4&

python src/tokenize_and_save.py --corpus data/training_data/counterfactual_babylm_prototypical_only.txt \
    --output_dir models/tokenized/ \
    --model kanishka/smolm-autoreg-bpe-counterfactual-babylm-aann-prototypical_only-1e-4&

python src/tokenize_and_save.py --corpus data/training_data/counterfactual_babylm_without_prototypical.txt \
    --output_dir models/tokenized/ \
    --model kanishka/smolm-autoreg-bpe-counterfactual-babylm-aann-no_prototypical-1e-4&

python src/tokenize_and_save.py --corpus data/training_data/counterfactual_babylm_aann_indef_articles_with_pl_nouns_removal.txt \
    --output_dir models/tokenized/ \
    --model kanishka/smolm-autoreg-bpe-counterfactual-babylm-indef_articles_with_pl_nouns-removal-1e-4&

python src/tokenize_and_save.py --corpus data/training_data/counterfactual_babylm_measure_nouns_as_singular.txt \
    --output_dir models/tokenized/ \
    --model kanishka/smolm-autoreg-bpe-counterfactual-babylm-measure_nouns_as_singular-1e-4&

python src/tokenize_and_save.py --corpus data/training_data/counterfactual_babylm_aann_excess_adj_removal.txt \
    --output_dir models/tokenized/ \
    --model kanishka/smolm-autoreg-bpe-counterfactual-babylm-adj_num_freq_balanced-1e-4&

python src/tokenize_and_save.py \
 --corpus data/training_data/counterfactual-babylm-random_removal.txt \
  --output_dir models/tokenized/ \
  --model kanishka/smolm-autoreg-bpe-counterfactual-babylm-random_removal-3e-4
  