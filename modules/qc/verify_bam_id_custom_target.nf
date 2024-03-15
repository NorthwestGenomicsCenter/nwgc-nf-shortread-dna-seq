process VERIFY_BAM_ID_CUSTOM_TARGET {

    label "VERIFY_BAM_ID_CUSTOM_TARGET_${params.sampleId}_${params.userId}"

    publishDir "${params.sampleQCDirectory}", mode: 'link', pattern: '*.VerifyBamId.selfSM'

    input:
        path bam
        path bai

    output:
        path "*.VerifyBamId.selfSM"
        path "versions.yaml", emit: versions

    script:

        """
        mkdir -p ${params.sampleQCDirectory}

        verifyBamID \
            --vcf ${params.customTargetContaminationReferenceVCF} \
            --bam $bam \
            --out ${params.sampleId}.VerifyBamId \
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