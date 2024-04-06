process BWA_MEM_SE {
    tag "BWA_MEM_SE_${flowCell}_${lane}_${library}_${userId}"

    publishDir "${publishDirectory}", mode: "link", pattern: "${flowCell}.${lane}.${library}.matefixed.sorted.bam"
    publishDir "${publishDirectory}", mode: "link", pattern: "${flowCell}.${lane}.${library}.matefixed.sorted.bam.bai"
    
    input:
        tuple path(fastq1), val(flowCell), val(lane), val(library), val(userId), val(readGroup), val(publishDirectory)
        val referenceGenome
        val memOpts


    output:
        tuple path("${flowCell}.${lane}.${library}.matefixed.sorted.bam"), path("${flowCell}.${lane}.${library}.matefixed.sorted.bam.bai")

    script:
        def threads = task.cpus / 2

        String tmpDir = "tmp"
        
        """
        mkdir ${tmpDir}
        bwa mem -t ${task.cpus} \
				${memOpts} \
				-R ${readGroup} \
				${referenceGenome} \
				${fastq1} | \
        samblaster --addMateTags -a | \
        samtools view -Sbhu - | \
        sambamba sort \
                -t ${task.cpus} \
                --tmpdir ${tmpDir} \
                -o ${flowCell}.${lane}.${library}.matefixed.sorted.bam \
                /dev/stdin
        """
}