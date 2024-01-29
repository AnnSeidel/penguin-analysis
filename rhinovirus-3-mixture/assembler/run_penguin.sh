#!/bin/bash
#SBATCH -J "rhinovirus-penguin"
#SBATCH -p hh
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=0
##SBATCH -C "haswell"
#SBATCH -o ../_clusterRuns/penguin/out.%A 
#SBATCH -e ../_clusterRuns/penguin/err.%A
#SBATCH --mail-type=BEGIN,END,FAIL
set -e

DATA_BASE=rhinovirus_3 
PLASS_VERSION=7571d37

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

READSFILE1=../input/${DATA_BASE}_mixed_4_2_1_cov50_reads.1.fq
READSFILE2=../input/${DATA_BASE}_mixed_4_2_1_cov50_reads.2.fq

VERSION="plass_${PLASS_VERSION}"
OUTDIR="../benchmark/penguin_${PLASS_VERSION}_clu99/"
mkdir -p ${OUTDIR}

# work locally
cp ${READSFILE1} ${TMP}/
cp ${READSFILE2} ${TMP}/
READSFILE1=${TMP}/${DATA_BASE}_mixed_4_2_1_cov50_reads.1.fq
READSFILE2=${TMP}/${DATA_BASE}_mixed_4_2_1_cov50_reads.2.fq
mkdir -p ${TMP}/penguin_out
mkdir -p ${TMP}/penguin_tmp

# command call
PENGUIN_COMMAND="/cbscratch/annika/virus-assembly-project/software/benchmark_versions/plass_${PLASS_VERSION} guided_nuclassemble ${READSFILE1} ${READSFILE2} ${TMP}/penguin_out/${DATA_BASE}.penguin.assembly.fa ${TMP}/penguin_tmp --threads ${SLURM_CPUS_ON_NODE} --clust-min-seq-id 0.99"
/usr/bin/time -f "%e,%M" --output ${OUTDIR}/${DATA_BASE}.penguin.time.mem.log ${PENGUIN_COMMAND} > ${OUTDIR}/${DATA_BASE}.penguin.log

# copy result back and rename
cp -r ${TMP}/penguin_out ${OUTDIR}/
cp ${OUTDIR}/penguin_out/${DATA_BASE}.penguin.assembly.fa ${OUTDIR}/${DATA_BASE}.penguin.assembly.fa
cp -rL ${TMP}/penguin_tmp ${OUTDIR}/
