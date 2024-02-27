#!/bin/bash
#SBATCH -J "HIV1-vicuna"
#SBATCH -p em
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=0
#SBATCH -C "haswell"
#SBATCH -o ../_clusterRuns/vicuna/out.%A.%a 
#SBATCH -e ../_clusterRuns/vicuna/err.%A.%a
#SBATCH --array=1-3
#SBATCH --mail-type=BEGIN,END,FAIL
set -e

DATA_BASE=HIV1 

id=$RANDOM
COV=$(sed "${SLURM_ARRAY_TASK_ID}q;d" cov_list)

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

READSFILE1=../input/${DATA_BASE}.cutAndDouble_cov${COV}_reads.1.fq
READSFILE2=../input/${DATA_BASE}.cutAndDouble_cov${COV}_reads.2.fq
OUTDIR="../benchmark_cutAndDoubleRef/vicuna/cov${COV}"
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
/usr/bin/time -f "%e,%M" --output ${CURRDIR}/${OUTDIR}/${DATA_BASE}_cov${COV}.vicuna.time.mem.log ${VICUNA_COMMAND} > ${CURRDIR}/${OUTDIR}/${DATA_BASE}_cov${COV}.vicuna.log
cd ${CURRDIR}

# copy result back
cp -r ${TMP}/vicuna_out ${OUTDIR}/
cp ${OUTDIR}/vicuna_out/contig.fasta ${OUTDIR}/${DATA_BASE}_cov${COV}.vicuna.contig.fa

# contig evaluation using mmseqs2
MIN_CONTIG_LEN=1000
mkdir -p ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/dbs
${SOFTWARE}/MMseqs2/build/src/mmseqs createdb ${OUTDIR}/${DATA_BASE}_cov${COV}.vicuna.contig.fa ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/dbs/${DATA_BASE}_cov${COV}.vicuna.contig
../evaluation/evaluateResultsCutAndDoubleRef.sh ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/dbs/${DATA_BASE}_cov${COV}.vicuna.contig ../input/genomes/${DATA_BASE}.cutAndDouble ../input/genomes/${DATA_BASE}.cutAndDouble ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/ ${MIN_CONTIG_LEN} > ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/mmseqs_eval.log


