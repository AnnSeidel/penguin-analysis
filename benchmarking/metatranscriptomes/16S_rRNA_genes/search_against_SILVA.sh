#!/bin/bash
#SBATCH -p medium
#SBATCH -A all
#SBATCH -N 1
#SBATCH -c 24
#SBATCH -t 24:00:00
#SBATCH -C scratch


# Searching PenguiN 16S rrnas found by barrnap (converted to mmseqs databasd) against SILVA with 99% identity threshold
module load anaconda3
source activate penguin_env
mmseqs search 16S_all_vicuna_rrna_barrnap_db_clu_rep_db /scratch/users/a.kolodyazhnaya01/SILVA_138.1_SSURef_NR99_tax_silva_db 16S_vicuna_barrnap_clu_rep_ag_SILVA138_SSURef_NR99_res tmp --min-seq-id 0.99 --search-type 3
mmseqs search 16S_all_haploflow_rrna_barrnap_db_clu_rep_db /scratch/users/a.kolodyazhnaya01/SILVA_138.1_SSURef_NR99_tax_silva_db 16S_haploflow_barrnap_clu_rep_ag_SILVA138_SSURef_NR99_res tmp --min-seq-id 0.99 --search-type 3
mmseqs search 16S_all_iva_rrna_barrnap_db_clu_rep_db /scratch/users/a.kolodyazhnaya01/SILVA_138.1_SSURef_NR99_tax_silva_db 16S_iva_barrnap_clu_rep_ag_SILVA138_SSURef_NR99_res tmp --min-seq-id 0.99 --search-type 3
mmseqs search 16S_all_megahit_rrna_barrnap_db_clu_rep_db /scratch/users/a.kolodyazhnaya01/SILVA_138.1_SSURef_NR99_tax_silva_db 16S_megahit_barrnap_clu_rep_ag_SILVA138_SSURef_NR99_res tmp --min-seq-id 0.99 --search-type 3
mmseqs search 16S_all_metaspades_rrna_barrnap_db_clu_rep_db /scratch/users/a.kolodyazhnaya01/SILVA_138.1_SSURef_NR99_tax_silva_db 16S_metaspades_barrnap_clu_rep_ag_SILVA138_SSURef_NR99_res tmp --min-seq-id 0.99 --search-type 3
mmseqs search 16S_all_penguin_rrna_barrnap_db_clu_rep_db /scratch/users/a.kolodyazhnaya01/SILVA_138.1_SSURef_NR99_tax_silva_db 16S_penguin_barrnap_clu_rep_ag_SILVA138_SSURef_NR99_res tmp --min-seq-id 0.99 --search-type 3
mmseqs search 16S_all_rnaviralspades_rrna_barrnap_db_clu_rep_db /scratch/users/a.kolodyazhnaya01/SILVA_138.1_SSURef_NR99_tax_silva_db 16S_rnaviralspades_barrnap_clu_rep_ag_SILVA138_SSURef_NR99_res tmp --min-seq-id 0.99 --search-type 3
mmseqs search 16S_all_rnaspades_rrna_barrnap_db_clu_rep_db /scratch/users/a.kolodyazhnaya01/SILVA_138.1_SSURef_NR99_tax_silva_db 16S_rnaspades_barrnap_clu_rep_ag_SILVA138_SSURef_NR99_res tmp --min-seq-id 0.99 --search-type 3

