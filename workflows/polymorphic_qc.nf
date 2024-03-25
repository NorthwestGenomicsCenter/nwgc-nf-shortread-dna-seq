include { BCFTOOLS_GVCF_TO_VCF } from "../modules/polymorphic_qc/bcftools_gvcf_to_vcf.nf"
include { BCFTOOLS_CREATE_SNPS_ONLY_VCF } from "../modules/polymorphic_qc/bcftools_create_snps_only_vcf.nf"
include { BCFTOOLS_UNFILTERED_TRANSITION_TRANSVERSION_STATS } from "../modules/polymorphic_qc/bcftools_unfiltered_transition_transversion_stats.nf"
include { BCFTOOLS_FILTERED_TRANSITION_TRANSVERSION_STATS } from "../modules/polymorphic_qc/bcftools_filtered_transition_transversion_stats.nf"
include { BCFTOOLS_HETEROZYGOUS_HOMOZYGOUS_STATS } from "../modules/polymorphic_qc/bcftools_heterozygous_homozygous_stats.nf"
include { BCFTOOLS_PERCENT_FILTERED_GATK_STATS } from "../modules/polymorphic_qc/bcftools_percent_filtered_gatk_stats.nf"

workflow POLYMORPHIC_QC {

    take:
        filtered_gvcf

    main:
        ch_versions = Channel.empty()

        // Convert from GVCF to VCF
        BCFTOOLS_GVCF_TO_VCF(filtered_gvcf)

        // Create SNPS only VCF file
        BCFTOOLS_CREATE_SNPS_ONLY_VCF(BCFTOOLS_GVCF_TO_VCF.out.filtered_vcf)

        // Collect Polymorphic QC Metrics
        BCFTOOLS_UNFILTERED_TRANSITION_TRANSVERSION_STATS(BCFTOOLS_CREATE_SNPS_ONLY_VCF.out.filtered_snps_vcf)
        BCFTOOLS_FILTERED_TRANSITION_TRANSVERSION_STATS(BCFTOOLS_CREATE_SNPS_ONLY_VCF.out.filtered_snps_vcf)
        BCFTOOLS_HETEROZYGOUS_HOMOZYGOUS_STATS(BCFTOOLS_CREATE_SNPS_ONLY_VCF.out.filtered_snps_vcf)
        BCFTOOLS_PERCENT_FILTERED_GATK_STATS(BCFTOOLS_CREATE_SNPS_ONLY_VCF.out.filtered_snps_vcf)

        // Versions
        ch_versions = ch_versions.mix(BCFTOOLS_GVCF_TO_VCF.out.versions)
        ch_versions = ch_versions.mix(BCFTOOLS_CREATE_SNPS_ONLY_VCF.out.versions)
        ch_versions = ch_versions.mix(BCFTOOLS_UNFILTERED_TRANSITION_TRANSVERSION_STATS.out.versions)
        ch_versions = ch_versions.mix(BCFTOOLS_FILTERED_TRANSITION_TRANSVERSION_STATS.out.versions)
        ch_versions = ch_versions.mix(BCFTOOLS_HETEROZYGOUS_HOMOZYGOUS_STATS.out.versions)
        ch_versions = ch_versions.mix(BCFTOOLS_PERCENT_FILTERED_GATK_STATS.out.versions)

}