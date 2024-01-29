#!/bin/bash
#SBATCH -J "phagedetection-sludgeMetaT"
#SBATCH -p hh
#SBATCH -t 01-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH -o ../_clusterRuns/out.%j 
#SBATCH -e ../_clusterRuns/err.%j
#SBATCH --mail-type=BEGIN,END,FAIL

set -e

################ COMBINE CONTIGS OF INTEREST + DETECTION ###############################

do_total_detection(){
  BASEDIR=$1
  mkdir -p ${BASEDIR}/detection_all/clu99/
  if [ ! -f ${BASEDIR}/detection_all/clu99/contigs.ofInterest.fa ]; then
    while read SAMPLE; do
      if [[ -f ${BASEDIR}/detection_${SAMPLE}/contigs.ofInterest.fa ]];then
      cat ${BASEDIR}/detection_${SAMPLE}/contigs.ofInterest.fa >> ${BASEDIR}/detection_all/clu99/contigs.ofInterest.fa
      cat ${BASEDIR}/detection_${SAMPLE}/protein.uniqueHits.tsv >> ${BASEDIR}/detection_all/clu99/proteins.uniqueHits.tsv
      else
        echo ${BASEDIR}/detection_${SAMPLE}/contigs.ofInterest.fa "Not found"
      fi
    done < samples/sra_sample_list
  fi

  if [[ ! -f ${BASEDIR}/detection_all/clu99/contigsEncoding3phageProteinsNoPartial.list ]];then
    ./evaluateContigs.sh ${BASEDIR}/detection_all/clu99/contigs.ofInterest.fa ${BASEDIR}/detection_all/clu99/proteins.uniqueHits.tsv ${BASEDIR}/detection_all/clu99 0.99
  fi
  if [[ ! -f ${BASEDIR}/detection_all/clu99/contigsEncoding3phageProteinsNoPartial.fa ]];then
    if [[ -s ${BASEDIR}/detection_all/clu99/contigsEncoding3phageProteinsNoPartial.list ]];then
      seqkit grep -f ${BASEDIR}/detection_all/clu99/contigsEncoding3phageProteinsNoPartial.list \
                     ${BASEDIR}/detection_all/clu99/contigs.ofInterest.fa \
                     > ${BASEDIR}/detection_all/clu99/contigsEncoding3phageProteinsNoPartial.fa
    else
      touch ${BASEDIR}/detection_all/clu99/contigsEncoding3phageProteinsNoPartial.fa
    fi
  fi
}



BASEDIR=../benchmark/rnaspades
do_total_detection ${BASEDIR}
BASEDIR=../benchmark/rnaviralspades
do_total_detection ${BASEDIR}
BASEDIR=../benchmark/metaspades
do_total_detection ${BASEDIR}
BASEDIR=../benchmark/metaviralspades
do_total_detection ${BASEDIR}
BASEDIR=../benchmark/megahit
do_total_detection ${BASEDIR}
BASEDIR=../benchmark/haploflow
do_total_detection ${BASEDIR}
BASEDIR=../benchmark/penguin_7571d37_clu99
do_total_detection ${BASEDIR}
BASEDIR=../benchmark/vicuna
do_total_detection ${BASEDIR}
