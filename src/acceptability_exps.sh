#!/bin/bash

# python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-1e-3 -b 128 -a data/mahowald-aann

# python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-aann-counterfactual-anan-1e-3 -b 128 -a data/mahowald-anan

# python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-aann-counterfactual-naan-3e-3 -b 128 -a data/mahowald-naan

declare -a modes=(aann anan naan)
# declare -a lrs=(1e-3 1e-4 3e-4)
declare -a lrs=(1e-4)

# readarray -t models < <( awk -F "\"*,\"*" '{print $2}' data/results/babylm_lms.csv | tail -n +2 ); IFS=' '

# for mode in ${modes[@]}
# do 
#     for lr in ${lrs[@]}
#     do
#         for model in ${models[@]}
#         do
#             # echo kanishka/smolm-autoreg-bpe-${model}-${lr} -b 128 -a data/mahowald-${mode}
#             python src/acceptability.py -m kanishka/smolm-autoreg-bpe-${model}-${lr} -b 128 -a data/mahowald-${mode}

#             python src/acceptability.py -m kanishka/smolm-autoreg-bpe-${model}-seed_1024-${lr} -b 128 -a data/mahowald-${mode}

#             python src/acceptability.py -m kanishka/smolm-autoreg-bpe-${model}-seed_211-${lr} -b 128 -a data/mahowald-${mode}
#         done
#     done
# done

# declare -a models=(counterfactual-babylm-measure_nouns_as_singular)
# declare -a models=(counterfactual-babylm-aann-prototypical_only counterfactual-babylm-aann-no_prototypical)
# declare -a models=(counterfactual-babylm-random_removal)
# declare -a models=(counterfactual-babylm-only_other_det_removal counterfactual-babylm-only_indef_articles_with_pl_nouns_removal counterfactual-babylm-only_measure_nps_as_singular_removal)
# declare -a models=(counterfactual-babylm-only_random_removal)
# declare -a models=(meta-llama/Llama-2-7b-hf)
# declare -a models=(counterfactual-babylm-old_union_new_regex_aanns_removal counterfactual-babylm-new_regex_aanns_removal)

# declare -a models=(counterfactual_babylm_naans_new counterfactual_babylm_300_naans_new counterfactual_babylm_300_anans_new)
declare -a models=(counterfactual_babylm_anans_new counterfactual_babylm_naans_new)
# declare -a models=(counterfactual_babylm_naans_new-1e-3 counterfactual_babylm_300_naans_new-1e-3 counterfactual_babylm_300_anans_new-1e-3 counterfactual_babylm_anans_new-1e-3)

for mode in ${modes[@]}
do 
    for lr in ${lrs[@]}
    do
        for model in ${models[@]}
        do
            # echo kanishka/smolm-autoreg-bpe-${model}-${lr} -b 128 -a data/mahowald-${mode}
            python src/acceptability.py -m kanishka/smolm-autoreg-bpe-${model}-${lr} -b 128 -a data/mahowald-${mode} --device cuda:2

            # python src/acceptability.py -m kanishka/smolm-autoreg-bpe-${model}-seed_1024-${lr} -b 128 -a data/mahowald-${mode}

            # python src/acceptability.py -m kanishka/smolm-autoreg-bpe-${model}-seed_211-${lr} -b 128 -a data/mahowald-${mode}
        done
    done
done

# for mode in ${modes[@]}
# do 
#     for model in ${models[@]}
#     do
#         # echo kanishka/smolm-autoreg-bpe-${model}-${lr} -b 128 -a data/mahowald-${mode}
#         python src/acceptability.py -m ${model} -b 32 -a data/mahowald-${mode}
#     done
# done