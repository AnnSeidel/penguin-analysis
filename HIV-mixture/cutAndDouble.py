#!~/env/python3

import sys
from Bio import SeqIO

fastafile = sys.argv[1]
alignfile = open(sys.argv[2], 'r')
outdir = sys.argv[3]

dic={}
count=0
for line in alignfile:
  splitted = line.split("\t")
  if (int(splitted[6]) < 500 and int(splitted[10]) > int(splitted[11]) - 500): # and float(splitted[2]) > 0.9):
    dic[splitted[0].split("_")[0]]=int(splitted[8])+int(splitted[9])-int(splitted[6]) 
    count+=1

print(count)


with open(outdir + "/HIV1.cut.fa", 'w') as output:
  for record in SeqIO.parse(fastafile, "fasta"):
    if record.id in dic:
      record.seq=record.seq[0:dic[record.id]]
    SeqIO.write(record, output, "fasta")

   
with open(outdir + "/HIV1.cutAndDouble.fa", 'w') as output:  
  for record in SeqIO.parse(fastafile, "fasta"):
    if record.id in dic:
      record.seq=record.seq[0:dic[record.id]]
    record.seq+=record.seq
    SeqIO.write(record, output, "fasta")

