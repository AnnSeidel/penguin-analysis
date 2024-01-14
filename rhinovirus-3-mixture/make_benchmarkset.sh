#!/bin/bash -x
# SIMULATE BENCHMARK READS

BASE=$(pwd)

#mkdir -p input/genomes
cd input/genomes

# download MF973193.1 MF973194.1 MN749156.1.fasta

# mix genomes 4:2:1
cat splits/MF973193.1.fasta splits/MF973193.1.fasta splits/MF973193.1.fasta splits/MF973193.1.fasta splits/MF973194.1.fasta splits/MF973194.1.fasta splits/MN749156.1.fasta > rhinovirus_3_mixed_4_2_1.fasta

cat splits/MF973193.1.fasta splits/MF973194.1.fasta splits/MN749156.1.fasta > rhinovirus_3.fasta

cd ..

${SOFTWARE}/bbmap/randomreads.sh ref=genomes/rhinovirus_3_mixed_4_2_1.fasta out1=rhinovirus_3_mixed_4_2_1_cov50_reads.1.fq out2=rhinovirus_3_mixed_4_2_1_cov50_reads.2.fq length=150 coverage=50 seed=1692021 paired=t mininsert=220 maxinsert=280 gaussian=f flat=t adderrors=f overlap=150


