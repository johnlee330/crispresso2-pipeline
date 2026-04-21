#!/bin/bash

#   usage
#   bash run_crispresso2.sh \
#     -a <amplicon_seq> \
#     -g <guide_seq> \
#     -i <fastq_dir> \
#     -o <output_dir> \
#     [-n <experiment_name>] \
#     [-t <threads>] \
#     [-q <min_avg_quality>] \
#     [-w <quantification_window>] \
#     [-p <plot_window>] \
#     [-m <max_mismatch_pct>]
#
# required parameters:
#   -a  Amplicon sequence (wild-type reference, no adapters)
#   -g  sgRNA guide sequence (20bp spacer, no PAM)
#   -i  Directory containing paired FASTQ files (*_R1_001.fastq.gz)
#   -o  Output directory
#
# optional:
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

set -euo pipefail

#==============================================================================
# Parse command-line arguments
#==============================================================================

AMPLICON_SEQ=""
GUIDE_SEQ=""
FASTQ_DIR=""
OUTPUT_DIR=""
EXP_NAME="crispresso_run"
THREADS=8
MIN_AVG_QUALITY=15
QUANT_WINDOW=10
PLOT_WINDOW=30
MAX_OVERLAP=150

usage() {
    echo ""
    echo "Usage: $0 -a <amplicon_seq> -g <guide_seq> -i <fastq_dir> -o <output_dir> [options]"
    echo ""
    echo "Required:"
    echo "  -a  Wild-type amplicon sequence (no adapters)"
    echo "  -g  sgRNA guide sequence (20bp spacer, no PAM)"
    echo "  -i  Directory containing paired FASTQ files"
    echo "  -o  Output directory"
    echo ""
    echo "Optional:"
    echo "  -n  Experiment name (default: crispresso_run)"
    echo "  -t  Threads (default: 8)"
    echo "  -q  Min average read quality (default: 15)"
    echo "  -w  Quantification window around cut site, bp (default: 10)"
    echo "  -p  Plot window around cut site, bp (default: 30)"
    echo "  -m  Max paired-end overlap for read merging (default: 150)"
    echo "  -h  Show this help message"
    echo ""
    exit 1
}

while getopts "a:g:i:o:n:t:q:w:p:m:h" opt; do
    case $opt in
        a) AMPLICON_SEQ="$OPTARG" ;;
        g) GUIDE_SEQ="$OPTARG" ;;
        i) FASTQ_DIR="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        n) EXP_NAME="$OPTARG" ;;
        t) THREADS="$OPTARG" ;;
        q) MIN_AVG_QUALITY="$OPTARG" ;;
        w) QUANT_WINDOW="$OPTARG" ;;
        p) PLOT_WINDOW="$OPTARG" ;;
        m) MAX_OVERLAP="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

#==============================================================================
# Validate inputs
#==============================================================================

ERRORS=0

if [[ -z "$AMPLICON_SEQ" ]]; then
    echo "ERROR: Amplicon sequence (-a) is required."
    ERRORS=1
fi

if [[ -z "$GUIDE_SEQ" ]]; then
    echo "ERROR: Guide sequence (-g) is required."
    ERRORS=1
fi

if [[ -z "$FASTQ_DIR" ]]; then
    echo "ERROR: FASTQ directory (-i) is required."
    ERRORS=1
elif [[ ! -d "$FASTQ_DIR" ]]; then
    echo "ERROR: FASTQ directory does not exist: $FASTQ_DIR"
    ERRORS=1
fi

if [[ -z "$OUTPUT_DIR" ]]; then
    echo "ERROR: Output directory (-o) is required."
    ERRORS=1
fi

if [[ $ERRORS -gt 0 ]]; then
    usage
fi

# Validate sequences contain only valid DNA characters
if [[ ! "$AMPLICON_SEQ" =~ ^[ACGTacgt]+$ ]]; then
    echo "ERROR: Amplicon sequence contains non-DNA characters."
    exit 1
