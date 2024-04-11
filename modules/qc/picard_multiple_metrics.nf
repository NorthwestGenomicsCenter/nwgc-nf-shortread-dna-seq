process PICARD_MULTIPLE_METRICS {

    tag "PICARD_MULTIPLE_METRICS${sampleId}${flowCellLaneLibraryString}_${userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${flowCellLaneLibraryString}.alignment_summary_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${flowCellLaneLibraryString}.base_distribution_by_cycle.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${flowCellLaneLibraryString}.gc_bias_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${flowCellLaneLibraryString}.gc_bias_summary_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${flowCellLaneLibraryString}.insert_size_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${flowCellLaneLibraryString}.quality_yield_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${flowCellLaneLibraryString}.base_distribution_by_cycle.pdf"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${flowCellLaneLibraryString}.insert_size_histogram.pdf"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${flowCellLaneLibraryString}.gc_bias.pdf"

    input:
        tuple path(bam), path(bai), val(sampleId), val(flowCellLaneLibrary), val(userId), val(publishDirectory)
        tuple val(isGRC38), val(referenceGenome)

    output:
        tuple val(flowCellLaneLibrary), path("${sampleId}${flowCellLaneLibraryString}.alignment_summary_metrics.txt"), path("${sampleId}${flowCellLaneLibraryString}.base_distribution_by_cycle.txt"),
              path("${sampleId}${flowCellLaneLibraryString}.gc_bias_metrics.txt"), path("${sampleId}${flowCellLaneLibraryString}.gc_bias_summary_metrics.txt"),
              path("${sampleId}${flowCellLaneLibraryString}.insert_size_metrics.txt"), path("${sampleId}${flowCellLaneLibraryString}.quality_yield_metrics.txt"), emit: metricsFiles
        path "${sampleId}${flowCellLaneLibraryString}.base_distribution_by_cycle.pdf"
        path "${sampleId}${flowCellLaneLibraryString}.insert_size_histogram.pdf"
        path "${sampleId}${flowCellLaneLibraryString}.gc_bias.pdf"
        path "versions.yaml", emit: versions

    script:
        flowCellLaneLibraryString = ""
        if (flowCellLaneLibrary != null) {
            flowCellLaneLibraryString = ".${flowCellLaneLibrary}"
        }

        """
        mkdir -p ${publishDirectory}

        java \
            -XX:InitialRAMPercentage=80 \
            -XX:MaxRAMPercentage=85 \
        	-jar \$PICARD_DIR/picard.jar \
        	CollectMultipleMetrics \
        	--INPUT $bam \
        	--OUTPUT ${sampleId}${flowCellLaneLibraryString} \
        	--REFERENCE_SEQUENCE ${referenceGenome} \
        	--VALIDATION_STRINGENCY SILENT \
        	--PROGRAM CollectAlignmentSummaryMetrics \
        	--PROGRAM CollectBaseDistributionByCycle \
        	--PROGRAM CollectInsertSizeMetrics \
        	--PROGRAM CollectGcBiasMetrics \
        	--PROGRAM CollectQualityYieldMetrics
        
        # Rename files to use txt
        mv ${sampleId}${flowCellLaneLibraryString}.alignment_summary_metrics ${sampleId}${flowCellLaneLibraryString}.alignment_summary_metrics.txt
        mv ${sampleId}${flowCellLaneLibraryString}.base_distribution_by_cycle_metrics ${sampleId}${flowCellLaneLibraryString}.base_distribution_by_cycle.txt
        mv ${sampleId}${flowCellLaneLibraryString}.gc_bias.detail_metrics ${sampleId}${flowCellLaneLibraryString}.gc_bias_metrics.txt
        mv ${sampleId}${flowCellLaneLibraryString}.gc_bias.summary_metrics ${sampleId}${flowCellLaneLibraryString}.gc_bias_summary_metrics.txt
        mv ${sampleId}${flowCellLaneLibraryString}.insert_size_metrics ${sampleId}${flowCellLaneLibraryString}.insert_size_metrics.txt
        mv ${sampleId}${flowCellLaneLibraryString}.quality_yield_metrics ${sampleId}${flowCellLaneLibraryString}.quality_yield_metrics.txt


        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            java: \$(java -version 2>&1 | grep version | awk '{print \$3}' | tr -d '"''')
            picard: \$(java -jar \$PICARD_DIR/picard.jar CollectRawWgsMetrics --version 2>&1 | awk '{split(\$0,a,":"); print a[2]}')
        END_VERSIONS
        """

}
