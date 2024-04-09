process VERIFY_BAM_ID {

    tag "VERIFY_BAM_ID_${sampleId}_${userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: '*.VerifyBamId.selfSM'

    input:
        tuple path(bam), path(bai), val(sampleId), val(libraryId), val(userId), val(publishDirectory)
        tuple val(isGRC38), val(referenceGenome)
        tuple val(contaminationUDPath), val(contaminationBedPath), val(contaminationMeanPath)


    output:
        path "*.VerifyBamId.selfSM"
        path "versions.yaml", emit: versions

    script:
        def disableSanityCheck = params.mode == 'test' ? '--DisableSanityCheck' : ''

        def refVersion = 'b37'
        if (isGRC38) {
            refVersion = 'b38'
        }

        def udPath = contaminationUDPath != 'null' ? contaminationUDPath : "\$MOD_GSVERIFYBAMID_DIR/resource/1000g.100k.${refVersion}.vcf.gz.dat.UD"
        def bedPath = contaminationBedPath != 'null' ? contaminationBedPath : "\$MOD_GSVERIFYBAMID_DIR/resource/1000g.100k.${refVersion}.vcf.gz.dat.bed"
        def meanPath = contaminationMeanPath != 'null' ? contaminationMeanPath : "\$MOD_GSVERIFYBAMID_DIR/resource/1000g.100k.${refVersion}.vcf.gz.dat.mu"

        String libraryIdString = ""
        if (libraryId != null) {
            libraryIdString = ".${libraryId}"
        }

        """
        mkdir -p ${publishDirectory}

        VerifyBamID \
            --UDPath $udPath \
            --BedPath $bedPath \
            --MeanPath $meanPath \
            --BamFile $bam \
            --Reference ${referenceGenome} \
            $disableSanityCheck \
            --Output ${sampleId}${libraryIdString}.VerifyBamId

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            VerifyBamId: \$(module list 2>&1 | awk '{for (i=1;i<=NF;i++){if (\$i ~/^VerifyBamID/) {print \$i}}}' | awk -F/ '{print \$NF}')
        END_VERSIONS

        """

}