#!/bin/bash
#SBATCH -J "sludgeMetaT-iva"
#SBATCH -p hh
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=128G
#SBATCH -o ../_clusterRuns/iva/out.%A.%a 
#SBATCH -e ../_clusterRuns/iva/err.%A.%a
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --array=1-82%3
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

OUTDIR_BASE="../benchmark/iva"
OUTDIR="${OUTDIR_BASE}/${SAMPLE}_1P_2P"
mkdir -p ${OUTDIR}

if [[ ! -f ${OUTDIR}/contigs.fasta ]]; then

	# work locally
	cp ../samples/${SAMPLE}_1P.fastq.gz ${TMP}/
	cp ../samples/${SAMPLE}_2P.fastq.gz ${TMP}/
	READSFILE1=${TMP}/${SAMPLE}_1P.fastq.gz
	READSFILE2=${TMP}/${SAMPLE}_2P.fastq.gz
	
    mkdir -p ${OUTDIR}
	
	# command call
	source /usr/users/aseidel1/miniconda3/etc/profile.d/conda.sh
	conda activate iva
	IVA_COMMAND="iva -f ${READSFILE1} -r ${READSFILE2} -t ${SLURM_CPUS_ON_NODE} ${TMP}/assembly"
	/usr/bin/time -f "%e,%M" --output ${OUTDIR}/${SAMPLE}.iva.time.mem.log ${IVA_COMMAND} > ${OUTDIR}/${SAMPLE}.iva.log
	# copy result back and rename
    cp -r ${TMP}/assembly/* ${OUTDIR}
	sed -i "s/^>/>${SAMPLE}_/g" ${OUTDIR}/contigs.fasta
fi

# contig evaluation
if [ -f ${OUTDIR}/contigs.fasta ]; then
  conda activate base
  bioawk -c fastx -v LEN=${LENCUTOFF} 'length($seq)>=LEN{print ">"$name" "$comment"\n"$seq}' ${OUTDIR}/contigs.fasta > ${OUTDIR}/contigs-${LENCUTOFF}.fasta
  if [[ ! -f ${OUTDIR}/detection_${SAMPLE}/contigs.ofInterest.fa ]]; then
    ./../evaluation/getContigsOfInterest.sh ${OUTDIR}/contigs-${LENCUTOFF}.fasta ${OUTDIR_BASE}/detection_${SAMPLE}
  fi
  ./../evaluation/evaluateContigs.sh ${OUTDIR_BASE}/detection_${SAMPLE}/contigs.ofInterest.fa ${OUTDIR_BASE}/detection_${SAMPLE}/protein.uniqueHits.tsv ${OUTDIR_BASE}/detection_${SAMPLE}/clu99 0.99
fi
