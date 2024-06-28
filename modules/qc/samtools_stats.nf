process SAMTOOLS_STATS {

    tag "SAMTOOLS_STATS_${filePrefixString}_${userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: "${filePrefixString}.onTarget.stats.txt"

    input:
        tuple path(bam), path(bai), val(sampleId), val(filePrefix), val(userId), val(publishDirectory)
        path sequencingTargetBedFile

    output:
        tuple val(filePrefix), path("${filePrefixString}.onTarget.stats.txt"), emit: statsFile
        path "versions.yaml", emit: versions

    script:
        filePrefixString = ""
        if (filePrefix != null) {
            filePrefixString = filePrefix
        }
        else {
            filePrefixString = "${sampleId}"
        }
        """
        mkdir -p ${publishDirectory}

        samtools \
            stats \
            -t ${sequencingTargetBedFile}\
            $bam \
            --threads ${task.cpus} \
            > ${filePrefixString}.onTarget.stats.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS
        """

}