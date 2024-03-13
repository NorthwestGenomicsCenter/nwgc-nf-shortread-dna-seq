process PICARD_MULTIPLE_METRICS {

    label "PICARD_MULTIPLE_METRICS${params.sampleId}_${params.libraryId}_${params.userId}"

    input:
        path bam
        path bai

    output:
        path "*.picard.metrics.txt"
        path "versions.yaml", emit: versions

    script:

        """
        mkdir -p $params.sampleQCDirectory

        java \
            -XX:InitialRAMPercentage=80 \
            -XX:MaxRAMPercentage=85 \
        	-jar \$PICARD_DIR/picard.jar \
        	CollectMultipleMetrics \
        	--INPUT $bam \
        	--OUTPUT ${params.sampleQCDirectory}/$params.sampleId \
        	--REFERENCE_SEQUENCE $params.referenceGenome \
        	--VALIDATION_STRINGENCY SILENT \
        	--PROGRAM CollectAlignmentSummaryMetrics \
        	--PROGRAM CollectBaseDistributionByCycle \
        	--PROGRAM CollectInsertSizeMetrics \
        	--PROGRAM CollectGcBiasMetrics \
        	--PROGRAM CollectQualityYieldMetrics

        ## sleep for 5 seconds so that we are sure the files exist
        sleep 5

        ## Move files to names ending in .txt
        mv ${params.sampleQCDirectory}/${params.sampleId}.alignment_summary_metrics ${params.sampleQCDirectory}/${params.sampleId}.alignment_summary_metrics.txt
        mv ${params.sampleQCDirectory}/${params.sampleId}.base_distribution_by_cycle_metrics ${params.sampleQCDirectory}/${params.sampleId}.base_distribution_by_cycle.txt
        mv ${params.sampleQCDirectory}/${params.sampleId}.gc_bias.detail_metrics ${params.sampleQCDirectory}/${params.sampleId}.gc_bias_metrics.txt
        mv ${params.sampleQCDirectory}/${params.sampleId}.gc_bias.summary_metrics ${params.sampleQCDirectory}/${params.sampleId}.gc_bias_summary_metrics.txt
        mv ${params.sampleQCDirectory}/${params.sampleId}.insert_size_metrics ${params.sampleQCDirectory}/${params.sampleId}.insert_size_metrics.txt
        mv ${params.sampleQCDirectory}/${params.sampleId}.quality_yield_metrics ${params.sampleQCDirectory}/${params.sampleId}.quality_yield_metrics.txt


        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            java: \$(java -version 2>&1 | grep version | awk '{print \$3}' | tr -d '"''')
            picard: \$(java -jar \$PICARD_DIR/picard.jar CollectRawWgsMetrics --version 2>&1 | awk '{split(\$0,a,":"); print a[2]}')
        END_VERSIONS
        """

}