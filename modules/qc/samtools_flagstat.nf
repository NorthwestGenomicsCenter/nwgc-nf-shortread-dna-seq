process SAMTOOLS_FLAGSTAT {

    tag "SAMTOOLS_FLAGSTAT_${sampleId}_${userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: "${sampleId}${libraryIdString}.flagstat.output.txt"

    input:
        tuple path(bam), path(bai), val(sampleId), val(libraryId), val(userId), val(publishDirectory)

    output:
        tuple val(libraryId), path("${sampleId}${libraryIdString}.flagstat.output.txt"), emit: flagstatFile
        path "versions.yaml", emit: versions

    script:
        libraryIdString = ""
        if (libraryId != null) {
            libraryIdString = ".${libraryId}"
        }

        """
        mkdir -p ${publishDirectory}

        samtools \
            flagstat \
            $bam \
            -@ ${task.cpus} \
            > ${sampleId}${libraryIdString}.flagstat.output.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS
        """

}