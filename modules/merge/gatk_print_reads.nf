process GATK_PRINT_READS {

    tag "GATK_PRINT_READS_${sampleId}_${params.userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}.merged.matefixed.sorted.markeddups.recal.bam" 
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}.merged.matefixed.sorted.markeddups.recal.bam.bai"

    input:
        path bam
        path bqsr_recalibration_table
        val sampleId
        val sequencingTarget
        val organism
        val referenceGenome
        val publishDirectory

    output:
        tuple path("${sampleId}.merged.matefixed.sorted.markeddups.recal.bam"), path("${sampleId}.merged.matefixed.sorted.markeddups.recal.bam.bai"), emit: bamBai
        path "versions.yaml", emit: versions

    script:
        String sqq = ''
        if (sequencingTarget.equals("WHOLE_GENOME") && organism.equals("Homo sapiens")) {
            sqq = "-SQQ 10 -SQQ 20 -SQQ 30"
        }

        """
        java \
            -XX:InitialRAMPercentage=80.0 \
            -XX:MaxRAMPercentage=85.0 \
            -jar \$GATK_DIR/GenomeAnalysisTK.jar \
            -T PrintReads \
            -R ${referenceGenome} \
            --disable_indel_quals \
            -I ${bam} \
            --out ${sampleId}.merged.matefixed.sorted.markeddups.recal.bam \
            ${sqq} \
            -BQSR ${sampleId}.recal.matrix

        mv ${sampleId}.merged.matefixed.sorted.markeddups.recal.bai ${sampleId}.merged.matefixed.sorted.markeddups.recal.bam.bai

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(java -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar --version)
        END_VERSIONS
        """

}
