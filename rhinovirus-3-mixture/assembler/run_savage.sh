#!/bin/bash
#SBATCH -J "rhinovirus-savage"
#SBATCH -p hh
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=0
#SBATCH -C "haswell"
#SBATCH -o ../_clusterRuns/savage/out.%A
#SBATCH -e ../_clusterRuns/savage/err.%A
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
OUTDIR="../benchmark/savage/"
mkdir -p ${OUTDIR}

# work locally
cp ${READSFILE1} ${TMP}/
cp ${READSFILE2} ${TMP}/
READSFILE1=${TMP}/${DATA_BASE}_mixed_4_2_1_cov50_reads.1.fq
READSFILE2=${TMP}/${DATA_BASE}_mixed_4_2_1_cov50_reads.2.fq
mkdir -p ${TMP}/savage_out/

# command call
#source /usr/users/aseidel1/miniconda3/etc/profile.d/conda.sh
#conda activate haploconduct-deps
SAVAGE_COMMAND="haploconduct savage -p1 ${READSFILE1} -p2 ${READSFILE2} --revcomp -t ${SLURM_CPUS_ON_NODE} -o ${TMP}/savage_out --split 1"
/usr/bin/time -f "%e,%M" --output ${OUTDIR}/${DATA_BASE}.savage.time.mem.log ${SAVAGE_COMMAND} > ${OUTDIR}/${DATA_BASE}.savage.log

# copy result back
cp -r ${TMP}/savage_out ${OUTDIR}/
cp ${OUTDIR}/savage_out/contigs_stage_c.fasta ${OUTDIR}/${DATA_BASE}.savage.contigs_stage_c.fa

