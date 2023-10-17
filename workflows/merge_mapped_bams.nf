include { PICARD_MARK_DUPLICATES } from '../modules/picard_mark_duplicates.nf'
include { BASE_RECALIBRATOR } from '../modules/base_recalibrator.nf'
include { APPLY_BQSR } from '../modules/apply_bqsr.nf'

workflow MERGE_MAPPED_BAMS {

    main:
        def mappedBams = Channel.fromPath(params.mappedBams)

        // Merge
        PICARD_MARK_DUPLICATES(mappedBams.collect())

        // Quality Calc
        BASE_RECALIBRATOR(PICARD_MARK_DUPLICATES.out.merged_sorted_bam)

        // Apply BQSR
        APPLY_BQSR(PICARD_MARK_DUPLICATES.out.merged_sorted_bam, BASE_RECALIBRATOR.out.bqsr_recalibration_table)

        // Versions
        ch_versions = Channel.empty()
        ch_versions = ch_versions.mix(PICARD_MARK_DUPLICATES.out.versions)
        ch_versions = ch_versions.mix(BASE_RECALIBRATOR.out.versions)
        ch_versions = ch_versions.mix(APPLY_BQSR.out.versions)
        ch_versions.unique().collectFile(name: 'merge_software_versions.yaml', storeDir: "${params.sampleDirectory}")

    emit:
        bam = APPLY_BQSR.out.bam
        bai = APPLY_BQSR.out.bai
}