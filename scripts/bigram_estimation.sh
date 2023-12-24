#!/bin/bash

readarray -t models < <( ls models/tokenized/ ); IFS=' '

for model in ${models[@]}
do
    models/kenlm/build/bin/lmplz -o 4 -S 40% -T models/kenlm/build/tmp <models/tokenized/${model} >models/kenlm-trained/${model}.arpa
    
    models/kenlm/build/bin/build_binary -T models/kenlm/tmp/ -S 40% trie models/kenlm-trained/${model}.arpa models/kenlm-trained/${model}.binary
    
    rm models/kenlm-trained/${model}.arpa
done