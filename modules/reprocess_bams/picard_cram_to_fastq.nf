process PICARD_CRAM_TO_FASTQ {

    tag "PICARD_CRAM_TO_FASTQ_${sampleId}_${userId}"
 
    input:
        tuple path(cram), val(reference)
        tuple val(sampleId), val(userId)
        val validationStringency

    output:
        path "*.fastq", emit: fastqs

    script:
        """
        SCRIPT_DIR=\$( cd -- "\$( dirname -- "\${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
        if samtools view -H "${cram}" | grep '^@RG' | grep -q "PU:"; then
                READ_GROUP_TAG="PU"
        else
                READ_GROUP_TAG="ID"
        fi
        java \
            -XX:InitialRAMPercentage=80 \
            -XX:MaxRAMPercentage=85 \
            -jar \$PICARD_DIR/picard.jar \
            SamToFastq \
            --INPUT ${cram} \
            --REFERENCE_SEQUENCE ${reference} \
            --OUTPUT_DIR \$SCRIPT_DIR \
            --OUTPUT_PER_RG true \
            --RG_TAG \$READ_GROUP_TAG \
            --VALIDATION_STRINGENCY ${validationStringency} \
            --INCLUDE_NON_PF_READS true
        """
}
