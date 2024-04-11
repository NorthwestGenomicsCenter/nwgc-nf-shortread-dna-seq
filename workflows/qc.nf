params.qcToRun = ["coverage", "coverage_by_chrom", "contamination", "fingerprint", "picard_multiple_metrics", "samtools_flagstat", "samtools_stats", "collect_and_plot"]
params.defaultBaseQuality = 20
params.defaultMappingQuality = 20
params.baseQualityRange = [0, 10, 20, 30]
params.mappingQualityRange = [0]
params.chromosomeNames = ["chr1", "chr2", "chr3", "chr4", "chr5", "chr6", "chr7", "chr8", "chr9", "chr10", "chr11", "chr12", "chr13", "chr14", "chr15", "chr16", "chr17", "chr18", "chr19", "chr20", "chr21", "chr22", "chrX", "chrY", "chrM"]

include { PICARD_COVERAGE_METRICS as PICARD_COVERAGE_METRICS_BASE_QUALITY } from '../modules/qc/picard_coverage_metrics.nf'
include { PICARD_COVERAGE_METRICS as PICARD_COVERAGE_METRICS_MAPPING_QUALITY } from '../modules/qc/picard_coverage_metrics.nf'
include { PICARD_COVERAGE_METRICS as PICARD_COVERAGE_METRICS_BY_CHROMOSOME } from '../modules/qc/picard_coverage_metrics.nf'
include { CREATE_FINGERPRINT_VCF } from '../modules/qc/create_fingerprint_vcf.nf'
include { PICARD_MULTIPLE_METRICS } from '../modules/qc/picard_multiple_metrics.nf'
include { SAMTOOLS_STATS } from '../modules/qc/samtools_stats.nf'
include { SAMTOOLS_FLAGSTAT } from '../modules/qc/samtools_flagstat.nf'
include { VERIFY_BAM_ID } from '../modules/qc/verify_bam_id.nf'
include { VERIFY_BAM_ID_CUSTOM_TARGET } from '../modules/qc/verify_bam_id_custom_target.nf'
include { COLLECT_AND_PLOT } from '../modules/qc/collect_and_plot.nf'

ch_versions = Channel.empty()

