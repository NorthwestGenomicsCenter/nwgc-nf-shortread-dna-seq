process APPLY_BQSR {

    label "APPLY_BQSR_${params.sampleId}_${params.libraryId}_${params.userId}"

    publishDir "$params.sampleDirectory", mode: 'link', pattern: '*.recal.bam'

    input:
        path bam
        path bqsr_recalibration_table

    output:
        path "${params.sampleId}.${params.libraryId}.${params.sequencingTarget}.recal.bam", emit: bam
        path "${params.sampleId}.${params.libraryId}.${params.sequencingTarget}.recal.bam.bai", emit: bai
        path "versions.yaml", emit: versions

    script:

        """
        gatk \
            --java-options "-XX:InitialRAMPercentage=80.0 -XX:MaxRAMPercentage=85.0" \
            ApplyBQSR \
            --input $bam \
            --bqsr-recal-file $bqsr_recalibration_table \
            --output ${params.sampleId}.${params.libraryId}.${params.sequencingTarget}.recal.bam \
            --create-output-bam-index true \
            --static-quantized-quals 10 \
            --static-quantized-quals 20 \
            --static-quantized-quals 30 

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(gatk --version | grep GATK | awk '{print \$6}')
        END_VERSIONS

        """

}
