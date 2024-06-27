process PICARD_MULTIPLE_METRICS {

    tag "PICARD_MULTIPLE_METRICS${sampleId}${filePrefixString}_${userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${filePrefixString}.alignment_summary_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${filePrefixString}.base_distribution_by_cycle.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${filePrefixString}.gc_bias_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${filePrefixString}.gc_bias_summary_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${filePrefixString}.insert_size_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${filePrefixString}.quality_yield_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${filePrefixString}.base_distribution_by_cycle.pdf"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${filePrefixString}.insert_size_histogram.pdf"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${filePrefixString}.gc_bias.pdf"

    input:
        tuple path(bam), path(bai), val(sampleId), val(filePrefix), val(userId), val(publishDirectory)
        tuple val(isGRC38), val(referenceGenome)

    output:
        tuple val(filePrefix), path("${sampleId}${filePrefixString}.alignment_summary_metrics.txt"), path("${sampleId}${filePrefixString}.base_distribution_by_cycle.txt"),
              path("${sampleId}${filePrefixString}.gc_bias_metrics.txt"), path("${sampleId}${filePrefixString}.gc_bias_summary_metrics.txt"),
              path("${sampleId}${filePrefixString}.insert_size_metrics.txt"), path("${sampleId}${filePrefixString}.quality_yield_metrics.txt"), emit: metricsFiles
        path "${sampleId}${filePrefixString}.base_distribution_by_cycle.pdf"
        path "${sampleId}${filePrefixString}.insert_size_histogram.pdf"
        path "${sampleId}${filePrefixString}.gc_bias.pdf"
        path "versions.yaml", emit: versions

    script:
        filePrefixString = ""
        if (filePrefix != null) {
            filePrefixString = filePrefix
        }
        else {
            filePrefixString = "${sampleId}"
        }

        """
        mkdir -p ${publishDirectory}

        java \
            -XX:InitialRAMPercentage=80 \
            -XX:MaxRAMPercentage=85 \
        	-jar \$PICARD_DIR/picard.jar \
        	CollectMultipleMetrics \
        	--INPUT $bam \
        	--OUTPUT ${sampleId}${filePrefixString} \
        	--REFERENCE_SEQUENCE ${referenceGenome} \
        	--VALIDATION_STRINGENCY SILENT \
        	--PROGRAM CollectAlignmentSummaryMetrics \
        	--PROGRAM CollectBaseDistributionByCycle \
        	--PROGRAM CollectInsertSizeMetrics \
        	--PROGRAM CollectGcBiasMetrics \
        	--PROGRAM CollectQualityYieldMetrics
        
        # Rename files to use txt
        mv ${sampleId}${filePrefixString}.alignment_summary_metrics ${sampleId}${filePrefixString}.alignment_summary_metrics.txt
        mv ${sampleId}${filePrefixString}.base_distribution_by_cycle_metrics ${sampleId}${filePrefixString}.base_distribution_by_cycle.txt
        mv ${sampleId}${filePrefixString}.gc_bias.detail_metrics ${sampleId}${filePrefixString}.gc_bias_metrics.txt
        mv ${sampleId}${filePrefixString}.gc_bias.summary_metrics ${sampleId}${filePrefixString}.gc_bias_summary_metrics.txt
        mv ${sampleId}${filePrefixString}.insert_size_metrics ${sampleId}${filePrefixString}.insert_size_metrics.txt
        mv ${sampleId}${filePrefixString}.quality_yield_metrics ${sampleId}${filePrefixString}.quality_yield_metrics.txt


        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            java: \$(java -version 2>&1 | grep version | awk '{print \$3}' | tr -d '"''')
            picard: \$(java -jar \$PICARD_DIR/picard.jar CollectRawWgsMetrics --version 2>&1 | awk '{split(\$0,a,":"); print a[2]}')
        END_VERSIONS
        """

}
