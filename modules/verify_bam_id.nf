process VERIFY_BAM_ID {

    label "VERIFY_BAM_ID_${params.sampleId}_${params.userId}"

    publishDir "${params.sampleQCDirectory}", mode: 'link', pattern: '*.VerifyBamId.selfSM'

    input:
        path bam
        path bai

    output:
        path "*.VerifyBamId.selfSM"
        path "versions.yaml", emit: versions

    script:
        def disableSanityCheck = params.mode == 'test' ? '--DisableSanityCheck' : ''

        def refVersion = 'b37'
        if (params.isGRC38) {
            refVersion = 'b38'
        }

        def udPath = params.contaminationUDPath != 'null' ? params.contaminationUDPath : "\$MOD_GSVERIFYBAMID_DIR/resource/1000g.100k.${refVersion}.vcf.gz.dat.UD"
        def bedPath = params.contaminationBedPath != 'null' ? params.contaminationBedPath : "\$MOD_GSVERIFYBAMID_DIR/resource/1000g.100k.${refVersion}.vcf.gz.dat.bed"
        def meanPath = params.contaminationMeanPath != 'null' ? params.contaminationMeanPath : "\$MOD_GSVERIFYBAMID_DIR/resource/1000g.100k.${refVersion}.vcf.gz.dat.mu"

        """
        mkdir -p ${params.sampleQCDirectory}

        VerifyBamID \
            --UDPath $udPath \
            --BedPath $bedPath \
            --MeanPath $meanPath \
            --BamFile $bam \
            --Reference ${params.referenceGenome} \
            $disableSanityCheck \
            --Output ${params.sampleId}.VerifyBamId

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            VerifyBamId: \$(module list 2>&1 | awk '{for (i=1;i<=NF;i++){if (\$i ~/^VerifyBamID/) {print \$i}}}' | awk -F/ '{print \$NF}')
        END_VERSIONS

        """

}