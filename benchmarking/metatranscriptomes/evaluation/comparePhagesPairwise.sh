#!/bin/bash

MMSEQS="/cbscratch/annika/virus-assembly-project/software/benchmark_versions/mmseqs_efacc69"

SUBDIR=clu99

MIN_SEQ_ID=99
COV=999
OUTDIR="../benchmark/summaries/${SUBDIR}/compare-${MIN_SEQ_ID}-cov${COV}"
mkdir -p "${OUTDIR}"
mkdir -p "${OUTDIR}/dbs"
mkdir -p "${OUTDIR}/pairwise"

if [ -z "${SLURM_CPUS_ON_NODE}" ]; then THREADS=""; else THREADS="--threads ${SLURM_CPUS_ON_NODE}"; fi

do_createdb(){
  FASTA_FILE=$1
  TOOL_ID=$2	
  ${MMSEQS} createdb ${FASTA_FILE} ${OUTDIR}/dbs/${TOOL_ID}.db
}

do_search(){
  TOOL1=$1
  TOOL2=$2	
  TOOL1_ID=$3
  TOOL2_ID=$4
  
  if [[ ! -f ${OUTDIR}/pairwise/${TOOL1_ID}_${TOOL2_ID}.tsv ]]; then
    if [ $MIN_SEQ_ID -eq 100 ]
      then
${MMSEQS} search ${TOOL1} ${TOOL2} ${OUTDIR}/pairwise/alignments_${TOOL1_ID}_${TOOL2_ID} ${OUTDIR}/pairwise/search_tmp_${TOOL1_ID}_${TOOL2_ID} --max-seqs 500000  -a --min-seq-id 1 --strand 2 --search-type 3 --min-aln-len 300 --max-seq-len 1000000 --remove-tmp-files 1 ${THREADS}
      else    
${MMSEQS} search ${TOOL1} ${TOOL2} ${OUTDIR}/pairwise/alignments_${TOOL1_ID}_${TOOL2_ID} ${OUTDIR}/pairwise/search_tmp_${TOOL1_ID}_${TOOL2_ID} --max-seqs 500000  -a --min-seq-id 0.${MIN_SEQ_ID} --strand 2 --search-type 3 --min-aln-len 300 --max-seq-len 1000000 --remove-tmp-files 1 ${THREADS}
     fi
    ${MMSEQS} createtsv ${TOOL1} ${TOOL2} ${OUTDIR}/pairwise/alignments_${TOOL1_ID}_${TOOL2_ID} ${OUTDIR}/pairwise/alignments_${TOOL1_ID}_${TOOL2_ID}.tsv
    count_aligned_contigs ${TOOL1}.index ${OUTDIR}/pairwise/alignments_${TOOL1_ID}_${TOOL2_ID}.tsv > ${OUTDIR}/pairwise/${TOOL1_ID}_${TOOL2_ID}.tsv
    ${MMSEQS} rmdb ${OUTDIR}/pairwise/alignments_${TOOL1_ID}_${TOOL2_ID}
    rm -rf ${OUTDIR}/pairwise/search_tmp_${TOOL1_ID}_${TOOL2_ID}
  fi
}

