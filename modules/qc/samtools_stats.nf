process SAMTOOLS_STATS {

    tag "SAMTOOLS_STATS_${sampleId}${flowCellLaneLibraryString}_${userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${flowCellLaneLibraryString}.onTarget.stats.txt"

    input:
        tuple path(bam), path(bai), val(sampleId), val(flowCellLaneLibrary), val(userId), val(publishDirectory)
        path sequencingTargetBedFile

    output:
        tuple val(flowCellLaneLibrary), path("${sampleId}${flowCellLaneLibraryString}.onTarget.stats.txt"), emit: statsFile
        path "versions.yaml", emit: versions

    script:
        flowCellLaneLibraryString = ""
        if (flowCellLaneLibrary != null) {
            flowCellLaneLibraryString = ".${flowCellLaneLibrary}"
        }

        """
        mkdir -p ${publishDirectory}

        samtools \
            stats \
            -t ${sequencingTargetBedFile}\
            $bam \
            --threads ${task.cpus} \
            > ${sampleId}${flowCellLaneLibraryString}.onTarget.stats.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS
        """

}