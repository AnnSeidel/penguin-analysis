#!/bin/bash

BENCHMARK_DIR="../benchmark_cutAndDoubleRef"
OUTDIR=${BENCHMARK_DIR}/compare_with_metaviralspades_penguin_clu99/
mkdir -p ${OUTDIR}

COV=(1 10 100)
declare -A TOOLS
TOOLS+=(["penguin"]="${BENCHMARK_DIR}/penguin_7571d37_clu99"
        ["megahit"]="${BENCHMARK_DIR}/megahit"
        ["metaspades"]="${BENCHMARK_DIR}/metaspades_only_assembler"
        ["rnaspades"]="${BENCHMARK_DIR}/rnaspades"
        ["rnaviralspades"]="${BENCHMARK_DIR}/rnaviralspades"
        ["savage"]="${BENCHMARK_DIR}/savage"
        ["iva"]="${BENCHMARK_DIR}/iva"
        ["vicuna"]="${BENCHMARK_DIR}/vicuna"        
        ["haploflow"]="${BENCHMARK_DIR}/haploflow")

tools=( "penguin" "megahit" "metaspades" "rnaspades" "rnaviralspades" "savage" "iva" "vicuna" "haploflow")

mkdir -p "${OUTDIR}/mmseqs_eval"
> ${OUTDIR}/mmseqs_eval/mmseqs.sensitivity_all.tsv
for cov in ${COV[@]}; do
  for key in ${tools[@]}; do
    file=(${TOOLS[$key]}/cov${cov}/mmseqs_eval_cutAndDoubleRef/HIV1_cov${cov}.*.1000.sense)
    if [[ -f ${file} ]]; then
      addInfo.sh ${file} sensitivity_all ${key} ${cov} >> ${OUTDIR}/mmseqs_eval/mmseqs.sensitivity_all.tsv
    fi
  done;
done;

> ${OUTDIR}/mmseqs_eval/mmseqs.precision.tsv
for cov in ${COV[@]}; do
  for key in ${tools[@]}; do
    file=(${TOOLS[$key]}/cov${cov}/mmseqs_eval_cutAndDoubleRef/HIV1_cov${cov}.*.1000.precision)
    if [[ -f ${file} ]]; then
      addInfo.sh ${file} precision ${key} ${cov} >> ${OUTDIR}/mmseqs_eval/mmseqs.precision.tsv
    fi
  done;
done;

> ${OUTDIR}/mmseqs_eval/mmseqs.sensitivity_largest.tsv
for cov in ${COV[@]}; do
  for key in ${tools[@]}; do
    file=(${TOOLS[$key]}/cov${cov}/mmseqs_eval_cutAndDoubleRef/HIV1_cov${cov}.*.1000.largestAlignment)
    if [[ -f ${file} ]]; then
      addInfo.sh ${file} sensitivity_largest ${key} ${cov} >> ${OUTDIR}/mmseqs_eval/mmseqs.sensitivity_largest.tsv
    fi
  done;
done;