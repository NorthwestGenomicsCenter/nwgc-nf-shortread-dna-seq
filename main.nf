include { MERGE_MAPPED_BAMS } from './workflows/merge_mapped_bams.nf'
include { SHORTREAD_QC as MERGING_QC } from './workflows/qc.nf' params (qcToRun: params.qcToRunCustom, mode: params.mode)
include { SHORTREAD_QC as MAPPING_QC } from './workflows/qc.nf' params (qcToRun: params.qcToRunMapping, mode: params.mode)
include { CALL_VARIANTS } from './workflows/call_variants.nf'
include { POLYMORPHIC_QC } from './workflows/polymorphic_qc.nf'
include { LANE_MAP } from './workflows/lane_map.nf'
include { FASTX_QC } from "./modules/fastx_quality_stats.nf"

workflow {

    // ******************
    // **** Fastx QC ****
    // ******************
    if (params.pipelineStepsToRun.contains("fastx_qc")) {
        Channel.fromList(params.flowCellLaneLibraries)
        | multiMap { 
            def flowCellLaneLibrary -> 
            fastq1Tuple: [flowCellLaneLibrary.fastq1, flowCellLaneLibrary.flowCell, flowCellLaneLibrary.lane, flowCellLaneLibrary.library, params.sampleId, params.userId, params.sampleFastxQCDirectory]
            fastq2Tuple: [flowCellLaneLibrary.fastq2, flowCellLaneLibrary.flowCell, flowCellLaneLibrary.lane, flowCellLaneLibrary.library, params.sampleId, params.userId, params.sampleFastxQCDirectory]
        }
        | mix
        | set { ch_fastqs }

        FASTX_QC(ch_fastqs)
    }

    // *****************
    // **** Mapping ****
    // *****************
    ch_mappedBams = Channel.empty()
    if (params.pipelineStepsToRun.contains("mapping")) {

        Channel.fromList(params.flowCellLaneLibraries)
        | map { def flowCellLaneLibrary -> 
                    def readGroup = Utils.defineReadGroup(params.sequencingCenter, params.sequencingPlatform, params.sampleId, flowCellLaneLibrary)
                    def readType = flowCellLaneLibrary.readType ? flowCellLaneLibrary.readType : params.readType

                    [flowCellLaneLibrary.fastq1, flowCellLaneLibrary.fastq2, flowCellLaneLibrary.flowCell, flowCellLaneLibrary.lane, flowCellLaneLibrary.library, params.sampleId,
                    params.userId, readGroup, flowCellLaneLibrary.readLength, readType, params.sampleMappedBamsDirectory + "/${flowCellLaneLibrary.flowCell}.${flowCellLaneLibrary.lane}.S${params.sampleId}.L${flowCellLaneLibrary.library}"] 
                }
        | set { ch_fastq_info }

        LANE_MAP(ch_fastq_info, params.isNovaseqQCPool, params.novaseqQCPoolPlexity, params.referenceGenome)
        ch_mappedBams = ch_mappedBams.mix(LANE_MAP.out.mappedBams)
    }

    // If there are input mapped bams mix them in
    ch_mappedBams = ch_mappedBams.mix(
    Channel.fromList(params.mappedBams)
    .map {mappedBamInfo -> [mappedBamInfo.bam, mappedBamInfo.bai, mappedBamInfo.flowcell, mappedBamInfo.lane, mappedBamInfo.library, params.sampleId]}
    )

    // ********************
    // **** Mapping QC ****
    // ********************
    // Global sample values used for Mapping QC and Merging QC
    Channel.value([params.isGRC38, params.referenceGenome]) | set { ch_referenceInfo }
    def qcSampleInfoMap = params.subMap(
        "sequencingTarget", "sequencingTargetIntervalsList", "sequencingTargetIntervalsDirectory", 
        "baseQualityRange", "mappingQualityRange", 
        "isCustomContaminationTargetSample", "customContaminationTargetReferenceVCF", "contaminationUDPath", "contaminationBedPath", "contaminationMeanPath", 
        "referenceAbbr", "dbSnp", "sequencingTargetBedFile", "fingerprintBedFile"
        )

    // Run Mapping QC
    if (params.pipelineStepsToRun.contains('mapping_qc')) {
        ch_mappedBams 
        | map({ bam, bai, flowCell, lane, library, sampleId -> [bam, bai, sampleId, "${flowCell}.${lane}.S${sampleId}.L${library}", params.userId, params.sampleMappingQCDirectory, flowcell, lane, library] })
        | set { ch_mappingQcBams }

        MAPPING_QC(ch_mappingQcBams, ch_referenceInfo, qcSampleInfoMap, params.sampleMappingQCDirectory)
    }

    // *****************
    // **** Merging ****
    // *****************
    if (params.pipelineStepsToRun.contains("merging")) {
        ch_mappedBams
        | map { bam, bai, flowCell, lane, library, sampleId -> bam }
        | set { ch_mappedBamsForMerge }
        MERGE_MAPPED_BAMS(ch_mappedBamsForMerge, params.sampleId, params.sequencingTarget, params.organism, params.isGRC38, params.dbSnp, params.goldStandardIndels, params.knownIndels, params.referenceGenome, params.sampleDirectory)
        ch_mergedBam = MERGE_MAPPED_BAMS.out.bam
    }
    else {
        ch_mergedBam = Channel.of([params.mergedBam, "${params.mergedBam}.bai"])
    }


    // ************
    // **** QC ****
    // ************
    if (params.pipelineStepsToRun.contains("qc")) {
        // Sample information that qc needs to run
        ch_bamInfo = ch_mergedBam.combine(Channel.of([params.sampleId, "${params.sampleId}", params.userId, params.sampleQCDirectory, null, null, null]))

        MERGING_QC(ch_bamInfo, ch_referenceInfo, qcSampleInfoMap, params.sampleQCDirectory)
    }


    // *************************
    // **** Variant Calling ****
    // *************************
    if (params.pipelineStepsToRun.contains("variant_calling")) {
        def variantCallingSampleInfoMap = params.subMap(
            "sampleId", "userId", "sequencingTarget", "targetListFile", "referenceGenome", "dbSnp", "organism"
        ) + [publishDirectory: params.sampleDirectory]

        def chromosomesToCall = params.isGRC38 ? params.grc38Chromosomes : params.hg19Chromosomes
        if (!params.organism.equals("Homo sapiens")) {
            chromosomesToCall = ['All']
        }

        CALL_VARIANTS(ch_mergedBam.map({ bam, bai -> bam}), variantCallingSampleInfoMap, chromosomesToCall)
        ch_filteredGVCF = CALL_VARIANTS.out.filteredGvcf
    }
    else {
        // This should only ever have one element but if we make it a value channel the process hangs forever on POLYMORPHIC_QC if params.filteredGVCF is null 
        ch_filteredGVCF = Channel.of(params.filteredGVCF)
    }


    // ************************
    // **** Polymorphic QC ****
    // ************************
    if (params.pipelineStepsToRun.contains("polymorphic_qc")) {
        POLYMORPHIC_QC(ch_filteredGVCF)
    }
}
