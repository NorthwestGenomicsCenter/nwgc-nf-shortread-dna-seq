process PICARD_SAM_TO_FASTQ {

    tag "PICARD_SAM_TO_FASTQ_${sampleId}_${userId}"
 
    input:
        path bam
        tuple val(sampleId), val(userId)

    output:
        path "*.fastq", emit: fastqs

    script:
        """
        SCRIPT_DIR=\$( cd -- "\$( dirname -- "\${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
        java \
            -XX:InitialRAMPercentage=80 \
            -XX:MaxRAMPercentage=85 \
            -jar \$PICARD_DIR/picard.jar \
            SamToFastq \
            --INPUT ${bam} \
            --OUTPUT_DIR \$SCRIPT_DIR \
            --OUTPUT_PER_RG true \
            --INCLUDE_NON_PF_READS true
        """
}