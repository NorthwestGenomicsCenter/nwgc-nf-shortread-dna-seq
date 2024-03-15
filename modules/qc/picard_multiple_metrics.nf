process PICARD_MULTIPLE_METRICS {

    label "PICARD_MULTIPLE_METRICS${params.sampleId}_${params.libraryId}_${params.userId}"

    publishDir "${params.sampleQCDirectory}", mode: 'link', pattern: "*.alignment_summary_metrics", saveAs: {filename -> "${filename}.txt"}
    publishDir "${params.sampleQCDirectory}", mode: 'link', pattern: "*.base_distribution_by_cycle_metrics", saveAs: {"${params.sampleId}.base_distribution_by_cycle.txt"}
    publishDir "${params.sampleQCDirectory}", mode: 'link', pattern: "*.gc_bias.detail_metrics", saveAs: {"${params.sampleId}.gc_bias_metrics.txt"}
    publishDir "${params.sampleQCDirectory}", mode: 'link', pattern: "*.gc_bias.summary_metrics", saveAs: {"${params.sampleId}.gc_bias_summary_metrics.txt"}
    publishDir "${params.sampleQCDirectory}", mode: 'link', pattern: "*.insert_size_metrics", saveAs: {filename -> "${filename}.txt"}
    publishDir "${params.sampleQCDirectory}", mode: 'link', pattern: "*.quality_yield_metrics", saveAs: {filename -> "${filename}.txt"}
    publishDir "${params.sampleQCDirectory}", mode: 'link', pattern: "*.base_distribution_by_cycle.pdf"
    publishDir "${params.sampleQCDirectory}", mode: 'link', pattern: "*.insert_size_histogram.pdf"
    publishDir "${params.sampleQCDirectory}", mode: 'link', pattern: "*.gc_bias.pdf"

    input:
        path bam
        path bai

    output:
        path "*.alignment_summary_metrics"
        path "*.base_distribution_by_cycle_metrics"
        path "*.gc_bias.detail_metrics"
        path "*.gc_bias.summary_metrics"
        path "*.insert_size_metrics"
        path "*.quality_yield_metrics"
        path "*.base_distribution_by_cycle.pdf"
        path "*.insert_size_histogram.pdf"
        path "*.gc_bias.pdf"
        path "versions.yaml", emit: versions
        val true, emit: ready

    script:

        """
        mkdir -p ${params.sampleQCDirectory}

        java \
            -XX:InitialRAMPercentage=80 \
            -XX:MaxRAMPercentage=85 \
        	-jar \$PICARD_DIR/picard.jar \
        	CollectMultipleMetrics \
        	--INPUT $bam \
        	--OUTPUT ${params.sampleId} \
        	--REFERENCE_SEQUENCE ${params.referenceGenome} \
        	--VALIDATION_STRINGENCY SILENT \
        	--PROGRAM CollectAlignmentSummaryMetrics \
        	--PROGRAM CollectBaseDistributionByCycle \
        	--PROGRAM CollectInsertSizeMetrics \
        	--PROGRAM CollectGcBiasMetrics \
        	--PROGRAM CollectQualityYieldMetrics

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            java: \$(java -version 2>&1 | grep version | awk '{print \$3}' | tr -d '"''')
            picard: \$(java -jar \$PICARD_DIR/picard.jar CollectRawWgsMetrics --version 2>&1 | awk '{split(\$0,a,":"); print a[2]}')
        END_VERSIONS
        """

}