calc() { awk "BEGIN{print $*}";}
count_aligned_contigs(){

  INDEX=$1
  TSV=$2
  TOTALNUM=$(cat $INDEX | wc -l)
  ALIGNEDNUM=$(awk -v THR=0.${COV} 'BEGIN{group=""; len=0; count=0; cov=0} 
                  $1!=group { if(cov >= THR) { count+=1;} group=$1; len=$8; cov=$7>$6 ? ($7-$6+1)/len:($6-$7+1)/len;}{covN=$7>$6 ? ($7-$6+1)/len:($6-$7+1)/len; cov = cov > covN ? cov : covN} 
                    END{if(cov >= THR) { count+=1;}; print count }' $TSV)
  printf '%.0f\t%.0f\t%.3f\n' $TOTALNUM $ALIGNEDNUM $(calc $ALIGNEDNUM/$TOTALNUM)
}

do_pairwise_comparision(){
  TOOL1=$1
  TOOL2=$2	
  TOOL1_ID=$3
  TOOL2_ID=$4	
  do_search ${TOOL1} ${TOOL2} ${TOOL1_ID} ${TOOL2_ID}
  do_search ${TOOL2} ${TOOL1} ${TOOL2_ID} ${TOOL1_ID}
}

PENGUIN_COMPLETE_PHAGES="../benchmark/penguin_7571d37_clu99/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial.fa"
do_createdb ${PENGUIN_COMPLETE_PHAGES} "penguin"
PENGUIN_DB="${OUTDIR}/dbs/penguin.db"

MEGAHIT_COMPLETE_PHAGES="../benchmark/megahit/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial.fa"
do_createdb ${MEGAHIT_COMPLETE_PHAGES} "megahit"
MEGAHIT_DB="${OUTDIR}/dbs/megahit.db"

RNASPADES_COMPLETE_PHAGES="../benchmark/rnaspades/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial.fa"
do_createdb ${RNASPADES_COMPLETE_PHAGES} "rnaspades"
RNASPADES_DB="${OUTDIR}/dbs/rnaspades.db"

RNAVIRALSPADES_COMPLETE_PHAGES="../benchmark/rnaviralspades/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial.fa"
do_createdb ${RNAVIRALSPADES_COMPLETE_PHAGES} "rnaviralspades"
RNAVIRALSPADES_DB="${OUTDIR}/dbs/rnaviralspades.db"

METASPADES_COMPLETE_PHAGES="../benchmark/metaspades/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial.fa"
do_createdb ${METASPADES_COMPLETE_PHAGES} "metaspades"
METASPADES_DB="${OUTDIR}/dbs/metaspades.db"

METAVIRALSPADES_COMPLETE_PHAGES="../benchmark/metaviralspades/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial.fa"
do_createdb ${METAVIRALSPADES_COMPLETE_PHAGES} "metaviralspades"
METAVIRALSPADES_DB="${OUTDIR}/dbs/metaviralspades.db"

VICUNA_COMPLETE_PHAGES="../benchmark/vicuna/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial.fa"
do_createdb ${VICUNA_COMPLETE_PHAGES} "vicuna"
VICUNA_DB="${OUTDIR}/dbs/vicuna.db"

HAPLOFLOW_COMPLETE_PHAGES="../benchmark/haploflow/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial.fa"
do_createdb ${HAPLOFLOW_COMPLETE_PHAGES} "haploflow"
HAPLOFLOW_DB="${OUTDIR}/dbs/haploflow.db"

do_pairwise_comparision ${PENGUIN_DB} ${MEGAHIT_DB} "penguin" "megahit"
do_pairwise_comparision ${PENGUIN_DB} ${RNASPADES_DB} "penguin" "rnaspades"
do_pairwise_comparision ${PENGUIN_DB} ${METASPADES_DB} "penguin" "metaspades"
do_pairwise_comparision ${PENGUIN_DB} ${RNAVIRALSPADES_DB} "penguin" "rnaviralspades"
do_pairwise_comparision ${PENGUIN_DB} ${METAVIRALSPADES_DB} "penguin" "metaviralspades"
do_pairwise_comparision ${PENGUIN_DB} ${VICUNA_DB} "penguin" "vicuna"
do_pairwise_comparision ${PENGUIN_DB} ${HAPLOFLOW_DB} "penguin" "haploflow"

do_pairwise_comparision ${MEGAHIT_DB} ${RNASPADES_DB} "megahit" "rnaspades"
do_pairwise_comparision ${MEGAHIT_DB} ${RNAVIRALSPADES_DB} "megahit" "rnaviralspades"
do_pairwise_comparision ${MEGAHIT_DB} ${METASPADES_DB} "megahit" "metaspades"
do_pairwise_comparision ${MEGAHIT_DB} ${VICUNA_DB} "megahit" "vicuna"
do_pairwise_comparision ${MEGAHIT_DB} ${HAPLOFLOW_DB} "megahit" "haploflow"

do_pairwise_comparision ${RNASPADES_DB} ${METASPADES_DB} "rnaspades" "metaspades"
do_pairwise_comparision ${RNASPADES_DB} ${RNAVIRALSPADES_DB} "rnaspades" "rnaviralspades"
do_pairwise_comparision ${RNASPADES_DB} ${HAPLOFLOW_DB} "rnaspades" "haploflow"
