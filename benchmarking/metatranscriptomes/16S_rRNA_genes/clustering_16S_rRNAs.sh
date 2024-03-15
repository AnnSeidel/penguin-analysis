#!/bin/bash
#SBATCH -p medium
#SBATCH -A all
#SBATCH -N 1
#SBATCH -c 36
#SBATCH -t 24:00:00
#SBATCH -C scratch


# clustering the found 16s rRNA sequences on different sequence identity levels in order to assess the diversity, on the example of PenguiN
module load anaconda3
source activate penguin_env

touch 16S_percent_all_penguin_rrna_barrnap_clu_80cov
for i in 1.0 0.99 0.98 0.97 0.96 0.95 0.94 0.93 0.92 0.91 0.9 0.8 0.7 0.6 0.5
do
mmseqs cluster /scratch/users/a.kolodyazhnaya01/16S_all_penguin_rrna_barrnap_db 16S_all_penguin_rrna_barrnap_db_clu_new tmp --min-seq-id $i

mmseqs createtsv /scratch/users/a.kolodyazhnaya01/16S_all_penguin_rrna_barrnap_db /scratch/users/a.kolodyazhnaya01/16S_all_penguin_rrna_barrnap_db 16S_all_penguin_rrna_barrnap_db_clu_new 16S_all_penguin_rrna_barrnap_db_clu_new.tsv

cat 16S_all_penguin_rrna_barrnap_db_clu_new.tsv | awk '{print $1}' | sort -u | awk -F'::' '{print $2}' | awk -F':' '{print $1,$2}' OFS='\t' | awk -F'(' '{print $1}' | awk -F'-' '{print $1,$2}' OFS='\t' | awk -F'\t' '{print $1, "barrnap:0.9", "rRNA", $2+1, $3}' OFS='\t' > 16S_all_penguin_rrna_barrnap_db_clu_new_rep_gff


rep=$(cat 16S_all_penguin_rrna_barrnap_db_clu_new_rep_gff | wc -l)
echo “Total representatives $i clustering = $rep” >> 16S_percent_all_penguin_rrna_barrnap_clu_80cov

cat 16S_all_penguin_rrna_barrnap_db_clu_new_rep_gff | awk '{print $1 "_" $2 "_" $3 "_" $4 "_" $5, $6}' > tmp11

sort tmp11 > 16S_all_penguin_rrna_barrnap_db_clu_new_rep_gff_merge_sorted

join 16S_all_penguin_rrna_barrnap_db_clu_new_rep_gff_merge_sorted /scratch/users/a.kolodyazhnaya01/all_penguin_rrna_barrnap.gff_percent_merge_sorted -o 2.1,2.2,2.3,2.4,2.5,2.6,2.7,2.8,2.9,2.10,2.11,2.12,2.13,2.14 > 16S_percent_all_penguin_rrna_barrnap_rep_gff_merged_new

rep_perc=$(cat 16S_percent_all_penguin_rrna_barrnap_rep_gff_merged_new | grep percent | awk -F'only ' '{print $2}' | awk -F' percent' '{print $1/100}' | wc -l)

echo “Representatives $i clustering with percent = $rep_perc” >> 16S_percent_all_penguin_rrna_barrnap_clu_80cov
echo “more 0.8 coverage, $i clustering” >> 16S_percent_all_penguin_rrna_barrnap_clu_80cov
echo $((rep-rep_perc)) >> 16S_percent_all_penguin_rrna_barrnap_clu_80cov

rm -f 16S_all_penguin_rrna_barrnap_db_clu_new*
rm -fr tmp
done 
