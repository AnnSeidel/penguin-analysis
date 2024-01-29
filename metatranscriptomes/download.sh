#!/bin/bash
#SBATCH -J "download-sludgeMetaT"
#SBATCH --array=1-82%10
#SBATCH -p hh
#SBATCH -t 00-10:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH -o _clusterRuns/out.%A.%a
#SBATCH -e _clusterRuns/err.%A.%a

id=$(sed "${SLURM_ARRAY_TASK_ID}q;d" sra_sample_list)
echo ${id}
OUTPATH=/cbscratch/annika/virus-assembly-project/sludgeMetaT/samples

function finish {
        rm -rf "/local_hdd/${id}"
}
trap finish EXIT
export NO_PROXY="localhost,127.0.0.1"
export no_proxy="localhost,127.0.0.1"
export HTTP_PROXY="http://www-cache.gwdg.de:3128"
export http_proxy="http://www-cache.gwdg.de:3128"
export HTTPS_PROXY="http://www-cache.gwdg.de:3128"
export https_proxy="http://www-cache.gwdg.de:3128"
export ALL_PROXY="www-cache.gwdg.de:3128"
export all_proxy="www-cache.gwdg.de:3128"

mkdir -p /local_hdd/${id}
cd /local_hdd/${id}

if [ ! -f ${OUTPATH}/${id}_1.fastq.gz ]; then

  ~/Software/sratoolkit.2.9.2/bin/prefetch ${id} -O .
  ~/Software/sratoolkit.2.9.2/bin/fastq-dump --split-files --readids --skip-technical --gzip ${id}.sra 
  
  mv ${id}*.fastq.gz ${OUTPATH}/
  rm $id
fi
