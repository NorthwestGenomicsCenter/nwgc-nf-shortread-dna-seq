process FASTX_QC {

    tag "FASTX_QC_${sampleId}_${userId}"

    publishDir "${publishDirectory}", mode:  'link', pattern: "*.fastq.stats"
 
    input:
        tuple path(fastq), val(flowcell), val(lane), val(library), val(sampleId), val(userId), val(publishDirectory)

    output:
        env FASTQ_BASENAME, emit: fastqBasename
        path "*.fastq.stats",  emit: stats
        path "versions.yaml", emit: versions

    script:
        """
        gunzip -c ${fastq} | \
        fastx_quality_stats \
            -Q 33 \
            -o ${flowcell}.${lane}.S${sampleId}.L${library}.fastq.stats.temp

        mv ${flowcell}.${lane}.S${sampleId}.L${library}.fastq.stats.temp ${flowcell}.${lane}.S${sampleId}.L${library}.fastq.stats
    
        cat <<-END_VERSIONS > versions.yaml
        '${task.process}_${task.index}':
            fastx_toolkit: \$(fastx_quality_stats -h | grep FASTX | awk '{print \$5}')
        END_VERSIONS
        """
}