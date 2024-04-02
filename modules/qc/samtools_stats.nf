process SAMTOOLS_STATS {

    tag "SAMTOOLS_STATS_${sampleId}_${userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: '*.onTarget.stats.txt'

    input:
        tuple path(bam), path(bai), val(sampleId), val(libraryId), val(userId), val(publishDirectory)
        path sequencingTargetBedFile

    output:
        path "*.onTarget.stats.txt"
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
            stats \
            -t ${sequencingTargetBedFile}\
            $bam \
            --threads ${task.cpus} \
            > ${sampleId}${libraryIdString}.onTarget.stats.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS
        """

}