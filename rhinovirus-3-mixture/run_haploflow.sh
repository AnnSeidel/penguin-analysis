#!/bin/bash
#SBATCH -J "rhinovirus-haploflow"
#SBATCH -p em
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=0
#SBATCH -C "haswell"
#SBATCH -o _clusterRuns/haploflow/out.%A 
#SBATCH -e _clusterRuns/haploflow/err.%A
#SBATCH --mail-type=BEGIN,END,FAIL
set -e

DATA_BASE=rhinovirus_3 

id=$RANDOM

if [ "$(nproc --all)" = "16" ]
then
  TMP=/local/${id}
else
  i=$(( ( RANDOM % 2 ) ))
  TMP=/nvme/n0${i}/${id}
fi
mkdir -p ${TMP}

function finish {
        rm -rf ${TMP}
}
trap finish EXIT

READSFILE1=input/${DATA_BASE}_mixed_4_2_1_cov50_reads.1.fq
READSFILE2=input/${DATA_BASE}_mixed_4_2_1_cov50_reads.2.fq
OUTDIR="benchmark/haploflow_default/"
mkdir -p ${OUTDIR}

# work locally, haploflow takes single fastq file
cat ${READSFILE1} ${READSFILE2} > ${TMP}/reads.fq
mkdir -p ${TMP}/haploflow_out/

# command call
# source /usr/users/aseidel1/miniconda3/etc/profile.d/conda.sh
# conda activate haploflow
HAPLOFLOW_COMMAND="haploflow --read-file ${TMP}/reads.fq --out ${TMP}/haploflow_out --filter 1000"
/usr/bin/time -f "%e,%M" --output ${OUTDIR}/${DATA_BASE}.haploflow.time.mem.log ${HAPLOFLOW_COMMAND} > ${OUTDIR}/${DATA_BASE}.haploflow.log

# copy result back
cp -r ${TMP}/haploflow_out ${OUTDIR}/
cp ${OUTDIR}/haploflow_out/contigs.fa ${OUTDIR}/${DATA_BASE}.haploflow.contigs.fa

