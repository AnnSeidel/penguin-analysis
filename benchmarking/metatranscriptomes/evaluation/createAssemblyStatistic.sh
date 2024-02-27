#!/bin/bash

SUBDIR=clu99

count(){ [ -f $* ] && awk 'END{print NR}' $*  || echo "x"; }
countNumFastaRecords(){ [ -f $* ] && awk 'BEGIN{RS=">"};END{print NR-1}' $* || echo "x"; }
getTimeFromLog(){ [ -f $* ] && awk 'BEGIN{FS=","}{print $1}' $* || echo "x";}
getMemFromLog(){ [ -f $* ] && awk 'BEGIN{FS=","}{print $2}' $* || echo "x";}

do_statistics_all(){
	TOOLNAME=$1
	BASEDIR=$2
	printf "TYPE\t${TOOLNAME}\n"
	printf "CONTIGS_ENCODING_PHAGE_PROTEINS\t$(countNumFastaRecords ${BASEDIR}/detection_all/${SUBDIR}/contigs.ofInterest.fa)\n"
	printf "CONTIGS_ENCODING_PHAGE_PROTEINS_NON_REDUNDANT\t$(count ${BASEDIR}/detection_all/${SUBDIR}/detection_tmp/contigs.ofInterest.nonRedundant.list)\n"
	printf "CONTIGS_ENCODING_PHAGE_PROTEINS_NON_REDUNDANT_750\t$(count ${BASEDIR}/detection_all/${SUBDIR}/detection_tmp/contigs.ofInterest.nonRedundant.minLen750.list)\n"
	printf "CONTIGS_ENCODING_AT_LEAST_2_PHAGE_PROTEINS\t$(count ${BASEDIR}/detection_all/${SUBDIR}/contigsEncodingAtLeast2phageProteins.list)\n"
	printf "CONTIGS_ENCODING_3_PHAGE_PROTEINS\t$(count ${BASEDIR}/detection_all/${SUBDIR}/contigsEncoding3phageProteins.list)\n"
	printf "CONTIGS_ENCODING_3_PHAGE_PROTEINS_NO_PARTIAL\t$(count ${BASEDIR}/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial.list)\n"
}


do_statistics_per_sample(){
	SAMPLE=$1
	TOOLDIR=$2
	TOOL=$3
	ASSEMBLYFILE=$4
    col0=${SAMPLE}
    col1=$( getTimeFromLog $(dirname $ASSEMBLYFILE)/${SAMPLE}.${TOOL}.time.mem.log)
    col2=$( getMemFromLog $(dirname $ASSEMBLYFILE)/${SAMPLE}.${TOOL}.time.mem.log)
    col3=$( countNumFastaRecords ${ASSEMBLYFILE}) # num assemled contigs
    DETECTION_DIR="${TOOLDIR}/detection_${SAMPLE}"
    col4=$(count ${DETECTION_DIR}/contigs.ofInterest.list)
    col5=$(count ${DETECTION_DIR}/${SUBDIR}/detection_tmp/contigs.ofInterest.nonRedundant.list) #cluster_repseq.index)
    col6=$(count ${DETECTION_DIR}/${SUBDIR}/detection_tmp/contigs.ofInterest.nonRedundant.minLen750.list) 
    col7=$(count ${DETECTION_DIR}/${SUBDIR}/contigsEncodingAtLeast2phageProteins.list)
    col8=$(count ${DETECTION_DIR}/${SUBDIR}/contigsEncoding3phageProteins.list)
    col9=$(count ${DETECTION_DIR}/${SUBDIR}/contigsEncoding3phageProteinsNoPartial.list)
    printf "${col0}\t${col1}\t${col2}\t${col3}\t${col4}\t${col5}\t${col6}\t${col7}\t${col8}\t${col9}\n" 
}


