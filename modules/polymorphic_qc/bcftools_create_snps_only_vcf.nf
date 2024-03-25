process BCFTOOLS_CREATE_SNPS_ONLY_VCF {

    label "BCFTOOLS_CREATE_SNPS_ONLY_VCF_${params.sampleId}_${params.userId}"

    publishDir "${params.samplePolymorphicQCDirectory}", mode: 'link', pattern: "${params.sampleId}.merged.matefixed.sorted.markeddups.recal.filtered.snps.vcf"

    input:
        path filtered_vcf

    output:
        path "${params.sampleId}.merged.matefixed.sorted.markeddups.recal.filtered.snps.vcf", emit: filtered_snps_vcf
        path "versions.yaml", emit: versions

    script:

        """
        bcftools view -V indels,mnps,other ${filtered_vcf} > ${params.sampleId}.merged.matefixed.sorted.markeddups.recal.filtered.snps.vcf

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            bcftools: \$(bcftools --version | grep ^bcftools | awk '{print \$2}')
        END_VERSIONS

        """
}