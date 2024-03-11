include { PICARD_COVERAGE_METRICS as PICARD_COVERAGE_METRICS_BASE_QUALITY } from '../modules/picard_coverage_metrics.nf'
include { PICARD_COVERAGE_METRICS as PICARD_COVERAGE_METRICS_MAPPING_QUALITY } from '../modules/picard_coverage_metrics.nf'
include { PICARD_COVERAGE_METRICS as PICARD_COVERAGE_METRICS_BY_CHROMOSOME } from '../modules/picard_coverage_metrics.nf'
include { CONTAMINATION_CHECK } from '../modules/contamination_check.nf'
include { CREATE_FINGERPRINT_VCF } from '../modules/create_fingerprint_vcf.nf'
include { PICARD_MULTIPLE_METRICS } from '../modules/picard_multiple_metrics.nf'
include { SAMTOOLS_STATS } from '../modules/samtools_stats.nf'
include { SAMTOOLS_FLAGSTAT } from '../modules/samtools_flagstat.nf'

ch_versions = Channel.empty()

workflow SHORTREAD_QC {

    // Input is a merged bam (and corresponding bai)
    take:
        bam
        bai

    main:

       def runAll = params.qcToRun.contains("All")

       // Defines default MINIMUM_BASE_QUALITY and MINIMUM_MAPPING_QUALITY
       defaultBaseQuality = Channel.value(20);
       defaultMappingQuality = Channel.value(20);

        if (runAll || params.qcToRun.contains("coverage")) {
            // Tuple containing intervals list and what part of the sequencing target is being analyzed
            // Blank in this case because the whole sequencing target is being analyzed
            def directoryInfo = [params.sequencingTargetIntervalsList, ""]

            // Runs PICARD_COVERAGE_METRICS with default MINIMUM_MAPPING_QUALITY for each MINIMUM_BASE_QUALITY in input baseQualityRange
            baseQualityRange = Channel.fromList(params.baseQualityRange)
            PICARD_COVERAGE_METRICS_BASE_QUALITY(bam, bai, baseQualityRange, defaultMappingQuality, directoryInfo)

            // Runs PICARD_COVERAGE_METRICS with default MINIMUM_BASE_QUALITY for each MINIMUM_MAPPING_QUALITY in input mappingQualityRange
            mappingQualityRange = Channel.fromList(params.mappingQualityRange)
            PICARD_COVERAGE_METRICS_MAPPING_QUALITY(bam, bai, defaultBaseQuality, mappingQualityRange, directoryInfo)

            // Logs module versions used
            ch_versions = ch_versions.mix(PICARD_COVERAGE_METRICS_BASE_QUALITY.out.versions)
            ch_versions = ch_versions.mix(PICARD_COVERAGE_METRICS_MAPPING_QUALITY.out.versions)
        }

        if ((runAll && params.sequencingTargetIntervalsDir != null) || params.qcToRun.contains("coverage_by_chrom")) {
            if (params.sequencingTargetIntervalsDir == null) {
                throw new Exception("Coverage by chromosome was specified but no intervalsDir was provided")
            }
            chromosomes = params.hg19Chromosomes
            if (params.isGRC38) {
               chromosomes = params.grc38Chromosomes;
            }

            // Generate a Channel with the intervals.list file and name of each chromosome
            directoryInfoList = [];
            for (String chromosome in params.grc38Chromosomes) {
                chromosomeIntervalsList = "${params.sequencingTargetIntervalsDir}/${params.sequencingTarget}.${params.referenceAbbr}.${chromosome}.intervals.list"
                // Tuple containing intervals lis and what part of the sequencing target is being analyzed (the chromosome)
                directoryInfoTuple = [chromosomeIntervalsList, chromosome]
                directoryInfoList << directoryInfoTuple
            }
            directoryInfo = Channel.fromList(directoryInfoList)

            // Runs PICARD_COVERAGE_METRICS once for each intervals.list file in the intervalsList Channel
            PICARD_COVERAGE_METRICS_BY_CHROMOSOME(bam, bai, defaultBaseQuality, defaultMappingQuality, directoryInfo)

            // Logs module versions used
            ch_versions = ch_versions.mix(PICARD_COVERAGE_METRICS_BY_CHROMOSOME.out.versions)
        }

        if (runAll || params.qcToRun.contains("contamination")) {
            CONTAMINATION_CHECK(bam, bai)
            ch_versions = ch_versions.mix(CONTAMINATION_CHECK.out.versions)
        }

        if (runAll || params.qcToRun.contains("fingerprint")) {
            CREATE_FINGERPRINT_VCF(bam, bai)
            ch_versions = ch_versions.mix(CREATE_FINGERPRINT_VCF.out.versions)
        }

        if (runAll || params.qcToRun.contains("picard_multiple_metrics")) {
            PICARD_MULTIPLE_METRICS(bam, bai)
            ch_version = ch_versions.mix(PICARD_MULTIPLE_METRICS.out.versions)
        }

        if (runAll || params.qcToRun.contains("samtools_flagstat")) {
            SAMTOOLS_FLAGSTAT(bam)
            ch_version = ch_versions.mix(SAMTOOLS_STATS.out.versions)
        }

        if (runAll || params.qcToRun.contains("samtools_stats")) {
            SAMTOOLS_STATS(bam, params.sequencingTargetBed)
            ch_version = ch_versions.mix(SAMTOOLS_STATS.out.versions)
        }
 
        ch_versions.unique().collectFile(name: 'qc_software_versions.yaml', storeDir: "${params.sampleDirectory}")

}