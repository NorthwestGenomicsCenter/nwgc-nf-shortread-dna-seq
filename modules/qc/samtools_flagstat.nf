process SAMTOOLS_FLAGSTAT {

    tag "SAMTOOLS_FLAGSTAT_${sampleId}_${userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: '*.flagstat.output.txt'

    input:
        tuple path(bam), path(bai), val(sampleId), val(libraryId), val(userId), val(publishDirectory)

    output:
        path "*.flagstat.output.txt"
        path "versions.yaml", emit: versions
        val true, emit: ready

    script:
        String libraryIdString = ""
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