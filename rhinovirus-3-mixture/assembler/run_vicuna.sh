#!/bin/bash
#SBATCH -J "rhinovirus-vicuna"
#SBATCH -p hh
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=0
#SBATCH -C "haswell"
#SBATCH -o _clusterRuns/vicuna/out.%A
#SBATCH -e _clusterRuns/vicuna/err.%A
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
OUTDIR="benchmark/vicuna/"
mkdir -p ${OUTDIR}
CURRDIR=$(pwd)

# work locally
mkdir -p ${TMP}/reads/
cp ${READSFILE1} ${TMP}/reads/
cp ${READSFILE2} ${TMP}/reads/

mkdir -p ${TMP}/vicuna_out/
cd ${TMP}

# command call
export OMP_NUM_THREADS=${SLURM_CPUS_ON_NODE}
VICUNA_COMMAND="/cbscratch/annika/virus-assembly-project/software/benchmark_versions/VICUNA_v1.3/executable/vicuna-omp.static.linux64 /cbscratch/annika/virus-assembly-project/software/benchmark_versions/VICUNA_v1.3/config/vicuna_config.txt"
/usr/bin/time -f "%e,%M" --output ${CURRDIR}/${OUTDIR}/${DATA_BASE}.vicuna.time.mem.log ${VICUNA_COMMAND} > ${CURRDIR}/${OUTDIR}/${DATA_BASE}.vicuna.log
cd ${CURRDIR}

# copy result back
cp -r ${TMP}/vicuna_out ${OUTDIR}/
cp ${OUTDIR}/vicuna_out/contig.fasta ${OUTDIR}/${DATA_BASE}.vicuna.contig.fa
