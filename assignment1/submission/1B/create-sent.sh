#!/usr/bin/env bash

. ./path.sh || exit 1
python create-T.py -words "$*"
fstcompile --isymbols=words.txt --osymbols=words.txt T.txt T.fst
# echo "T.fst generated"
fstcompose T.fst L.fst composed.fst
# echo "composed.fst generated"
fstshortestpath composed.fst out_shortest.fst
# echo "out_shortest.fst generated"
fstprint out_shortest.fst > out_shortest.txt 
# fstdraw --isymbols=words.txt --osymbols=words.txt -portrait out_shortest.fst | dot -Tjpg > out.jpg

n=$(sed -n '$=' out_shortest.txt)
output=$(awk '{if(NR==1) print $3}' out_shortest.txt)
word=$(grep -w $output words.txt | head -1 | awk '{print $1}')
sent=(${sent[@]} $word)

for ((i=n; i>=3; i--));do  
	output=$(sed -n ${i}p out_shortest.txt | awk '{print $3}')
	word=$(grep -w $output words.txt | head -1 | awk '{print $1}')
	sent=(${sent[@]} $word)
done
echo ${sent[*]}
