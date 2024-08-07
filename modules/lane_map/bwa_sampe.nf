process BWA_SAMPE {

    tag "BWA_SAMPE_${flowCell}_${lane}_${library}_${userId}"

    memory { 7.GB * (Math.pow(2, task.attempt - 1)) }
    
    input:
        tuple path(fastq1), path(fastq2), val(flowCell), val(lane), val(library), val(sampleId), val(userId), val(readGroup), val(publishDirectory)
        val referenceGenome


    output:
        tuple path("${flowCell}.${lane}.S${sampleId}.L${library}.bam"), val(flowCell), val(lane), val(library), val(sampleId), val(userId), val(publishDirectory), emit: sampe

    script:
        def threads = task.cpus / 2

        """
        set -o pipefail
        bwa sampe \
                -P ${referenceGenome} \
                -r ${readGroup} \
                <(bwa aln -t ${threads} ${referenceGenome} -1 ${fastq1}) \
                <(bwa aln -t ${threads} ${referenceGenome} -2 ${fastq2}) \
                ${fastq1} \
                ${fastq2} | \
        samblaster --addMateTags -a | \
        samtools view -Sbhu - | \
        sambamba sort \
                -t ${task.cpus} \
                -o ${flowCell}.${lane}.S${sampleId}.L${library}.bam \
                /dev/stdin
        """
}