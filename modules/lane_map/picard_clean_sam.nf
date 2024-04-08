process PICARD_CLEAN_SAM {
    tag "PICARD_CLEAN_SAM_${flowCell}_${lane}_${library}_${userId}"

    publishDir "${publishDirectory}", mode: "link", pattern: "${fileToClean}"
    publishDir "${publishDirectory}", mode: "link", pattern: "${fileToClean}.bai"

    input:
        tuple path(fileToClean), val(flowCell), val(lane), val(library), val(userId), val(publishDirectory)

    output:
        tuple path("${fileToClean}"), path("${fileToClean}.bai"), emit: mappedBam

    script:

    """
    java \
        -XX:InitialRAMPercentage=80 \
        -XX:MaxRAMPercentage=85 \
        -jar \$PICARD_DIR/picard.jar CleanSam \
        I= ${fileToClean} \
        O= ${fileToClean}.clean
    
    mv ${fileToClean}.clean ${fileToClean}

    samtools index ${fileToClean}
    """
}