set_tooldir(){
	if [[ ${tool} == "penguin" ]]; then
		tooldir="../benchmark/penguin_7571d37_clu99"
	    assemblyfile="${tooldir}/${SAMPLE}.penguin.assembly.fa"
	    
	elif [[ ${tool} == "megahit" ]]; then
	    tooldir="../benchmark/megahit"
	    assemblyfile="${tooldir}/${SAMPLE}_1P_2P/megahit.contigs.fa"
	    
	elif [[ ${tool} == "rnaspades" ]]; then
	    tooldir="../benchmark/rnaspades"
	    assemblyfile="${tooldir}/${SAMPLE}_1P_2P/hard_filtered_transcripts-500.fasta"
	    
	elif [[ ${tool} == "rnaviralspades" ]]; then
	    tooldir="../benchmark/rnaviralspades"
	    assemblyfile="${tooldir}/${SAMPLE}_1P_2P/contigs-500.fasta"
	    
	elif [[ ${tool} == "metaspades" ]]; then
	    tooldir="../benchmark/metaspades"
	    assemblyfile="${tooldir}/${SAMPLE}_1P_2P/scaffolds-500.fasta"
	    
	elif [[ ${tool} == "metaviralspades" ]]; then
	    tooldir="../benchmark/metaviralspades"
	    assemblyfile="${tooldir}/${SAMPLE}_1P_2P/scaffolds-500.fasta"
	
    elif [[ ${tool} == "vicuna" ]]; then
	    tooldir="../benchmark/vicuna"
	    assemblyfile="${tooldir}/${SAMPLE}_1P_2P/contigs-500.fasta"
	
    elif [[ ${tool} == "haploflow" ]]; then
	    tooldir="../benchmark/haploflow"
	    assemblyfile="${tooldir}/${SAMPLE}_1P_2P/contigs.fa"
	fi
}

tools=( "penguin" "megahit" "rnaspades" "rnaviralspades" "metaspades" "metaviralspades" "vicuna" "haploflow" )
tooldir=""
assemblyfile=""
for tool in ${tools[@]}; do
    set_tooldir
	
    OUTFILE="${tooldir}/assembly_${SUBDIR}.per_sample_statistic.tsv"
    
    if [[ ! -f ${OUTFILE} ]]; then
		printf "SAMPLE\tTIME\tMEM\tASSEMBLED_CONTIGS\tCONTIGS_ENCODING_PHAGE_PROTEINS\tCONTIGS_ENCODING_PHAGE_PROTEINS_NON_REDUNDANT\tCONTIGS_ENCODING_PHAGE_PROTEINS_NON_REDUNDANT_750\t"  > ${OUTFILE}
	    printf "CONTIGS_ENCODING_AT_LEAST_2_PHAGE_PROTEINS\tCONTIGS_ENCODING_3_PHAGE_PROTEINS\tCONTIGS_ENCODING_3_PHAGE_PROTEINS_NO_PARTIAL\n" >> ${OUTFILE} 
		while read SAMPLE; do
			set_tooldir
			do_statistics_per_sample ${SAMPLE} ${tooldir} ${tool} ${assemblyfile} >> ${OUTFILE}
		done < samples/sra_sample_list
	fi
	
	OUTFILE2="${tooldir}/assembly_${SUBDIR}.total_statistic.tsv"
	if [[ ! -f ${OUTFILE2} ]]; then
		do_statistics_all ${tool} ${tooldir} > ${OUTFILE2}
	fi
	
	if [[ ( ! -f ${tooldir}/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial_lengths.tsv) && ( -s ${tooldir}/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial.fa) ]]; then 
	  bioawk -v tool=${tool} -c fastx '{print tool"\t"$name"\t"length($seq)}' ${tooldir}/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial.fa > ${tooldir}/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial_lengths.tsv
	fi
	
	if [[ ( ! -f ${tooldir}/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial_proteins.tsv) && ( -s ${tooldir}/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial.fa) ]]; then 
	  awk 'NR==FNR{A[$1]=1;next} $6 in A {print $0}' ${tooldir}/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial.list ${tooldir}/detection_all/${SUBDIR}/proteins.uniqueHits.tsv > ${tooldir}/detection_all/${SUBDIR}/contigsEncoding3phageProteinsNoPartial_proteins.tsv
	fi
done
