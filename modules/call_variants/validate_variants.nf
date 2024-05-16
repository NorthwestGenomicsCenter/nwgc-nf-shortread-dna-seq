process VALIDATE_VARIANTS {

    tag "VALIDATE_VARIANTS_${sampleId}_${userId}"

    publishDir "${publishDirectory}", mode:  'link', pattern: "validate_variants.txt", saveAs: {s-> "${sampleId}.${sequencingTarget}.validate_variants.txt"}

    input:
        path gvcf
        path index
        tuple val(sampleId), val(userId), val(sequencingTarget), val(referenceGenome), val(publishDirectory)
        val chromosomesToCheck // List of the chromosome name of checks. i.e. ['chr1', 'chr2', 'chr3', 'chr4', ...] or ['1', '2', '3', '4', ...]
        val dbSnp

    output:
        path "validate_variants.txt", emit: validate_variants
        path "versions.yaml", emit: versiosn

    script:
        def taskMemoryString = "$task.memory"
        def javaMemory = taskMemoryString.substring(0, taskMemoryString.length() - 1).replaceAll("\\s","")

        def chromosomesToCheckString = ""
        def chromosomesToCheckPrefix = " -L "
        if (chromosomesToCheck != null) {
            for (chromosome in chromosomesToCheck) {
                chromosomesToCheckString += chromosomesToCheckPrefix + chromosome
            }
        }

        """
        java \
            -XX:InitialRAMPercentage=80 \
            -XX:MaxRAMPercentage=85 \
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