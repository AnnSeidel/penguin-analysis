#!/bin/bash
#SBATCH -J "sludgeMetaT-penguin"
#SBATCH -p hh
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 32
#SBATCH --mem=128G
#SBATCH -o ../_clusterRuns/penguin/out.%A.%a 
#SBATCH -e ../_clusterRuns/penguin/err.%A.%a
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --array=1-82%15
set -e

SLURM_CPUS_ON_NODE=16 # updated script when changing from em to new hh nodes
SAMPLE=$(sed "${SLURM_ARRAY_TASK_ID}q;d" ../samples/sra_sample_list)
PLASS_VERSION=7571d37

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

VERSION="plass_${PLASS_VERSION}"
OUTDIR="../benchmark/penguin_${PLASS_VERSION}_clu99/"
mkdir -p ${OUTDIR}

if [[ ! -f ${OUTDIR}/${SAMPLE}.penguin.assembly.fa ]];then

	# work locally
	cp ../samples/${SAMPLE}_1P.fastq.gz ${TMP}/
	cp ../samples/${SAMPLE}_2P.fastq.gz ${TMP}/
	READSFILE1=${TMP}/${SAMPLE}_1P.fastq.gz
	READSFILE2=${TMP}/${SAMPLE}_2P.fastq.gz
	
	mkdir -p ${TMP}/penguin_out
	mkdir -p ${TMP}/penguin_tmp
	
	# command call
	PENGUIN_COMMAND="/cbscratch/annika/virus-assembly-project/software/benchmark_versions/plass_${PLASS_VERSION} guided_nuclassemble ${READSFILE1} ${READSFILE2} ${TMP}/penguin_out/${SAMPLE}.penguin.assembly.fa ${TMP}/penguin_tmp --threads ${SLURM_CPUS_ON_NODE} --min-contig-len 500 --clust-min-seq-id 0.99"
	/usr/bin/time -f "%e,%M" --output ${TMP}/${SAMPLE}.penguin.time.mem.log ${PENGUIN_COMMAND} > ${TMP}/${SAMPLE}.penguin.log
	
	# copy result back and rename
	cp ${TMP}/*log ${OUTDIR}/
	cp ${TMP}/penguin_out/${SAMPLE}.penguin.assembly.fa ${OUTDIR}/
	sed -i "s/^>/>${SAMPLE}_/g" ${OUTDIR}/${SAMPLE}.penguin.assembly.fa

fi
if [[ ! -f ${OUTDIR}/detection_${SAMPLE}/contigs.ofInterest.fa ]]; then
  # contig evaluation
  ./../evaluation/getContigsOfInterest.sh ${OUTDIR}/${SAMPLE}.penguin.assembly.fa ${OUTDIR}/detection_${SAMPLE}
fi

./../evaluation/evaluateContigs.sh ${OUTDIR}/detection_${SAMPLE}/contigs.ofInterest.fa ${OUTDIR}/detection_${SAMPLE}/protein.uniqueHits.tsv ${OUTDIR}/detection_${SAMPLE}/clu99 0.99
