#!/bin/bash
calc() { awk "BEGIN{print $*}";}

ASSEMBLY=$1
REFERENCE=$2
REFERENCENR=$3
OUTDIR=$4
LEN=$5

MMSEQS=/cbscratch/annika/virus-assembly-project/software/benchmark_versions/mmseqs_efacc69
ASSEMBLY_NAME=$(basename "${ASSEMBLY}")
#ASSEMBLY_NAME=${ASSEMBLY_NAME%.*}
TMPDIR="${OUTDIR}/tmp_${LEN}"
mkdir -p ${TMPDIR} #Create outdir and tmpdir if it doesn't exist


if [ -z "${SLURM_CPUS_ON_NODE}" ]; then THREADS=""; else THREADS="--threads ${SLURM_CPUS_ON_NODE}"; fi


awk -v len=$LEN '$3 >= len { print }' ${ASSEMBLY}.index > ${ASSEMBLY}.ids
if [ ! -f "${ASSEMBLY}.${LEN}" ]
then
    ${MMSEQS} createsubdb ${ASSEMBLY}.ids ${ASSEMBLY} ${ASSEMBLY}.${LEN}
    ${MMSEQS} createsubdb ${ASSEMBLY}.ids ${ASSEMBLY}_h ${ASSEMBLY}.${LEN}_h
fi

# precision
> $OUTDIR/${ASSEMBLY_NAME}.${LEN}.precision
mkdir -p ${TMPDIR}/search1 
${MMSEQS} search ${ASSEMBLY}.${LEN} ${REFERENCE} ${TMPDIR}/assembly_against_reference ${TMPDIR}/search1 --max-seqs 5000 --min-ungapped-score 100 -a --min-seq-id 0.89 --strand 2 --search-type 3 --max-seq-len 10000000  ${THREADS}
for i in $(seq 90 99| awk '{print $1/100}'); do
  ${MMSEQS} filterdb     ${TMPDIR}/assembly_against_reference ${TMPDIR}/assembly_against_reference_${i} --filter-column 3 --comparison-value ${i} --comparison-operator ge ${THREADS}
  ${MMSEQS} createtsv    ${ASSEMBLY}.${LEN} ${REFERENCE} ${TMPDIR}/assembly_against_reference_${i} ${TMPDIR}/assembly_against_reference_${i}.tsv ${THREADS}
  ${MMSEQS} rmdb ${TMPDIR}/assembly_against_reference_${i}

  # mapped fraction
  SUM=$(awk 'BEGIN{sum=0} {sum+=$3-2}END{print sum}' ${ASSEMBLY}.${LEN}.index )
  ALIGNED=$(countAlignedLenCutAndDoubleTarget.sh ${TMPDIR}/assembly_against_reference_${i}.tsv)
  printf '%.0f\t%.0f\t%.3f\n' $SUM $ALIGNED $(calc $ALIGNED/$SUM) >> $OUTDIR/${ASSEMBLY_NAME}.${LEN}.precision
  #mappedFraction.sh ${ASSEMBLY}.${LEN}.index ${TMPDIR}/assembly_against_reference_${i}.tsv $LEN >> $OUTDIR/${ASSEMBLY_NAME}.${LEN}.precision
done
cat $OUTDIR/${ASSEMBLY_NAME}.${LEN}.precision

# sensitivity
> ${OUTDIR}/${ASSEMBLY_NAME}.${LEN}.sense
mkdir -p ${TMPDIR}/search2
${MMSEQS} search $REFERENCENR ${ASSEMBLY}.${LEN} ${TMPDIR}/reference_against_assembly ${TMPDIR}/search2 --max-seqs 500000  -a --min-seq-id 0.89 --strand 2 --search-type 3  --max-seq-len 10000000 ${THREADS} 
for i in $(seq 90 99| awk '{print $1/100}'); do
  ${MMSEQS} filterdb     ${TMPDIR}/reference_against_assembly ${TMPDIR}/reference_against_assembly_${i} --filter-column 3 --comparison-value $i --comparison-operator ge ${THREADS}
  ${MMSEQS} createtsv    ${REFERENCENR} ${ASSEMBLY}.${LEN} ${TMPDIR}/reference_against_assembly_${i} ${TMPDIR}/reference_against_assembly_${i}.tsv ${THREADS}
  ${MMSEQS} rmdb ${TMPDIR}/reference_against_assembly_${i}
  #mappedFractionOverAll.sh ${REFERENCENR}.index ${TMPDIR}/reference_against_assembly_${i}.tsv $LEN >> ${OUTDIR}/${ASSEMBLY_NAME}.${LEN}.sense
  #mappedFraction.sh ${REFERENCENR}.index ${TMPDIR}/reference_against_assembly_${i}.tsv $LEN >> ${OUTDIR}/${ASSEMBLY_NAME}.${LEN}.largestAlignment
  
  # mapped fraction
  SUM=$(awk 'BEGIN{sum=0} {sum+=$3-2}END{print sum/2}' ${REFERENCENR}.index )
  ALIGNED=$(countAlignedLenCutAndDoubleRef.sh  ${TMPDIR}/reference_against_assembly_${i}.tsv)
  printf '%.0f\t%.0f\t%.3f\n' $SUM $ALIGNED $(calc $ALIGNED/$SUM) >> ${OUTDIR}/${ASSEMBLY_NAME}.${LEN}.largestAlignment
  
  # mapped fraction overall
  OVERALLALIGNED=$(coveredPositionCutAndDoubleRef.py ${TMPDIR}/reference_against_assembly_${i}.tsv $LEN)
  printf '%.0f\t%.0f\t%.3f\n' $SUM $OVERALLALIGNED $(calc $OVERALLALIGNED/$SUM) >> ${OUTDIR}/${ASSEMBLY_NAME}.${LEN}.sense

done
cat $OUTDIR/${ASSEMBLY_NAME}.${LEN}.sense



