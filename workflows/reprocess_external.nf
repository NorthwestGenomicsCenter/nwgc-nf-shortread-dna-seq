include { PICARD_SAM_TO_FASTQ } from "../modules/reprocess_bams/picard_sam_to_fastq.nf"
include { EXTRACT_READ_LENGTH } from "../modules/reprocess_bams/extract_read_length.nf"
include { PATHIFY_FASTQS }      from "../modules/reprocess_bams/pathify_fastqs.nf"

workflow REPROCESS_EXTERNAL {

    take:
        // ch_bams = Queue Channel with a list of bam paths
        // ch_fastqInputs = Queue Channel with a list of fastq paths
        ch_bams // bam paths
        ch_fastqInputs // fastq paths

        // Groovy objects
        sampleInfo // Tuple [sampleId, userId]
        

    main:

        // Closure to extract the flowcell lane and barcode/library out of the beginning of a fastq name
        extractFlowCellLaneBarcode = { 
            prefix, fastqs ->
            prefixArray = prefix.split("\\.")
            libOrBarcode = prefixArray[2]
            if (prefixArray.size() > 3) {
                libOrBarcode = "${prefixArray[2]}.${prefixArray[3]}"
            }
            return [fastq1: fastqs[0], fastq2: fastqs[1], flowCell: prefixArray[0], lane: prefixArray[1], library: libOrBarcode]
        }

        // Closure to filter out all fastqs that don't have exactly 2 reads
        filterUnpairedReads = {
                prefix, fastqs -> fastqs.size() == 2
            }


        // ************************
        // *** Start processing ***
        // ************************

        // takes bam and converst it to fastqs
        PICARD_SAM_TO_FASTQ(ch_bams, sampleInfo)
        // Split bam into fastqs by read group
        ch_fastqs = PICARD_SAM_TO_FASTQ.out.fastqs.flatten()
        ch_fastqs = ch_fastqs.mix(ch_fastqInputs)

        // Processes fastq files from raw stream of individual files to a channel of flowcell lane library maps
        ch_fastqs 
        | PATHIFY_FASTQS // Makes sure that all of the fastqs are treated as paths by nextflow
        | map { fastq -> 
            fastqFileName = fastq.getFileName().toString()
            return [fastqFileName.take(fastqFileName.length() - 11), fastq] }
        | groupTuple
        | filter(filterUnpairedReads)
        | map(extractFlowCellLaneBarcode)
        | EXTRACT_READ_LENGTH
        | map { fastqInfo, readLengthRaw -> 
            readLengthAdjusted = Integer.valueOf(readLengthRaw) - 1 // Done because the script overcounts by one due the newline character
            fastqInfo + [readLength: readLengthAdjusted] }
        | set { ch_fcllInfo }


    emit:
       flowCellLaneLibraries = ch_fcllInfo
}