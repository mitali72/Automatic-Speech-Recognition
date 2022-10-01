#!/usr/bin/python
file= open('exp/tri1_ali/phones.txt', "r") 
words={}
for line in file:
    x=line.split()
    words[x[1]]=x[0]
file.close()

file= open('exp/tri1_ali/merged_alignment.txt', "r") 
lines = file.readlines()
for i in range(len(lines)):
    x=lines[i].split()
    x[-1]=words[x[-1]]
    lines[i]=' '.join(x)+'\n'
file= open('exp/tri1_ali/phone_alignment.txt', "w") 
file.writelines(lines)
file.close()

file= open('exp/tri1_ali/phone_alignment.txt', "r") 
lines = file.readlines()
sp=1
old_sp=(lines[0].split())[0]
old_sp=old_sp.split("_")[1]
f = open("exp/tri1_ali/sp"+str(sp)+".txt", "w")
for i in range(len(lines)):
    x=lines[i].split()
    if(x[0].split("_")[1]!=old_sp):
        f.close()
        sp+=1
        old_sp=x[0].split("_")[1]
        f = open("exp/tri1_ali/sp"+str(sp)+".txt", "w")
    new_line=' '.join(x)+'\n'
    f.write(new_line)
f.close()
file.close()

f=open("lang/lexicon.txt", 'r')
word_phone_dic={}
for line in f:
    x=line.split()
    word=x[0]
    phone_seq=' '.join(x[1:])
    word_phone_dic[phone_seq]=word

phone_seq=[]
for i in range(1,15):
    f = open("exp/tri1_ali/sp"+str(i)+".txt", 'r')
    file=open("exp/tri1_ali/sp_word"+str(i)+".txt", 'w')
    for line in f:
        x=line.split()
        phone=x[-1]
        if phone == "SIL":
            continue
        phone=phone.split("_")
        phon=phone[0]
        pos=phone[1]
        if phon=="SIL":
                continue
        if pos == "B":
            start=x[2]
            phone_seq.append(phon)
        elif pos == "S":
            start=x[2]
            end=str(float(x[3])+float(start))
            phone_seq.append(phon)
            word=word_phone_dic[' '.join(phone_seq)]
            file.write(x[0] + ' ' + word + ' ' + str(start) + ' ' + str(end)+'\n')
            phone_seq=[]
        elif pos == "E":
            end=str(float(x[2])+float(x[3]))
            phone_seq.append(phon)
            word=word_phone_dic[' '.join(phone_seq)]
            file.write(x[0] + ' ' + word + ' ' + str(start) + ' ' + str(end)+'\n')
            phone_seq=[]
        elif pos == "I":
            phone_seq.append(phon)
    file.close()
    f.close()
