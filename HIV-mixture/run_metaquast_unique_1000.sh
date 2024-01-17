#!/bin/bash
#SBATCH -J "HIV1-metaquast-unique"
#SBATCH -p hh
#SBATCH -t 14-00:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 64
#SBATCH --mem=0
#SBATCH -o _clusterRuns/metaquast/out.%A.%a 
#SBATCH -e _clusterRuns/metaquast/err.%A.%a
#SBATCH --array=1-3
#SBATCH --mail-type=BEGIN,END,FAIL

id=$RANDOM
COV=$(sed "${SLURM_ARRAY_TASK_ID}q;d" cov_list)

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
#trap finish EXIT

mkdir -p ${TMP}/metaquast
mkdir -p ${TMP}/refs
mkdir -p ${TMP}/assemblies
#mkdir -p ${TMP}/reads

BENCHMARK_DIR="benchmark_cutAndDoubleRef"
declare -A TOOLS
TOOLS+=(["penguin"]="${BENCHMARK_DIR}/penguin_7571d37_clu99"
        ["megahit"]="${BENCHMARK_DIR}/megahit"
        ["rnaspades"]="${BENCHMARK_DIR}/rnaspades"
        ["rnaviralspades"]="${BENCHMARK_DIR}/rnaviralspades"
        ["metaspades"]="${BENCHMARK_DIR}/metaspades_only_assembler"
        ["metaviralspades"]="${BENCHMARK_DIR}/metaviralspades_only_assembler"
        ["haploflow"]="${BENCHMARK_DIR}/haploflow"
        ["vicuna"]="${BENCHMARK_DIR}/vicuna"
        ["savage"]="${BENCHMARK_DIR}/savage"
        ["iva"]="${BENCHMARK_DIR}/iva")

tools=( "penguin" "megahit" "metaspades" "metaviralspades" "rnaspades" "rnaviralspades" "savage" "iva" "vicuna" "haploflow")
existing=()
for key in ${tools[@]}; do
  file=(${TOOLS[$key]}/cov${COV}/*fa)
  if [[ -f ${file} ]]; then
	cp ${TOOLS[$key]}/cov${COV}/*fa ${TMP}/assemblies/${key}.fa
	existing+=("$key")
  fi
done

cp input/genomes/cutAndDouble/splits/* ${TMP}/refs/

#source /usr/users/aseidel1/miniconda3/etc/profile.d/conda.sh
#conda activate quast

OUTDIR=${BENCHMARK_DIR}/metaquast_unique/cov${COV}/
mkdir -p ${OUTDIR}
metaquast.py $(for key in ${existing[@]};do  printf " "${TMP}/assemblies/${key}.fa;done) -r ${TMP}/refs --output-dir ${TMP}/metaquast -m 1000 --threads ${SLURM_CPUS_ON_NODE} --no-icarus --unique-mapping
mv ${TMP}/metaquast/* ${OUTDIR}/
