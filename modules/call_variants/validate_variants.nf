process VALIDATE_VARIANTS {

    tag "VALIDATE_VARIANTS_${sampleId}_${userId}"

    publishDir "$params.sampleDirectory", mode:  'link', pattern: "validate_variants.txt", saveAs: {s-> "${sampleId}.${sequencingTarget}.validate_variants.txt"}

    input:
        path gvcf
        path index
        tuple val(sampleId), val(userId), val(sequencingTarget), val(referenceGenome), val(publishDirectory)
        val chromosomesToCheck // List of the chromosome name of checks. i.e. ['chr1', 'chr2', 'chr3', 'chr4', ...] or ['1', '2', '3', '4', ...]
        val dbSnp

    script:
        def taskMemoryString = "$task.memory"
        def javaMemory = taskMemoryString.substring(0, taskMemoryString.length() - 1).replaceAll("\\s","")

        // ******************************
        // ** NEED TO MOVE TO WORKFLOW **
        // ******************************
        // def chromosomesToCheck = ""
        // if ("$params.organism" == 'Homo sapiens') {
        //     def chromsomsesToCheckPrefix = " -L "
        //     def chromosomes = "$params.isGRC38" == 'true' ? "$params.grc38Chromosomes" : "$params.hg19Chromosomes"
        //     chromosomes = chromosomes.substring(1,chromosomes.length()-1).split(",").collect{it as String}
        //     for (chromosome in chromosomes) {
        //         chromosomesToCheck += chromsomsesToCheckPrefix + chromosome
        //     }
        // }
        def chromosomesToCheckString = ""
        def chromosomesToCheckPrefix = " -L "
        if (chromosomesToCheck != null) {
            for (chromosome in chromosomesToCheck) {
                chromosomesToCheckString += chromosomesToCheckPrefix + chromosome
            }
        }

        """
        java "-Xmx$javaMemory" \
            -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar \
            -T ValidateVariants \
            -R $referenceGenome \
            -V $gvcf \
            --dbsnp $dbSnp \
            $chromosomesToCheckString \
            --validateGVCF \
            --warnOnErrors

        cp .command.out validate_variants.txt

        ERROR_TEXT=\$(grep WARN .command.out | grep '\\*\\*\\*\\*\\*') || true
        if [ "\$ERROR_TEXT" != "" ]; then
          printf "Validate Variants error"
          exit 1
        fi

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(java -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar --version)
        END_VERSIONS

        """

}