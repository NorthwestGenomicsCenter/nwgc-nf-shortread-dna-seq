process FILTER_VARIANTS {

    label "FILTER_VARIANTS_${params.sampleId}_${params.userId}"

    input:
        tuple val(chromosome), path(bam), path(gvcf)

    output:
        tuple val(chromosome), path(bam), path("*.filtered.g.vcf"),  emit: gvcf_tuple
        path  "*.filtered.g.vcf", emit: gvcf
        path "versions.yaml", emit: versions

    when:
        params.organism == 'Homo sapiens'

    script:
        def taskMemoryString = "$task.memory"
        def javaMemory = taskMemoryString.substring(0, taskMemoryString.length() - 1).replaceAll("\\s","")

        """
        java "-Xmx$javaMemory" \
            -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar \
            -T VariantFiltration \
            -R $params.referenceGenome \
            --filterName QDFilter -filter "QD < 5.0" \
            --filterName QUALFilter -filter "QUAL <= 50.0" \
            --filterName ABFilter -filter "ABHet > 0.75" \
            --filterName SBFilter -filter "SB >= 0.10" \
            --filterName HRunFilter -filter "HRun > 4.0" \
            -l OFF \
            -L $params.targetListFile \
            --disable_auto_index_creation_and_locking_when_reading_rods \
            -V $gvcf \
            -o ${chromosome}.filtered.g.vcf

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(java -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar --version)
        END_VERSIONS

        """

}