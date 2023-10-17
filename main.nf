include { MERGE_MAPPED_BAMS } from './workflows/merge_mapped_bams.nf'
include { SHORTREAD_QC } from './modules/qc.nf'

workflow {

    MERGE_MAPPED_BAMS()
    SHORTREAD_QC(MERGE_MAPPED_BAMS.out.bam, MERGE_MAPPED_BAMS.out.bai)

}
