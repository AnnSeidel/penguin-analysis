#!/bin/bash
#SBATCH -J "metaquast-unique"
#SBATCH -p hh
#SBATCH -t 14-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=0
##SBATCH -C "rome"
#SBATCH -o _clusterRuns/metaquast/out.%A
#SBATCH -e _clusterRuns/metaquast/err.%A
#SBATCH --mail-type=BEGIN,END,FAIL

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

mkdir -p ${TMP}/metaquast
mkdir -p ${TMP}/refs
mkdir -p ${TMP}/assemblies
mkdir -p ${TMP}/reads

cp benchmark/penguin_7571d37_clu99/rhinovirus_3.penguin.assembly.fa \
benchmark/megahit/rhinovirus_3.megahit.contigs.fa \
benchmark/metaspades/rhinovirus_3.metaspades.contigs.fa \
benchmark/rnaspades/rhinovirus_3.rnaspades.hard_filtered_transcripts.fa \
benchmark/rnaviralspades/rhinovirus_3.rnaviralspades.contigs.fa \
benchmark/savage/rhinovirus_3.savage.contigs_stage_c.fa \
benchmark/iva/rhinovirus_3.iva.contigs.fa \
benchmark/vicuna/rhinovirus_3.vicuna.contig.fa \
benchmark/haploflow/rhinovirus_3.haploflow.contigs.fa ${TMP}/assemblies/

for f in ${TMP}/assemblies/*; do
 bioawk -c fastx 'length($seq)>=1000{print ">"$name"\n"$seq}' $f > ${f}.1000
done;

cp input/genomes/splits/* ${TMP}/refs/

cp input/rhinovirus_3_mixed_4_2_1_cov50_reads.1.fq ${TMP}/reads/
READSFILE1=${TMP}/reads/rhinovirus_3_mixed_4_2_1_cov50_reads.1.fq 
cp input/rhinovirus_3_mixed_4_2_1_cov50_reads.2.fq ${TMP}/reads/
READSFILE2=${TMP}/reads/rhinovirus_3_mixed_4_2_1_cov50_reads.2.fq 

source /usr/users/aseidel1/miniconda3/etc/profile.d/conda.sh
conda activate quast

OUTDIR=benchmark/compare/metaquast_unique_1000_clu99/
mkdir -p ${OUTDIR}
metaquast.py ${TMP}/assemblies/rhinovirus_3.penguin.assembly.fa.1000 \
${TMP}/assemblies/rhinovirus_3.megahit.contigs.fa.1000 \
${TMP}/assemblies/rhinovirus_3.metaspades.contigs.fa.1000 \
${TMP}/assemblies/rhinovirus_3.rnaspades.hard_filtered_transcripts.fa.1000 \
${TMP}/assemblies/rhinovirus_3.rnaviralspades.contigs.fa.1000 \
${TMP}/assemblies/rhinovirus_3.savage.contigs_stage_c.fa.1000 \
${TMP}/assemblies/rhinovirus_3.iva.contigs.fa.1000 \
${TMP}/assemblies/rhinovirus_3.vicuna.contig.fa.1000 \
${TMP}/assemblies/rhinovirus_3.haploflow.contigs.fa.1000 \
 -r ${TMP}/refs --output-dir ${TMP}/metaquast -1 ${READSFILE1} -2 ${READSFILE2} -m 1000 -l penguin,megahit,metaspades,rnaspades,rnaviralspades,savage,iva,vicuna,haploflow --threads ${SLURM_CPUS_ON_NODE} --unique-mapping

mv ${TMP}/metaquast/* ${OUTDIR}
