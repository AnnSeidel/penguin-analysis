#!/bin/bash -x
BASE=$(pwd)

#mkdir -p input/genomes
cd input/

#To make cutAndDouble reference genomes: 
# (1) Create genomes/tmp/${GENOME} for each genome id and put two files in each folder: ${GENOME}_1.fa ${GENOME}_2.fa containing the first and second half 
# (2) go to each folder and run ${SOFTWARE}/mmseqs easy-search ${GENOME}_1.fa ${GENOME}_2.fa mmseqs_search.tsv mmseqs_search_tmp --search-type 3 --format-output query,target,fident,alnlen,mismatch,gapopen,qstart,qend,qlen,tstart,tend,tlen,evalue,bits --threads 1 
# (3) cat genomes/tmp/*/mmseqs_search.tsv > genomes/mmseqs_search.tsv
# (4) run python cutAndDouble.py genomes/HIV1.fa genomes/mmseqs_search.tsv genomes/
# (5) for evaluation purpose HIV1.cutAndDouble.fa will be need in mmseqs database format, to create that file run ${SOFTWARE}/mmseqs createdb genomes/HIV1.cutAndDouble.fa genomes/HIV1.cutAndDouble.dbs
# (6) for metaquast reference genomes we need the genomes in single files, run seqkit split -i --out-dir splits HIV1.cut.fa


${SOFTWARE}/bbmap/randomreads.sh ref=genomes/HIV1.cutAndDouble.fa out1=HIV1.cutAndDouble_cov1_reads.1.fq out2=HIV1.cutAndDouble_cov1_reads.2.fq length=150 coverage=0.5 seed=26102021 paired=t mininsert=220 maxinsert=280 gaussian=f flat=t adderrors=f overlap=150 illuminanames=t addslash=t overwrite=f

${SOFTWARE}/bbmap/randomreads.sh ref=genomes/HIV1.cutAndDouble.fa out1=HIV1.cutAndDouble_cov10_reads.1.fq out2=HIV1.cutAndDouble_cov10_reads.2.fq length=150 coverage=5 seed=26102021 paired=t mininsert=220 maxinsert=280 gaussian=f flat=t adderrors=f overlap=150 illuminanames=t addslash=t overwrite=f

${SOFTWARE}/bbmap/randomreads.sh ref=genomes/HIV1.cutAndDouble.fa out1=HIV1.cutAndDouble_cov100_reads.1.fq out2=HIV1.cutAndDouble_cov100_reads.2.fq length=150 coverage=50 seed=26102021 paired=t mininsert=220 maxinsert=280 gaussian=f flat=t adderrors=f overlap=150 illuminanames=t addslash=t overwrite=f

