include { MAP } from "../workflows/lane_map/map.nf"
workflow LANE_MAP {

    take:
        // Queue Channel containing tuples of flowCell lane library information
        // [fastq1, fastq2, flowCell, lane, library, userId, readGroup, publishDirectory]
        ch_flowCellLaneLibraryTuple

        // Groovy objects
        referenceGenome

    main:
        // Check if reads > 100 (Undecided if we are doing this here)

        // Downsample for novaseq pool

        // run fastx

        // map
        MAP(ch_flowCellLaneLibraryTuple, referenceGenome)

}