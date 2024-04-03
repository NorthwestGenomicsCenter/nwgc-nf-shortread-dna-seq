process SAMTOOLS_VIEW_SBHU {
    tag "SAMTOOLS_VIEW_SBHU_${flowCell}_${lane}_${library}"

    input:
        tuple stdin(toView), val(flowCell), val(lane), val(library), val(userId), val(readGroup), val(publishDirectory)

    output:
        tuple stdout(beenViewed), val(flowCell), val(lane), val(library), val(userId), val(readGroup), val(publishDirectory), emit: viewed

    script:
    """
    samtools view -Sbhu - 
    """
}