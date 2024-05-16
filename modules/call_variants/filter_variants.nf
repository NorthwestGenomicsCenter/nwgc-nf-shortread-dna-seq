process FILTER_VARIANTS {

    tag "FILTER_VARIANTS_${sampleId}_${userId}"

    input:
        tuple val(chromosome), path(bam), path(gvcf), val(sampleId), val(userId)
        val referenceGenome
        val targetListFile

    output:
        tuple val(chromosome), path(bam), path("*.filtered.g.vcf"), val(sampleId), val(userId),  emit: gvcf_tuple
        path  "*.filtered.g.vcf", emit: gvcf
        path "versions.yaml", emit: versions

    script:
        def taskMemoryString = "$task.memory"

        """
        java \
            -XX:InitialRAMPercentage=80 \
            -XX:MaxRAMPercentage=85 \
            -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar \
            -T VariantFiltration \
            -R $referenceGenome \
            --filterName QDFilter -filter "QD < 5.0" \
            --filterName QUALFilter -filter "QUAL <= 50.0" \
            --filterName ABFilter -filter "ABHet > 0.75" \
            --filterName SBFilter -filter "SB >= 0.10" \
            --filterName HRunFilter -filter "HRun > 4.0" \
            -l OFF \
            -L $targetListFile \
            --disable_auto_index_creation_and_locking_when_reading_rods \
            -V $gvcf \
            -o ${chromosome}.filtered.g.vcf

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(java -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar --version)
        END_VERSIONS

        """

}