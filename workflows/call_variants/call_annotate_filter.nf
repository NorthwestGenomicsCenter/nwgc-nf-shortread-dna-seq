include { HAPLOTYPE_CALLER } from '../../modules/call_variants/haplotype_caller.nf'
include { ANNOTATE_VARIANTS } from '../../modules/call_variants/annotate_variants.nf'
include { FILTER_VARIANTS } from '../../modules/call_variants/filter_variants.nf'

workflow CALL_ANNOTATE_FILTER {

    take:
       chromosomeToCallTuple

    main:
        ch_versions = Channel.empty()

        HAPLOTYPE_CALLER(chromosomeToCallTuple)
        ANNOTATE_VARIANTS(HAPLOTYPE_CALLER.out.gvcf_tuple)
        FILTER_VARIANTS(ANNOTATE_VARIANTS.out.gvcf_tuple)

        // Versions
        ch_versions = ch_versions.mix(FILTER_VARIANTS.out.versions)
        ch_versions = ch_versions.mix(HAPLOTYPE_CALLER.out.versions)
        ch_versions = ch_versions.mix(ANNOTATE_VARIANTS.out.versions)

    emit:
        gvcf = ANNOTATE_VARIANTS.out.gvcf
        filtered_gvcf = FILTER_VARIANTS.out.gvcf
        versions = ch_versions
}