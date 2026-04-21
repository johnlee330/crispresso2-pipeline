# CRISPResso2 Amplicon Editing Pipeline

The function of this pipeline is to quantify the percentage and diversity of indels in a genomic region targeted by CRISPR knockout, using deep Illumina sequencing. This pipeline details the molecular biology involved from starting genomic DNA to Illumina sequencing-ready library, as well as the script to execute the targeted analysis of indels.

## Overview
Workflow is broken into two stages: the library prep (wet-lab) and the indel analysis (computational).

## Molecular Biology

### Target Region
- Shoot for a ~200bp region centered around your single-guide RNA(sgRNA) edit site. This allows for paired-end sequencing using 150 cycle flow cells.
### Primer Design
- Primers are designed by combining 30nt at the ends of target region with an adapter sequence. This adapter sequence allows the annealing of the primers used in PCR2, which allows for binding to Illumina flow cells.
- 
### Library prep / PCR amplification strategy
### Sequencing approach (paired-end, read length, depth recommendations)
- Any wet lab considerations (primer design, amplicon size constraints)
<img width="954" height="167" alt="image" src="https://github.com/user-attachments/assets/27bb5394-ed15-4489-b8f4-09343164ba19" />

## Computational Pipeline
- Dependencies / installation (CRISPResso2, conda env)
- Input requirements (FASTQ format, directory structure)
- Usage with all flags explained
- Output files and how to interpret them

## Example Run
Paste your example run command here

## Parameters Reference
Table of all flags with defaults and descriptions

## Citation / Acknowledgements
