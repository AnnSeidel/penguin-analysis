#!/bin/bash
#SBATCH -J "sludgeMetaT-vicuna"
#SBATCH -p hh
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=128G
#SBATCH -o ../_clusterRuns/vicuna/out.%A.%a 
#SBATCH -e ../_clusterRuns/vicuna/err.%A.%a
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --array=1-82%10


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

OUTDIR_BASE="../benchmark/vicuna"
OUTDIR="${OUTDIR_BASE}/${SAMPLE}_1P_2P"
mkdir -p ${OUTDIR}


if [[ ! -f ${OUTDIR}/contig.fasta ]]; then

	# work locally
	mkdir -p ${TMP}/reads/
	cp ../samples/${SAMPLE}_1P.fastq.gz ${TMP}/reads/
	cp ../samples/${SAMPLE}_2P.fastq.gz ${TMP}/reads/
	gunzip -d ${TMP}/reads/${SAMPLE}_1P.fastq.gz
	gunzip -d ${TMP}/reads/${SAMPLE}_2P.fastq.gz

	
    mkdir -p ${OUTDIR}
    mkdir -p ${TMP}/vicuna_out
	CURRDIR=$(pwd)
	cd ${TMP}
	# command call
	VICUNA_COMMAND="/cbscratch/annika/virus-assembly-project/software/benchmark_versions/VICUNA_v1.3/executable/vicuna-omp.static.linux64 \
		/cbscratch/annika/virus-assembly-project/software/benchmark_versions/VICUNA_v1.3/config/vicuna_config_ml500.txt"

	/usr/bin/time -f "%e,%M" --output ${CURRDIR}/${OUTDIR}/${SAMPLE}.vicuna.time.mem.log ${VICUNA_COMMAND} > ${CURRDIR}/${OUTDIR}/${SAMPLE}.vicuna.log
	cd ${CURRDIR}
	# copy result back and rename
    cp -r ${TMP}/vicuna_out/* ${OUTDIR}
	sed -i "s/^>/>${SAMPLE}_/g" ${OUTDIR}/contig.fasta
fi

# contig evaluation
if [ -f ${OUTDIR}/contig.fasta ]; then
  bioawk -c fastx -v LEN=${LENCUTOFF} 'length($seq)>=LEN{print ">"$name" "$comment"\n"$seq}' ${OUTDIR}/contig.fasta > ${OUTDIR}/contigs-${LENCUTOFF}.fasta
  if [[ ! -f ${OUTDIR}/detection_${SAMPLE}/contigs.ofInterest.fa ]]; then
    ./../evaluation/getContigsOfInterest.sh ${OUTDIR}/contigs-${LENCUTOFF}.fasta ${OUTDIR_BASE}/detection_${SAMPLE}
  fi

  ./../evaluation/evaluateContigs.sh ${OUTDIR_BASE}/detection_${SAMPLE}/contigs.ofInterest.fa ${OUTDIR_BASE}/detection_${SAMPLE}/protein.uniqueHits.tsv ${OUTDIR_BASE}/detection_${SAMPLE}/clu99 0.99
fi
