process VALIDATE_VARIANTS {

    label "VALIDATE_VARIANTS_${params.sampleId}_${params.userId}"

    publishDir "$params.sampleDirectory", mode:  'link', pattern: "validate_variants.txt", saveAs: {s-> "${params.sampleId}.${params.sequencingTarget}.validate_variants.txt"}

    input:
        path gvcf
        path index

    script:
        def taskMemoryString = "$task.memory"
        def javaMemory = taskMemoryString.substring(0, taskMemoryString.length() - 1).replaceAll("\\s","")

        def chromosomesToCheck = ""
        if ("$params.organism" == 'Homo sapiens') {
            def chromsomsesToCheckPrefix = " -L "
            def chromosomes = "$params.isGRC38" == 'true' ? "$params.grc38Chromosomes" : "$params.hg19Chromosomes"
            chromosomes = chromosomes.substring(1,chromosomes.length()-1).split(",").collect{it as String}
            for (chromosome in chromosomes) {
                chromosomesToCheck += chromsomsesToCheckPrefix + chromosome
            }
        }

        """
        java "-Xmx$javaMemory" \
            -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar \
            -T ValidateVariants \
            -R $params.referenceGenome \
            -V $gvcf \
            --dbsnp $params.dbSnp \
            $chromosomesToCheck \
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
