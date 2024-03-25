include { MERGE_MAPPED_BAMS } from './workflows/merge_mapped_bams.nf'
include { SHORTREAD_QC } from './workflows/qc.nf'
include { CALL_VARIANTS } from './workflows/call_variants.nf'
include { POLYMORPHIC_QC } from './workflows/polymorphic_qc.nf'

workflow {

    // If there is an input mapped bam set up a channel and run MERGE_MAPPED_BAMS
    ch_MappedBams = Channel.empty()
    
    if (params.mappedBams != null) {
        ch_MappedBams = Channel.value(params.mappedBams)
    }

    MERGE_MAPPED_BAMS(ch_MappedBams)

    ch_MergedBam = MERGE_MAPPED_BAMS.out.bam
    ch_MergedBai = MERGE_MAPPED_BAMS.out.bai

    // If there is an input merged bam set up a channel and run SHORTREAD_QC and CALL_VARIANTS
    if (params.mergedBam != null) {
        ch_MergedBam = Channel.value(params.mergedBam)
        ch_MergedBai = Channel.value("${params.mergedBam}.bai")
    }

    SHORTREAD_QC(ch_MergedBam, ch_MergedBai)
    CALL_VARIANTS(ch_MergedBam)

    ch_FilteredGVCF = CALL_VARIANTS.out.filtered_gvcf

    // If there is an input filtered GVCF set up a channel and run POLYMORPHIC_QC
    if (params.filteredGVCF != null) {
        ch_FilteredGVCF = Channel.value(params.filteredGVCF)
    }
    POLYMORPHIC_QC(ch_FilteredGVCF)

    // if(params.mergedBam == null) {
    //     MERGE_MAPPED_BAMS()
    //     SHORTREAD_QC(MERGE_MAPPED_BAMS.out.bam, MERGE_MAPPED_BAMS.out.bai)
    //     CALL_VARIANTS(MERGE_MAPPED_BAMS.out.bam)
    //     POLYMORPHIC_QC(CALL_VARIANTS.out.filtered_gvcf)
    // }
    // else {
    //     mergedBam = Channel.value(params.mergedBam)
    //     SHORTREAD_QC(mergedBam, "${params.mergedBam}.bai")
    //     CALL_VARIANTS(mergedBam)
    //     POLYMORPHIC_QC(CALL_VARIANTS.out.filtered_gvcf)
    // }

}
