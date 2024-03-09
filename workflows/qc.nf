include { PICARD_COVERAGE_METRICS as PICARD_COVERAGE_METRICS_BASE_QUALITY } from '../modules/picard_coverage_metrics.nf'
include { PICARD_COVERAGE_METRICS as PICARD_COVERAGE_METRICS_MAPPING_QUALITY } from '../modules/picard_coverage_metrics.nf'
include { PICARD_COVERAGE_METRICS as PICARD_COVERAGE_METRICS_BY_CHROMOSOME } from '../modules/picard_coverage_metrics.nf'
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
            def intervalsList = "${params.intervalsDir}/${params.sequencingTarget}.${params.referenceAbbr}.intervals.list"

            // Runs PICARD_COVERAGE_METRICS with default MINIMUM_MAPPING_QUALITY for each MINIMUM_BASE_QUALITY in input baseQualityRange
            baseQuality = Channel.fromList(params.baseQualityRange)
            baseQualityIdent = Channel.fromList(params.baseQualityRange)
            PICARD_COVERAGE_METRICS_BASE_QUALITY(bam, bai, baseQuality, -1, intervalsList, "1${baseQualityIdent}")

            // Runs PICARD_COVERAGE_METRICS with default MINIMUM_BASE_QUALITY for each MINIMUM_MAPPING_QUALITY in input mappingQualityRange
            mappingQuality = Channel.fromList(params.mappingQualityRange)
            PICARD_COVERAGE_METRICS_MAPPING_QUALITY(bam, bai, -1, mappingQuality, intervalsList, "100")

            // Logs module versions used
            ch_versions = ch_versions.mix(PICARD_COVERAGE_METRICS_BASE_QUALITY.out.versions)
            ch_versions = ch_versions.mix(PICARD_COVERAGE_METRICS_MAPPING_QUALITY.out.versions)
        }

        if (runAll || params.qcToRun.contains("coverage_by_chrom")) {
            intervalsList = Channel.empty()
            chromosomes = Channel.fromList(params.hg19Chromosomes)
            if (params.isGRC38) {
                for (String chromosome in params.grc38Chromosomes) {
                    chromosomeIntervalsList = Channel.value("${params.intervalsDir}/${params.sequencingTarget}.${params.referenceAbbr}.${chromosome}.intervals.list")
                    intervalsList = intervalsList.concat(chromosomeIntervalsList)
                    chromosomes = Channel.fromList(params.hg19Chromosomes)
                }
            }
            else {
                for (String chromosome in params.hg19Chromosomes) {
                    chromosomeIntervalsList = Channel.value("${params.intervalsDir}/${params.sequencingTarget}.${params.referenceAbbr}.${chromosome}.intervals.list")
                    intervalsList = intervalsList.concat(chromosomeIntervalsList)
                }
            }

            /*
            // Generate a Channel with one intervals.list file per chromosome
            intervalsListFront = Channel.value("${params.intervalsDir}/${params.sequencingTarget}.${params.referenceAbbr}.")
            intervalsListEnd = Channel.value('.intervals.list')
            intervalsList = "${params.intervalsDir}/${params.sequencingTarget}.${params.referenceAbbr}" + chromosomes + '.intervals.list'
            */

            // Runs PICARD_COVERAGE_METRICS once for each intervals.list file in the intervalsList Channel
            PICARD_COVERAGE_METRICS_BY_CHROMOSOME(bam, bai, -1, -1, intervalsList, chromosomes)

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

        if (runAll || params.qcToRun.contains("multiple")) {
            PICARD_MULTIPLE_METRICS(bam, bai)
            ch_version = ch_versions.mix(PICARD_MULTIPLE_METRICS.out.versions)
        }
 
        ch_versions.unique().collectFile(name: 'qc_software_versions.yaml', storeDir: "${params.sampleDirectory}")

}