# CRISPResso2 Amplicon Editing Pipeline

The function of this pipeline is to quantify the percentage and diversity of indels in a genomic region targeted by CRISPR knockout, using deep Illumina sequencing. This pipeline details the molecular biology involved from starting genomic DNA to Illumina sequencing-ready library, as well as the script to execute the targeted analysis of indels.

## Overview
Workflow is broken into two stages: the library prep (wet-lab) and the indel analysis (computational).

## Experimental Workflow

### Target Region
- Shoot for a ~200bp region centered around your single-guide RNA(sgRNA) edit site. This allows for paired-end sequencing using 150 cycle flow cells.
### Primer Design
- Primers are designed by combining ~30nt at the ends of target region with an adapter sequence. This adapter sequence allows the annealing of the primers used in PCR2, which allows for binding to Illumina flow cells. What the user needs to be determine is the overlap region with target locus.
- Considerations for primer design:
-   try to limit primer length. Try and shoot for a total primer length of ~60nt.
-   GC content 40 - 60%.
-   Melting temp of 70 or lower to prevent secondary annealing
### Library prep / PCR amplification strategy
### Sequencing approach (paired-end, read length, depth recommendations)
- Any wet lab considerations (primer design, amplicon size constraints)
<img width="954" height="167" alt="image" src="https://github.com/user-attachments/assets/27bb5394-ed15-4489-b8f4-09343164ba19" />

## Computational Workflow
- Dependencies
-   CRISPResso2. Installation guide is [here](https://docs.crispresso.com/installation.html)
- Inputs
-   FASTQs
- Usage with all flags explained
- Output files and how to interpret them

## Example Run
Paste your example run command here

## Parameters Reference
Table of all flags with defaults and descriptions

## Citation / Acknowledgements
