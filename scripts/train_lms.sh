#!/bin/bash

declare -a seeds=(42 211 1024)
# declare -a seeds=(211 1024)

for seed in ${seeds[@]}
do
    
    CUDA_VISIBLE_DEVICES=0 bash scripts/autoreg.sh kanishka/counterfactual_babylm_measure_nps_as_singular counterfactual-babylm-measure_nps_as_singular-seed_${seed} 1e-4 $seed

    CUDA_VISIBLE_DEVICES=1 bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_all_det_removal counterfactual-babylm-all_det_removal-seed_${seed} 1e-3 $seed

    CUDA_VISIBLE_DEVICES=0 bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_indef_removal counterfactual-babylm-indef-removal-seed_${seed} 1e-4 $seed 

    CUDA_VISIBLE_DEVICES=0 bash scripts/autoreg.sh kanishka/counterfactual_babylm_prototypical_only counterfactual-babylm-prototypical_only-seed_${seed} 1e-3 $seed

    CUDA_VISIBLE_DEVICES=0 bash scripts/autoreg.sh kanishka/counterfactual_babylm_without_prototypical counterfactual-babylm-no_prototypical-seed_${seed} 3e-4 $seed 

    CUDA_VISIBLE_DEVICES=1 bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_indef_articles_with_pl_nouns_removal counterfactual-babylm-indef_articles_with_pl_nouns-removal-seed_${seed} 3e-4 $seed

    CUDA_VISIBLE_DEVICES=0 bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_excess_adj_removal counterfactual-babylm-adj_num_freq_balanced-seed_${seed} 1e-4 $seed

    CUDA_VISIBLE_DEVICES=1 bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_indef_naan counterfactual-babylm-indef-naan-rerun-seed_${seed} 1e-3 $seed

    CUDA_VISIBLE_DEVICES=0 bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_indef_anan counterfactual-babylm-indef-anan-seed_${seed} 3e-4 $seed
done
