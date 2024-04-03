process SAMBAMBA_SORT {
    tag "SAMBAMBA_SORT_${flowCell}_${lane}_${library}"

    input:
        tuple stdin(toSort), val(flowCell), val(lane), val(library), val(userId), val(readGroup), val(publishDirectory)

    output:
        tuple path("${flowCell}.${lane}.${library}.matefixed.sorted.bam"), val(flowCell), val(lane), val(library), val(userId), val(readGroup), val(publishDirectory), emit: sorted

    script:
        String tmpDir = "tmp"
        // TBH im not sure that the way this tmp is set up wont be a problem with sambamba
        """
        mkdir ${tmpDir}

        \$SAMBAMBA sort \
            -t ${task.cpus} \
            --tmpdir ${tmpDir} \
            -o ${flowCell}.${lane}.${library}.matefixed.sorted.bam \
            /dev/stdin
        """
}