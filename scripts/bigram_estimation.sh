#!/bin/bash

readarray -t models < <( ls models/tokenized/ ); IFS=' '

for model in ${models[@]}
do
    models/kenlm/build/bin/lmplz -o 2 -S 40% -T models/kenlm/build/tmp <models/tokenized/${model} >models/bigrams/${model}.arpa
    
    models/kenlm/build/bin/build_binary -T models/kenlm/tmp/ -S 40% trie models/bigrams/${model}.arpa models/bigrams/${model}.binary
    
    rm models/bigrams/${model}.arpa
done
