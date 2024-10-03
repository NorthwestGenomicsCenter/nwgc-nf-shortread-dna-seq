include { PICARD_SAM_TO_FASTQ } from "../modules/reprocess_bams/picard_sam_to_fastq.nf"
include { EXTRACT_FASTQ_INFO } from "../modules/reprocess_bams/extract_fastq_info.nf"
include { PATHIFY_FASTQS }      from "../modules/reprocess_bams/pathify_fastqs.nf"
include { PICARD_CRAM_TO_FASTQ } from "../modules/reprocess_bams/picard_cram_to_fastq.nf"
include { EXTRACT_READ_GROUPS } from "../modules/reprocess_bams/extract_read_groups.nf"
include { GZIP } from "../modules/reprocess_bams/gzip.nf"

workflow REPROCESS_EXTERNAL {

    take:
        // ch_crams = Queue Channel with a list of crams in the format [cram: <cram file path>, reference: <reference file path>]
        // ch_bams = Queue Channel with a list of bam paths
        // fastqInputs = Queue Channel with a list of fastqs in the format [[read1: <file path to the first read>, read2: <file path to the second read>], ...]
        ch_crams
        ch_bams // bam paths
        ch_fastqInputs // fastq paths

        // Groovy objects
        sampleInfo // Tuple [sampleId, userId]
        

    main:

        // Closure to extract the individual read groups from a large string of read groups
        def splitReadGroupString = {
            readGroupPUString, readGroupString ->
            readGroupPUArray = readGroupPUString.split("\n")
            readGroupArray = readGroupString.split("\n")
            ret = []
            for (int i=0; i < readGroupArray.size(); i++) {
                ret += [PU: readGroupPUArray[i] - "\t", RG: readGroupArray[i]]
            }
            return ret
        }

        // Converts RG map to RG tuple (The previous step needs a map to flatten the channel properly)
        def  tupleifyRG = {
            readGroup ->
            return [readGroup["PU"], readGroup["RG"]]
        }

        // Closure to extract the @PU from a fastq name (generated by Picard samtofastq)
        def extractPU = {
            fastq ->
            fastqNameArray = fastq.getFileName().toString().split("_")
            PU = ""
            for (int i=0; i < fastqNameArray.size() - 1; i++) {
                PU = PU + fastqNameArray[i] + "_"
            }
            PU = "PU:" + PU - "_"
            return [PU, fastq]
        }

        // Closure to filter out all fastqs that don't have exactly 2 reads
        def filterUnpairedReads = { prefix, fastqs -> fastqs.size() == 2 }

        // Closure to convert a tuple of fastq information into a map of fastq information
        def mapifyFCLL = { 
            PU, fastqs, readGroup ->
            def puTag = PU.split(":")[1]
            return [fastq1: fastqs[0], fastq2: fastqs[1], RG: readGroup, library: puTag]
        }

        // Closure to adjust read length and merge read length / flow cell / lane into the fastq info map
        def mergeFastqExtraInfo = { fastqInfo, readLengthRaw, fastqAtString -> 
            def readLengthAdjusted = Integer.valueOf(readLengthRaw) - 1 // Done because the script overcounts by one due the newline character
            def fastqAtStringArray = fastqAtString.split(":")
            def flowCell = fastqInfo["library"]
            def lane = fastqInfo["library"]

            if (fastqAtStringArray.size() >= 4) {
                lane = fastqAtStringArray[3]
            }
            if (fastqAtStringArray.size() >= 3) {
                flowCell = fastqAtStringArray[2]
            }

            return fastqInfo + [readLength: readLengthAdjusted, flowCell: flowCell, lane: lane]
        }

        // Closure to set library tag if needed for external fastqs
        def setLibraryTag = { externalFastqInfo ->
            returnInfo = externalFastqInfo 
            if (returnInfo["library"] == null) {
                    returnInfo["library"] = 1
            }
            return returnInfo
        }

        // ************************
        // *** Start processing ***
        // ************************

        ch_crams = ch_crams.map { cramInfo -> [cramInfo.cram, cramInfo.reference]}
        PICARD_CRAM_TO_FASTQ(ch_crams, sampleInfo)

        // takes bam and converst it to fastqs
        PICARD_SAM_TO_FASTQ(ch_bams, sampleInfo)
        // Split bam into fastqs by read group
        ch_uncompressedFastqs = PICARD_CRAM_TO_FASTQ.out.fastqs.flatten()
        ch_uncompressedFastqs = ch_uncompressedFastqs.mix(PICARD_SAM_TO_FASTQ.out.fastqs.flatten())
        GZIP(ch_uncompressedFastqs)
        ch_fastqs = GZIP.out

        // Extracts the readGroup from bam/cram files
        ch_cramsAndBams = ch_crams.mix(ch_bams)
        EXTRACT_READ_GROUPS(ch_cramsAndBams)
        | flatMap(splitReadGroupString)
        | map(tupleifyRG)
        | set {ch_readGroups}

        // Processes fastq files from raw stream of individual files to a channel of flowcell lane library maps
        ch_fastqs 
        | PATHIFY_FASTQS // Makes sure that all of the fastqs are treated as paths by nextflow
        | map (extractPU)
        | groupTuple
        | filter (filterUnpairedReads)
        | join(ch_readGroups)
        | map (mapifyFCLL)
        | set { ch_bamCramFCLLMaps }

        ch_fastqInputs
        | map (setLibraryTag)
        | mix (ch_bamCramFCLLMaps)
        | set { ch_fcllMaps }

        ch_fcllMaps
        | EXTRACT_FASTQ_INFO
        | map (mergeFastqExtraInfo)
        | set { ch_fcllInfo }


    emit:
       flowCellLaneLibraries = ch_fcllInfo
}