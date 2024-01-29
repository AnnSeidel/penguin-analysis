# penguin-analysis
Benchmarking for PenguiN paper

Includes all data and scripts used for generating the benchmark results

## rhinovirus-3-mixture
This folder includes the command line to generate the reads from the input genomes, to run the assembly tools and subsequent metaquast for teh analysis
rhinovirus-3-mixture/input/ contains the benchmark reads and the orginial genomes 

## HIV-mixture
This folder includes the script to generate the cutAndDouble input genomes (see paper) and simulate the reads for all three coverage sets used in the benchmarks.
Reads are not included due to size but can be re-geenerated using make_benchmarkset.sh or requested from the authors.
Includes the command line run the assembly tools and evaluation tools