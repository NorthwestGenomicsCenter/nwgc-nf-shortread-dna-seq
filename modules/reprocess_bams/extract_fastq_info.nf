process EXTRACT_FASTQ_INFO {

    executor 'local'
 
    input:
        val fcllInfo

    output:
        tuple val(fcllInfo), env("READ_LENGTH"), env("FASTQ_AT_STRING")

    script:

        fastq1 = fcllInfo["fastq1"]
    
        """
        READ_LENGTH=\$(zcat ${fastq1} | head -2 | tail -1 | wc | awk '{print \$3}')
        FASTQ_AT_STRING=\$(zcat ${fastq1} | head -1)
        """

}
