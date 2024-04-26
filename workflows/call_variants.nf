include { CALL_ANNOTATE_FILTER } from '../workflows/call_variants/call_annotate_filter.nf'
include { COMBINE_GVCFS as COMBINE_GVCFS } from '../modules/call_variants/combine_gvcfs.nf'
include { COMBINE_GVCFS as COMBINE_FILTERED_GVCFS } from '../modules/call_variants/combine_gvcfs.nf'
include { VALIDATE_VARIANTS } from '../modules/call_variants/validate_variants.nf'

workflow CALL_VARIANTS {

    take:
        // Channels
        ch_bam

        // Groovy objects
        // Map with relevant sample info & userId
        // sampleId, userId, sequencingTarget, targetListFile, referenceGenome, dbSnp, organism, publishDirectory
        sampleInfoMap
        // List of chromosome names. i.e [chr1, chr2, chr3, chr4, ...] or [1, 2, 3, 4, ...]
        // If not a human sample use ['All']
        chromosomesToCall


    main:
        ch_versions = Channel.empty()

        // Chromosomse to Call
        ch_chromosomesToCall = Channel.fromList(chromosomesToCall)

        // Set up CALL_ANNOTATE_FILTER input tuple
        ch_chromosomesToCall
        | combine(ch_bam.map({ bam -> [bam, sampleInfoMap.sampleId, sampleInfoMap.userId] }))
        | set { ch_chromosomesToCallTuple }

        // Set up COMBINE_GVCFS & VALIDATE_VARIANTS input tuple
        Channel.value([sampleInfoMap.sampleId, sampleInfoMap.userId, sampleInfoMap.sequencingTarget, sampleInfoMap.referenceGenome, sampleInfoMap.publishDirectory])
        | set { ch_sampleInfoTuple }


        // Do Variant Calling
        CALL_ANNOTATE_FILTER(ch_chromosomesToCallTuple, sampleInfoMap.referenceGenome, sampleInfoMap.dbSnp, sampleInfoMap.targetListFile, sampleInfoMap.organism)
        CALL_ANNOTATE_FILTER.out.gvcf
        | collect
        | set { ch_collectedGvcfs }

        // There are only filtered GVCFs if the sample is human
        CALL_ANNOTATE_FILTER.out.filtered_gvcf
        | collect
        | set { ch_collectedFilteredGvcfs }


        COMBINE_GVCFS('main', ch_collectedGvcfs, ch_sampleInfoTuple)
        COMBINE_FILTERED_GVCFS('filtered', ch_collectedFilteredGvcfs, ch_sampleInfoTuple)

        // Validate that the files are well formatted
        VALIDATE_VARIANTS(COMBINE_GVCFS.out.gvcf, COMBINE_GVCFS.out.tbi, ch_sampleInfoTuple, chromosomesToCall, sampleInfoMap.dbSnp)

        // Versions
        ch_versions = ch_versions.mix(CALL_ANNOTATE_FILTER.out.versions)
        ch_versions = ch_versions.mix(COMBINE_GVCFS.out.versions)
        ch_versions = ch_versions.mix(COMBINE_FILTERED_GVCFS.out.gvcf)
        ch_versions.unique().collectFile(name: 'call_variants_software_versions.yaml', storeDir: "${params.sampleDirectory}")

    emit:
        gvcf = COMBINE_GVCFS.out.gvcf
        gvcfIndex = COMBINE_GVCFS.out.tbi
        filteredGvcf = COMBINE_FILTERED_GVCFS.out.gvcf

}