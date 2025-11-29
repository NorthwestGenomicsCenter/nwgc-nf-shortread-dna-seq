process GATK_BASE_RECALIBRATOR {

    tag "GATK_BASE_RECALIBRATOR_${sampleId}_${params.userId}"

    input:
        path bam
        val sampleId
        val organism
        val isGRC38
        val dbSnp
        val gsIndels
        val kIndels
        val referenceGenome

    output:
        path "${sampleId}.recal.matrix", emit: bqsr_recalibration_table
        path "versions.yaml", emit: versions

    script:
        String CHR_TAG = ''
        if (isGRC38) {
            CHR_TAG = 'chr'
        }

        String snps = ''
        if (isGRC38 && organism.equals("Homo sapiens")) {
            snps = "-knownSites ${dbSnp} "
        }

        String indels = ''
        if (isGRC38 && organism.equals("Homo sapiens")) {
            indels = "-knownSites ${gsIndels} \
                      -knownSites ${kIndels} "
        }

        String chroms = ''
        if (organism.equals("Homo sapiens")) {
            chroms = "  -L ${CHR_TAG}1 \
                        -L ${CHR_TAG}2 \
                        -L ${CHR_TAG}3 \
                        -L ${CHR_TAG}4 \
                        -L ${CHR_TAG}5 \
                        -L ${CHR_TAG}6 \
                        -L ${CHR_TAG}7 \
                        -L ${CHR_TAG}8 \
                        -L ${CHR_TAG}9 \
                        -L ${CHR_TAG}10 \
                        -L ${CHR_TAG}11 \
                        -L ${CHR_TAG}12 \
                        -L ${CHR_TAG}13 \
                        -L ${CHR_TAG}14 \
                        -L ${CHR_TAG}15 \
                        -L ${CHR_TAG}16 \
                        -L ${CHR_TAG}17 \
                        -L ${CHR_TAG}18 \
                        -L ${CHR_TAG}19 \
                        -L ${CHR_TAG}20 \
                        -L ${CHR_TAG}21 \
                        -L ${CHR_TAG}22 "
        }

        """
        java \
        -XX:InitialRAMPercentage=80.0 \
        -XX:MaxRAMPercentage=85.0 \
        -jar \$GATK_DIR/GenomeAnalysisTK.jar \
        -T BaseRecalibrator \
        -R ${referenceGenome} \
        -I ${bam} \
        --out ${sampleId}.recal.matrix \
        -nct ${task.cpus} \
        ${snps} \
        ${indels} \
        --downsample_to_fraction 0.1 \
        ${chroms} \
        --deletions_default_quality 45 \
        --indels_context_size 3 \
        --insertions_default_quality 45 \
        --low_quality_tail 3 \
        --maximum_cycle_value 500 \
        --mismatches_context_size 2 \
        --mismatches_default_quality -1  \
        --quantizing_levels 16

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(java -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar --version)
        END_VERSIONS
        """
}