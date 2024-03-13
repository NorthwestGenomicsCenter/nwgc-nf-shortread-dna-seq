process SAMTOOLS_FLAGSTAT {

    label "SAMTOOLS_FLAGSTAT_${params.sampleId}_${params.userId}"

    publishDir "${params.sampleQCDirectory}", mode: 'link', pattern: '*.flagstat.output.txt'

    input:
        path bam
        path bai

    output:
        path "*.flagstat.output.txt"
        path "versions.yaml", emit: versions

    script:

        """
        mkdir -p ${params.sampleQCDirectory}

        samtools \
            flagstat \
            $bam \
            -@ ${task.cpus} \
            > ${params.sampleId}.flagstat.output.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
        END_VERSIONS
        """

}