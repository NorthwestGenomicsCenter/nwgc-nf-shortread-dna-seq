process BCFTOOLS_GVCF_TO_VCF {

    tag "BCFTOOLS_GVCF_TO_VCF_${params.sampleId}_${params.userId}"

    input:
        path filtered_gvcf

    output:
        path "${params.sampleId}.merged.matefixed.sorted.markeddups.recal.filtered.vcf", emit: filtered_vcf
        path "versions.yaml", emit: versions

    script:

        """
        bcftools view -v snps -a ${filtered_gvcf} > ${params.sampleId}.merged.matefixed.sorted.markeddups.recal.filtered.vcf

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            bcftools: \$(bcftools --version | grep ^bcftools | awk '{print \$2}')
        END_VERSIONS

        """
}