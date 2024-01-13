#!/bin/bash

# python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-1e-3 -b 128 -a data/mahowald-aann

# python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-aann-counterfactual-anan-1e-3 -b 128 -a data/mahowald-anan

# python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-aann-counterfactual-naan-3e-3 -b 128 -a data/mahowald-naan

declare -a modes=(aann anan naan)
declare -a lrs=(1e-3 1e-4 3e-4)

# declare -a models=$(awk -F "\"*,\"*" '{print $2}'| tail -n +2)

readarray -t models < <( awk -F "\"*,\"*" '{print $2}' data/results/babylm_lms.csv | tail -n +2 ); IFS=' '

for mode in ${modes[@]}
do 
    for lr in ${lrs[@]}
    do
        for model in ${models[@]}
        do
            # echo kanishka/smolm-autoreg-bpe-${model}-${lr} -b 128 -a data/mahowald-${mode}
            python src/acceptability.py -m kanishka/smolm-autoreg-bpe-${model}-${lr} -b 128 -a data/mahowald-${mode}

            python src/acceptability.py -m kanishka/smolm-autoreg-bpe-${model}-seed_1024-${lr} -b 128 -a data/mahowald-${mode}

            python src/acceptability.py -m kanishka/smolm-autoreg-bpe-${model}-seed_211-${lr} -b 128 -a data/mahowald-${mode}
        done
    done

    # python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-aann-counterfactual-anan-1e-3 -b 128 -a data/mahowald-${mode}

    # python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-aann-counterfactual-naan-3e-3 -b 128 -a data/mahowald-${mode}

    # python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-no_aann-infilling-1e-3 -b 128 -a data/mahowald-${mode}

    # python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-no_aann-removal-3e-3 -b 128 -a data/mahowald-${mode}

    # python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-no_aann-all-det-removal-1e-3 -b 128 -a data/mahowald-${mode}

done