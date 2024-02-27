# penguin-analysis
Benchmarking for PenguiN paper

|--benchmarking: Includes all data and scripts used for generating the benchmark results  
|  
|--results: Includes all relevant assembly results as text files  
|  
|--notebooks: Includes jupyter notebooks for generating figures  
|  
|--figures: Includes paper figures  

############### BENCHMARKING ##################

## rhinovirus-3-mixture
This folder includes the command line to generate the reads from the input three genomes, to run the assembly tools and subsequent metaquast for the analysis
rhinovirus-3-mixture/input/ contains the benchmark reads and the orginial genomes 
rhinovirus-3-mixture/assembler/ contains how the assembly tools were called

## HIV-mixtures
This folder includes the script to generate the cutAndDouble input genomes (see paper) and simulate the reads for all three coverage sets used in the benchmarks.
Reads are not included due to size but can be re-geenerated using make_benchmarkset.sh or requested from the authors.
HIV-mixtures/assembler/ contains how the assembly tools were called
HIV-mixtures/evaluation/ contains all scripts used for the precision and sensitivity analysis

## metatranscriptomes
This folder includes the scripts and data for the analysis of ssRNA phages from real metatranscriptomic samples from activated sludge and aquatic environments.
It contains the list of 82 metatranscriptomics sample identifer for the samples from activated sludge and aquatic environments, used in Callanan et a., 2020 [1] as well as our download script.

preprocessData.sh describes the preprocessing steps using Trimmomatic and Cutadapt
metatranscriptomes/assembler includes the scripts to run the assembly tools
metatranscriptomes/evaluation includes the scripts to detect and classify ssRNA phage contigs in the assemblies

getContigsOfInterest.sh extracts all contigs >=750bp, including at least HMM protein hit 
evaluateContigs.sh performs clustering of contigs of interest at 99% idendity, filter step by step to the three sets:
contigs containing at least 2 protein hits (partial genomes), 3 protein hits (near-complete genomes), 3 protein hits without edge proteins (complete genomes)
This data are used in the per-sample analysis. This allows for example the per-location analysis (Fig. 6A)

For the over all sample analysis use run_all_summaries.sh (Fig. 5)
It contains the following steps
(1) run_total_detection collects for each assembler all contigs of interest over all samples, cluster subsequently at 99% identity, and writes the three sets (parital genomes, near-complete genomes, complete genomes)
(1b) run_total_detection_unique does the same but with 100% identity (as in the orginal study, Callanan et al., 2020)
(2) cluster_analysis clusters rdrp proteins from the complete genomes at diffefent idenity levels (Fig. 6C)
(3) createAssemblyStatistic writes for each tool time, memory, and statistic of contigs (per sample and over all)
(4) joinAssemblyStatsistic combine statistics over all assemblers 
(5) comparePhagesPairwise aligns complete genomes from different assembelrs (pairwise) to assess the inetrsection of the assembly sets

metatranscriptomes/16S_rRNA_genes: contains the detection and evaluation scripts for the 16s RRNA gene analysis
