#!/usr/bin/env bash

. ./path.sh || exit 1
python create-SymbolTable.py -vocab_file $1
arpa2fst --disambig-symbol=#0 --read-symbol-table=$PWD/words.txt $PWD/L.arpa $PWD/L.fst