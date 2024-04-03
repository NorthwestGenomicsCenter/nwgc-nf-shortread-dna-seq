include { BWA_SAMSE } from '../../modules/lane_map/bwa_samse.nf'
include { BWA_SAMPE } from '../../modules/lane_map/bwa_sampe.nf'
include { SAMBLASTER_ADD_MATE_TAGS } from '../../modules/lane_map/samblaster_add_mate_tags.nf'
include { SAMTOOLS_VIEW_SBHU } from '../../modules/lane_map/samtools_view_sbhu.nf'
include { SAMBAMBA_SORT } from '../../modules/lane_map/sambamba_sort.nf'
include { PICARD_CLEAN_SAM } from '../../modules/lane_map/picard_clean_sam.nf'


workflow MAP {
    take:
        // Queue Channel containing tuples of flowCell lane library information
        // [fastq1, fastq2, flowCell, lane, library, userId, readGroup, publishDirectory]
        flowCellLaneLibraryTuple

    main:
    // if single read
    BWA_SAMSE()
    // else
    BWA_SAMPE(flowCellLaneLibrarytuple)

    ch_bwa_out = Channel.empty()
    ch_bwa_out = ch_bwa_out.mix(BWA_SAMSE.out.samse)
    ch_bwa_out = ch_bwa_out.mix(BWA_SAMPE.out.sampe)

    SAMBLASTER_ADD_MATE_TAGS(ch_bwa_out)
    SAMTOOLS_VIEW_SBHU(SAMBLASTER_ADD_MATE_TAGS.out.tagged)
    SAMBAMBA_SORT(SAMTOOLS_VIEW_SBHU.out.viewed)
    PICARD_CLEAN_SAM(SAMBAMBA_SORT.out.sorted)
}