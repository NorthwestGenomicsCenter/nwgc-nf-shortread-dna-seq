process HAPLOTYPE_CALLER {

    tag "HAPLOTYPE_CALLER_${sampleId}_${userId}"

    input:
        tuple val(chromosome), path(bam), val(sampleId), val(userId)
        val referenceGenome
        val dbSnp

    output:
        tuple val(chromosome), path(bam), path("*.g.vcf"), val(sampleId), val(userId),  emit: gvcf_tuple
        path "versions.yaml", emit: versions

    script:
        def taskMemoryString = "$task.memory"

        """
        gatk \
            --java-options "-XX:InitialRAMPercentage=80.0 -XX:MaxRAMPercentage=85.0" \
            HaplotypeCaller \
            -R $referenceGenome \
            -I $bam \
            -D $dbSnp \
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