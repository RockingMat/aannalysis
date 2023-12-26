#!/bin/bash

# readarray -t models < <( ls models/unigrams/ ); IFS=' '

# for model in ${models[@]}
# do 
#     python src/ngram_tokenized_acceptability.py -m models/unigrams/${model} --unigram
# done


readarray -t models < <( ls models/bigrams/ ); IFS=' '

for model in ${models[@]}
do 
    python src/ngram_tokenized_acceptability.py -m models/bigrams/${model}
done