fi

if [[ ! "$GUIDE_SEQ" =~ ^[ACGTacgt]+$ ]]; then
    echo "ERROR: Guide sequence contains non-DNA characters."
    exit 1
fi

# Convert to uppercase
AMPLICON_SEQ=$(echo "$AMPLICON_SEQ" | tr 'acgt' 'ACGT')
GUIDE_SEQ=$(echo "$GUIDE_SEQ" | tr 'acgt' 'ACGT')

# Check that guide exists in amplicon (forward or reverse complement)
GUIDE_RC=$(echo "$GUIDE_SEQ" | rev | tr 'ACGT' 'TGCA')

GUIDE_STRAND="not found"
if echo "$AMPLICON_SEQ" | grep -qi "$GUIDE_SEQ"; then
    GUIDE_STRAND="forward"
    GUIDE_POS=$(echo "$AMPLICON_SEQ" | grep -ob "$GUIDE_SEQ" | cut -d: -f1)
elif echo "$AMPLICON_SEQ" | grep -qi "$GUIDE_RC"; then
    GUIDE_STRAND="reverse complement"
    GUIDE_POS=$(echo "$AMPLICON_SEQ" | grep -ob "$GUIDE_RC" | cut -d: -f1)
fi

if [[ "$GUIDE_STRAND" == "not found" ]]; then
    echo "WARNING: Guide sequence not found in amplicon (checked both strands)."
    echo "  Guide:    $GUIDE_SEQ"
    echo "  Guide RC: $GUIDE_RC"
    echo "  CRISPResso2 will still run but may not correctly identify the cut site."
    echo "  Double-check your guide and amplicon sequences."
    echo ""
fi

# Check CRISPResso2 is installed
if ! command -v CRISPResso &> /dev/null; then
    echo "ERROR: CRISPResso2 not found in PATH."
    echo ""
    echo "Install with conda:"
    echo "  conda create -n crispresso2_env -c bioconda crispresso2"
    echo "  conda activate crispresso2_env"
    echo ""
    echo "Or with pip:"
    echo "  pip install CRISPResso2"
    exit 1
fi

#==============================================================================
# Setup
#==============================================================================
OUTPUT_DIR=$(realpath "$OUTPUT_DIR")
FASTQ_DIR=$(realpath "$FASTQ_DIR")


mkdir -p "$OUTPUT_DIR"

# Log all parameters
LOG_FILE="${OUTPUT_DIR}/${EXP_NAME}_pipeline.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "============================================"
echo "CRISPResso2 Amplicon Analysis Pipeline"
echo "============================================"
echo "Experiment:          $EXP_NAME"
echo "Started:             $(date)"
echo "Amplicon length:     ${#AMPLICON_SEQ} bp"
echo "Guide sequence:      $GUIDE_SEQ (${#GUIDE_SEQ} bp)"
echo "Guide strand:        $GUIDE_STRAND"
if [[ "$GUIDE_STRAND" != "not found" ]]; then
    echo "Guide position:      $GUIDE_POS"
fi
echo "FASTQ directory:     $FASTQ_DIR"
echo "Output directory:    $OUTPUT_DIR"
echo "Threads:             $THREADS"
echo "Min avg quality:     $MIN_AVG_QUALITY"
echo "Quant window:        $QUANT_WINDOW bp"
echo "Plot window:         $PLOT_WINDOW bp"
echo "Max PE overlap:      $MAX_OVERLAP bp"
echo "CRISPResso2 version: $(CRISPResso --version 2>&1 || echo 'unknown')"
echo "============================================"
echo ""

#==============================================================================
# Build batch file
#==============================================================================

# Helper: strip BaseSpace download suffixes from sample/directory names
# e.g. "MUT_R1-ds.874a3b2c" -> "MUT_R1"
#      "CSF_R3-ds.12345678-90ab-cdef" -> "CSF_R3"
clean_sample_name() {
    echo "$1" | sed -E 's/-ds\.[a-f0-9].*$//'
}

