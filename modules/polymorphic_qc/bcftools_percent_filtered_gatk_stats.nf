process BCFTOOLS_PERCENT_FILTERED_GATK_STATS {

    label "BCFTOOLS_PERCENT_FILTERED_GATK_STATS_${params.sampleId}_${params.userId}"

    publishDir "${params.samplePolymorphicQCDirectory}", mode: 'link', pattern: "${params.sampleId}.percent_filtered_gatk.txt"

    input:
        path filtered_snps_vcf

    output:
        path "${params.sampleId}.percent_filtered_gatk.txt"
        path "versions.yaml", emit: versions

    script:

        """
        bcftools stats -f PASS ${filtered_snps_vcf} \
        | grep "number of SNPs:" \
        | awk '{print "NUM_FILTERED: " \$6}' \
        > ${params.sampleId}.percent_filtered_gatk.txt

        bcftools stats ${filtered_snps_vcf} \
        | grep "number of SNPs:" \
        | awk '{print "NUM_VARIANTS: " \$6}' \
        >> ${params.sampleId}.percent_filtered_gatk.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            bcftools: \$(bcftools --version | grep ^bcftools | awk '{print \$2}')
        END_VERSIONS

        """
}