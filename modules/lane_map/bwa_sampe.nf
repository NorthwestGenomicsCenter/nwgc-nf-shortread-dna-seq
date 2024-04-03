process BWA_SAMPE {

    tag "BWA_SAMPE_${flowCell}_${lane}_${library}_${userId}"
    
    input:
        tuple path(fastq1), path(fastq2), val(flowCell), val(lane), val(library), val(userId), val(readGroup), val(publishDirectory)
        path referenceGenome


    output:
        tuple stdout(out), val(flowCell), val(lane), val(library), val(userId), val(publishDirectory), emit: sampe

    script:
        def threads = task.cpus / 2

        """
        mkdir ${tmpDir}

        \$BWA sampe \
				-P ${referenceGenome} \
				-r ${readGroup} \
		    	<(\$BWA aln -t ${threads} ${referenceGenome} -1 ${fastq1}) \
                <(\$BWA aln -t ${threads} ${referenceGenome} -2 ${fastq2}) \
		    	${fastq1} \
                ${fastq2}
        """
}