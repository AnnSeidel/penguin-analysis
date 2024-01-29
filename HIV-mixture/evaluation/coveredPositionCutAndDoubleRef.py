#!/bin/env python

import numpy as np
import sys

genomes = {}
lenCutOff = int(sys.argv[2])
with open(sys.argv[1], "r") as tsvfile:
    for line in tsvfile:
        line = line.strip()
        if not line:
            continue
        splitted = line.split()
        #print(splitted)
        genomeID = splitted[0]
        genomeLen = int(int(splitted[7])/2)
        genomeStart = int(splitted[5])
        genomeEnd = int(splitted[6])
        contigLen = int(splitted[10])
        if contigLen < lenCutOff:
            continue
        if genomeStart> genomeEnd:
            #reverse
            tmp = genomeStart
            genomeStart = genomeEnd
            genomeEnd = tmp
        if not genomeID in genomes:
            genomes[genomeID] = np.zeros(genomeLen)
        #print(genomeStart)
        #print(genomeEnd)
        if genomeEnd >= genomeLen and genomeStart < genomeLen:
          genomes[genomeID][genomeStart:genomeLen] = 1
          genomes[genomeID][0:genomeEnd-genomeLen+1] = 1
        elif genomeEnd > genomeLen and genomeStart > genomeLen:
          genomes[genomeID][genomeStart-genomeLen:genomeEnd+1-genomeLen] = 1
        else:
          genomes[genomeID][genomeStart:genomeEnd+1] = 1
        #print(np.sum(genomes[genomeID]))

coveredPos = [np.sum(genomes[genomeID]) for genomeID in genomes]
print(int(np.sum(coveredPos)))
