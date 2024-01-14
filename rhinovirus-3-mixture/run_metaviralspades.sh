#!/bin/bash
#SBATCH -J "rhinovirus-metaviralspades"
#SBATCH -p hh
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=0
#SBATCH -C "haswell"
#SBATCH -o _clusterRuns/metaviralspades/out.%A
#SBATCH -e _clusterRuns/metaviralspades/err.%A
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
OUTDIR="benchmark/metaviralspades"
mkdir -p ${OUTDIR}

# work locally
cp ${READSFILE1} ${TMP}/
cp ${READSFILE2} ${TMP}/
READSFILE1=${TMP}/${DATA_BASE}_mixed_4_2_1_cov50_reads.1.fq
READSFILE2=${TMP}/${DATA_BASE}_mixed_4_2_1_cov50_reads.2.fq
mkdir -p ${TMP}/metaviralspades_out
mkdir -p ${TMP}/metaviralspades_tmp

# command call
METAVIRALSPADES_COMMAND="/cbscratch/annika/virus-assembly-project/software/benchmark_versions/SPAdes-3.15.3-Linux/bin/metaviralspades.py -1 ${READSFILE1} -2 ${READSFILE2} -o ${TMP}/metaviralspades_out --tmp-dir ${TMP}/metaviralspades_tmp -t ${SLURM_CPUS_ON_NODE}"
/usr/bin/time -f "%e,%M" --output ${OUTDIR}/${DATA_BASE}.metaviralspades.time.mem.log ${METAVIRALSPADES_COMMAND} > ${OUTDIR}/${DATA_BASE}.metaviralspades.log

# copy result back and rename
cp -r ${TMP}/metaviralspades_out ${OUTDIR}/
cp ${OUTDIR}/metaviralspades_out/contigs.fasta ${OUTDIR}/${DATA_BASE}.metaviralspades.contigs.fa
