#!/bin/bash
#SBATCH -J "rhinovirus-iva"
#SBATCH -p hh
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=0
#SBATCH -C "haswell"
#SBATCH -o ../_clusterRuns/iva/out.%A
#SBATCH -e ../_clusterRuns/iva/err.%A
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
OUTDIR="../benchmark/iva/"
mkdir -p ${OUTDIR}

# work locally
cp ${READSFILE1} ${TMP}/
cp ${READSFILE2} ${TMP}/
READSFILE1=${TMP}/${DATA_BASE}_mixed_4_2_1_cov50_reads.1.fq
READSFILE2=${TMP}/${DATA_BASE}_mixed_4_2_1_cov50_reads.2.fq

# command call
#source /usr/users/aseidel1/miniconda3/etc/profile.d/conda.sh
#conda activate iva
IVA_COMMAND="iva -f ${READSFILE1} -r ${READSFILE2} -t ${SLURM_CPUS_ON_NODE} ${TMP}/iva_out"
/usr/bin/time -f "%e,%M" --output ${OUTDIR}/${DATA_BASE}.iva.time.mem.log ${IVA_COMMAND} > ${OUTDIR}/${DATA_BASE}.iva.log

# copy result back
cp -r ${TMP}/iva_out ${OUTDIR}/
cp ${OUTDIR}/iva_out/contigs.fasta ${OUTDIR}/${DATA_BASE}.iva.contigs.fa