BATCH_FILE="${OUTPUT_DIR}/${EXP_NAME}_batch.tsv"
echo -e "name\tfastq_r1\tfastq_r2" > "$BATCH_FILE"

echo "Scanning for FASTQ pairs..."

FOUND=0

# Strategy 1: Subdirectory structure (each sample in its own folder)
#   FASTQ_DIR/
#     MUT_R1-ds.874a3b2c/
#       MUT_R1_S1_L001_R1_001.fastq.gz
#       MUT_R1_S1_L001_R2_001.fastq.gz

for SUBDIR in "${FASTQ_DIR}"/*/; do
    [[ -d "$SUBDIR" ]] || continue
    RAW_NAME=$(basename "$SUBDIR")
    SAMPLE=$(clean_sample_name "$RAW_NAME")

    # Look for R1 in this subdirectory (BaseSpace naming)
    R1=$(find "$SUBDIR" -maxdepth 1 -name "*_R1_001.fastq.gz" -type f | head -1)
    if [[ -n "$R1" ]]; then
        R2="${R1/_R1_001.fastq.gz/_R2_001.fastq.gz}"
        if [[ -f "$R2" ]]; then
            echo -e "${SAMPLE}\t${R1}\t${R2}" >> "$BATCH_FILE"
            echo "  Found: $SAMPLE (from dir: $RAW_NAME)"
            FOUND=$((FOUND + 1))
            continue
        fi
    fi

    # Try simpler naming (*_1.fastq.gz)
    R1=$(find "$SUBDIR" -maxdepth 1 -name "*_1.fastq.gz" -type f | head -1)
    if [[ -n "$R1" ]]; then
        R2="${R1/_1.fastq.gz/_2.fastq.gz}"
        if [[ -f "$R2" ]]; then
            echo -e "${SAMPLE}\t${R1}\t${R2}" >> "$BATCH_FILE"
            echo "  Found: $SAMPLE (from dir: $RAW_NAME)"
            FOUND=$((FOUND + 1))
            continue
        fi
    fi

    # Try any *R1*.fastq.gz
    R1=$(find "$SUBDIR" -maxdepth 1 -name "*R1*.fastq.gz" -type f | head -1)
    if [[ -n "$R1" ]]; then
        R2=$(echo "$R1" | sed 's/R1/R2/')
        if [[ -f "$R2" ]]; then
            echo -e "${SAMPLE}\t${R1}\t${R2}" >> "$BATCH_FILE"
            echo "  Found: $SAMPLE (from dir: $RAW_NAME)"
            FOUND=$((FOUND + 1))
        fi
    fi
done

# Strategy 2: Flat directory (all FASTQs in one folder) — fallback
if [[ $FOUND -eq 0 ]]; then
    echo "  No subdirectories with FASTQs found. Trying flat directory..."
    for R1 in "${FASTQ_DIR}"/*_R1_001.fastq.gz; do
        if [[ -f "$R1" ]]; then
            R2="${R1/_R1_001.fastq.gz/_R2_001.fastq.gz}"
            if [[ -f "$R2" ]]; then
                RAW_NAME=$(basename "$R1" | sed 's/_S[0-9]*_L[0-9]*_R1_001.fastq.gz//')
                SAMPLE=$(clean_sample_name "$RAW_NAME")
                echo -e "${SAMPLE}\t${R1}\t${R2}" >> "$BATCH_FILE"
                echo "  Found: $SAMPLE (flat)"
                FOUND=$((FOUND + 1))
            fi
        fi
    done
fi

# Strategy 3: Flat directory with simpler naming — last resort
if [[ $FOUND -eq 0 ]]; then
    echo "  Trying *_1.fastq.gz pattern..."
    for R1 in "${FASTQ_DIR}"/*_1.fastq.gz; do
        if [[ -f "$R1" ]]; then
            R2="${R1/_1.fastq.gz/_2.fastq.gz}"
            if [[ -f "$R2" ]]; then
                RAW_NAME=$(basename "$R1" | sed 's/_1.fastq.gz//')
                SAMPLE=$(clean_sample_name "$RAW_NAME")
                echo -e "${SAMPLE}\t${R1}\t${R2}" >> "$BATCH_FILE"
                echo "  Found: $SAMPLE (flat)"
                FOUND=$((FOUND + 1))
            fi
        fi
    done
fi

echo ""
echo "Total samples found: $FOUND"

if [[ $FOUND -eq 0 ]]; then
    echo "ERROR: No FASTQ pairs found in $FASTQ_DIR"
    echo "Supported layouts:"
    echo "  1. Subdirectories:  FASTQ_DIR/SampleName[-ds.xxx]/*.fastq.gz"
    echo "  2. Flat directory:  FASTQ_DIR/*_R1_001.fastq.gz"
    echo "  3. Flat simple:     FASTQ_DIR/*_1.fastq.gz"
    exit 1
fi

#==============================================================================
# Run CRISPRessoBatch
#==============================================================================

echo ""
echo "============================================"
echo "Running CRISPRessoBatch ($FOUND samples)"
echo "============================================"
echo ""

CRISPRessoBatch \
    --batch_settings "$BATCH_FILE" \
    --amplicon_seq "$AMPLICON_SEQ" \
    --amplicon_name "${EXP_NAME}" \
    --guide_seq "$GUIDE_SEQ" \
    --output_folder "$OUTPUT_DIR" \
    --min_average_read_quality "$MIN_AVG_QUALITY" \
    --quantification_window_size "$QUANT_WINDOW" \
    --plot_window_size "$PLOT_WINDOW" \
    --n_processes "$THREADS" \
    --max_paired_end_reads_overlap "$MAX_OVERLAP" \
    --min_paired_end_reads_overlap 10 \
    --stringent_flash_merging \
    --place_report_in_output_folder \
    2>&1

CRISPRESSO_EXIT=$?

if [[ $CRISPRESSO_EXIT -ne 0 ]]; then
    echo ""
    echo "WARNING: CRISPRessoBatch exited with code $CRISPRESSO_EXIT"
    echo "Check individual sample logs for errors."
fi

#==============================================================================
# Summarize results
#==============================================================================

echo ""
echo "============================================"
echo "Extracting Results"
echo "============================================"

SUMMARY_FILE="${OUTPUT_DIR}/${EXP_NAME}_editing_summary.tsv"

# Write header
echo -e "Sample\tTotal_Reads_Input\tReads_After_Merge\tReads_Aligned\tPct_Unmodified\tPct_Modified\tPct_Insertions\tPct_Deletions\tPct_Substitutions\tMean_Insertion_Size\tMean_Deletion_Size" > "$SUMMARY_FILE"

for SAMPLE_DIR in "${OUTPUT_DIR}"/CRISPRessoBatch_on_*/CRISPResso_on_*/ "${OUTPUT_DIR}"/CRISPResso_on_*/; do
    [[ -d "$SAMPLE_DIR" ]] || continue
    SAMPLE_NAME=$(basename "$SAMPLE_DIR" | sed 's/CRISPResso_on_//')

    # CRISPResso2 stores results in multiple files depending on version
    # Try the mapping statistics file first
    MAP_FILE="${SAMPLE_DIR}/CRISPResso_mapping_statistics.txt"
    QUANT_FILE="${SAMPLE_DIR}/CRISPResso_quantification_of_editing_frequency.txt"

    if [[ -f "$QUANT_FILE" ]]; then
        # Parse quantification file (tab-separated, header + 1 data row per amplicon)
        # Columns vary by version but typically include:
        # Amplicon, Unmodified%, Modified%, Reads_aligned, etc.
        
        # Use Python for robust parsing
        python3 -c "
