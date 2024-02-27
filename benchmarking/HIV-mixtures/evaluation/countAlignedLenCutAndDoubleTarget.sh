#!/bin/bash
TSV=$1

awk 'BEGIN{group=""; len=0; sum=""; aligned=0} 
                    $1!=group { { sum+=aligned; } group=$1; len=$11/2; aligned=$7>$6 ? $7-$6+1:$6-$7+1; aligned=aligned>len?len:aligned}{alignedN=$7>$6 ? $7-$6+1:$6-$7+1; alignedN=alignedN>len?len:alignedN; aligned = aligned > alignedN ? aligned : alignedN} 
                    END{{ sum+=aligned; }; print sum }' ${TSV} 
