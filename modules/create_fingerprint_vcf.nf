process CREATE_FINGERPRINT_VCF {

    label "CREATE_FINGERPRINT_VCF_${params.sampleId}_${params.libraryId}_${params.userId}"

    publishDir "$params.sampleQCDirectory", mode: 'link', pattern: '*.fingerprint.vcf.gz'
    publishDir "$params.sampleQCDirectory", mode: 'link', pattern: '*.fingerprint.vcf.gz.tbi'
 
    input:
        path bam
        path bai

    output:
        path "*.fingerprint.vcf.gz", emit: vcf
        path "*.fingerprint.vcf.gz.tbi", emit: tbi
        path "versions.yaml", emit: versions

    script:

        """
        mkdir -p $params.sampleQCDirectory

        ## GVCF
        gatk \
            --java-options "-XX:InitialRAMPercentage=80.0 -XX:MaxRAMPercentage=85.0" \
            HaplotypeCaller \
            -R $params.referenceGenome \
            -I $bam \
            -D $params.dbSnp \
            -L $params.fingerprintBed \
            -G StandardAnnotation \
            -pairHMM AVX_LOGLESS_CACHING \
            -ERC GVCF \
            --output ${params.sampleId}.${params.libraryId}.fingerprint.g.vcf.gz

        ## VCF File
        gatk \
            --java-options "-XX:InitialRAMPercentage=80.0 -XX:MaxRAMPercentage=85.0" \
            GenotypeGVCFs \
            -R $params.referenceGenome \
            -L $params.fingerprintBed \
            --variant ${params.sampleId}.${params.libraryId}.fingerprint.g.vcf.gz \
            -O ${params.sampleId}.${params.libraryId}.fingerprint.vcf.gz \
            --include-non-variant-sites

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(gatk --version | grep GATK | awk '{print \$6}')
        END_VERSIONS

        """

}
