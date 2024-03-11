process SAMTOOLS_WGS_STATS {

    label "SAMTOOLS_WGS_STATS_${params.sampleId}_${params.userId}"

    publishDir "${params.sampleQCDirectory}", mode: 'link', pattern: '*.flagstat.output.txt'
    publishDir "${params.sampleQCDirector}", mode: 'link', pattern: '*.onTarget.stats.txt'

    input:
        path bam
        path bed

    output:
        path "*.flagstat.output.txt"
        path "*.onTarget.stats.txt"
        path "versions.yaml", emit: versions

    script:

        """
        mkdir -p ${params.sampleQCDirectory}

        # global
        samtools flagstat $bam > ${params.sampleId}.flagstat.output.txt
        # on-target
        samtools stats -t $bed $bam > ${params.sampleId}.onTarget.stats.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: "" #get samtools version here
        END_VERSIONS
        """

}