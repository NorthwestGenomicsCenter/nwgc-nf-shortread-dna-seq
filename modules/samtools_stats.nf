process SAMTOOLS_STATS {

    label "SAMTOOLS_STATS_${params.sampleId}_${params.userId}"

    publishDir "${params.sampleQCDirector}", mode: 'link', pattern: '*.onTarget.stats.txt'

    input:
        path bam
        path bed

    output:
        path "*.onTarget.stats.txt"
        path "versions.yaml", emit: versions

    script:

        """
        mkdir -p ${params.sampleQCDirectory}

        samtools \
            stats \
            -t $bed \
            $bam \
            -- threads ${task.cpus} \
            > ${params.sampleId}.onTarget.stats.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS
        """

}