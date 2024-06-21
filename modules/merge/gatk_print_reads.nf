process GATK_PRINT_READS {

    tag "GATK_PRINT_READS_${sampleId}_${params.userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}.${sequencingTarget}.merged.bam" 
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}.${sequencingTarget}.merged.bam.bai"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}.${sequencingTarget}.merged.bam.md5sum" 
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}.${sequencingTarget}.merged.bam.bai.md5sum"

    input:
        path bam
        path bqsr_recalibration_table
        val sampleId
        val sequencingTarget
        val organism
        val referenceGenome
        val publishDirectory

    output:
        tuple path("${sampleId}.${sequencingTarget}.merged.bam"), path("${sampleId}.${sequencingTarget}.merged.bam.bai"), emit: bamBai
        path "${sampleId}.${sequencingTarget}.merged.bam.md5sum"
        path "${sampleId}.${sequencingTarget}.merged.bam.bai.md5sum"
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
            --out ${sampleId}.${sequencingTarget}.merged.bam \
            ${sqq} \
            -BQSR ${sampleId}.recal.matrix

        mv ${sampleId}.${sequencingTarget}.merged.bai ${sampleId}.${sequencingTarget}.merged.bam.bai

        md5sum ${sampleId}.${sequencingTarget}.merged.bam | awk '{print \$1}' > ${sampleId}.${sequencingTarget}.merged.bam.md5sum
        md5sum ${sampleId}.${sequencingTarget}.merged.bam.bai | awk '{print \$1}' > ${sampleId}.${sequencingTarget}.merged.bam.bai.md5sum

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(java -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar --version)
        END_VERSIONS
        """

}
