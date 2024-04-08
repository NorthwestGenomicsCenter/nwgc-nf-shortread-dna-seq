include { PICARD_MARK_DUPLICATES } from '../modules/merge/picard_mark_duplicates.nf'
include { GATK_BASE_RECALIBRATOR } from '../modules/merge/gatk_base_recalibrator.nf'
include { GATK_PRINT_READS } from '../modules/merge/gatk_print_reads.nf'

workflow MERGE_MAPPED_BAMS {

    take:
        // Input Channels
        ch_mappedBams

        // Groovy Objects
        sampleId
        sequencingTarget
        organism
        isGRC38
        dbSnp
        gsIndels
        kIndels
        referenceGenome
        publishDirectory

    main:

        // Merge
        PICARD_MARK_DUPLICATES(ch_mappedBams.collect())

        // Quality Calc
        if (!(isGRC38 && organism.equals("Homo sapiens"))) {
            gsIndels = ""
            kIndels = ""
        }
        GATK_BASE_RECALIBRATOR(PICARD_MARK_DUPLICATES.out.bam, sampleId, organism, isGRC38, dbSnp, gsIndels, kIndels, referenceGenome)

        // Apply BQSR
        GATK_PRINT_READS(PICARD_MARK_DUPLICATES.out.bam, GATK_BASE_RECALIBRATOR.out.bqsr_recalibration_table, sampleId, sequencingTarget, organism, referenceGenome, publishDirectory)

        // Versions
        ch_versions = Channel.empty()
        ch_versions = ch_versions.mix(PICARD_MARK_DUPLICATES.out.versions)
        ch_versions = ch_versions.mix(GATK_BASE_RECALIBRATOR.out.versions)
        ch_versions = ch_versions.mix(GATK_PRINT_READS.out.versions)
        ch_versions.unique().collectFile(name: 'merge_software_versions.yaml', storeDir: "${params.sampleDirectory}")

    emit:
        bam = GATK_PRINT_READS.out.bamBai
}