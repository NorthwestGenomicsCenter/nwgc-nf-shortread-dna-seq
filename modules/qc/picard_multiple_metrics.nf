process PICARD_MULTIPLE_METRICS {

    tag "PICARD_MULTIPLE_METRICS${sampleId}_${userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${libraryIdString}.alignment_summary_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${libraryIdString}.base_distribution_by_cycle.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${libraryIdString}.gc_bias_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${libraryIdString}.gc_bias_summary_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${libraryIdString}.insert_size_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${libraryIdString}.quality_yield_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${libraryIdString}.base_distribution_by_cycle.pdf"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${libraryIdString}.insert_size_histogram.pdf"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${libraryIdString}.gc_bias.pdf"

    input:
        tuple path(bam), path(bai), val(sampleId), val(libraryId), val(userId), val(publishDirectory)
        tuple val(isGRC38), val(referenceGenome)

    output:
        tuple path("${sampleId}${libraryIdString}.alignment_summary_metrics.txt"), path("${sampleId}${libraryIdString}.base_distribution_by_cycle.txt"),
              path("${sampleId}${libraryIdString}.gc_bias_metrics.txt"), path("${sampleId}${libraryIdString}.gc_bias_summary_metrics.txt"),
              path("${sampleId}${libraryIdString}.insert_size_metrics.txt"), path("${sampleId}${libraryIdString}.quality_yield_metrics.txt"), emit: metricsFiles
        path "${sampleId}${libraryIdString}.base_distribution_by_cycle.pdf"
        path "${sampleId}${libraryIdString}.insert_size_histogram.pdf"
        path "${sampleId}${libraryIdString}.gc_bias.pdf"
        path "versions.yaml", emit: versions

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
        
        # Rename files to use txt
        mv ${sampleId}${libraryIdString}.alignment_summary_metrics ${sampleId}${libraryIdString}.alignment_summary_metrics.txt
        mv ${sampleId}${libraryIdString}.base_distribution_by_cycle_metrics ${sampleId}${libraryIdString}.base_distribution_by_cycle.txt
        mv ${sampleId}${libraryIdString}.gc_bias.detail_metrics ${sampleId}${libraryIdString}.gc_bias_metrics.txt
        mv ${sampleId}${libraryIdString}.gc_bias.summary_metrics ${sampleId}${libraryIdString}.gc_bias_summary_metrics.txt
        mv ${sampleId}${libraryIdString}.insert_size_metrics ${sampleId}${libraryIdString}.insert_size_metrics.txt
        mv ${sampleId}${libraryIdString}.quality_yield_metrics ${sampleId}${libraryIdString}.quality_yield_metrics.txt


        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            java: \$(java -version 2>&1 | grep version | awk '{print \$3}' | tr -d '"''')
            picard: \$(java -jar \$PICARD_DIR/picard.jar CollectRawWgsMetrics --version 2>&1 | awk '{split(\$0,a,":"); print a[2]}')
        END_VERSIONS
        """

}
