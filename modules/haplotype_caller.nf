process HAPLOTYPE_CALLER {

    label "HAPLOTYPE_CALLER_${params.sampleId}_${params.userId}"

    input:
        tuple val(chromosome), path(bam)

    output:
        tuple val(chromosome), path(bam), path("*.g.vcf"),  emit: gvcf_tuple
        path "versions.yaml", emit: versions

    script:
        def taskMemoryString = "$task.memory"
        def javaMemory = taskMemoryString.substring(0, taskMemoryString.length() - 1).replaceAll("\\s","")

        """
        gatk \
            --java-options "-Xmx$javaMemory" \
            HaplotypeCaller \
            -R $params.referenceGenome \
            -I $bam \
            -D $params.dbSnp \
            -L $chromosome \
            --annotation-group StandardAnnotation \
            --pair-hmm-implementation AVX_LOGLESS_CACHING \
            --emit-ref-confidence GVCF \
            --output ${chromosome}.g.vcf 

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}_${task.index}':
            gatk: \$(gatk --version | grep GATK | awk '{print \$6}')
        END_VERSIONS
        """

}
