#!/bin/bash
#SBATCH -p medium
#SBATCH -A all
#SBATCH -N 1
#SBATCH -c 36
#SBATCH -t 48:00:00
#SBATCH -C scratch

#running barrnap tool (rRNA detector) for the assemblies
module load anaconda3
source activate penguin_env
barrnap --threads 36 -o all_haploflow_rrna_barrnap.fa < all_haploflow.assembly.fa > all_haploflow_rrna_barrnap.gff
barrnap --threads 36 -o all_iva_rrna_barrnap.fa < all_iva.assembly.fa > all_iva_rrna_barrnap.gff
barrnap --threads 36 -o all_megahit_rrna_barrnap.fa < all_megahit.assembly.fa > all_megahit_rrna_barrnap.gff
barrnap --threads 36 -o all_metaspades_rrna_barrnap.fa < all_metaspades.assembly.fa > all_metaspades_rrna_barrnap.gff
barrnap --threads 36 -o all_penguin_rrna_barrnap.fa < all_penguin.assembly.fa > all_penguin_rrna_barrnap.gff
barrnap --threads 36 -o all_rnaspades_rrna_barrnap.fa < all_rnaspades.assembly.fa > all_rnaspades_rrna_barrnap.gff
barrnap --threads 36 -o all_rnaviralspades_rrna_barrnap.fa < all_rnaviralspades.assembly.fa > all_rnaviralspades_rrna_barrnap.gff
