#!/bin/bash
#SBATCH -J "sludgeMetaT-megahit"
#SBATCH -p hh
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=128G
#SBATCH -o ../_clusterRuns/megahit/out.%A.%a
#SBATCH -e ../_clusterRuns/megahit/err.%A.%a
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

OUTDIR_BASE="../benchmark/megahit"
OUTDIR="${OUTDIR_BASE}/${SAMPLE}_1P_2P"
mkdir -p ${OUTDIR}

if [ ! -f ${OUTDIR}/megahit.contigs.fa ]; then

	# work locally
	cp ../samples/${SAMPLE}_1P.fastq.gz ${TMP}/
	cp ../samples/${SAMPLE}_2P.fastq.gz ${TMP}/
	READSFILE1=${TMP}/${SAMPLE}_1P.fastq.gz
	READSFILE2=${TMP}/${SAMPLE}_2P.fastq.gz
	
    mkdir -p ${OUTDIR}
	mem=$(( 110 * 1024 *1024 *1024 ))
	# command call
	MEGAHIT_COMMAND="/cbscratch/annika/virus-assembly-project/software/benchmark_versions/MEGAHIT-1.2.9-Linux-x86_64-static/bin/megahit \
		-1 ${READSFILE1} -2 ${READSFILE2} --out-dir ${TMP}/assembly --out-prefix megahit --min-contig-len ${LENCUTOFF} \
		--tmp-dir ${TMP} --memory ${mem} -t ${SLURM_CPUS_ON_NODE}"
	
	/usr/bin/time -f "%e,%M" --output ${TMP}/${SAMPLE}.megahit.time.mem.log ${MEGAHIT_COMMAND} > ${TMP}/${SAMPLE}.megahit.log
	# copy result back and rename
    cp ${TMP}/*.log ${OUTDIR}/
    cp -r ${TMP}/assembly/* ${OUTDIR}
    sed -i "s/^>/>${SAMPLE}_/g" ${OUTDIR}/megahit.contigs.fa

fi

# contig evaluation
if [ -f ${OUTDIR}/megahit.contigs.fa ]; then
  if [[ ! -f ${OUTDIR}/detection_${SAMPLE}/contigs.ofInterest.fa ]]; then
    ./../evaluation/getContigsOfInterest.sh ${OUTDIR}/megahit.contigs.fa ${OUTDIR_BASE}/detection_${SAMPLE}
  fi
  ./../evaluation/evaluateContigs.sh ${OUTDIR_BASE}/detection_${SAMPLE}/contigs.ofInterest.fa ${OUTDIR_BASE}/detection_${SAMPLE}/protein.uniqueHits.tsv ${OUTDIR_BASE}/detection_${SAMPLE}/clu99 0.99
fi
