include { MERGE_MAPPED_BAMS } from './workflows/merge_mapped_bams.nf'
include { SHORTREAD_QC } from './workflows/qc.nf' params (qcToRun: params.qcToRunCustom)
include { CALL_VARIANTS } from './workflows/call_variants.nf'
include { POLYMORPHIC_QC } from './workflows/polymorphic_qc.nf'

workflow {

    // // If there is an input mapped bam set up a channel and run MERGE_MAPPED_BAMS
    // ch_MappedBams = Channel.empty()
    
    // if (params.mappedBams != null) {
    //     ch_MappedBams = Channel.value(params.mappedBams)
    // }

    // MERGE_MAPPED_BAMS(ch_MappedBams)

    // ch_MergedBam = MERGE_MAPPED_BAMS.out.bam
    // ch_MergedBai = MERGE_MAPPED_BAMS.out.bai

    // // If there is an input merged bam set up a channel and run SHORTREAD_QC and CALL_VARIANTS
    // if (params.mergedBam != null) {
    //     ch_MergedBam = Channel.value(params.mergedBam)
    //     ch_MergedBai = Channel.value("${params.mergedBam}.bai")
    // }
    ch_sampleInfo = Channel.of([file("${params.mergedBam}"), file("${params.mergedBam}.bai"), params.sampleId, params.libraryId, params.userId, params.sampleQCDirectory])
    ch_referenceInfo = Channel.of([params.isGRC38, params.referenceGenome])
    ch_sampleInfoMap = Channel.of(params.subMap("sequencingTarget", "sequencingTargetIntervalsList", "sequencingTargetIntervalsDirectory", 
                               "baseQualityRange", "mappingQualityRange", 
                               "isCustomContaminationTargetSample", "customContaminationTargetReferenceVCF", "contaminationUDPath", "contaminationBedPath", "contaminationMeanPath", 
                               "referenceAbbr", "dbSnp", "sequencingTargetBedFile", "fingerprintBedFile"))

    ch_sampleInfo.view()
    ch_referenceInfo.view()
    ch_sampleInfoMap.view()

    SHORTREAD_QC(ch_sampleInfo, ch_referenceInfo, ch_sampleInfoMap)
    // CALL_VARIANTS(ch_MergedBam)

    // ch_FilteredGVCF = CALL_VARIANTS.out.filtered_gvcf

    // // If there is an input filtered GVCF set up a channel and run POLYMORPHIC_QC
    // if (params.filteredGVCF != null) {
    //     ch_FilteredGVCF = Channel.value(params.filteredGVCF)
    // }
    // POLYMORPHIC_QC(ch_FilteredGVCF)
}
