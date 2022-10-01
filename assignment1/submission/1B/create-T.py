import argparse
parser = argparse.ArgumentParser("Create input symbol table, output symbol table for F")
parser.add_argument('-words',type = str)
args = parser.parse_args()

vocab_words = open("./vocab.txt","r").read().splitlines()
words = args.words.split()
ftext = open("./T.txt","w")

def arc(pstate,nstate,word):
    ftext.write("{}\t{}\t{}\t{}\n".format(pstate,nstate,word,word))


arc(0,1,words[0])
arc(1,4,words[1])
arc(4,8,words[2])
arc(8,11,words[3])
arc(4,9,words[3])
arc(9,11,words[2])
arc(1,5,words[2])
arc(5,8,words[1])
arc(0,2,words[2])
arc(2,5,words[0])
arc(5,10,words[3])
arc(10,11,words[1])
arc(1,6,words[3])
arc(6,9,words[1])
arc(6,10,words[2])
arc(0,3,words[3])
arc(3,6,words[0])
arc(2,7,words[3])
arc(3,7,words[2])
arc(7,10,words[0])

vocab_comp = list(set(vocab_words)-set(words))
#print(vocab_comp)

for i in range(12):
    for v in vocab_comp:
        arc(i,i,v)
ftext.write("11\n")
