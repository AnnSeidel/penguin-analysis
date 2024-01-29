#!/bin/bash

# exit when any command fails
set -e

PRODIGAL="/cbscratch/annika/virus-assembly-project/software/benchmark_versions/prodigal_v2.6.3"
HMMSCAN="/cbscratch/annika/virus-assembly-project/software/benchmark_versions/hmmscan_3.2.1"
HMMMODEL="/cbscratch/annika/virus-assembly-project/sludgeMetaT/hmm/hmm_m5-mc"

ASSEMBLY=$1
RESULT=$2

TMP="${RESULT}/detection_tmp"
BASENAME=$(basename $ASSEMBLY)
PROTEINS=${BASENAME}.proteins.fa
HMMOUT=${BASENAME}.hmmscan.tsv

mkdir -p "${RESULT}"
mkdir -p "${TMP}"

bioawk -c fastx '{print $name"\t"length($seq)}' ${ASSEMBLY} > ${TMP}/contig_lengths.tsv

if [ ! -f ${TMP}/${PROTEINS} ];then
  ${PRODIGAL} -p meta -n -i ${ASSEMBLY} -a ${TMP}/${PROTEINS} -o /dev/null
fi

# protId startCoord endCoord Strand partial contigId
awk 'BEGIN {RS = ">" ;} NR>1 { contigId=$1;gsub(/_[0-9]+$/,"", contigId);  match($0, /partial=([0-1]+)/); p=substr($0, RSTART + 8, 2); print $1"\t"$3"\t"$5"\t"$7"\t"p"\t"contigId} ' ${TMP}/${PROTEINS} > ${TMP}/prodigal.tsv

# protId startCoord endCoord Strand partial contigId contigLen
awk ' NR == FNR { X[$1] = $2; next } {print $0"\t"X[$6]}' ${TMP}/contig_lengths.tsv ${TMP}/prodigal.tsv > ${TMP}/proteins_contigs.tsv

if [ ! -f ${TMP}/${HMMOUT} ];then
  ${HMMSCAN} --cpu ${SLURM_CPUS_ON_NODE} --tblout ${TMP}/${HMMOUT} $HMMMODEL ${TMP}/${PROTEINS}
fi

## protId protein score
awk ' /^#/ { next }  { print $3"\t"$1"\t"$6} ' ${TMP}/${HMMOUT} > ${TMP}/proteinHits.tsv
## unique protein ID hits with HMM score >=30
## protId startCoord endCoord Strand partial contigId contigLen protein score
awk ' NR == FNR {if ($3 >=30 && (!X[$1] || $3>X[$1])){X[$1]=$3;Y[$1]=$2}; next} $1 in Y { print $0"\t"Y[$1]"\t"X[$1]} ' ${TMP}/proteinHits.tsv ${TMP}/proteins_contigs.tsv > ${RESULT}/protein.uniqueHits.tsv

awk '{X[$6]++} END { for (key in X) { print key } }' ${RESULT}/protein.uniqueHits.tsv > ${RESULT}/contigs.ofInterest.list

bioawk -c fastx -v file="${RESULT}/contigs.ofInterest.list" 'BEGIN{while((getline k < file)>0)i[k]=1}{if(i[$name])print ">"$name"\n"$seq}' ${ASSEMBLY} > ${RESULT}/contigs.ofInterest.fa


