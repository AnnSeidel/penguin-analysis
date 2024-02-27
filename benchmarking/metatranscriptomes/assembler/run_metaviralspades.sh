#!/bin/bash
#SBATCH -J "sludgeMetaT-metaviralspades"
#SBATCH -p hh
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=128G
#SBATCH -o ../_clusterRuns/metaviralspades/out.%A.%a 
#SBATCH -e ../_clusterRuns/metaviralspades/err.%A.%a
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --array=1-82%15

#set -e

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

OUTDIR_BASE="../benchmark/metaviralspades"
OUTDIR="${OUTDIR_BASE}/${SAMPLE}_1P_2P"
mkdir -p ${OUTDIR}


if [[ ! -f ${OUTDIR}/scaffolds.fasta ]]; then

	# work locally
	cp ../samples/${SAMPLE}_1P.fastq.gz ${TMP}/
	cp ../samples/${SAMPLE}_2P.fastq.gz ${TMP}/
	READSFILE1=${TMP}/${SAMPLE}_1P.fastq.gz
	READSFILE2=${TMP}/${SAMPLE}_2P.fastq.gz
	
    mkdir -p ${OUTDIR}
    mkdir -p ${TMP}/assembly
	
	# command call
	METAVIRALSPADES_COMMAND="/cbscratch/annika/virus-assembly-project/software/benchmark_versions/SPAdes-3.15.2-Linux/bin/metaviralspades.py \
            -1 ${READSFILE1} -2 ${READSFILE2} -o ${TMP}/assembly \
            --tmp-dir "${TMP}" -t ${SLURM_CPUS_ON_NODE}"
	/usr/bin/time -f "%e,%M" --output ${TMP}/${SAMPLE}.metaviralspades.time.mem.log ${METAVIRALSPADES_COMMAND} > ${TMP}/${SAMPLE}.metaviralspades.log
	# copy result back and rename
    cp ${TMP}/*.log ${OUTDIR}/
    cp -r ${TMP}/assembly/* ${OUTDIR}
	sed -i "s/^>/>${SAMPLE}_/g" ${OUTDIR}/scaffolds.fasta
fi


# contig evaluation
if [ -f ${OUTDIR}/scaffolds.fasta ]; then
  bioawk -c fastx -v LEN=${LENCUTOFF} 'length($seq)>=LEN{print ">"$name" "$comment"\n"$seq}' ${OUTDIR}/scaffolds.fasta > ${OUTDIR}/scaffolds-${LENCUTOFF}.fasta
  if [[ ! -f ${OUTDIR}/detection_${SAMPLE}/contigs.ofInterest.fa ]]; then
    ./../evaluation/getContigsOfInterest.sh ${OUTDIR}/scaffolds-${LENCUTOFF}.fasta ${OUTDIR_BASE}/detection_${SAMPLE}
  fi
  ./../evaluation/evaluateContigs.sh ${OUTDIR_BASE}/detection_${SAMPLE}/contigs.ofInterest.fa ${OUTDIR_BASE}/detection_${SAMPLE}/protein.uniqueHits.tsv ${OUTDIR_BASE}/detection_${SAMPLE}/clu99 0.99
fi
