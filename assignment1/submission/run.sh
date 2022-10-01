#!/bin/bash

# This script trains + decodes a baseline ASR system for Wolof.

# initialization PATH
. ./path.sh  || die "path.sh expected";
# initialization commands
. ./cmd.sh

[ ! -L "steps" ] && ln -s ../wsj/s5/steps

[ ! -L "utils" ] && ln -s ../wsj/s5/utils

###############################################################
#                   Configuring the ASR pipeline
###############################################################
stage=0    # from which stage should this script start
nj=8        # number of parallel jobs to run during training
test_nj=2    # number of parallel jobs to run during decoding
# the above two parameters are bounded by the number of speakers in each set
###############################################################

# Stage 1: Prepares the train/dev data. Prepares the dictionary and the
# language model.
if [ $stage -le 1 ]; then
  echo "Preparing lexicon and language models"
  local/prepare_lexicon.sh
  local/prepare_lm.sh
fi
> lang/dict/silence_phones.txt

echo "********************************************************"
echo "data preparation done"
echo "********************************************************"

# Feature extraction
# Stage 2: MFCC feature extraction + mean-variance normalization
if [ $stage -le 2 ]; then
   for x in train dev test; do
      steps/make_mfcc.sh --nj 8 --cmd "$train_cmd" data/$x exp/make_mfcc/$x mfcc
      steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
   done
fi

echo "********************************************************"
echo "feature extraction done"
echo "********************************************************"

# Stage 3: Training and decoding monophone acoustic models
if [ $stage -le 3 ]; then
  ### Monophone
    echo "Monophone training"
  steps/train_mono.sh --nj "$nj" --cmd "$train_cmd" data/train lang exp/mono
    echo "Monophone training done"
    (
    echo "Decoding the test set"
    utils/mkgraph.sh lang exp/mono exp/mono/graph
  
    # This decode command will need to be modified when you 
    # want to use tied-state triphone models 
    steps/decode.sh --nj $test_nj --cmd "$decode_cmd" \
      exp/mono/graph data/test exp/mono/decode_test
    echo "Monophone decoding done."
    ) &
fi

echo "********************************************************"
echo "training and decoding of monophones done"
echo "********************************************************"

# Stage 4: Training tied-state triphone acoustic models
if [ $stage -le 4 ]; then
  ### Triphone
    echo "Triphone training"
    steps/align_si.sh --nj $nj --cmd "$train_cmd" \
      data/train lang exp/mono exp/mono_ali
  steps/train_deltas.sh --boost-silence 1.25  --cmd "$train_cmd"  \
    1500 30000 data/train lang exp/mono_ali exp/tri1
    echo "Triphone training done"
  # Add triphone decoding steps here #
  (
    echo "Decoding the test set"
    utils/mkgraph.sh lang exp/tri1 exp/tri1/graph

    # This decode command will need to be modified when you 
    # want to use tied-state triphone models 
    steps/decode.sh --nj $test_nj --cmd "$decode_cmd" \
      exp/tri1/graph data/test exp/tri1/decode_test
    echo "Triphone decoding done."
  ) &
fi

echo "********************************************************"
echo "training and decoding of triphones done"
echo "********************************************************"

