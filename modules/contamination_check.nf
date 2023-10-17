process CONTAMINATION_CHECK {

    label "CONTAMINATION_CHECK_${params.sampleId}_${params.libraryId}_${params.userId}"

    publishDir "$params.sampleQCDirectory", mode: 'link', pattern: '*.VerifyBamID.selfSM'

    input:
        path bam
        path bai

    output:
        path "*.VerifyBamID.selfSM"
        path "versions.yaml", emit: versions

    script:
        def disableSanityCheck = params.mode == 'test' ? '--DisableSanityCheck' : ''

        """
        mkdir -p $params.sampleQCDirectory

        VERIFYBAMID_RESOURCE=\$MOD_GSVERIFYBAMID_DIR/resource

        UDPATH=\$VERIFYBAMID_RESOURCE/1000g.phase3.100k.b38.vcf.gz.dat.UD
        BEDPATH=\$VERIFYBAMID_RESOURCE/1000g.phase3.100k.b38.vcf.gz.dat.bed
        MEANPATH=\$VERIFYBAMID_RESOURCE/1000g.phase3.100k.b38.vcf.gz.dat.mu

        VerifyBamID \
            --UDPath \$UDPATH \
            --BedPath \$BEDPATH \
            --MeanPath \$MEANPATH \
            --BamFile $bam
            --Reference $params.referenceGenome \
            --Output ${params.sampleId}.${params.libraryId}.VerifyBamID

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            samtools: \$(samtools --version | grep ^samtools | awk '{print \$2}')
            VerifyBamId: \$(module list 2>&1 | awk '{for (i=1;i<=NF;i++){if (\$i ~/^VerifyBamID/) {print \$i}}}' | awk -F/ '{print \$NF}')
        END_VERSIONS

        """

}
