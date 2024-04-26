include { HAPLOTYPE_CALLER } from '../../modules/call_variants/haplotype_caller.nf'
include { ANNOTATE_VARIANTS } from '../../modules/call_variants/annotate_variants.nf'
include { FILTER_VARIANTS } from '../../modules/call_variants/filter_variants.nf'

workflow CALL_ANNOTATE_FILTER {

    take:
        // Channels
        ch_chromosomeToCallTuple

        // Groovy objects
        referenceGenome
        dbSnp
        targetListFile
        organism

    main:
        ch_versions = Channel.empty()

        HAPLOTYPE_CALLER(ch_chromosomeToCallTuple, referenceGenome, dbSnp)
        ANNOTATE_VARIANTS(HAPLOTYPE_CALLER.out.gvcf_tuple, referenceGenome, dbSnp)
        
        ch_filteredGvcf = Channel.empty()
        if (organism.equals('Homo sapiens')) {
            FILTER_VARIANTS(ANNOTATE_VARIANTS.out.gvcf_tuple, referenceGenome, targetListFile)
            ch_filteredGvcf = FILTER_VARIANTS.out.gvcf
            ch_versions = ch_versions.mix(FILTER_VARIANTS.out.versions)
        }

        // Versions
        ch_versions = ch_versions.mix(HAPLOTYPE_CALLER.out.versions)
        ch_versions = ch_versions.mix(ANNOTATE_VARIANTS.out.versions)

    emit:
        gvcf = ANNOTATE_VARIANTS.out.gvcf
        filtered_gvcf = ch_filteredGvcf
        versions = ch_versions
}