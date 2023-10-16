include { CALL_ANNOTATE_FILTER } from '../workflows/call_annotate_filter.nf'
include { COMBINE_GVCFS as COMBINE_GVCFS } from '../modules/combine_gvcfs.nf'
include { COMBINE_GVCFS as COMBINE_FILTERED_GVCFS } from '../modules/combine_gvcfs.nf'

workflow CALL_VARIANTS {

    main:
        ch_versions = Channel.empty()

        // Chromosomse to Call
        chromosomesToCall = Channel.fromList(params.hg19Chromosomes)
        if (params.isGRC38) {
            chromosomesToCall = Channel.fromList(params.grc38Chromosomes)
        }

        if (params.organism != 'Homo sapiens') {
            chromosomesToCall = Channel.fromList(['All'])
        }

        bamChannel = Channel.of(params.bam)
        chromosomesToCallTuple = chromosomesToCall.combine(bamChannel) 

        if (params.organism == 'Homo sapiens') {
            CALL_ANNOTATE_FILTER(chromosomesToCallTuple)
            COMBINE_GVCFS('main', CALL_ANNOTATE_FILTER.out.gvcf.collect())
            COMBINE_FILTERED_GVCFS('filtered', CALL_ANNOTATE_FILTER.out.filtered_gvcf.collect())
        }
        else {
            CALL_ANNOTATE_FILTER(chromosomesToCallTuple)
            COMBINE_GVCFS('main', CALL_ANNOTATE_FILTER.out.gvcf.collect())
        }

        // Versions
        ch_versions = ch_versions.mix(CALL_ANNOTATE_FILTER.out.versions)
        ch_versions = ch_versions.mix(COMBINE_GVCFS.out.versions)
        ch_versions.unique().collectFile(name: 'call_variants_software_versions.yaml', storeDir: "${params.sampleDirectory}")

    emit:
        gvcf = COMBINE_GVCFS.out.gvcf
        gvcf_index = COMBINE_GVCFS.out.tbi
        filtered_gvcf = COMBINE_FILTERED_GVCFS.out.gvcf
}