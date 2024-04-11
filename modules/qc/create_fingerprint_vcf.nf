process CREATE_FINGERPRINT_VCF {

    tag "CREATE_FINGERPRINT_VCF_${sampleId}${flowCellLaneLibraryString}_${userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: '*.fingerprint.vcf.gz'
    publishDir "${publishDirectory}", mode: 'link', pattern: '*.fingerprint.vcf.gz.tbi'
 
    input:
        tuple path(bam), path(bai), val(sampleId), val(flowCellLaneLibrary), val(userId), val(publishDirectory)
        tuple val(isGRC38), val(referenceGenome)
        path dbSnp
        path fingerprintBed

    output:
        path "*.fingerprint.vcf.gz", emit: vcf
        path "*.fingerprint.vcf.gz.tbi", emit: tbi
        path "versions.yaml", emit: versions

    script:
        flowCellLaneLibraryString = ""
        if (flowCellLaneLibrary != null) {
            flowCellLaneLibraryString = ".${flowCellLaneLibrary}"
        }

        """
        mkdir -p ${publishDirectory}

        ## GVCF
        gatk \
            --java-options "-XX:InitialRAMPercentage=80.0 -XX:MaxRAMPercentage=85.0" \
            HaplotypeCaller \
            -R ${referenceGenome}\
            -I $bam \
            -D $dbSnp \
            -L $fingerprintBed \
            -G StandardAnnotation \
            -pairHMM AVX_LOGLESS_CACHING \
            -ERC GVCF \
            --output ${sampleId}${flowCellLaneLibraryString}.fingerprint.g.vcf.gz

        ## VCF File
        gatk \
            --java-options "-XX:InitialRAMPercentage=80.0 -XX:MaxRAMPercentage=85.0" \
            GenotypeGVCFs \
            -R $referenceGenome \
            -L $fingerprintBed \
            --variant ${sampleId}${flowCellLaneLibraryString}.fingerprint.g.vcf.gz \
            -O ${sampleId}${flowCellLaneLibraryString}.fingerprint.vcf.gz \
            --include-non-variant-sites

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(gatk --version | grep GATK | awk '{print \$6}')
        END_VERSIONS

        """

}
