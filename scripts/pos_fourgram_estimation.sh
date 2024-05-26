#!/bin/bash

models/kenlm/build/bin/lmplz -o 4 -S 40% -T models/kenlm/build/tmp <../rawdata/babylm_data/babylm_100M/sents/postags.txt >models/fourgrams/babylm_postags.arpa --discount_fallback

models/kenlm/build/bin/build_binary -T models/kenlm/tmp/ -S 40% trie models/fourgrams/babylm_postags.arpa models/fourgrams/babylm_postags.binary
    
rm models/fourgrams/babylm_postags.arpa