workflow SHORTREAD_QC {

    take:
        // ***************************************
        // **** Can be queue or value channel ****
        // ***************************************
        // "Input" for the workflow

        // (bam, bai, sample id, flowCell.lane.library, user id, publish directory)
        // flowCell.lane.library is null when doing qc on a merged bam
        ch_qcInputTuple

        // *************************************
        // **** Assumed to be value channel ****
        // *************************************
        // "Environment" for the workflow

        // (is GRC38, reference genome file path)
        ch_referenceInfoTuple

        // (is custom contamination target (true), contamination file path)
        // or
        // (is custom contamination target (false), UD Path, Bed Path, Mean Path)
        // UD Path, Bed Path, and Mean Path can be null and a default value will be used
        
        // ************************
        // **** Groovy objects ****
        // ************************
        
        // Map containing fields sequencingTarget, sequencingTargetIntervalsList, sequencingIntervalsTargetDirectory, 
        //                       baseQualityRange, mappingQualityRange, 
        //                       isCustomContaminationTargetSample, customContaminationTargetReferenceVCF, contaminationUDPath, contaminationBedPath, contaminationMeanPath, 
        //                       referenceAbbr, dbSnp, sequencingTargetBedFile, fingerprintBedFile
        sampleInfoMap
        
        versionsDirectory


    main:

        // RUNS PICARD_COVERAGE_METRICS ON FULL SAMPLE
        if (params.qcToRun.contains("coverage")) {

            def baseQualityRange = Channel.fromList(params.baseQualityRange)
            def mappingQualityRange = Channel.fromList(params.mappingQualityRange)

            // Runs PICARD_COVERAGE_METRICS with default MINIMUM_MAPPING_QUALITY for each MINIMUM_BASE_QUALITY in input baseQualityRange
            PICARD_COVERAGE_METRICS_BASE_QUALITY(ch_qcInputTuple, ch_referenceInfoTuple, baseQualityRange, params.defaultMappingQuality, sampleInfoMap.sequencingTargetIntervalsList)

            // Runs PICARD_COVERAGE_METRICS with default MINIMUM_BASE_QUALITY for each MINIMUM_MAPPING_QUALITY in input mappingQualityRange
            PICARD_COVERAGE_METRICS_MAPPING_QUALITY(ch_qcInputTuple, ch_referenceInfoTuple, params.defaultBaseQuality, mappingQualityRange, sampleInfoMap.sequencingTargetIntervalsList)

            // Logs module versions used
            ch_versions = ch_versions.concat(PICARD_COVERAGE_METRICS_BASE_QUALITY.out.versions)
            ch_versions = ch_versions.concat(PICARD_COVERAGE_METRICS_MAPPING_QUALITY.out.versions)
        }


        // RUNS PICARD_COVERAGE_METRICS ON EACH CHROMOSOME
        if (params.qcToRun.contains("coverage_by_chrom")) {

            // Construct .intervals.list files for all chromosomes
            def intervalsList = Channel.value("${sampleInfoMap.sequencingTargetIntervalsDirectory}/${sampleInfoMap.sequencingTarget}.${sampleInfoMap.referenceAbbr}")
            def chromosomes = Channel.fromList(params.chromosomeNames)

            intervalsList.combine(chromosomes)
            | map { iList, chr ->
                "${iList}.${chr}.intervals.list"
            }
            | set { intervalsLists }

            // Runs PICARD_COVERAGE_METRICS once for each intervals.list file in the intervalsList Channel
            PICARD_COVERAGE_METRICS_BY_CHROMOSOME(ch_qcInputTuple, ch_referenceInfoTuple, params.defaultBaseQuality, params.defaultMappingQuality, intervalsLists)

            // Logs module versions used
            ch_versions = ch_versions.concat(PICARD_COVERAGE_METRICS_BY_CHROMOSOME.out.versions)
        }


        // RUNS CONTAMINATION FOR THE SAMPLE
        if (params.qcToRun.contains("contamination")) {
            // Runs contamination
            if (sampleInfoMap.isCustomContaminationTargetSample) {
                VERIFY_BAM_ID_CUSTOM_TARGET(ch_qcInputTuple, sampleInfoMap.customContaminationTargetReferenceVCF)
                ch_versions = ch_versions.concat(VERIFY_BAM_ID_CUSTOM_TARGET.out.versions)
            }
            else {
                def regularContamInfo = [it.contaminationUDPath, it.contaminationBedPath, it.contaminationMeanPath]
                VERIFY_BAM_ID(ch_qcInputTuple, ch_referenceInfoTuple, regularContamInfo)
                ch_versions = ch_versions.concat(VERIFY_BAM_ID.out.versions)
            }
        }


        // CREATES VCF FOR THE SAMPLE
        if (params.qcToRun.contains("fingerprint")) {
            CREATE_FINGERPRINT_VCF(ch_qcInputTuple, ch_referenceInfoTuple, sampleInfoMap.dbSnp, sampleInfoMap.fingerprintBedFile)
            ch_versions = ch_versions.concat(CREATE_FINGERPRINT_VCF.out.versions)
        }

        
        // RUNS PICARD MULTIPLE METRICS ON THE SAMPLE
        if (params.qcToRun.contains("picard_multiple_metrics")) {
            PICARD_MULTIPLE_METRICS(ch_qcInputTuple, ch_referenceInfoTuple)
            ch_versions = ch_versions.concat(PICARD_MULTIPLE_METRICS.out.versions)
        }


        // RUNS SAMTOOLS FLAGSTAT ON THE SAMPLE
        if (params.qcToRun.contains("samtools_flagstat")) {
            SAMTOOLS_FLAGSTAT(ch_qcInputTuple)
            ch_versions = ch_versions.concat(SAMTOOLS_FLAGSTAT.out.versions)
        }


        // RUNS SAMTOOLS STATS ON THE SAMPLE
        if (params.qcToRun.contains("samtools_stats")) {
            SAMTOOLS_STATS(ch_qcInputTuple, sampleInfoMap.sequencingTargetBedFile)
            ch_versions = ch_versions.concat(SAMTOOLS_STATS.out.versions)
        }


        // GENERATES A PLOT FOR EACH QC STEP (excluding contamination and vcf)
        if (params.qcToRun.contains("collect_and_plot")) {
            // Collect output for each flowCell.lane.library where necessary
            PICARD_COVERAGE_METRICS_BASE_QUALITY.out.metricsFile.groupTuple(size: 4, sort: true) | set { ch_pcmBaseQGrouped }
            PICARD_COVERAGE_METRICS_BY_CHROMOSOME.out.metricsFile.groupTuple(size: 25) | set { ch_pcmChrGrouped }

            // Map Channels from [flowCell.lane.library, file1, file2, ...] to [flowCell.lane.library, [file1, file2, ...]]
            // Then Join them together
            ch_qcInputTuple.map({[it[3], it]}) | set { ch_qcInputTupleFormatted } // flowCell.lane.library is the 3rd index of ch_qcInputTuple
            def filterFlowCellLaneLibrary = { fileTuple -> [fileTuple[0], fileTuple - fileTuple[0]] }
            PICARD_MULTIPLE_METRICS.out.metricsFiles.map(filterFlowCellLaneLibrary)
            | join(SAMTOOLS_FLAGSTAT.out.flagstatFile.map(filterFlowCellLaneLibrary))
            | join(SAMTOOLS_STATS.out.statsFile.map(filterFlowCellLaneLibrary))
            | join(PICARD_COVERAGE_METRICS_MAPPING_QUALITY.out.metricsFile.map(filterFlowCellLaneLibrary))
            | join(ch_pcmBaseQGrouped)
            | join(ch_pcmChrGrouped)
            | join(ch_qcInputTupleFormatted)
            // MultiMap to proper input streams
            | multiMap {flowCellLaneLibrary, picardMultipleMetricsFiles, samtoolsFlagstatFile, samtoolsStatsFile, pcmMapQFile, pcmBaseQFiles, pcmChrFiles, qcGeneralInfo ->
                    picardMultipleMetrics: picardMultipleMetricsFiles
                    samtoolsFlagstat: samtoolsFlagstatFile
                    samtoolsStats: samtoolsStatsFile
                    pcmMapQ: pcmMapQFile
                    pcmBaseQ: pcmBaseQFiles
                    pcmChr: pcmChrFiles
                    qcInput: qcGeneralInfo
            }
            | set { ch_collectAndPlotInput }


            
            COLLECT_AND_PLOT( ch_collectAndPlotInput.picardMultipleMetrics, ch_collectAndPlotInput.samtoolsFlagstat, ch_collectAndPlotInput.samtoolsStats,
                              ch_collectAndPlotInput.pcmMapQ, ch_collectAndPlotInput.pcmBaseQ, ch_collectAndPlotInput.pcmChr,
                              ch_collectAndPlotInput.qcInput, sampleInfoMap.sequencingTargetBedFile)
            ch_versions = ch_versions.concat(COLLECT_AND_PLOT.out.versions)
        }
 

        // VERSIONS
        ch_versions.unique().collectFile(name: 'qc_software_versions.yaml', storeDir: "${versionsDirectory}")

}