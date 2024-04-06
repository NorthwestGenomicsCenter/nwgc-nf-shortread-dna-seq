include { MAP } from "../workflows/lane_map/map.nf"
include { FASTX_QC } from "../modules/lane_map/fastx_quality_stats.nf"

workflow LANE_MAP {

    take:
        // Queue Channel containing tuples of flowCell lane library information
        // [fastq1, fastq2, flowCell, lane, library, userId, readGroup, readLength, readType, publishDirectory]
        ch_flowCellLaneLibraryTuple

        // Groovy objects
        sampleId
        sampleDirectory
        userId
        referenceGenome

    main:
        // Check if reads > 100 (Undecided if we are doing this here)

        // Downsample for novaseq pool

        // run fastx
        ch_flowCellLaneLibraryTuple.multiMap { 
            fastq1, fastq2, flowCell, lane, library, userId, readGroup, readLength, readType, publishDirectory -> 
            fastq1Tuple: [fastq1, publishDirectory]
            fastq2Tuple: [fastq2, publishDirectory]
        }
        | mix
        | set { ch_fastqs }
        
        def ch_sampleInfo = Channel.value([sampleId, sampleDirectory, userId])
        FASTX_QC(ch_fastqs, ch_sampleInfo)

        // map
        MAP(ch_flowCellLaneLibraryTuple, referenceGenome)

}