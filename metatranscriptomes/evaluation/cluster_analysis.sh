#!/bin/bash
#SBATCH -J "sludgeMetaT-clustering"
#SBATCH -p hh
#SBATCH -t 14-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 64
#SBATCH -o ../_clusterRuns/clustering/out.%J 
#SBATCH -e ../_clusterRuns/clustering/err.%J

MMSEQS="/cbscratch/annika/virus-assembly-project/software/benchmark_versions/mmseqs_efacc69"

SUBDIR=clu99

if [ -z "${SLURM_CPUS_ON_NODE}" ]; then THREADS=""; else THREADS="--threads ${SLURM_CPUS_ON_NODE}"; fi

calc() { awk "BEGIN{print $*}";}

function do_clustering {
    NAME=$1
    DETECTION_DIR=$2
    SAMPLE_DETECTION_DIR=$3
    RESULT_DIR=$4
    cov=$5

    if [[ ! -f ${RESULT_DIR}/clust_c${cov}.tsv ]];then

        mkdir -p ${RESULT_DIR}/tmp
        
        if [[ ! -f ${RESULT_DIR}/RdRps_completePhages.fa ]];then
          if [[ ! -s ${DETECTION_DIR}/contigsEncoding3phageProteinsNoPartial.list ]]; then
			      echo "Could not find ${DETECTION_DIR}/contigsEncoding3phageProteinsNoPartial.list"
			      return
		      fi
			    awk 'NR==FNR{A[$1]=1;S[$1]=0;next} $6 in A && $8 ~ /RdRp/ && $5 == 00 && $9>S[$6]{S[$6]=$9;A[$6]=$1}END{for (i in A){print A[i]}}' \
			        ${DETECTION_DIR}/contigsEncoding3phageProteinsNoPartial.list ${DETECTION_DIR}/proteins.uniqueHits.tsv > ${RESULT_DIR}/tmp/rdrps.list
              > ${RESULT_DIR}/RdRps_completePhages.fa
          for f in ${SAMPLE_DETECTION_DIR}/detection_SRR*/detection_tmp/*proteins.fa; do
            if [[ -s $f ]];then
              bioawk -c fastx -v file="${RESULT_DIR}/tmp/rdrps.list" 'BEGIN{while((getline k < file)>0)i[k]=1}{if(i[$name])print ">"$name"\n"$seq}' \
                  >> ${RESULT_DIR}/RdRps_completePhages.fa
            fi
          done
        fi

        "${MMSEQS}" createdb ${RESULT_DIR}/RdRps_completePhages.fa ${RESULT_DIR}/tmp/contigsEncoding3phageProteinsNoPartial.rdrps.db
        dbRdRpFile=${RESULT_DIR}/tmp/contigsEncoding3phageProteinsNoPartial.rdrps.db

        for i in `seq 50 10 90 && seq 91 1 100`; do 
          WORKDIR_LIN="${RESULT_DIR}/tmp/clust_c${cov}_sid${i}"
          "${MMSEQS}" cluster ${dbRdRpFile} ${dbRdRpFile}.clu_c${cov}_sid${i} ${WORKDIR_LIN} -c $(calc $cov/100) --cov-mode 1 --min-seq-id $(calc $i/100) --max-seqs 50000 --diag-score 1 --zdrop 200 ${THREADS}
          echo -e ${NAME}"\tRdRp\t"${cov}"\t"$i"\t" $(wc -l < ${dbRdRpFile}.clu_c${cov}_sid${i}.index)  >> ${RESULT_DIR}/clust_c${cov}.tsv
        done;
       
        rm -rf "${RESULT_DIR}/tmp"
    fi
}

COV=99

#PENGUIN
do_clustering "penguin" ../benchmark/penguin_7571d37_clu99/detection_all/${SUBDIR} ../benchmark/penguin_7571d37_clu99/ ../benchmark/penguin_7571d37_clu99/detection_all/${SUBDIR}/rdrp_clustering/ ${COV}

#rnaspades
do_clustering "rnaspades" "../benchmark/rnaspades/detection_all/${SUBDIR}" "../benchmark/rnaspades/" "../benchmark/rnaspades/detection_all/${SUBDIR}/rdrp_clustering/" ${COV}

#rnaviralspades
do_clustering "rnaviralspades" "../benchmark/rnaviralspades/detection_all/${SUBDIR}" "../benchmark/rnaviralspades/" "../benchmark/rnaviralspades/detection_all/${SUBDIR}/rdrp_clustering/" ${COV}

#metaspades
do_clustering "metaspades" "../benchmark/metaspades/detection_all/${SUBDIR}" "../benchmark/metaspades/" "../benchmark/metaspades/detection_all/${SUBDIR}/rdrp_clustering/" ${COV}

#metaviralspades
#do_clustering "metaviralspades" "../benchmark/metaviralspades/detection_all/${SUBDIR}" "../benchmark/metaviralspades/" "../benchmark/metaviralspades/detection_all/${SUBDIR}/rdrp_clustering/" ${COV}

#megahit
do_clustering "megahit" "../benchmark/megahit/detection_all/${SUBDIR}" "../benchmark/megahit/" "../benchmark/megahit/detection_all/${SUBDIR}/rdrp_clustering/" ${COV}

#vicuna
do_clustering "vicuna" "../benchmark/vicuna/detection_all/${SUBDIR}" "../benchmark/vicuna/" "../benchmark/vicuna/detection_all/${SUBDIR}/rdrp_clustering/" ${COV}

#haploflow
do_clustering "haploflow" "../benchmark/haploflow/detection_all/${SUBDIR}" "../benchmark/haploflow/" "../benchmark/haploflow/detection_all/${SUBDIR}/rdrp_clustering/" ${COV}

echo -e "Tool\tType\tCluster Coverage\tCluster SeqId\tNum Representatives" > ../benchmark/summaries/clust_c${COV}.tsv;
for f in ../benchmark/*/detection_all/${SUBDIR}/rdrp_clustering/clust_c${COV}.tsv; do tail --lines=+2 $f; done >> ../benchmark/summaries/${SUBDIR}/clust_c${COV}.tsv

