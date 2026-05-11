#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
echo "Usage: $0 <input.fastq.gz> <trascriptome.fa> <out_prefix> <n_threads>"
exit 1
fi

TRANSCRIPTOME=$2
FASTQ=$1
OUT_PREFIX=$3
THREADS=${4-16}


# Optional HPC module loading.
# Works on your server, silently skipped elsewhere.
if command -v ml >/dev/null 2>&1; then
    ml GCC/13.3.0 || true
    ml minimap2 || true
    ml SAMtools/1.21 || true
fi

# Check tools after optional module loading.
command -v minimap2 >/dev/null 2>&1 || {
    echo "ERROR: minimap2 not found in PATH"
    exit 1
}

command -v samtools >/dev/null 2>&1 || {
    echo "ERROR: samtools not found in PATH"
    exit 1
}

echo "Mapping:"
echo "  FASTQ        : ${FASTQ}"
echo "  Transcriptome: ${TRANSCRIPTOME}"
echo "  Output BAM   : ${OUT_PREFIX}.bam"
echo "  Threads      : ${THREADS}"

minimap2 \
    -ax map-ont \
    --cap-kalloc 100m \
    --cap-sw-mem 50m \
    --end-bonus 10 \
    -p 0.9 \
    -N 3 \
    -t "${THREADS}" \
    "${TRANSCRIPTOME}" \
    "${FASTQ}" \
| samtools view \
    -h \
    -@ 2 \
    -b \
    -F 2308 \
    -o "${OUT_PREFIX}.bam" \
    -
echo "Done:"
echo "  ${OUT_PREFIX}.bam"
