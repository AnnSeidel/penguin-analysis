#!/bin/bash
#SBATCH -J "rhinovirus-megahit"
#SBATCH -p hh
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=0
#SBATCH -C "haswell"
#SBATCH -o ../_clusterRuns/megahit/out.%A
#SBATCH -e ../_clusterRuns/megahit/err.%A
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

READSFILE1=../input/${DATA_BASE}_mixed_4_2_1_cov50_reads.1.fq
READSFILE2=../input/${DATA_BASE}_mixed_4_2_1_cov50_reads.2.fq
OUTDIR="../benchmark/megahit/"
mkdir -p ${OUTDIR}

# work locally
cp ${READSFILE1} ${TMP}/
cp ${READSFILE2} ${TMP}/
READSFILE1=${TMP}/${DATA_BASE}_mixed_4_2_1_cov50_reads.1.fq
READSFILE2=${TMP}/${DATA_BASE}_mixed_4_2_1_cov50_reads.2.fq
#mkdir -p ${TMP}/megahit_out
mkdir -p ${TMP}/megahit_tmp

# command call
MEGAHIT_COMMAND="/cbscratch/annika/virus-assembly-project/software/benchmark_versions/MEGAHIT-1.2.9-Linux-x86_64-static/bin/megahit -1 ${READSFILE1} -2 ${READSFILE2} --out-dir ${TMP}/megahit_out --out-prefix ${DATA_BASE}.megahit --min-contig-len 1000 --tmp-dir ${TMP}/megahit_tmp -t ${SLURM_CPUS_ON_NODE}"
/usr/bin/time -f "%e,%M" --output ${OUTDIR}/${DATA_BASE}.megahit.time.mem.log ${MEGAHIT_COMMAND} > ${OUTDIR}/${DATA_BASE}.megahit.log

# copy result back and rename
cp -r ${TMP}/megahit_out ${OUTDIR}/
cp ${OUTDIR}/megahit_out/${DATA_BASE}.megahit.contigs.fa ${OUTDIR}/${DATA_BASE}.megahit.contigs.fa
