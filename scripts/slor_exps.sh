#!/bin/bash

# readarray -t models < <( ls models/unigrams/ ); IFS=' '

# for model in ${models[@]}
# do 
#     python src/ngram_tokenized_acceptability.py -m models/unigrams/${model} --unigram
# done


readarray -t models < <( ls models/fourgrams/ ); IFS=' '
# declare -a models=(counterfactual-babylm-measure-nouns-as-singular_removal.binary)
# declare -a models=(counterfactual-babylm-only_random_removal.binary)
# declare -a models=(counterfactual-babylm-only_indef_articles_with_pl_nouns_removal counterfactual-babylm-only_other_det_removal counterfactual-babylm-only_random_removal counterfactual-babylm-only_measure_nps_as_singular_removal)

for model in ${models[@]}
do 
    # python src/ngram_tokenized_acceptability.py -m models/bigrams/${model} --ngram 2
    python src/ngram_tokenized_acceptability.py -m models/fourgrams/${model} --ngram 4
done