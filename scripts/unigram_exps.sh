#!/bin/bash

readarray -t models < <( ls models/unigrams/ ); IFS=' '

for model in ${models[@]}
do 
    python src/unigram_acceptability.py -m models/unigrams/${model}
done
