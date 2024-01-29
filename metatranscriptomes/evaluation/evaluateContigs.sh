#!/bin/bash

CONTIGS_OF_INTEREST=$1
PROTEIN_UNIQUE_HITS=$2 #${TMP}/proteins.uniqueHits.tsv
RESULT=$3
MIN_SEQ_ID=${4:-0.97}

MMSEQS="/cbscratch/annika/virus-assembly-project/software/benchmark_versions/mmseqs_efacc69"
TMP="${RESULT}/detection_tmp"
mkdir -p "${RESULT}"
mkdir -p "${TMP}"

if [ -z "${SLURM_CPUS_ON_NODE}" ]; then THREADS=""; else THREADS="--threads ${SLURM_CPUS_ON_NODE}"; fi

${MMSEQS} createdb ${CONTIGS_OF_INTEREST} ${TMP}/contigs.ofInterest
${MMSEQS} cluster ${TMP}/contigs.ofInterest ${TMP}/cluster ${TMP}/clusterTmp -c 0.99 --cov-mode 1 --min-seq-id ${MIN_SEQ_ID} --max-seqs 50000 --diag-score 1 --zdrop 200 ${THREADS}
${MMSEQS} result2repseq ${TMP}/contigs.ofInterest ${TMP}/cluster ${TMP}/cluster_repseq
${MMSEQS} rmdb ${TMP}/cluster
#rm -rf ${TMP}/clusterTmp
${MMSEQS} result2flat ${TMP}/contigs.ofInterest ${TMP}/contigs.ofInterest ${TMP}/cluster_repseq ${TMP}/cluster_repseq.fa --use-fasta-header

awk 'BEGIN {RS = ">"} NR>1 {print $1} ' ${TMP}/cluster_repseq.fa > ${TMP}/contigs.ofInterest.nonRedundant.list

# non-redundant contigs >=750bp
awk 'NR==FNR {if ($7>=750){X[$6]}; next; }; $1 in X { print $0 }' ${PROTEIN_UNIQUE_HITS} ${TMP}/contigs.ofInterest.nonRedundant.list > ${TMP}/contigs.ofInterest.nonRedundant.minLen750.list

awk ' FNR==NR { X[$1]; next} $6 in X {print $0 } ' ${TMP}/contigs.ofInterest.nonRedundant.minLen750.list ${PROTEIN_UNIQUE_HITS} > ${TMP}/proteins.uniqueHits.filtered.tsv

# partial genomes encoding at least 2 protein hits
awk '{X[$6]++;if($8 ~ /RdRp/){R[$6]++} else if($8 ~ /CP/){C[$6]++} else if ($8 ~ /MP/){M[$6]++}} END { for (a in X){if(((R[a]>0)+(M[a]>0)+(C[a]>0))>1){print a}}}' ${TMP}/proteins.uniqueHits.filtered.tsv > ${RESULT}/contigsEncodingAtLeast2phageProteins.list


# near-complete genomes with 3 protein hits
#awk '{ X[$6]++ } END { for (a in X){ if (X[a]>2){print a}}}' ${TMP}/proteins.uniqueHits_encodedBy_contigs.ofInterest.nonRedundant.minLen750.tsv > ${TMP}/nearcompleteGenomes.list
awk '{X[$6]++;if($8 ~ /RdRp/){R[$6]++} else if($8 ~ /CP/){C[$6]++} else if ($8 ~ /MP/){M[$6]++}} END { for (a in X){if(((R[a]>0)+(M[a]>0)+(C[a]>0))>2){print a}}}' ${TMP}/proteins.uniqueHits.filtered.tsv > ${RESULT}/contigsEncoding3phageProteins.list

# complete genomes with 3 protein hits without edge proteins
awk '{if ($5 ~ 1){next}; X[$6]++;if($8 ~ /RdRp/){R[$6]++} else if($8 ~ /CP/){C[$6]++} else if ($8 ~ /MP/){M[$6]++}} END { for (a in X){if(((R[a]>0)+(M[a]>0)+(C[a]>0))>2){print a}}}' ${TMP}/proteins.uniqueHits.filtered.tsv > ${RESULT}/contigsEncoding3phageProteinsNoPartial.list
if [[ ( -s ${CONTIGS_OF_INTEREST} ) && ( -s ${RESULT}/contigsEncoding3phageProteinsNoPartial.list )]];then
  seqkit grep -f ${RESULT}/contigsEncoding3phageProteinsNoPartial.list ${CONTIGS_OF_INTEREST} > ${RESULT}/contigsEncoding3phageProteinsNoPartial.fa
else
  touch ${RESULT}/contigsEncoding3phageProteinsNoPartial.fa
fi