import sys, os
quant_file = '${QUANT_FILE}'
sample = '${SAMPLE_NAME}'

try:
    with open(quant_file) as f:
        header = f.readline().strip().split('\t')
        data = f.readline().strip().split('\t')
    
    d = dict(zip(header, data))
    
    # Extract fields (handle different CRISPResso2 versions)
    def get(keys, default='NA'):
        for k in keys:
            for h in d:
                if k.lower() in h.lower():
                    return d[h]
        return default
    
    reads_input = get(['Reads_Input', 'reads_input', 'Total'])
    reads_merged = get(['Reads_after_merging', 'reads_merged'])
    reads_aligned = get(['Reads_Aligned', 'reads_aligned'])
    pct_unmod = get(['Unmodified%', 'unmodified'])
    pct_mod = get(['Modified%', 'modified'])
    pct_ins = get(['Insertions%', 'insertions', 'Only Insertions'])
    pct_del = get(['Deletions%', 'deletions', 'Only Deletions'])
    pct_sub = get(['Substitutions%', 'substitutions', 'Only Substitutions'])
    
    print(f'{sample}\t{reads_input}\t{reads_merged}\t{reads_aligned}\t{pct_unmod}\t{pct_mod}\t{pct_ins}\t{pct_del}\t{pct_sub}\tNA\tNA')
