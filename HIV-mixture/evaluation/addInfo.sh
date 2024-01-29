#!/bin/bash

awk -v metric=$2 -v tool=$3 -v coverage=$4 'BEGIN{i=90}{print metric"\t"tool"\t"coverage"\t"i"\t"$0; i+=1}' ${1}
