#!/bin/bash
#SBATCH -J "HIV1-megahit"
#SBATCH -p em
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=0
#SBATCH -C "haswell"
#SBATCH -o _clusterRuns/megahit/out.%A.%a 
#SBATCH -e _clusterRuns/megahit/err.%A.%a
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
OUTDIR="benchmark_cutAndDoubleRef/megahit/cov${COV}"
mkdir -p ${OUTDIR}

# work locally
cp ${READSFILE1} ${TMP}/
cp ${READSFILE2} ${TMP}/
READSFILE1=${TMP}/$(basename $READSFILE1)
READSFILE2=${TMP}/$(basename $READSFILE2)
#mkdir -p ${TMP}/megahit_out
mkdir -p ${TMP}/megahit_tmp

# command call
MEGAHIT_COMMAND="/cbscratch/annika/virus-assembly-project/software/benchmark_versions/MEGAHIT-1.2.9-Linux-x86_64-static/bin/megahit -1 ${READSFILE1} -2 ${READSFILE2} --out-dir ${TMP}/megahit_out --out-prefix ${DATA_BASE}_cov${COV}.megahit --min-contig-len 1000 --tmp-dir ${TMP}/megahit_tmp -t ${SLURM_CPUS_ON_NODE}"
/usr/bin/time -f "%e,%M" --output ${OUTDIR}/${DATA_BASE}_cov${COV}.megahit.time.mem.log ${MEGAHIT_COMMAND} > ${OUTDIR}/${DATA_BASE}_cov${COV}.megahit.log

# copy result back and rename
mv ${TMP}/megahit_out ${OUTDIR}/
cp ${OUTDIR}/megahit_out/${DATA_BASE}_cov${COV}.megahit.contigs.fa ${OUTDIR}/${DATA_BASE}_cov${COV}.megahit.contigs.fa

# contig evaluation using mmseqs2
MIN_CONTIG_LEN=1000
mkdir -p ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/dbs
${SOFTWARE}/MMseqs2/build/src/mmseqs createdb ${OUTDIR}/${DATA_BASE}_cov${COV}.megahit.contigs.fa ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/dbs/${DATA_BASE}_cov${COV}.megahit.contigs
evaluateResultsCutAndDoubleRef.sh ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/dbs/${DATA_BASE}_cov${COV}.megahit.contigs input/genomes/${DATA_BASE}.cutAndDouble input/genomes/${DATA_BASE}.cutAndDouble ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/ ${MIN_CONTIG_LEN} > ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/mmseqs_eval.log

