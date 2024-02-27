#!/bin/bash
#SBATCH -J "HIV1-savage"
#SBATCH -p em
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=0
#SBATCH -C "haswell"
#SBATCH -o ../_clusterRuns/savage/out.%A.%a 
#SBATCH -e ../_clusterRuns/savage/err.%A.%a
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
OUTDIR="../benchmark_cutAndDoubleRef/savage/cov${COV}"
mkdir -p ${OUTDIR}

# work locally
cp ${READSFILE1} ${TMP}/
cp ${READSFILE2} ${TMP}/
READSFILE1=${TMP}/$(basename $READSFILE1)
READSFILE2=${TMP}/$(basename $READSFILE2)
mkdir -p ${TMP}/savage_out/

# command call
source /usr/users/aseidel1/miniconda3/etc/profile.d/conda.sh
conda activate haploconduct-deps
SAVAGE_COMMAND="haploconduct savage -p1 ${READSFILE1} -p2 ${READSFILE2} --revcomp -t ${SLURM_CPUS_ON_NODE} -o ${TMP}/savage_out --split 1"
/usr/bin/time -f "%e,%M" --output ${OUTDIR}/${DATA_BASE}_cov${COV}.savage.time.mem.log ${SAVAGE_COMMAND} > ${OUTDIR}/${DATA_BASE}_cov${COV}.savage.log

# copy result back
cp -r ${TMP}/savage_out ${OUTDIR}/
cp ${OUTDIR}/savage_out/contigs_stage_c.fasta ${OUTDIR}/${DATA_BASE}_cov${COV}.savage.contigs_stage_c.fa

# contig evaluation using mmseqs2
MIN_CONTIG_LEN=1000
mkdir -p ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/dbs
${SOFTWARE}/MMseqs2/build/src/mmseqs createdb ${OUTDIR}/${DATA_BASE}_cov${COV}.savage.contigs_stage_c.fa ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/dbs/${DATA_BASE}_cov${COV}.savage.contigs_stage_c
../evaluation/evaluateResultsCutAndDoubleRef.sh ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/dbs/${DATA_BASE}_cov${COV}.savage.contigs_stage_c ../input/genomes/${DATA_BASE}.cutAndDouble ../input/genomes/${DATA_BASE}.cutAndDouble ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/ ${MIN_CONTIG_LEN} > ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/mmseqs_eval.log

