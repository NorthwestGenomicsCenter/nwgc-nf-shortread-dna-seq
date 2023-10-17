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
        def taskMemoryString = "$task.memory"
        def javaMemory = taskMemoryString.substring(0, taskMemoryString.length() - 1).replaceAll("\\s","")

        """
        gatk \
            --java-options "-Xmx$javaMemory" \
            ApplyBQSRSpark \
            --spark-master local[$task.cpus] \
            --input $bam \
            --bqsr-recal-file $bqsr_recalibration_table \
            --output ${params.sampleId}.${params.libraryId}.${params.sequencingTarget}.recal.bam \
            --static-quantized-quals 10 \
            --static-quantized-quals 20 \
            --static-quantized-quals 30

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(java -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar --version)
        END_VERSIONS

        """

}
