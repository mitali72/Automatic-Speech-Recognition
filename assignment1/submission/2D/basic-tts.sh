#!/bin/bash

# initialization PATH
. ./path.sh  || die "path.sh expected";

for i in  exp/tri1_ali/ali.*.gz;
do ../../src/bin/ali-to-phones --ctm-output exp/tri1/final.mdl \
ark:"gunzip -c $i|" -> ${i%.gz}.ctm;
done
cat exp/tri1_ali/*.ctm > exp/tri1_ali/merged_alignment.txt

python word_ali.py

for i in {1..14}
do  
	files=()
	start_times=()
	end_times=()
	all_done=1
	for word in $1
	do
		file=$(grep -w "$word" exp/tri1_ali/sp_word$i.txt | head -1 | awk '{print $1}')
		start=$(grep -w "$word" exp/tri1_ali/sp_word$i.txt | head -1 | awk '{print $3}')
		end=$(grep -w $word exp/tri1_ali/sp_word$i.txt | head -1 | awk '{print $4}')
		files=(${files[@]} $file)
		start_times=(${start_times[@]} $start)
		end_times=(${end_times[@]} $end)
		if [[ $file == '' ]];then
			all_done=0
			break
		fi
	done
	if [[ $all_done == 1 ]];then
		break
	fi
done

i=0
for file in "${files[@]}"
do
	sox wav/$file.wav out_wav$i.wav trim ${start_times[$i]} =${end_times[$i]}
	(( i+=1 ))
done
sox $(ls out_wav*.wav | sort -n) out.wav
rm -f out_wav*.wav
