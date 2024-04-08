process GATK_PRINT_READS {

    tag "GATK_PRINT_READS_${sampleId}_${params.libraryId}_${params.userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: '*.recal.bam' 
    publishDir "${publishDirectory}", mode: 'link', pattern: '*.recal.bai'

    input:
        path bam
        path bqsr_recalibration_table
        val sampleId
        val sequencingTarget
        val organism
        val referenceGenome
        val publishDirectory

    output:
        tuple path("${sampleId}.${params.libraryId}.${sequencingTarget}.recal.bam"), path("${sampleId}.${params.libraryId}.${sequencingTarget}.recal.bai"), emit: bamBai
        path "versions.yaml", emit: versions

    script:

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
            #if (${sequencingTarget}.equals("WHOLE_GENOME") && ${organism}.equals("Homo sapiens"))
                -SQQ 10 -SQQ 20 -SQQ 30 \
            #end
            -BQSR ${sampleId}.recal.matrix
        """

}
