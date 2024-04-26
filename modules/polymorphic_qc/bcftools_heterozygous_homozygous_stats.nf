process BCFTOOLS_HETEROZYGOUS_HOMOZYGOUS_STATS {

    tag "BCFTOOLS_HETEROZYGOUS_HOMOZYGOUS_STATS_${params.sampleId}_${params.userId}"

    publishDir "${params.samplePolymorphicQCDirectory}", mode: 'link', pattern: "${params.sampleId}.het_hom.txt"

    input:
        path filtered_snps_vcf

    output:
        path "${params.sampleId}.het_hom.txt"
        path "versions.yaml", emit: versions

    script:

        """
        bcftools stats -f PASS -i AC=1 ${filtered_snps_vcf} \
        | grep "number of SNPs:" \
        | awk '{print "HET: " \$6}' \
        > ${params.sampleId}.het_hom.txt

        bcftools stats -f PASS -i AC=2 ${filtered_snps_vcf} \
        | grep "number of SNPs:" \
        | awk '{print "HOM: " \$6}' \
        >> ${params.sampleId}.het_hom.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            bcftools: \$(bcftools --version | grep ^bcftools | awk '{print \$2}')
        END_VERSIONS

        """
}