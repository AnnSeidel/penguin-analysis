#!/bin/bash
#SBATCH -J "sludgeMetaT-haploflow"
#SBATCH -p hh
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=128G
#SBATCH -o ../_clusterRuns/haploflow/out.%A.%a 
#SBATCH -e ../_clusterRuns/haploflow/err.%A.%a
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --array=1-82%15
set -e

SAMPLE=$(sed "${SLURM_ARRAY_TASK_ID}q;d" ../samples/sra_sample_list)

id=$RANDOM
LENCUTOFF=500
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

OUTDIR_BASE="../benchmark/haploflow"
OUTDIR="${OUTDIR_BASE}/${SAMPLE}_1P_2P"
mkdir -p ${OUTDIR}
source /usr/users/aseidel1/miniconda3/etc/profile.d/conda.sh


if [[ ! -f ${OUTDIR}/contigs.fa ]]; then

	# work locally
	zcat ../samples/${SAMPLE}_1P.fastq.gz ../samples/${SAMPLE}_2P.fastq.gz > ${TMP}/reads.fq

	READSFILE=${TMP}/reads.fq
	
    mkdir -p ${OUTDIR}
    mkdir -p ${TMP}/assembly
	
	# command call
	conda activate haploflow
	HAPLOFLOW_COMMAND="haploflow --read-file ${TMP}/reads.fq --out ${TMP}/assembly --error-rate 0.001 --filter ${LENCUTOFF}"
	/usr/bin/time -f "%e,%M" --output ${OUTDIR}/${SAMPLE}.haploflow.time.mem.log ${HAPLOFLOW_COMMAND} > ${OUTDIR}/${SAMPLE}.haploflow.log
	# copy result back and rename
    #cp ${TMP}/*.log ${OUTDIR}/
    cp -r ${TMP}/assembly/* ${OUTDIR}
	sed -i "s/^>/>${SAMPLE}_/g" ${OUTDIR}/contigs.fa
fi


# contig evaluation
if [ -f ${OUTDIR}/contigs.fa ]; then
  conda activate base
  if [[ ! -f ${OUTDIR}/detection_${SAMPLE}/contigs.ofInterest.fa ]]; then
      ./../evaluation/getContigsOfInterest.sh ${OUTDIR}/contigs.fa ${OUTDIR_BASE}/detection_${SAMPLE}
  fi
  ./../evaluation/evaluateContigs.sh ${OUTDIR_BASE}/detection_${SAMPLE}/contigs.ofInterest.fa ${OUTDIR_BASE}/detection_${SAMPLE}/protein.uniqueHits.tsv ${OUTDIR_BASE}/detection_${SAMPLE}/clu99 0.99
fi
