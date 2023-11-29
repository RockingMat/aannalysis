#!/bin/bash

# python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-1e-3 -b 128 -a data/mahowald-aann

# python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-aann-counterfactual-anan-1e-3 -b 128 -a data/mahowald-anan

# python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-aann-counterfactual-naan-3e-3 -b 128 -a data/mahowald-naan

declare -a modes=(aann anan naan)

for mode in ${modes[@]}
do 

    # python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-aann-counterfactual-anan-1e-3 -b 128 -a data/mahowald-${mode}

    # python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-aann-counterfactual-naan-3e-3 -b 128 -a data/mahowald-${mode}

    # python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-no_aann-infilling-1e-3 -b 128 -a data/mahowald-${mode}

    # python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-no_aann-removal-3e-3 -b 128 -a data/mahowald-${mode}

    # python src/acceptability.py -m kanishka/smolm-autoreg-bpe-babylm-no_aann-all-det-removal-1e-3 -b 128 -a data/mahowald-${mode}
done