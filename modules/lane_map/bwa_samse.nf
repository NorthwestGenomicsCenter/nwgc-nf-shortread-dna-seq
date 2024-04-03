process BWA_SAMSE {

    tag "BWA_SAMSE_${flowCell}_${lane}_${library}_${userId}"
    
    input:
        tuple path(fastq1), val(flowCell), val(lane), val(library), val(userId), val(readGroup), val(publishDirectory)
        path referenceGenome


    output:
        tuple stdout(out), val(flowCell), val(lane), val(library), val(userId), val(publishDirectory), emit: samse

    script:
        """
        mkdir ${tmpDir}

        \$BWA samse \
				${referenceGenome} \
				-r ${readGroup} \
		    	<(\$BWA aln -t ${task.cpus} ${referenceGenome} -0 ${fastq1}) \
		    	${fastq1}
        """
}