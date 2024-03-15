process SAMTOOLS_STATS {

    label "SAMTOOLS_STATS_${params.sampleId}_${params.userId}"

    publishDir "${params.sampleQCDirectory}", mode: 'link', pattern: '*.onTarget.stats.txt'

    input:
        path bam
        path bai

    output:
        path "*.onTarget.stats.txt"
        path "versions.yaml", emit: versions
        val true, emit: ready

    script:

        """
        mkdir -p ${params.sampleQCDirectory}

        samtools \
            stats \
            -t ${params.sequencingTargetBedFile}\
            $bam \
            --threads ${task.cpus} \
            > ${params.sampleId}.onTarget.stats.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS
        """

}