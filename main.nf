include { MERGE_MAPPED_BAMS } from './workflows/merge_mapped_bams.nf'
include { SHORTREAD_QC } from './workflows/qc.nf'

workflow {

    if(params.mergedBam == null) {
        MERGE_MAPPED_BAMS()
        SHORTREAD_QC(MERGE_MAPPED_BAMS.out.bam, MERGE_MAPPED_BAMS.out.bai)
    }
    else {
        SHORTREAD_QC(params.mergedBam, "${params.mergedBam}.bai")
    }

}
