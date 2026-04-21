# CRISPResso2 Amplicon Editing Pipeline

The function of this pipeline is to quantify the percentage and diversity of indels in a genomic region targeted by CRISPR knockout, using deep Illumina sequencing. This pipeline details the molecular biology involved from starting genomic DNA to Illumina sequencing-ready library, as well as the script to execute the targeted analysis of indels.

## Overview
Workflow is broken into two stages: the library prep (wet-lab) and the indel analysis (computational).

## Experimental Workflow

### Reagents
- PCR1 Primers(Design is detailed in sections below)
- PCR Polymerase Master Mix. We use [Roche Diagnostics KAPA HiFi HotStart ReadyMix](https://www.fishersci.com/shop/products/hifi-hotstart-ready-mix-100rxn-1/501965217).
- [NEBNext® Multiplex Oligos for Illumina® (96 Unique Dual Index Primer Pairs)](https://www.neb.com/en-us/products/e6440-nebnext-multiplex-oligos-for-illumina-96-unique-dual-index-primer-pairs). These NEB primers function as PCR2 primers.
- Water
- PCR Thermocycler
- D1000 Tapestation
- NextSeq2000
### Target Region
- Shoot for a ~200bp region centered around your single-guide RNA(sgRNA) edit site. This allows for paired-end sequencing using 150 cycle flow cells.
### PCR1 Primer Design
- Primers are designed by combining ~30nt at the ends of target region with an adapter sequence. This adapter sequence allows the annealing of the primers used in PCR2, which allows for binding to Illumina flow cells. What the user needs to be determine is the overlap region with target locus.
- Considerations for primer design:
  - try to limit primer length. Try and shoot for a total primer length of ~60nt.
  - GC content 40 - 60%.
  - Melting temp of 70 or lower to prevent secondary annealing
- Template for primer design
  - Forward overhang: 5’ ACACTCTTTCCCTACACGACGCTCTTCCGATCT-[region specific sequence]. 
  - Reverse overhang: 5’ GACTGGAGTTCAGACGTGTGCTCTTCCGATCT-[region specific sequence. keep in mind this is reverse complement]. e.g targeting exon 4 in TP53: Forward strand sequence is gtctgtgacttgca. If I made a reverse PCR1 primer, I would order a primer that looks like GACTGGAGTTCAGACGTGTGCTCTTCCGATCT-**tgcaagtcacagac**.
### PCR amplification strategy
<img width="954" height="167" alt="image" src="https://github.com/user-attachments/assets/27bb5394-ed15-4489-b8f4-09343164ba19" />

- This workflow employs a two-PCR strategy. PCR1 functions to amplify the target locus, while also attaching PCR2 adapters
### Sequencing approach (paired-end, read length, depth recommendations)
- Any wet lab considerations (primer design, amplicon size constraints)

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
Clement K, Rees H, Canver MC, Gehrke JM, Farouni R, Hsu JY, Cole MA, Liu DR, Joung JK, Bauer DE, Pinello L.
CRISPResso2 provides accurate and rapid genome editing sequence analysis.
Nat Biotechnol. 2019 Mar; 37(3):224-226. doi: 10.1038/s41587-019-0032-3. PubMed PMID: 30809026.

