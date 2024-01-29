#!/bin/bash
#SBATCH -J "sludgeMetaT-savage"
#SBATCH -p hh
#SBATCH -t 10-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=128G
#SBATCH -o ../_clusterRuns/savage/out.%A.%a 
#SBATCH -e ../_clusterRuns/savage/err.%A.%a
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --array=1-82%3

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

OUTDIR_BASE="../benchmark/savage"
OUTDIR="${OUTDIR_BASE}/${SAMPLE}_1P_2P"
mkdir -p ${OUTDIR}


if [[ ! -f ${OUTDIR}/contigs_stage_c.fasta ]]; then

	# work locally
	cp samples_savage_format/${SAMPLE}_1P.renamed.fastq ${TMP}/
	cp samples_savage_format/${SAMPLE}_2P.renamed.fastq ${TMP}/
	READSFILE1=${TMP}/${SAMPLE}_1P.renamed.fastq
	READSFILE2=${TMP}/${SAMPLE}_2P.renamed.fastq
	
    mkdir -p ${OUTDIR}
    mkdir -p ${TMP}/assembly
	
	# command call
	source /usr/users/aseidel1/miniconda3/etc/profile.d/conda.sh
	conda activate haploconduct-deps
	SAVAGE_COMMAND="haploconduct savage -p1 ${READSFILE1} -p2 ${READSFILE2} --revcomp -t ${SLURM_CPUS_ON_NODE} -o ${TMP}/assembly/ --split 1"
	/usr/bin/time -f "%e,%M" --output ${OUTDIR}/${SAMPLE}.savage.time.mem.log ${SAVAGE_COMMAND} > ${OUTDIR}/${SAMPLE}.savage.log
	# copy result back and rename
    cp -r ${TMP}/assembly/* ${OUTDIR}
	sed -i "s/^>/>${SAMPLE}_/g" ${OUTDIR}/contigs_stage_c.fasta
fi


# contig evaluation
if [ -f ${OUTDIR}/contigs_stage_c.fasta ]; then
    conda activate base
    bioawk -c fastx -v LEN=${LENCUTOFF} 'length($seq)>=LEN{print ">"$name" "$comment"\n"$seq}' ${OUTDIR}/contigs_stage_c.fasta > ${OUTDIR}/contigs_stage_c-${LENCUTOFF}.fasta
    if [[ ! -f ${OUTDIR}/detection_${SAMPLE}/contigs.ofInterest.fa ]]; then
      ./../evaluation/getContigsOfInterest.sh ${OUTDIR}/contigs_stage_c-${LENCUTOFF}.fasta ${OUTDIR_BASE}/detection_${SAMPLE}
	fi

    ./../evaluation/evaluateContigs.sh ${OUTDIR_BASE}/detection_${SAMPLE}/contigs.ofInterest.fa ${OUTDIR_BASE}/detection_${SAMPLE}/protein.uniqueHits.tsv ${OUTDIR_BASE}/detection_${SAMPLE}/clu99 0.99
fi
