include { PICARD_COVERAGE_METRICS } from '../modules/picard_coverage_metrics.nf'
include { CONTAMINATION_CHECK } from '../modules/contamination_check.nf'
include { CREATE_FINGERPRINT_VCF } from '../modules/create_fingerprint_vcf.nf'

ch_versions = Channel.empty()

workflow SHORTREAD_QC {

    // Input is a merged bam (and corresponding bai)
    take:
        bam
        bai

    main:

       def runAll = params.qcToRun.contains("All")

        if (runAll || params.qcToRun.contains("coverage")) {
            PICARD_COVERAGE_METRICS(bam, bai)
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
 
        ch_versions.unique().collectFile(name: 'qc_software_versions.yaml', storeDir: "${params.sampleDirectory}")

}