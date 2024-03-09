process PICARD_COVERAGE_METRICS {

    label "PICARD_COVERAGE_METRICS_${params.sampleId}_${params.libraryId}_${params.userId}"

    publishDir "$params.sampleQCDirectory", mode: 'link', pattern: '*.picard.coverage.txt', saveAs:"${chrom}.picard.coverage.txt"
 
    input:
        path bam
        path bai
        val baseQuality
        val mappingQuality
        path intervalsList
        val chrom

    output:
        path "*.picard.coverage.txt"
        path "versions.yaml", emit: versions

    script:
        String baseQualityString = ""
        String mappingQualityString = ""
        Integer baseQualityVal = baseQuality
        Integer mappingQualityVal = mappingQuality

        if(baseQualityVal != -1) {
            baseQualityString = "--MINIMUM_BASE_QUALITY $baseQualityVal"
        }

        if(mappingQualityVal != -1) {
            mappingQualityString = "--MINIMUM_MAPPING_QUALITY $mappingQualityVal"
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
            $baseQualityString \
            $mappingQualityString \
            --INTERVALS $intervalsList \
            --COVERAGE_CAP 300000 \
            --OUTPUT ${params.sampleId}.${params.libraryId}.picard.coverage.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            java: \$(java -version 2>&1 | grep version | awk '{print \$3}' | tr -d '"''')
            picard: \$(java -jar \$PICARD_DIR/picard.jar CollectRawWgsMetrics --version 2>&1 | awk '{split(\$0,a,":"); print a[2]}')
        END_VERSIONS

        """

}
