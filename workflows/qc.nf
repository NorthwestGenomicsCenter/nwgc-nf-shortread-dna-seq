include { PICARD_COVERAGE_METRICS } from '../modules/picard_coverage_metrics.nf'
include { CONTAMINATION_CHECK } from '../modules/contamination_check.nf'
include { CREATE_FINGERPRINT_VCF } from '../modules/create_fingerprint_vcf.nf'
include { PICARD_MULTIPLE_METRICS } from '../modules/picard_multiple_metrics.nf'

ch_versions = Channel.empty()

workflow SHORTREAD_QC {

    // Input is a merged bam (and corresponding bai)
    take:
        bam
        bai

    main:

       def runAll = params.qcToRun.contains("All")

        if (runAll || params.qcToRun.contains("coverage")) {
            // Defines the location of the intervals.list file to be used for PICARD_COVERAGE_METRICS
            def intervalsList = params.intervalsDir + '/' + params.sequencingTarget + '.' + params.referenceAbbr + '.intervals.list'

            // Runs PICARD_COVERAGE_METRICS with default MINIMUM_MAPPING_QUALITY for each MINIMUM_BASE_QUALITY in input baseQualityRange
            Channel baseQuality = Channel.from(params.baseQualityRange)
            PICARD_COVERAGE_METRICS(bam, bai, baseQuality, -1, intervalsList)

            // Runs PICARD_COVERAGE_METRICS with default MINIMUM_BASE_QUALITY for each MINIMUM_MAPPING_QUALITY in input mappingQualityRange
            Channel mappingQuality = Channel.from(params.mappingQualityRange)
            PICARD_COVERAGE_METRICS(bam, bai, -1, mappingQuality, intervalsList)

            // Logs module versions used
            ch_versions = ch_versions.mix(PICARD_COVERAGE_METRICS.out.versions)
        }

        if (runAll || params.qcToRun.contains("coverage_by_chrom")) {
            Channel chromosomes = Channel.from(params.hg19Chromosomes)
            if (params.isGRC38) {
                chromosomes = Channel.from(params.grc38Chromosomes)
            }

            // Generate a Channel with one intervals.list file per chromosome
            Channel intervalsListFront = Channel.value(params.intervalsDir + '/' + params.sequencingTarget + '.' params.referenceAbbr)
            Channel intervalsListEnd = Channel.value('.intervals.list')
            intervalsList = intervalsList.combine(chromosomes).combine(intervalsListEnd)

            // Runs PICARD_COVERAGE_METRICS once for each intervals.list file in the intervalsList Channel
            PICARD_COVERAGE_METRICS(bam, bai, -1, -1, intervalsList)

            // Logs module versions used
            ch_versions = ch_versions.mix(PICARD_COVERAGE_METRICS.out.versions)
        }

        if (runAll || params.qcToRun.contains("contamination")) {
            CONTAMINATION_CHECK(bam, bai)
            ch_versions = ch_versions.mix(CONTAMINATION_CHECK.out.versions)
        }

        if (runAll || params.qcToRun.contains("fingerprint")) {
            CREATE_FINGERPRINT_VCF(bam, bai)
            ch_versions = ch_versions.mix(CREATE_FINGERPRINT_VCF.out.versions)
        }

        if (runAll || params.qcToRun.contains("multiple")) {
            PICARD_MULTIPLE_METRICS(bam, bai)
            ch_version = ch_versions.mix(PICARD_MULTIPLE_METRICS.out.versions)
        }
 
        ch_versions.unique().collectFile(name: 'qc_software_versions.yaml', storeDir: "${params.sampleDirectory}")

}