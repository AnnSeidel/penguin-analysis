#!/bin/bash
#SBATCH -J "HIV1-haploflow_default"
#SBATCH -p em
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=0
#SBATCH -C "haswell"
#SBATCH -o _clusterRuns/haploflow/out.%A.%a 
#SBATCH -e _clusterRuns/haploflow/err.%A.%a
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

READSFILE1=input/${DATA_BASE}.cutAndDouble_cov${COV}_reads.1.fq
READSFILE2=input/${DATA_BASE}.cutAndDouble_cov${COV}_reads.2.fq
OUTDIR="benchmark_cutAndDoubleRef/haploflow_default/cov${COV}"
mkdir -p ${OUTDIR}

# work locally, haploflow takes single fastq file
cat ${READSFILE1} ${READSFILE2} > ${TMP}/reads.fq
mkdir -p ${TMP}/haploflow_out/

# command call
#source /usr/users/aseidel1/miniconda3/etc/profile.d/conda.sh
#conda activate haploflow
HAPLOFLOW_COMMAND="haploflow --read-file ${TMP}/reads.fq --out ${TMP}/haploflow_out --filter 1000 --log ${OUTDIR}/log_file"
/usr/bin/time -f "%e,%M" --output ${OUTDIR}/${DATA_BASE}_cov${COV}.haploflow.time.mem.log ${HAPLOFLOW_COMMAND} > ${OUTDIR}/${DATA_BASE}_cov${COV}.haploflow.log

# copy result back
cp -r ${TMP}/haploflow_out ${OUTDIR}/
cp ${OUTDIR}/haploflow_out/contigs.fa ${OUTDIR}/${DATA_BASE}_cov${COV}.haploflow.contigs.fa

# contig evaluation using mmseqs2
MIN_CONTIG_LEN=1000
mkdir -p ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/dbs
${SOFTWARE}/MMseqs2/build/src/mmseqs createdb ${OUTDIR}/${DATA_BASE}_cov${COV}.haploflow.contigs.fa ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/dbs/${DATA_BASE}_cov${COV}.haploflow.contigs
evaluateResultsCutAndDoubleRef.sh ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/dbs/${DATA_BASE}_cov${COV}.haploflow.contigs input/genomes/${DATA_BASE}.cutAndDouble input/genomes/${DATA_BASE}.cutAndDouble ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/ ${MIN_CONTIG_LEN} > ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/mmseqs_eval.log
