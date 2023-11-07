process CREATE_FINGERPRINT_VCF {

    label "CREATE_FINGERPRINT_VCF_${params.sampleId}_${params.libraryId}_${params.userId}"

    publishDir "$params.sampleQCDirectory", mode: 'link', pattern: '*.fingerprint.vcf.gz'
 
    input:
        path bam
        path bai

    output:
        path "*.fingerprint.vcf.gz" emit: vcf
        path "versions.yaml", emit: versions

    script:

        """
        mkdir -p $params.sampleQCDirectory

        ## GVCF
        time $GATK/gatk \
            HaplotypeCaller \
            -R $params.referenceGenome \
            -I $bam \
            -D $params.dbSnp \
            -L $params.fingerprintBed \
            -G StandardAnnotation \
            -pairHMM AVX_LOGLESS_CACHING \
            -ERC GVCF \
            --output ${params.sampleId}.fingerprint.g.vcf.gz

        ## VCF File
        time $GATK/gatk
                -XX:InitialRAMPercentage=80 \
                -XX:MaxRAMPercentage=85 \
                GenotypeGVCFs \
                -R $params.referenceGenome \
                -L $params.fingerprintBed \
                --variant ${params.sampleId}.fingerprint.g.vcf.gz \
                -O ${params.sampleId}.fingerprint.vcf.gz \
                --include-non-variant-sites

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(gatk --version | grep GATK | awk '{print \$6}')
        END_VERSIONS

        """

}
