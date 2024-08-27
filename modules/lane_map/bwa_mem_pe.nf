process BWA_MEM_PE {
    tag "BWA_MEM_PE_${flowCell}_${lane}_${library}_${userId}"

    publishDir "${publishDirectory}", mode: "link", pattern: "${flowCell}.${lane}.S${sampleId}.L${library}.bam"
    publishDir "${publishDirectory}", mode: "link", pattern: "${flowCell}.${lane}.S${sampleId}.L${library}.bam.bai"
    
    input:
        tuple path(fastq1), path(fastq2), val(flowCell), val(lane), val(library), val(sampleId), val(userId), val(readGroup), val(publishDirectory)
        val referenceGenome
        val memOpts


    output:
        tuple path("${flowCell}.${lane}.S${sampleId}.L${library}.bam"), path("${flowCell}.${lane}.S${sampleId}.L${library}.bam.bai"), val(flowCell), val(lane), val(library), val(sampleId), emit: mappedBam
    script:
        def threads = task.cpus / 2

        String tmpDir = "tmp"
        
        """
        set -o pipefail
        bwa mem -t ${task.cpus} \
				${memOpts} \
				-R ${readGroup} \
				${referenceGenome} \
				${fastq1}  \
				${fastq2} | \
        samblaster --addMateTags -a | \
        samtools view -Sbhu - | \
        sambamba sort \
                -t ${task.cpus} \
                -o ${flowCell}.${lane}.S${sampleId}.L${library}.bam \
                /dev/stdin
        """
}