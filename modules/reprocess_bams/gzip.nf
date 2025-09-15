process GZIP {

	tag "GZIP_FASTQ_${sampleId}_${userId}"

    input:
        path fileToCompress
       	tuple val(sampleId), val(userId)

    output:
        path "${fileToCompress}.gz"

    script:
        """
        gzip -f ${fileToCompress}
        """
}