process SAMBLASTER_ADD_MATE_TAGS {
    tag "SAMBLASTER_ADD_MATE_TAGS_${flowCell}_${lane}_${library}"

    input:
        tuple stdin(toTag), val(flowCell), val(lane), val(library), val(userId), val(readGroup), val(publishDirectory)

    output:
        tuple stdout(beenTagged), val(flowCell), val(lane), val(library), val(userId), val(readGroup), val(publishDirectory), emit: tagged

    script:
    """
    samblaster --addMateTags -a 
    """
}