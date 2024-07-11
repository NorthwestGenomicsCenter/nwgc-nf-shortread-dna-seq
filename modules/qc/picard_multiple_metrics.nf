process PICARD_MULTIPLE_METRICS {

    tag "PICARD_MULTIPLE_METRICS${filePrefixString}_${userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: "${filePrefixString}.alignment_summary_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${filePrefixString}.base_distribution_by_cycle.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${filePrefixString}.gc_bias_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${filePrefixString}.gc_bias_summary_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${filePrefixString}.insert_size_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${filePrefixString}.quality_yield_metrics.txt"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${filePrefixString}.base_distribution_by_cycle.pdf"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${filePrefixString}.insert_size_histogram.pdf"
    publishDir "${publishDirectory}", mode: 'link', pattern: "${filePrefixString}.gc_bias.pdf"

    input:
        tuple path(bam), path(bai), val(sampleId), val(filePrefix), val(userId), val(publishDirectory), val(flowcell), val(lane), val(library)
        tuple val(isGRC38), val(referenceGenome)

    output:
        tuple val(filePrefix), path("${filePrefixString}.alignment_summary_metrics.txt"), path("${filePrefixString}.base_distribution_by_cycle.txt"),
              path("${filePrefixString}.gc_bias_metrics.txt"), path("${filePrefixString}.gc_bias_summary_metrics.txt"),
              path("${filePrefixString}.insert_size_metrics.txt"), path("${filePrefixString}.quality_yield_metrics.txt"), emit: metricsFiles
        path "${filePrefixString}.base_distribution_by_cycle.pdf"
        path "${filePrefixString}.insert_size_histogram.pdf"
        path "${filePrefixString}.gc_bias.pdf"
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
        	--OUTPUT ${filePrefixString} \
        	--REFERENCE_SEQUENCE ${referenceGenome} \
        	--VALIDATION_STRINGENCY SILENT \
        	--PROGRAM CollectAlignmentSummaryMetrics \
        	--PROGRAM CollectBaseDistributionByCycle \
        	--PROGRAM CollectInsertSizeMetrics \
        	--PROGRAM CollectGcBiasMetrics \
        	--PROGRAM CollectQualityYieldMetrics
        
        # Rename files to use txt
        mv ${filePrefixString}.alignment_summary_metrics ${filePrefixString}.alignment_summary_metrics.txt
        mv ${filePrefixString}.base_distribution_by_cycle_metrics ${filePrefixString}.base_distribution_by_cycle.txt
        mv ${filePrefixString}.gc_bias.detail_metrics ${filePrefixString}.gc_bias_metrics.txt
        mv ${filePrefixString}.gc_bias.summary_metrics ${filePrefixString}.gc_bias_summary_metrics.txt
        mv ${filePrefixString}.insert_size_metrics ${filePrefixString}.insert_size_metrics.txt
        mv ${filePrefixString}.quality_yield_metrics ${filePrefixString}.quality_yield_metrics.txt


        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            java: \$(java -version 2>&1 | grep version | awk '{print \$3}' | tr -d '"''')
            picard: \$(java -jar \$PICARD_DIR/picard.jar CollectRawWgsMetrics --version 2>&1 | awk '{split(\$0,a,":"); print a[2]}')
        END_VERSIONS
        """

}
