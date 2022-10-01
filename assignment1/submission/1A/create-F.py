import argparse
parser = argparse.ArgumentParser("Create input symbol table, output symbol table for F")
parser.add_argument('-sentence',type = str)
args = parser.parse_args()

vocab_words = open("./vocab.txt","r").read().splitlines()

words = args.sentence.split()
fLfst_sym_table = open("./words.txt","r").read().splitlines()
Lsym={line.split()[0]:line.split()[1] for line in fLfst_sym_table}
fisyms = open("./isyms.txt","w")
fosyms = open("./osyms.txt","w")
ftext = open("./F.txt","w")
fisyms.write("<eps>\t0\n")
fosyms.write("<eps>\t0\n")
fisyms.write("<s>\t{}\n".format(Lsym["<s>"]))
fisyms.write("</s>\t{}\n".format(Lsym["</s>"]))
ftext.write("{}\t{}\t{}\t{}\n".format(0,0,"<s>","<eps>"))
pstate = 0
nstate = 1
out_sym_dict = set()
inp_sym_dict = set()
out_sym_dict.add("<eps>")
inp_sym_dict.add("<eps>")
for word in words:
    if word == "XXX":
        
        fisyms.write(word+"\t"+str(len(Lsym))+"\n")
        for vocab_word in vocab_words:
            
            if vocab_word not in out_sym_dict: 
                out_sym_dict.add(vocab_word)
                fosyms.write(vocab_word+"\t"+Lsym[vocab_word]+"\n")

            ftext.write("{}\t{}\t{}\t{}\n".format(pstate,nstate,word,vocab_word))
            nstate+=1

    else:
        if (nstate - pstate) != 1:
            for s in range(pstate+1,nstate):
                ftext.write("{}\t{}\t{}\t{}\n".format(s,nstate,word,word))
            pstate = nstate
            nstate +=1 
        else:
            ftext.write("{}\t{}\t{}\t{}\n".format(pstate,nstate,word,word))
            pstate+=1
            nstate+=1

        # print(word,Lsym[word])
        if word not in inp_sym_dict: 
            inp_sym_dict.add(word)
            fisyms.write(word+"\t"+Lsym[word]+"\n")

        if word not in out_sym_dict: 
            out_sym_dict.add(word)
            fosyms.write(word+"\t"+Lsym[word]+"\n")
word="<eps>"
if (nstate - pstate) != 1:
    for s in range(pstate+1,nstate):
        ftext.write("{}\t{}\t{}\t{}\n".format(s,nstate,word,word))
    pstate = nstate
    nstate +=1

ftext.write("{}\t{}\t{}\t{}\n".format(pstate,pstate,"</s>","<eps>"))
ftext.write(str(pstate)+"\n")
            