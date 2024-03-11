process PICARD_COVERAGE_METRICS {

    label "PICARD_COVERAGE_METRICS_${params.sampleId}_${params.userId}"

    publishDir "$params.sampleQCDirectory", mode: 'link', pattern: '*.picard.coverage.txt'
 
    input:
        path bam
        path bai
        val baseQuality
        val mappingQuality
        tuple path(intervalsList), val(partOfSequencingTarget)

    output:
        path "*.picard.coverage.txt"
        path "versions.yaml", emit: versions

    script:
        Integer baseQualityVal = baseQuality
        Integer mappingQualityVal = mappingQuality

        // If there was a given part of sequencing target format it to be used in the file path.
        String partOfSequencingTargetOutput = partOfSequencingTarget
        if (!partOfSequencingTargetOutput.equals("")) {
            partOfSequencingTargetOutput = ".${partOfSequencingTargetOutput}"
        }

        """
        mkdir -p $params.sampleQCDirectory

        java \
            -XX:InitialRAMPercentage=80 \
            -XX:MaxRAMPercentage=85 \
            -jar \$PICARD_DIR/picard.jar \
            CollectWgsMetrics \
            --INPUT $bam \
            --REFERENCE_SEQUENCE $params.referenceGenome \
            --VALIDATION_STRINGENCY SILENT \
            --MINIMUM_BASE_QUALITY $baseQualityVal \
            --MINIMUM_MAPPING_QUALITY $mappingQualityVal \
            --INTERVALS $intervalsList \
            --COVERAGE_CAP 300000 \
            --OUTPUT ${params.sampleId}.BASEQ${baseQualityVal}.MAPQ${mappingQualityVal}${partOfSequencingTargetOutput}.picard.coverage.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            java: \$(java -version 2>&1 | grep version | awk '{print \$3}' | tr -d '"''')
            picard: \$(java -jar \$PICARD_DIR/picard.jar CollectRawWgsMetrics --version 2>&1 | awk '{split(\$0,a,":"); print a[2]}')
        END_VERSIONS

        """

}
