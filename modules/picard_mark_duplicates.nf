process PICARD_MARK_DUPLICATES {

    label "PICARD_MARK_DUPLICATES${params.sampleId}_${params.libraryId}_${params.userId}"

    input:
        path bamList

    output:
        path "${params.sampleId}.${params.libraryId}.${params.sequencingTarget}.bam", emit: bam
        path "${params.sampleId}.${params.libraryId}.${params.sequencingTarget}.bai", emit: bai
        path "versions.yaml", emit: versions

    script:

        def inputs = "";
        for (bam in bamList) {
            inputs = inputs += " --INPUT " + bam;
        }

        """
        java \
            -XX:InitialRAMPercentage=80.0 \
            -XX:MaxRAMPercentage=85.0 \
            -jar \$PICARD_DIR/picard.jar \
            MarkDuplicates \
            $inputs \
            --OUTPUT ${params.sampleId}.${params.libraryId}.${params.sequencingTarget}.bam \
            --METRICS_FILE ${params.sampleId}.${params.libraryId}.${params.sequencingTarget}.duplicate_metrics.txt \
            --ASSUME_SORT_ORDER coordinate \
            --CREATE_MD5_FILE false \
            --CREATE_INDEX true \
            --OPTICAL_DUPLICATE_PIXEL_DISTANCE 100 \
            --QUIET false \
            --PROGRAM_RECORD_ID null \
            --REMOVE_DUPLICATES false \
            --COMPRESSION_LEVEL 5 

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            java: \$(java -version 2>&1 | grep version | awk '{print \$3}' | tr -d '"''')
            picard: \$(java -jar \$PICARD_DIR/picard.jar MarkDuplicates --version 2>&1 | awk '{split(\$0,a,":"); print a[2]}')
        END_VERSIONS

        """

}
