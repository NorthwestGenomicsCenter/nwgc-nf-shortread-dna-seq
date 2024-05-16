params.totalNovaseqQCReads = 2400000000
params.averageNovaseqQCReadCountTarget = 1250000

include { MAP } from "../workflows/lane_map/map.nf"
include { SEQTK_DOWNSAMPLE_NOVASEQ_FASTQS } from "../modules/lane_map/seqtk_downsample_novaseq_fastqs.nf"

workflow LANE_MAP {

    take:
        // Queue Channel containing tuples of flowCell lane library information
        // [fastq1, fastq2, flowCell, lane, library, userId, readGroup, readLength, readType, publishDirectory]
        ch_flowCellLaneLibraryTuple

        // Groovy objects
        isNovaseqQCPool
        novaseqQCPoolPlexity
        referenceGenome

    main:

        // Downsample for novaseq pool
        if (isNovaseqQCPool) {
            def downsamplePercentage = params.averageNovaseqQCReadCountTarget / (params.totalNovaseqQCReads / novaseqQCPoolPlexity)
            SEQTK_DOWNSAMPLE_NOVASEQ_FASTQS(ch_flowCellLaneLibraryTuple, downsamplePErcentage)
            ch_flowCellLaneLibraryTuple = SEQTK_DOWNSAMPLE_NOVASEQ_FASTQS.out.flowCellLaneLibraryTuple
        }

        // map
        MAP(ch_flowCellLaneLibraryTuple, referenceGenome)

    emit:
        mappedBams = MAP.out.mappedBams
}