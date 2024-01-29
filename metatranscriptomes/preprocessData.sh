#!/bin/bash
#SBATCH -J "sludgeMetaT-preprocessing"
#SBATCH -p hh
#SBATCH -t 01-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH -o _clusterRuns/preprocessing/out.%A.%a 
#SBATCH -e _clusterRuns/preprocessing/err.%A.%a
#SBATCH --array=1-82%10

INDIR=/cbscratch/annika/virus-assembly-project/sludgeMetaT/samples/
SAMPLE=$(sed "${SLURM_ARRAY_TASK_ID}q;d" sra_sample_list)
cd ${INDIR}

#Cut Illumina universal adapters from the sequences
cutadapt -j 0 -b AGATCGGAAGAGC -B AGATCGGAAGAGC -o ${SAMPLE}_1.cut.fastq.gz -p ${SAMPLE}_2.cut.fastq.gz ${SAMPLE}_1.fastq.gz ${SAMPLE}_2.fastq.gz

#Trimmomatic
java -jar /usr/users/aseidel1/Software/Trimmomatic-0.39/trimmomatic-0.39.jar PE -phred33 ${SAMPLE}_1.cut.fastq.gz ${SAMPLE}_2.cut.fastq.gz -baseout ${SAMPLE}.fastq.gz LEADING:3 TRAILING:3 SLIDINGWINDOW:4:30 MINLEN:100
rm ${SAMPLE}_1.cut.fastq.gz
rm ${SAMPLE}_2.cut.fastq.gz

