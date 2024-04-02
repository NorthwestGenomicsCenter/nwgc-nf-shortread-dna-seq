process PICARD_MULTIPLE_METRICS {

    tag "PICARD_MULTIPLE_METRICS${sampleId}_${userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: "*.alignment_summary_metrics", saveAs: {filename -> "${filename}.txt"}
    publishDir "${publishDirectory}", mode: 'link', pattern: "*.base_distribution_by_cycle_metrics", saveAs: {"${sampleId}${libraryIdString}.base_distribution_by_cycle.txt"}
    publishDir "${publishDirectory}", mode: 'link', pattern: "*.gc_bias.detail_metrics", saveAs: {"${sampleId}${libraryIdString}.gc_bias_metrics.txt"}
    publishDir "${publishDirectory}", mode: 'link', pattern: "*.gc_bias.summary_metrics", saveAs: {"${sampleId}${libraryIdString}.gc_bias_summary_metrics.txt"}
    publishDir "${publishDirectory}", mode: 'link', pattern: "*.insert_size_metrics", saveAs: {filename -> "${filename}.txt"}
    publishDir "${publishDirectory}", mode: 'link', pattern: "*.quality_yield_metrics", saveAs: {filename -> "${filename}.txt"}
    publishDir "${publishDirectory}", mode: 'link', pattern: "*.base_distribution_by_cycle.pdf"
    publishDir "${publishDirectory}", mode: 'link', pattern: "*.insert_size_histogram.pdf"
    publishDir "${publishDirectory}", mode: 'link', pattern: "*.gc_bias.pdf"

    input:
        tuple path(bam), path(bai), val(sampleId), val(libraryId), val(userId), val(publishDirectory)
        tuple val(isGRC38), val(referenceGenome)

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
        libraryIdString = ""
        if (libraryId != null) {
            libraryIdString = ".${libraryId}"
        }

        """
        mkdir -p ${publishDirectory}

        java \
            -XX:InitialRAMPercentage=80 \
            -XX:MaxRAMPercentage=85 \
        	-jar \$PICARD_DIR/picard.jar \
        	CollectMultipleMetrics \
        	--INPUT $bam \
        	--OUTPUT ${sampleId}${libraryIdString} \
        	--REFERENCE_SEQUENCE ${referenceGenome} \
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
