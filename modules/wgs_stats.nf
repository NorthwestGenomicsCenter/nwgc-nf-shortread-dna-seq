process SAMTOOLS_WGS_STATS {

    label "SAMTOOLS_WGS_STATS_${params.sampleId}_${params.userId}"

    // publishDir "$params.sampleQCDirectory", mode: 'link', pattern: '*.txt'

    input:
        path bam
        path bed

    output:
        path "*.flagstat.output.txt"
        path "*.onTarget.stats.txt"
        path "versions.yaml", emit: versions

    script:

        """
        mkdir -p $params.sampleQCDirectory

        # global
        time samtools flagstat ${bam} > ${params.sampleQCDirectory}/${params.sampleId}.flagstat.output.txt
        # on-target
        time samtools stats -t ${bed} ${bam} > ${params.sampleQCDirectory}/${params.sampleId}.onTarget.stats.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: "" #get samtools version here
        END_VERSIONS
        """

}