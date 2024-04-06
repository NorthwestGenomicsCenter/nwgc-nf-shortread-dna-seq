process PICARD_CLEAN_SAM {
    tag "PICARD_CLEAN_SAM_${flowCell}_${lane}_${library}_${userId}"

    publishDir "${publishDirectory}", mode: "link", pattern: "${fileToClean}.clean", saveAs: {"${fileToClean}"}

    input:
        tuple path(fileToClean), val(flowCell), val(lane), val(library), val(userId), val(publishDirectory)

    output:
        path "${fileToClean}.clean"

    script:

    """
    java \
        -XX:InitialRAMPercentage=80 \
        -XX:MaxRAMPercentage=85 \
        -jar \$PICARD_DIR/picard.jar CleanSam \
        I= ${fileToClean} \
        O= ${fileToClean}.clean
    """
}