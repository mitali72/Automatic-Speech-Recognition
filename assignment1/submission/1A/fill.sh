#!/usr/bin/env bash

. ./path.sh || exit 1
# echo $*
python create-F.py -sentence "$*"
fstcompile --isymbols=isyms.txt --osymbols=osyms.txt F.txt F.fst
fstcompose F.fst L.fst composed.fst
fstshortestpath composed.fst out_shortest.fst
#fstprint composed.fst
#fstprint L.fst > L.txt
fstprint out_shortest.fst > out_shortest.txt 
output=$(grep -w "5005" out_shortest.txt | head -1 | awk '{print $4}')
word=$(grep -w $output words.txt | head -1 | awk '{print $1}')
echo $word

#fstprint --isymbols=isyms.txt --osymbols=words.txt F.fst text.txt 
