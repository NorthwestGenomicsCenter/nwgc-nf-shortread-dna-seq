process EXTRACT_READ_LENGTH {

    executor 'local'
 
    input:
        val fcllInfo

    output:
        tuple val(fcllInfo), env("READ_LENGTH")

    script:

        fastq1 = fcllInfo["fastq1"]
    
        """
        READ_LENGTH=\$(zcat ${fastq1} | head -2 | tail -1 | wc | awk '{print \$3}')
        """

}
