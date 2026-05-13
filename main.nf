nextflow.enable.dsl = 2

params.input_bam     = "/data1/testCase/TP53_capt_1_basecalls_unmapped.bam"
params.transcriptome = "/data1/testCase/transcriptome.fa"
params.stringtie_gff = "/data1/testCase/stringtie.gff"
params.genome_fa     = "${System.getenv('HOME')}/Downloads/GRCh38.p14.genome.fa.gz"
params.splice_index  = "${System.getenv('HOME')}/Downloads/gencode.v49.annotation.gtf.dat"
params.vcf           = "/data1/testCase/SNPs.vcf"
params.minimap_script = "/data1/testCase/minimap_script_chatty.sh"

params.merge_bams = true

params.outdir = "/data1/testCase/nf_tp53_out_multi"
params.threads = 5

process NORMALIZE_ONT_BAM {
    publishDir params.outdir, mode: 'copy'

    input:
    path bam

    output:
    tuple path("${bam.simpleName}_rust_sliced.fastq.gz"),
          path("${bam.simpleName}_rust_sliced_cell_ids.tab")

    script:
    """
    bam-ont-normalizer \\
      -b ${bam} \\
      -o ${bam.simpleName}_rust_sliced.fastq.gz \\
      -t ${bam.simpleName}_rust_sliced_cell_ids.tab
    """
}

process MAP_TO_TRANSCRIPTOME {
    publishDir params.outdir, mode: 'copy'

    input:
    tuple path(sliced_bam), path(read_tag_table)
    path transcriptome

    output:
    tuple path("${sliced_bam.simpleName}_mapped.bam"),
          path(read_tag_table)

    script:
    """
    ${params.minimap_script} \\
      ${sliced_bam} \\
      ${transcriptome} \\
      ${sliced_bam.simpleName}_mapped \\
      ${params.threads}
    """
}

process TRANSCRIPTOME_TO_GENOME {
    publishDir params.outdir, mode: 'copy'

    input:
    tuple path(mapped_bam), path(read_tag_table)
    path stringtie_gff
    path genome_fa

    output:
    tuple path("${mapped_bam.simpleName}_genomic.bam"),
          path(read_tag_table)

    script:
    """
    bam-transcriptome-to-genome \\
      -b ${mapped_bam} \\
      -g ${stringtie_gff} \\
      -f ${genome_fa} \\
      -o ${mapped_bam.simpleName}_genomic.bam
    """
}

process BAM_QUANT {
    publishDir params.outdir, mode: 'copy'

    cpus params.threads

    input:
    tuple path(genomic_bams), path(read_tag_tables)
    path splice_index
    path vcf
    path genome_fa

    output:
    path "quant_out*"

    script:
    def bam_args = genomic_bams.collect { "-b ${it}" }.join(" \\\n      ")
    def tag_args = read_tag_tables.collect { "--read-tag-table ${it}" }.join(" \\\n      ")

    """
    bam-quant \\
      ${bam_args} \\
      -i ${splice_index} \\
      -o quant_out \\
      -s \\
      --quant-mode transcript \\
      --threads ${task.cpus} \\
      --vcf ${vcf} \\
      --genome ${genome_fa} \\
      --min-cell-counts 1 \\
      ${tag_args}
    """
}

workflow {
    input_bam_ch = Channel
        .fromList(params.input_bam.tokenize(' '))
        .map { file(it, checkIfExists: true) }

    transcriptome_ch = file(params.transcriptome)
    stringtie_gff_ch = file(params.stringtie_gff)
    genome_fa_ch     = file(params.genome_fa)
    splice_index_ch  = file(params.splice_index)
    vcf_ch           = file(params.vcf)

    normalized_ch = NORMALIZE_ONT_BAM(input_bam_ch)

    mapped_ch = MAP_TO_TRANSCRIPTOME(
        normalized_ch,
        transcriptome_ch
    )

    genomic_ch = TRANSCRIPTOME_TO_GENOME(
        mapped_ch,
        stringtie_gff_ch,
        genome_fa_ch
    )

    if (params.merge_bams) {

        quant_input_ch = genomic_ch
            .collect()
            .map { pairs ->
                def bams = pairs.collect { it[0] }
                def tabs = pairs.collect { it[1] }
                tuple("merged", bams, tabs)
            }

    } else {

        quant_input_ch = genomic_ch
            .map { genomic_bam, read_tag_table ->
                tuple(genomic_bam.simpleName, [genomic_bam], [read_tag_table])
            }
    }

    BAM_QUANT(
        quant_input_ch,
        splice_index_ch,
        vcf_ch,
        genome_fa_ch
    )
}