# Stage 5: Augmentation
if [ $stage -le 5 ]; then
  echo "Perform augmentation"
  echo "Preparing lexicon and language models"
  # local/prepare_lexicon.sh
  # local/prepare_lm.sh

  utils/data/perturb_data_dir_speed_3way.sh data/train data/train_sp3

  for x in train_sp3 dev test; do
      steps/make_mfcc.sh --nj 8 --cmd "$train_cmd" data/$x exp/make_mfcc/$x mfcc
      steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
  done

  ### Monophone training after augmentation
  echo "Monophone training"
  steps/train_mono.sh --nj "$nj" --cmd "$train_cmd" data/train_sp3 lang exp/mono
    echo "Monophone training done"
    (
    echo "Decoding the test set"
    utils/mkgraph.sh lang exp/mono exp/mono/graph
  
    # This decode command will need to be modified when you 
    # want to use tied-state triphone models 
    steps/decode.sh --nj $test_nj --cmd "$decode_cmd" \
      exp/mono/graph data/dev exp/mono/decode_dev
    echo "Monophone decoding done."
    ) &

  ### Triphone training after augmentation
    echo "Triphone training after augmentation"
    steps/align_si.sh --nj $nj --cmd "$train_cmd" \
      data/train_sp3 lang exp/mono exp/mono_ali
  steps/train_deltas.sh --boost-silence 1.25  --cmd "$train_cmd"  \
    1500 30000 data/train_sp3 lang exp/mono_ali exp/tri1
    echo "Triphone training done"
  # Add triphone decoding steps here #
  (
    echo "Decoding the test set"
    utils/mkgraph.sh lang exp/tri1 exp/tri1/graph

    # This decode command will need to be modified when you 
    # want to use tied-state triphone models 
    steps/decode.sh --nj $test_nj --cmd "$decode_cmd" \
      exp/tri1/graph data/dev exp/tri1/decode_dev
    echo "Triphone decoding done."
  ) &
fi

echo "********************************************************"
echo "training and decoding on augmented data done"
echo "********************************************************"

if [ $stage -le 6 ]; then
  echo "Perform augmentation"
  echo "Preparing lexicon and language models"
  > lang/dict/silence_phones.txt
  local/prepare_lexicon.sh
  local/prepare_lm.sh

  utils/data/perturb_data_dir_speed_3way.sh data/train data/train_sp3

  for x in train_sp3 dev test; do
      steps/make_mfcc.sh --nj 8 --cmd "$train_cmd" data/$x exp/make_mfcc/$x mfcc
      steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
  done

  ### Monophone training after augmentation
  echo "Monophone training"
  steps/train_mono.sh --nj "$nj" --cmd "$train_cmd" data/train_sp3 lang exp/mono
    echo "Monophone training done"

  ### Triphone training after augmentation
  echo "Triphone training after augmentation"
  steps/align_si.sh --nj $nj --cmd "$train_cmd" \
    data/train_sp3 lang exp/mono exp/mono_ali

  steps/train_deltas.sh --boost-silence 1.25  --cmd "$train_cmd"  \
    1500 30000 data/train_sp3 lang exp/mono_ali exp/tri1
    echo "train deltas done"

  steps/align_si.sh --nj $nj --cmd "$train_cmd" \
    data/train_sp3 lang exp/tri1 exp/tri1_ali

  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    2000 30000 data/train_sp3 lang exp/tri1_ali exp/tri2

  echo "train lda mltt done"
  (
    echo "Decoding the test set after lda mltt training"
    utils/mkgraph.sh lang exp/tri2 exp/tri2/graph

    # This decode command will need to be modified when you 
    # want to use tied-state triphone models 
    steps/decode.sh --nj $test_nj --cmd "$decode_cmd" \
      exp/tri2/graph data/dev exp/tri2/decode_dev
    steps/decode.sh --nj $test_nj --cmd "$decode_cmd" \
      exp/tri2/graph data/test exp/tri2/decode_test
    echo "Decoding the test set after lda mltt training done."
  ) &

  echo "align flmrr"

  steps/align_fmllr.sh  --nj $nj --cmd "$train_cmd" \
    data/train_sp3 lang exp/tri2 exp/tri2_ali

  echo "train sat"

  steps/train_sat.sh  --cmd "$train_cmd" \
    2000 30000 data/train_sp3 lang exp/tri2_ali exp/tri3
  # Add triphone decoding steps here #
  (
    echo "Decoding the test set after sat training"
    utils/mkgraph.sh lang exp/tri3 exp/tri3/graph

    # This decode command will need to be modified when you 
    # want to use tied-state triphone models 
    steps/decode.sh --nj $test_nj --cmd "$decode_cmd" \
      exp/tri3/graph data/dev exp/tri3/decode_dev
    steps/decode.sh --nj $test_nj --cmd "$decode_cmd" \
      exp/tri3/graph data/test exp/tri3/decode_test
    echo "Decoding the test set after sat training done"
    echo "Triphone decoding done."
  ) &
fi
wait;
#score
# Computing the best WERs
for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done