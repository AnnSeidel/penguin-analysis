import sys, random
from Bio import SeqIO
from Bio.SeqRecord import SeqRecord

errorate=float(sys.argv[1])
readfile=sys.argv[2]
outfile=sys.argv[3]
random.seed(int(sys.argv[4])) #29072024

alphabet={'A', 'C', 'G', 'T'}
mutation_counter=0
total_counter=0
mutated_sequences=[]

linenr = 0
with open(outfile, "w") as outhandle:
    with open(readfile, "r") as inhandle:
        for linenumber, line in enumerate(inhandle):
            if linenumber%4==1:
              sequence=list(line.strip())
              for idx, base in enumerate(sequence):
                total_counter+=1
                if random.random() <= errorate:
                   sequence[idx]=random.choice(list(alphabet-{base}))
                   mutation_counter+=1
                   #print(base + " " + sequence[idx])
              outhandle.write("".join(sequence)+"\n")
            else:
              outhandle.write(line)
        

print(mutation_counter/total_counter)
