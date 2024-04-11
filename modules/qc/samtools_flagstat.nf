process SAMTOOLS_FLAGSTAT {

    tag "SAMTOOLS_FLAGSTAT_${sampleId}${flowCellLaneLibraryString}_${userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${flowCellLaneLibraryString}.flagstat.output.txt"

    input:
        tuple path(bam), path(bai), val(sampleId), val(flowCellLaneLibrary), val(userId), val(publishDirectory)

    output:
        tuple val(flowCellLaneLibrary), path("${sampleId}${flowCellLaneLibraryString}.flagstat.output.txt"), emit: flagstatFile
        path "versions.yaml", emit: versions

    script:
        flowCellLaneLibraryString = ""
        if (flowCellLaneLibrary != null) {
            flowCellLaneLibraryString = ".${flowCellLaneLibrary}"
        }

        """
        mkdir -p ${publishDirectory}

        samtools \
            flagstat \
            $bam \
            -@ ${task.cpus} \
            > ${sampleId}${flowCellLaneLibraryString}.flagstat.output.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS
        """

}