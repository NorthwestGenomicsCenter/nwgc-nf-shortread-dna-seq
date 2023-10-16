include { HAPLOTYPE_CALLER } from '../modules/haplotype_caller.nf'
include { ANNOTATE_VARIANTS } from '../modules/annotate_variants.nf'
include { FILTER_VARIANTS } from '../modules/filter_variants.nf'

workflow CALL_ANNOTATE_FILTER {

    take:
       chromosomeToCallTuple

    main:
        ch_versions = Channel.empty()

        if (params.organism == 'Homo sapiens') {
            HAPLOTYPE_CALLER(chromosomeToCallTuple)
            ANNOTATE_VARIANTS(HAPLOTYPE_CALLER.out.gvcf_tuple)
            FILTER_VARIANTS(ANNOTATE_VARIANTS.out.gvcf_tuple)
            ch_versions = ch_versions.mix(FILTER_VARIANTS.out.versions)
        }
        else {
            HAPLOTYPE_CALLER(chromosomeToCallTuple)
            ANNOTATE_VARIANTS(HAPLOTYPE_CALLER.out.gvcf_tuple)
        }

        // Versions
        ch_versions = ch_versions.mix(HAPLOTYPE_CALLER.out.versions)
        ch_versions = ch_versions.mix(ANNOTATE_VARIANTS.out.versions)

    emit:
        gvcf = ANNOTATE_VARIANTS.out.gvcf
        filtered_gvcf = FILTER_VARIANTS.out.gvcf
        versions = ch_versions
}