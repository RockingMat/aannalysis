#!/bin/bash

DATASET=$1
SUFFIX=$2 # -indef_removal
LR=$3
SEED=$4

MODEL_NAME=smolm-autoreg-bpe-$SUFFIX-$LR

python src/tokenizer_and_config.py -m $MODEL_NAME \
    --bpe \
    --attention_heads 12 \
    --layers 12 \
    --hidden_size 768 \
    --intermediate_size 3072 \
    --vocab 16384 \
    --max_len 258 \
    --train_file $DATASET \
    --from_iterator

# warning: this will upload to your huggingface account (as long as you have the token set up)
# else, it will error out; just omit --push_to_hub if you do not want this.

python src/train_autoreg.py \
    --config_name models/$MODEL_NAME \
    --tokenizer_name models/$MODEL_NAME \
    --per_device_train_batch_size 32 \
    --per_device_eval_batch_size 64 \
    --do_train \
    --do_eval \
    --dataset_name $DATASET \
    --evaluation_strategy epoch \
    --output_dir models/$MODEL_NAME \
    --overwrite_output_dir \
    --learning_rate $LR \
    --save_total_limit 1 \
    --block_size 258 \
    --num_train_epochs 20 \
    --save_steps 5000 \
    --logging_steps 1000 \
    --add_prefix_space \
    --warmup_steps 32000 \
    --seed $SEED \
    --fp16 \
    --push_to_hub \
    --hub_model_id $MODEL_NAME