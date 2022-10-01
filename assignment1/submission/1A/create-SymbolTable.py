import argparse
import argparse
parser = argparse.ArgumentParser("Create input symbol table")
parser.add_argument('-vocab_file',type = str)
args = parser.parse_args()

vocab = open(args.vocab_file,"r").read().splitlines()
fwords = open("./words.txt","w")

fwords.write("<eps>\t0\n")
fwords.write("<unk>\t1\n")
i = 2
for word in vocab:
    fwords.write(word + "\t" + str(i) + "\n")
    i += 1

fwords.write("<s>\t" + str(i) + "\n")
i+=1
fwords.write("</s>\t" + str(i) + "\n")
i+=1
fwords.write("#0\t" + str(i) + "\n")
