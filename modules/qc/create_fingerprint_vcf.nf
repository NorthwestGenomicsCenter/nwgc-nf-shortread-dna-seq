process CREATE_FINGERPRINT_VCF {

    tag "CREATE_FINGERPRINT_VCF_${filePrefixString}_${userId}"

    publishDir "${publishDirectory}", mode: 'link', pattern: '*.fingerprint.vcf.gz'
    publishDir "${publishDirectory}", mode: 'link', pattern: '*.fingerprint.vcf.gz.tbi'
 
    input:
        tuple path(bam), path(bai), val(sampleId), val(filePrefix), val(userId), val(publishDirectory), val(flowcell), val(lane), val(library)
        tuple val(isGRC38), val(referenceGenome)
        val dbSnp
        val fingerprintBed

    output:
        path "*.fingerprint.vcf.gz", emit: vcf
        path "*.fingerprint.vcf.gz.tbi", emit: tbi
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
            --output ${filePrefixString}.fingerprint.g.vcf.gz

        ## VCF File
        gatk \
            --java-options "-XX:InitialRAMPercentage=80.0 -XX:MaxRAMPercentage=85.0" \
            GenotypeGVCFs \
            -R $referenceGenome \
            -L $fingerprintBed \
            --variant ${filePrefixString}.fingerprint.g.vcf.gz \
            -O ${filePrefixString}.fingerprint.vcf.gz \
            --include-non-variant-sites

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(gatk --version | grep GATK | awk '{print \$6}')
        END_VERSIONS

        """

}