except Exception as e:
    print(f'{sample}\tERROR\t{e}', file=sys.stderr)
    print(f'{sample}\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA')
" >> "$SUMMARY_FILE"
        echo "  Processed: $SAMPLE_NAME"
    else
        echo "  WARNING: No quantification file for $SAMPLE_NAME"
        echo -e "${SAMPLE_NAME}\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA" >> "$SUMMARY_FILE"
    fi
done

#==============================================================================
# Print summary table
#==============================================================================

echo ""
echo "============================================"
echo "Editing Efficiency Summary"
echo "============================================"
echo ""
column -t -s $'\t' "$SUMMARY_FILE" 2>/dev/null || cat "$SUMMARY_FILE"

#==============================================================================
# Generate summary plot
#==============================================================================

echo ""
echo "Generating summary plots..."

export OUTPUT_DIR
export EXP_NAME

python3 << 'PYTHON_SCRIPT'
import os
import sys
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

output_dir = os.environ.get('OUTPUT_DIR', '.')
exp_name = os.environ.get('EXP_NAME', 'crispresso_run')

summary_file = os.path.join(output_dir, f'{exp_name}_editing_summary.tsv')

if not os.path.exists(summary_file):
    print("  No summary file found, skipping plots.")
    sys.exit(0)

df = pd.read_csv(summary_file, sep='\t')

# Clean up percentage columns (remove % signs if present, convert to float)
for col in ['Pct_Unmodified', 'Pct_Modified', 'Pct_Insertions', 'Pct_Deletions', 'Pct_Substitutions']:
    if col in df.columns:
        df[col] = pd.to_numeric(df[col].astype(str).str.replace('%', ''), errors='coerce')

if 'Pct_Modified' not in df.columns or df['Pct_Modified'].isna().all():
    print("  No modification data found, skipping plots.")
    sys.exit(0)

# Parse sample groups and replicates
# Try to extract group name by removing trailing _R# or _Rep#
df['Group'] = df['Sample'].str.replace(r'[_-][Rr](?:ep)?\.?\d+$', '', regex=True)
df['Replicate'] = df['Sample'].str.extract(r'[_-][Rr](?:ep)?\.?(\d+)$')[0].fillna('1')

# Sort by group
df = df.sort_values(['Group', 'Replicate'])

# --- Figure 1: Editing efficiency by group ---
fig, axes = plt.subplots(1, 2, figsize=(14, 6))

# Group-level bar plot with replicates as points
group_stats = df.groupby('Group', sort=False)['Pct_Modified'].agg(['mean', 'std', 'count']).reset_index()
group_stats.columns = ['Group', 'Mean', 'SD', 'N']
group_stats = group_stats.sort_values('Mean', ascending=False)

