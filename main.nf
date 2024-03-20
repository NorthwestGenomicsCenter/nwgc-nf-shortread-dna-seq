include { MERGE_MAPPED_BAMS } from './workflows/merge_mapped_bams.nf'
include { SHORTREAD_QC } from './workflows/qc.nf'
include { CALL_VARIANTS } from './workflows/call_variants.nf'

workflow {

    if(params.mergedBam == null) {
        MERGE_MAPPED_BAMS()
        SHORTREAD_QC(MERGE_MAPPED_BAMS.out.bam, MERGE_MAPPED_BAMS.out.bai)
        CALL_VARIANTS(MERGE_MAPPED_BAMS.out.bam)
    }
    else {
        mergedBam = Channel.value(params.mergedBam)
        SHORTREAD_QC(mergedBam, "${params.mergedBam}.bai")
        CALL_VARIANTS(mergedBam)
    }

}
