#!/bin/bash
#SBATCH --job-name=crispresso2    # Job name
#SBATCH --mail-type=END,FAIL          # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=johnlee@coh.org     # Where to send mail  
#SBATCH -n 16                          # Number of cores
#SBATCH -N 1-1                        # Min - Max Nodes
#SBATCH -p bigmem                        # default queue is all if you don't specify
#SBATCH --mem=256G                      # Amount of memory in GB
#SBATCH --time=4:00:00               # Time limit hrs:min:sec
#SBATCH --output=serial_test_%j.log   # Standard output and error log



## ENVS ##
source /coh_labs/dits/johnlee/anaconda3/etc/profile.d/conda.sh
conda activate crispresso2





#     [-p <plot_window>] \
#     [-m <max_mismatch_pct>]
#
# Required:
#   -a  Amplicon sequence (wild-type reference, no adapters)
#   -g  sgRNA guide sequence (20bp spacer, no PAM)
#   -i  Directory containing paired FASTQ files (*_R1_001.fastq.gz)
#   -o  Output directory
#
# Optional:
#   -n  Experiment name (default: crispresso_run)
#   -t  Number of threads (default: 8)
#   -q  Minimum average read quality, phred (default: 15)
#   -w  Quantification window size around cut site in bp (default: 10)
#   -p  Plot window size around cut site in bp (default: 30)
#   -m  Max paired-end read overlap for merging (default: 150)
#
# Example:
#   bash run_crispresso2.sh \
#     -a "AGGCTGCCTGGCAGTTGG...CCACAGGAAGT" \
#     -g "ATGATAGTCACTGACAACAA" \
#     -i /path/to/fastqs \
#     -o /path/to/output \
#     -n tgfbr2_knockout
#
###############################################################################



############
## THIS IS A BATCH FUNCTION. GIVE IT THE DIR FULL OF INDIVIDUAL SAMPLE DIRS, 
## AND OUTPUT DIR AS THE GENERIC DIR TO CREATE SAMPLE-SPECIFIC DIRS.



## it can technically handle single sample dirs as well. leave the output as the same as the generic outputdir.
###########


amplicon="AGGCTGCCTGGCAGTTGGATAATCATTTAATATATCTTTCTCTCTCCTCAGTTAATAACGACATGATAGTCACTGACAACAACGGTGCAGTCAAGTTTCCACAACTGTGTAAATTTTGTGATGTGAGATTTTCCACCTGTGACAACCAGAAATCCTGCATGAGCAACTGCAGCATCACCTCCATCTGTGAGAAGCCACAGGAAGT"
guide="ATGATAGTCACTGACAACAA"

input_dir="/coh_labs/dits/johnlee/tgfbr2/fastqs/260415/"
output_dir="/coh_labs/dits/johnlee/tgfbr2/crispresso_outputs/"

experiment_name="260415_pilot"

bash /home/jolee/scripts/tgfbr2/crispresso2.sh \
    -a ${amplicon} \
    -g ${guide} \
    -i ${input_dir} \
    -o ${output_dir} \
    -n ${experiment_name}