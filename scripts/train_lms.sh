#!/bin/bash

declare -a seeds=(42 211 1024)
# declare -a seeds=(211 1024)

for seed in ${seeds[@]}
do

    # Experiment 1: exposure to aann/no aann/anan/naan

    # regular babylm
    bash scripts/autoreg-regular.sh data/babylm/train.sents babylm-seed_${seed} 1e-3 ${seed} 

    # no aann
    bash scripts/autoreg.sh kanishka/counterfactual-babylm-new_regex_aanns_removal counterfactual-babylm-new_regex_aanns_removal-seed_${seed} 1e-3 ${seed} 

    # naan
    bash scripts/autoreg.sh kanishka/counterfactual_babylm_naans_new counterfactual_babylm_naans_new-seed_${seed} 1e-4 ${seed}

    # anan
    bash scripts/autoreg.sh kanishka/counterfactual_babylm_anans_new counterfactual_babylm_anans_new-seed_${seed} 1e-4 ${seed}


    # EXPERIMENT 2: Hypotheses

    # no dt ann
    bash scripts/autoreg.sh kanishka/counterfactual-babylm-only_other_det_removal kanishka/counterfactual-babylm-only_other_det_removal-seed_${seed} 1e-3 ${seed}

    # no dt ann + aann removed
    bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_dtanns counterfactual_babylm_aanns_dtanns-seed_${seed} 1e-4 ${seed}

    # no indef articles with pl NPs
    bash scripts/autoreg.sh kanishka/counterfactual-babylm-only_indef_articles_with_pl_nouns_removal counterfactual-babylm-only_indef_articles_with_pl_nouns_removal-seed_${seed} 1e-3 ${seed}

    # no indef articles with pl NPs + aanns removed
    bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_indef_articles_with_pl_nouns_removal_new counterfactual_babylm_indef_articles_with_pl_nouns_removal_new-seed_${seed} 1e-3 ${seed}

    # measure nps w/ singular verbs
    bash scripts/autoreg.sh kanishka/counterfactual-babylm-only_measure_nps_as_singular_removal counterfactual-babylm-only_measure_nps_as_singular_removal-seed_${seed} 1e-3 ${seed}

    # measure nps w/ singular verbs + aanns removed
    bash scripts/autoreg.sh kanishka/counterfactual_babylm_measure_nps_as_singular_new counterfactual_babylm_measure_nps_as_singular_new-seed_${seed} 1e-3 $seed

    # freq balance
    bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_excess_adj_removal counterfactual-babylm-adj_num_freq_balanced-seed_${seed} 1e-4 $seed

    # random removal
    bash scripts/autoreg.sh kanishka/counterfactual-babylm-only_random_removal counterfactual-babylm-only_random_removal-seed_${seed} 1e-3 ${seed}

    # random removal + aanns removed
    bash scripts/autoreg.sh kanishka/counterfactual-babylm-random_removal counterfactual-babylm-random_removal-seed_${seed} 3e-4 ${seed} 

    # Experiment 3: Variability

    # all open slots
    bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_high_variability_all counterfactual_babylm_aann_high_variability_all-seed_${seed} 1e-3 ${seed}

    bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_low_variability_all counterfactual_babylm_aann_low_variability_all_${seed} 1e-3 ${seed}

    # adj slots
    bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_high_variability_adj counterfactual_babylm_aann_high_variability_adj-seed_${seed} 1e-3 ${seed}

    bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_low_variability_adj counterfactual_babylm_aann_low_variability_adj_${seed} 1e-3 ${seed}

    # num slots
    bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_high_variability_numeral counterfactual_babylm_aann_high_variability_numeral-seed_${seed} 1e-3 ${seed}

    bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_low_variability_numeral counterfactual_babylm_aann_low_variability_numeral_${seed} 1e-3 ${seed}

    # noun slots
    bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_high_variability_noun counterfactual_babylm_aann_high_variability_noun-seed_${seed} 1e-3 ${seed}

    bash scripts/autoreg.sh kanishka/counterfactual_babylm_aann_low_variability_noun counterfactual_babylm_aann_low_variability_noun_${seed} 1e-3 ${seed}

done
