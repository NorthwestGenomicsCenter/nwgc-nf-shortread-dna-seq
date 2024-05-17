process ANNOTATE_VARIANTS {

    tag "ANNOTATE_VARIANTS_${sampleId}_${userId}"

    input:
        tuple val(chromosome), path(bam), path(gvcf), val(sampleId), val(userId)
        val referenceGenome
        val dbSnp

    output:
        tuple val(chromosome), path(bam), path("*.annotated.g.vcf"), val(sampleId), val(userId),  emit: gvcf_tuple
        path  "*.annotated.g.vcf", emit: gvcf
        path "versions.yaml", emit: versions

    script:
        def taskMemoryString = "$task.memory"

        """
        java \
            -XX:InitialRAMPercentage=80.0 \
            -XX:MaxRAMPercentage=85.0 \
            -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar \
            -T VariantAnnotator \
            -R $referenceGenome \
            -I $bam \
            -A Coverage \
            -A QualByDepth \
            -A FisherStrand \
            -A StrandOddsRatio \
            -L $chromosome \
            -D $dbSnp \
            --disable_auto_index_creation_and_locking_when_reading_rods \
            -V $gvcf \
            -o ${chromosome}.annotated.g.vcf

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(java -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar --version)
        END_VERSIONS

        """

}