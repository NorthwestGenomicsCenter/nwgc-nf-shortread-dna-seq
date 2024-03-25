process BCFTOOLS_FILTERED_TRANSITION_TRANSVERSION_STATS {

    label "BCFTOOLS_FILTERED_TRANSITION_TRANSVERSION_STATS_${params.sampleId}_${params.userId}"
    
    publishDir "${params.samplePolymorphicQCDirectory}", mode: 'link', pattern: "${params.sampleId}.transition_transversion.filtered.txt"

    input:
        path filtered_snps_vcf

    output:
        path "${params.sampleId}.transition_transversion.filtered.txt"
        path "versions.yaml", emit: versions

    script:

        """
        bcftools stats -f PASS -I ${filtered_snps_vcf} \
        | grep ^TSTV \
        | awk '{if (\$2 == 0) print "known_ti_count: " \$3 "\\nknown_tv_count: " \$4 "\\nknown_ti_tv: " \$5; else  print "novel_ti_count: " \$3 "\\nnovel_tv_count: " \$4 "\\nnovel_ti_tv: " \$5}' \
        > ${params.sampleId}.transition_transversion.filtered.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            bcftools: \$(bcftools --version | grep ^bcftools | awk '{print \$2}')
        END_VERSIONS

        """
}