colors = plt.cm.Set2(np.linspace(0, 1, max(len(group_stats), 3)))

ax = axes[0]
bars = ax.bar(range(len(group_stats)), group_stats['Mean'],
              yerr=group_stats['SD'], capsize=5,
              color=colors[:len(group_stats)], edgecolor='black', linewidth=0.5)
ax.set_xticks(range(len(group_stats)))
ax.set_xticklabels(group_stats['Group'], rotation=45, ha='right')
ax.set_ylabel('% Modified Reads')
ax.set_title(f'{exp_name}: Editing Efficiency by Group')
ax.set_ylim(0, min(max(group_stats['Mean'].max() * 1.3, 10), 105))

# Overlay individual data points
for i, group in enumerate(group_stats['Group']):
    group_data = df[df['Group'] == group]['Pct_Modified']
    ax.scatter([i] * len(group_data), group_data, color='black',
              zorder=5, s=30, alpha=0.7)

# --- Figure 2: Stacked bar showing edit types ---
ax2 = axes[1]
edit_types = []
for col, label in [('Pct_Deletions', 'Deletions'), ('Pct_Insertions', 'Insertions'),
                    ('Pct_Substitutions', 'Substitutions')]:
    if col in df.columns and not df[col].isna().all():
        edit_types.append((col, label))

if edit_types:
    group_order = group_stats['Group'].tolist()
    bottoms = np.zeros(len(group_order))
    type_colors = {'Deletions': '#e74c3c', 'Insertions': '#3498db', 'Substitutions': '#2ecc71'}

    for col, label in edit_types:
        vals = df.groupby('Group', sort=False)[col].mean().reindex(group_order).fillna(0).values
        ax2.bar(range(len(group_order)), vals, bottom=bottoms,
                label=label, color=type_colors.get(label, 'gray'),
                edgecolor='black', linewidth=0.5)
        bottoms += vals

    ax2.set_xticks(range(len(group_order)))
    ax2.set_xticklabels(group_order, rotation=45, ha='right')
    ax2.set_ylabel('% Reads')
    ax2.set_title(f'{exp_name}: Edit Type Breakdown')
    ax2.legend(loc='upper right')
    ax2.set_ylim(0, min(max(bottoms.max() * 1.3, 10), 105))
else:
    ax2.text(0.5, 0.5, 'No edit type data available',
             transform=ax2.transAxes, ha='center', va='center')

plt.tight_layout()
plot_path = os.path.join(output_dir, f'{exp_name}_editing_summary.png')
plt.savefig(plot_path, dpi=150, bbox_inches='tight')
plt.savefig(plot_path.replace('.png', '.pdf'), bbox_inches='tight')
print(f"  Saved: {plot_path}")

# --- Print summary ---
print(f"\n  {'Group':<15} {'Mean %Mod':>10} {'SD':>8} {'N':>4}")
print("  " + "-" * 42)
for _, row in group_stats.iterrows():
    sd_str = f"{row['SD']:.1f}" if pd.notna(row['SD']) else "NA"
    print(f"  {row['Group']:<15} {row['Mean']:>9.1f}% {sd_str:>7} {int(row['N']):>4}")

PYTHON_SCRIPT

#==============================================================================
# Done
#==============================================================================

echo ""
echo "============================================"
echo "Pipeline Complete: $(date)"
echo "============================================"
echo ""
echo "Output: $OUTPUT_DIR"
echo ""
echo "Key files:"
echo "  ${EXP_NAME}_editing_summary.tsv   Editing rates per sample"
echo "  ${EXP_NAME}_editing_summary.png   Summary bar plots"
echo "  ${EXP_NAME}_pipeline.log          Full pipeline log"
echo "  CRISPResso_on_*/                  Per-sample results:"
echo "    - Allele_frequency_table.zip      Every unique variant + count"
echo "    - Indel_histogram.txt             Indel size distribution"
echo "    - CRISPResso2_report.html         Interactive report"
echo ""
echo "============================================"