process VERIFY_BAM_ID_CUSTOM_TARGET {

    tag "VERIFY_BAM_ID_CUSTOM_TARGET_${filePrefixString}_${userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: '*.VerifyBamId.selfSM'

    input:
        tuple path(bam), path(bai), val(sampleId), val(filePrefix), val(userId), val(publishDirectory)
        path customTargetContaminationReferenceVCF

    output:
        path "*.VerifyBamId.selfSM"
        path "versions.yaml", emit: versions


    script:
        filePrefixString = ""
        if (filePrefix != null) {
            filePrefixString = filePrefix
        }
        else {
            filePrefixString = "${sampleId}"
        }

        """
        mkdir -p ${publishDirectory}

        verifyBamID \
            --vcf ${customTargetContaminationReferenceVCF} \
            --bam $bam \
            --out ${filePrefixString}.VerifyBamId \
            --verbose \
            --chip-none \
            --maxDepth 1000 \
            --precise

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            verifyBamId: \$(module list 2>&1 | awk '{for (i=1;i<=NF;i++){if (\$i ~/^verifyBamID/) {print \$i}}}' | awk -F/ '{print \$NF}')
        END_VERSIONS

        """

}           