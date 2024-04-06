process FASTX_QC {

    tag "FASTX_QC_${sampleId}_${userId}"

    publishDir "${publishDirectory}", mode:  'link', pattern: "*.fastq.stats"
 
    input:
        tuple path(fastq), val(publishDirectory)
        tuple val(sampleId), val(sampleDirectory), val(userId)

    output:
        env FASTQ_BASENAME, emit: fastqBasename
        path "*.fastq.stats",  emit: stats
        path "versions.yaml", emit: versions

    script:
        """
        FASTQ_BASENAME=\$(basename "$fastq" .fq.gz)

        gunzip -c $fastq | \
        fastx_quality_stats \
            -Q 33 \
            -o \${FASTQ_BASENAME}.fastq.stats.temp

        mv \${FASTQ_BASENAME}.fastq.stats.temp \${FASTQ_BASENAME}.fastq.stats
    
        cat <<-END_VERSIONS > versions.yaml
        '${task.process}_${task.index}':
            fastx_toolkit: \$(fastx_quality_stats -h | grep FASTX | awk '{print \$5}')
        END_VERSIONS
        """
}