#!/bin/bash
#SBATCH -J "HIV1-penguin"
#SBATCH -p em
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=0
##SBATCH -C "haswell"
#SBATCH -o ../_clusterRuns/penguin_clu99/out.%A.%a 
#SBATCH -e ../_clusterRuns/penguin_clu99/err.%A.%a
#SBATCH --array=1
#SBATCH --mail-type=BEGIN,END,FAIL
set -e

DATA_BASE=HIV1 
PLASS_VERSION=7571d37

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

VERSION="plass_${PLASS_VERSION}"
OUTDIR="../benchmark_cutAndDoubleRef/penguin_${PLASS_VERSION}_clu99/cov${COV}"
mkdir -p ${OUTDIR}

# work locally
cp ${READSFILE1} ${TMP}/
cp ${READSFILE2} ${TMP}/
READSFILE1=${TMP}/$(basename $READSFILE1)
READSFILE2=${TMP}/$(basename $READSFILE2)
mkdir -p ${TMP}/penguin_out
mkdir -p ${TMP}/penguin_tmp

# command call
PENGUIN_COMMAND="/cbscratch/annika/virus-assembly-project/software/benchmark_versions/plass_${PLASS_VERSION} guided_nuclassemble ${READSFILE1} ${READSFILE2} ${TMP}/penguin_out/${DATA_BASE}_cov${COV}.penguin.assembly.fa ${TMP}/penguin_tmp --threads ${SLURM_CPUS_ON_NODE} --clust-min-seq-id 0.99"
/usr/bin/time -f "%e,%M" --output ${OUTDIR}/${DATA_BASE}_cov${COV}.penguin.time.mem.log ${PENGUIN_COMMAND} > ${OUTDIR}/${DATA_BASE}_cov${COV}.penguin.log

# copy result back and rename
cp -r ${TMP}/penguin_out ${OUTDIR}/
cp ${OUTDIR}/penguin_out/${DATA_BASE}_cov${COV}.penguin.assembly.fa ${OUTDIR}/${DATA_BASE}_cov${COV}.penguin.assembly.fa
cp -rL ${TMP}/penguin_tmp ${OUTDIR}/

# contig evaluation using mmseqs2
MIN_CONTIG_LEN=1000
mkdir -p ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/dbs
${SOFTWARE}/MMseqs2/build/src/mmseqs createdb ${OUTDIR}/${DATA_BASE}_cov${COV}.penguin.assembly.fa ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/dbs/${DATA_BASE}_cov${COV}.penguin.assembly
../evaluation/evaluateResultsCutAndDoubleRef.sh ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/dbs/${DATA_BASE}_cov${COV}.penguin.assembly ../input/genomes/HIV1.cutAndDouble ../input/genomes/HIV1.cutAndDouble ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/ ${MIN_CONTIG_LEN} > ${OUTDIR}/mmseqs_eval_cutAndDoubleRef/mmseqs_eval.log

