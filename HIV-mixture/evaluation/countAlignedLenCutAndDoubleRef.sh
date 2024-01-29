#!/bin/bash
TSV=$1

awk -v lencut=$LEN 'BEGIN{group=""; sum=""; aligned=0} 
                    $1!=group { { sum+=aligned; } group=$1; len=$8/2; aligned=$7>$6 ? $7-$6+1:$6-$7+1; aligned=aligned>len?len:aligned}{alignedN=$7>$6 ? $7-$6+1:$6-$7+1; alignedN=alignedN>len?len:alignedN; aligned = aligned > alignedN ? aligned : alignedN} 
                    END{{ sum+=aligned; }; print sum }' ${TSV} 
