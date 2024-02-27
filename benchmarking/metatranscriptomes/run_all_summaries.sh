#!/bin/bash

# precondition, create total detection for all
./run_total_detection.sh
./run_total_detection_unique.sh

# cluster analysis for total genome and rdrp protein
./cluster_analysis.sh

# create, for each tool, two files with assembly info by sample and of merged detection
./createAssemblyStatsitic.sh
./joinAssemblyStatistic.sh

# compare phages pairwise between tools -> input for venn diagrams
./comparePhagesPairwise.sh
