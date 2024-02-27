#!/bin/bash

SUBDIR=clu99

declare -A TOOLS
TOOLS+=(["penguin"]="benchmark/penguin_7571d37_clu99"
        ["megahit"]="benchmark/megahit"
        ["rnaspades"]="benchmark/rnaspades"
        ["rnaviralspades"]="benchmark/rnaviralspades"
        ["metaspades"]="benchmark/metaspades"
        ["metaviralspades"]="benchmark/metaviralspades"
        ["vicuna"]="benchmark/vicuna"
        ["haploflow"]="benchmark/haploflow")


tools=( "penguin" "megahit" "metaspades" "rnaspades" "rnaviralspades" "haploflow" "vicuna" )
outdir=benchmark/summaries/${SUBDIR}
mkdir -p ${outdir}

printf "Sample$(for key in ${tools[@]};do  printf "\t"${key}; done)\n" > ${outdir}/assembly_${SUBDIR}.per_sample_statistic.complete_phages.tsv
                
awk 'BEGIN{FS="\t"};FNR==1{for (i = 1; i <= NF; i += 1){ if($i == "CONTIGS_ENCODING_3_PHAGE_PROTEINS_NO_PARTIAL"){col=i}} }FNR>1{a[FNR]=((a[FNR]? a[FNR] FS : $1 FS) $col)};END{for(i=2;i<=FNR;i++){print a[i]}}' \
                     $(for key in ${tools[@]};do  printf " "${TOOLS[$key]}/assembly_${SUBDIR}.per_sample_statistic.tsv; done) >> ${outdir}/assembly_${SUBDIR}.per_sample_statistic.complete_phages.tsv

printf "Sample$(for key in ${tools[@]};do  printf "\t"${key}; done)\n" > ${outdir}/assembly_${SUBDIR}.per_sample_statistic.near_complete_phages.tsv
awk 'BEGIN{FS="\t"};FNR==1{for (i = 1; i <= NF; i += 1){ if($i == "CONTIGS_ENCODING_3_PHAGE_PROTEINS"){col=i}} }FNR>1{a[FNR]=((a[FNR]? a[FNR] FS : $1 FS) $col)};END{for(i=2;i<=FNR;i++){print a[i]}}' \
                     $(for key in ${tools[@]};do  printf " "${TOOLS[$key]}/assembly_${SUBDIR}.per_sample_statistic.tsv; done) >> ${outdir}/assembly_${SUBDIR}.per_sample_statistic.near_complete_phages.tsv

printf "Sample$(for key in ${tools[@]};do  printf "\t"${key}; done)\n" > ${outdir}/assembly_${SUBDIR}.per_sample_statistic.partial_phages.tsv
awk 'BEGIN{FS="\t"};FNR==1{for (i = 1; i <= NF; i += 1){ if($i == "CONTIGS_ENCODING_AT_LEAST_2_PHAGE_PROTEINS"){col=i}} }FNR>1{a[FNR]=((a[FNR]? a[FNR] FS : $1 FS) $col)};END{for(i=2;i<=FNR;i++){print a[i]}}' \
                     $(for key in ${tools[@]};do  printf " "${TOOLS[$key]}/assembly_${SUBDIR}.per_sample_statistic.tsv; done) >> ${outdir}/assembly_${SUBDIR}.per_sample_statistic.partial_phages.tsv
                     
printf "Sample$(for key in ${tools[@]};do  printf "\t"${key}; done)\n" > ${outdir}/assembly_${SUBDIR}.per_sample_statistic.time.tsv
awk 'BEGIN{FS="\t"};FNR==1{for (i = 1; i <= NF; i += 1){ if($i == "TIME"){col=i}} }FNR>1{a[FNR]=((a[FNR]? a[FNR] FS : $1 FS) $col)};END{for(i=2;i<=FNR;i++){print a[i]}}' \
                     $(for key in ${tools[@]};do  printf " "${TOOLS[$key]}/assembly_${SUBDIR}.per_sample_statistic.tsv; done) >> ${outdir}/assembly_${SUBDIR}.per_sample_statistic.time.tsv
                     
                     
printf "Sample$(for key in ${tools[@]};do  printf "\t"${key}; done)\n" > ${outdir}/assembly_${SUBDIR}.per_sample_statistic.mem.tsv
awk 'BEGIN{FS="\t"};FNR==1{for (i = 1; i <= NF; i += 1){ if($i == "MEM"){col=i}} }FNR>1{a[FNR]=((a[FNR]? a[FNR] FS : $1 FS) $col)};END{for(i=2;i<=FNR;i++){print a[i]}}' \
                     $(for key in ${tools[@]};do  printf " "${TOOLS[$key]}/assembly_${SUBDIR}.per_sample_statistic.tsv; done) >> ${outdir}/assembly_${SUBDIR}.per_sample_statistic.mem.tsv
                     

printf "Type$(for key in ${tools[@]};do  printf "\t"${key}; done)\n" > ${outdir}/assembly_${SUBDIR}.total_statistic.tsv
awk -v COLUMN=2 'BEGIN{FS="\t"};FNR>1{a[FNR]=((a[FNR]? a[FNR] FS : $1 FS) $COLUMN)};END{for(i=2;i<=FNR;i++){print a[i]}}' \
                     $(for key in ${tools[@]};do  printf " "${TOOLS[$key]}/assembly_${SUBDIR}.total_statistic.tsv; done) >> ${outdir}/assembly_${SUBDIR}.total_statistic.tsv


printf "Tool\tContig\tLength\n" > ${outdir}/complete_phage.length_statistic.tsv
for key in ${tools[@]}; do
  cat ${TOOLS[$key]}/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial_lengths.tsv >> ${outdir}/complete_phage.length_statistic.tsv
done

mkdir -p ${outdir}/proteins/
for key in ${tools[@]}; do
  if [[ ( -f ${TOOLS[$key]}/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial_proteins.tsv) ]]; then
    cp ${TOOLS[$key]}/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial_proteins.tsv ${outdir}/proteins/${key}.complete_phage.proteins.tsv
  fi
done

COV=99
printf "Tool\tType\tCluster Coverage\tCluster SeqId\tNum Representatives\n" > ${outdir}/rdrp_clustering_c${COV}.tsv
for key in ${tools[@]}; do
  cat ${TOOLS[$key]}/detection_all/${SUBDIR}/rdrp_clustering/clust_c${COV}.tsv >> ${outdir}/rdrp_clustering_c${COV}.tsv
done

