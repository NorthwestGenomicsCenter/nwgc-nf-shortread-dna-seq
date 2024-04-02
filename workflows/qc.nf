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

        // (bam, bai, sample id, library id, user id, publish directory)
        // library id is null when doing qc on a merged bam
        qcInputTuple

        // **************************************
        // **** Assumed to be value channel ****
        // **************************************
        // "Environment" for the workflow

        // (is GRC38, reference genome file path)
        referenceInfoTuple

        // (is custom contamination target (true), contamination file path)
        // or
        // (is custom contamination target (false), UD Path, Bed Path, Mean Path)
        // UD Path, Bed Path, and Mean Path can be null and a default value will be used
        
        // Map containing fields sequencingTarget, sequencingTargetIntervalsList, sequencingIntervalsTargetDirectory, 
        //                       baseQualityRange, mappingQualityRange, 
        //                       isCustomContaminationTargetSample, customContaminationTargetReferenceVCF, contaminationUDPath, contaminationBedPath, contaminationMeanPath, 
        //                       referenceAbbr, dbSnp, sequencingTargetBedFile, fingerprintBedFile
        sampleInfoMap


    main:

        // RUNS PICARD_COVERAGE_METRICS ON FULL SAMPLE
        if (params.qcToRun.contains("coverage")) {
            // Parse input channels from sampleInfoMap
            intervalsList = sampleInfoMap.map {
                it.sequencingTargetIntervalsList
            }
            def baseQualityRange = Channel.fromList(params.baseQualityRange)
            def mappingQualityRange = Channel.fromList(params.mappingQualityRange)

            // Runs PICARD_COVERAGE_METRICS with default MINIMUM_MAPPING_QUALITY for each MINIMUM_BASE_QUALITY in input baseQualityRange
            PICARD_COVERAGE_METRICS_BASE_QUALITY(qcInputTuple, referenceInfoTuple, baseQualityRange, params.defaultMappingQuality, intervalsList)

            // Runs PICARD_COVERAGE_METRICS with default MINIMUM_BASE_QUALITY for each MINIMUM_MAPPING_QUALITY in input mappingQualityRange
            PICARD_COVERAGE_METRICS_MAPPING_QUALITY(qcInputTuple, referenceInfoTuple, params.defaultBaseQuality, mappingQualityRange, intervalsList)

            // Logs module versions used
            ch_versions = ch_versions.concat(PICARD_COVERAGE_METRICS_BASE_QUALITY.out.versions)
            ch_versions = ch_versions.concat(PICARD_COVERAGE_METRICS_MAPPING_QUALITY.out.versions)
        }


        // RUNS PICARD_COVERAGE_METRICS ON EACH CHROMOSOME
        if (params.qcToRun.contains("coverage_by_chrom")) {

            // Construct .intervals.list files for all chromosomes
            intervalsList = sampleInfoMap.map {
                "${it.sequencingTargetIntervalsDirectory}/${it.sequencingTarget}.${it.referenceAbbr}"
            }
            chromosomes = Channel.fromList(params.chromosomeNames)

            intervalsList.combine(chromosomes)
            | map { intervalsList, chr ->
                "${intervalsList}.${chr}.intervals.list"
            }
            | set { intervalsLists }

            // Runs PICARD_COVERAGE_METRICS once for each intervals.list file in the intervalsList Channel
            PICARD_COVERAGE_METRICS_BY_CHROMOSOME(qcInputTuple, referenceInfoTuple, params.defaultBaseQuality, params.defaultMappingQuality, intervalsLists)

            // Logs module versions used
            ch_versions = ch_versions.concat(PICARD_COVERAGE_METRICS_BY_CHROMOSOME.out.versions)
        }


        // RUNS CONTAMINATION FOR THE SAMPLE
        if (params.qcToRun.contains("contamination")) {
            contamInfo = sampleInfoMap.branch {
                custom: it.isCustomContaminationTargetSample
                regular: true
            }
            
            customContamInfo = contamInfo.custom.map {
                [it.isCustomContaminationTargetSample, it.customContaminationTargetReferenceVCF]
            }

            regularContamInfo = contamInfo.regular.map {
                [it.isCustomContaminationTargetSample, it.contaminationUDPath, it.contaminationBedPath, it.contaminationMeanPath]
            }

            // Runs contamination
            // ISSUE WITH NULL FILES MAYBE IS CUSTOM CONTAMINATION TARGET SHOULD BE A PARAM
            // basically just cant call both of these raw because itll try to run one of them with null channels and crash
            // may also have some issues with work-dir = null whatever that means
            VERIFY_BAM_ID_CUSTOM_TARGET(qcInputTuple, customContamInfo)
            VERIFY_BAM_ID(qcInputTuple, referenceInfoTuple, regularContamInfo)

            // Logs module versions used
            ch_versions = ch_versions.concat(VERIFY_BAM_ID_CUSTOM_TARGET.out.versions)
            ch_versions = ch_versions.concat(VERIFY_BAM_ID.out.versions)
        }


        // CREATES VCF FOR THE SAMPLE
        if (params.qcToRun.contains("fingerprint")) {
            fingerprintInfo = sampleInfoMap.multiMap {
                dbSnp: it.dbSnp
                fingerprintBed: it.fingerprintBedFile
            }

            CREATE_FINGERPRINT_VCF(qcInputTuple, referenceInfoTuple, fingerprintInfo.dbSnp, fingerprintInfo.fingerprintBed)
            ch_versions = ch_versions.concat(CREATE_FINGERPRINT_VCF.out.versions)
        }

        
        // RUNS PICARD MULTIPLE METRICS ON THE SAMPLE
        if (params.qcToRun.contains("picard_multiple_metrics")) {
            PICARD_MULTIPLE_METRICS(qcInputTuple, referenceInfoTuple)
            ch_versions = ch_versions.concat(PICARD_MULTIPLE_METRICS.out.versions)
        }


        // RUNS SAMTOOLS FLAGSTAT ON THE SAMPLE
        if (params.qcToRun.contains("samtools_flagstat")) {
            SAMTOOLS_FLAGSTAT(qcInputTuple)
            ch_versions = ch_versions.concat(SAMTOOLS_FLAGSTAT.out.versions)
        }


        // RUNS SAMTOOLS STATS ON THE SAMPLE
        if (params.qcToRun.contains("samtools_stats")) {
            sequencingTargetBedFile = sampleInfoMap.map { it.sequencingTargetBedFile }

            SAMTOOLS_STATS(qcInputTuple, sequencingTargetBedFile)
            ch_versions = ch_versions.concat(SAMTOOLS_STATS.out.versions)
        }


        // GENERATES A PLOT FOR EACH QC STEP (excluding contamination and vcf)
        if (params.qcToRun.contains("collect_and_plot")) {
            sequencingTargetBedFile = sampleInfoMap.map { it.sequencingTargetBedFile }

            COLLECT_AND_PLOT(PICARD_COVERAGE_METRICS_BASE_QUALITY.out.ready.collect(), PICARD_COVERAGE_METRICS_MAPPING_QUALITY.out.ready.collect(),
                            PICARD_COVERAGE_METRICS_BY_CHROMOSOME.out.ready.collect(), PICARD_MULTIPLE_METRICS.out.ready.collect(), 
                            SAMTOOLS_FLAGSTAT.out.ready.collect(), SAMTOOLS_STATS.out.ready.collect(), qcInputTuple, sequencingTargetBedFile)
            ch_versions = ch_versions.concat(COLLECT_AND_PLOT.out.versions)
        }
 

        // VERSIONS
        ch_versions.unique().collectFile(name: 'qc_software_versions.yaml', storeDir: "${params.sampleDirectory}")

}