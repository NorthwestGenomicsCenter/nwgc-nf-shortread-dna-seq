process ANNOTATE_VARIANTS {

    label "ANNOTATE_VARIANTS_${params.sampleId}_${params.userId}"

    input:
        tuple val(chromosome), path(bam), path(gvcf)

    output:
        tuple val(chromosome), path(bam), path("*.annotated.g.vcf"),  emit: gvcf_tuple
        path  "*.annotated.g.vcf", emit: gvcf
        path "versions.yaml", emit: versions

    script:
        def taskMemoryString = "$task.memory"
        def javaMemory = taskMemoryString.substring(0, taskMemoryString.length() - 1).replaceAll("\\s","")

        """
        java "-Xmx$javaMemory" \
            -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar \
            -T VariantAnnotator \
            -R $params.referenceGenome \
            -I $bam \
            -A Coverage \
            -A QualByDepth \
            -A FisherStrand \
            -A StrandOddsRatio \
            -L $chromosome \
            -D $params.dbSnp \
            --disable_auto_index_creation_and_locking_when_reading_rods \
            -V $gvcf \
            -o ${chromosome}.annotated.g.vcf

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(java -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar --version)
        END_VERSIONS

        """

}
