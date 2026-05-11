# sc-ont-mut-quant

Single-cell Oxford Nanopore mutation-aware transcript quantification.

---

## Overview

sc-ont-mut-quant is a Nextflow pipeline for processing
single-cell Oxford Nanopore transcriptome sequencing data
into mutation-aware expression matrices.

The workflow:

1. Normalizes ONT reads into a consistent 10x-like structure
2. Maps reads to a transcriptome
3. Converts transcript coordinates back to genomic coordinates
4. Quantifies transcript expression
5. Detects SNP support directly from aligned reads
6. Produces sparse matrices compatible with downstream single-cell analysis

The pipeline is designed for targeted and full-transcript
single-cell ONT workflows where transcript identity and
mutation state must be analyzed simultaneously.

---

## Features

* Single-cell ONT preprocessing
* Mutation-aware transcript quantification
* Transcriptome → genome coordinate conversion
* SNP-aware read classification
* Multi-BAM support
* Static MUSL-compiled Rust binaries
* Nextflow DSL2 workflow
* HPC-friendly
* No Python runtime required during execution

---

## Workflow

```text
ONT BAM
  ↓
bam-ont-normalizer
  ↓
normalized FASTQ + CB/UMI table
  ↓
minimap2
  ↓
transcriptome BAM
  ↓
bam-transcriptome-to-genome
  ↓
genomic BAM
  ↓
bam-quant
  ↓
expression + SNP matrices
```

---

## Requirements

* Nextflow >= 24
* Java >= 17
* minimap2
* samtools

No Rust installation is required for running the pipeline.

---

## Installation

Clone the repository:

```bash
git clone https://github.com/stela2502/sc-ont-mut-quant.git
cd sc-ont-mut-quant
```

---

## Included binaries

The `bin/` directory contains statically compiled MUSL binaries:

* bam-ont-normalizer
* bam-transcriptome-to-genome
* bam-quant

These binaries should run on most modern Linux systems without additional dependencies.

---

## Example run

```bash
nextflow run main.nf \
  --input_bam "/data/*.bam" \
  --transcriptome transcriptome.fa \
  --stringtie_gff stringtie.gff \
  --splice_index splice_index.dat \
  --genome_fa GRCh38.fa.gz \
  --vcf SNPs.vcf \
  --outdir results
```

---

## Outputs

```text
quant_out/
├── matrix.mtx.gz
├── barcodes.tsv.gz
├── features.tsv.gz
├── ref/
├── alt/
└── intronic/
```

---

## Mutation-aware quantification

sc-ont-mut-quant can quantify:

* transcript expression
* SNP reference support
* SNP alternate support
* intronic expression

from the same reads.

This enables joint analysis of:

* clonal structure
* transcript isoforms
* mutation state
* expression programs

within single cells.

---

## Typical use cases

* TP53 mutation analysis
* targeted ONT panels
* leukemia clonality
* isoform-specific mutation analysis
* long-read single-cell transcriptomics

---

## Citation

If you use this pipeline, please cite:

```text
Lang S. et al.
sc-ont-mut-quant:
single-cell ONT mutation-aware transcript quantification.
```

---

## License

MIT

