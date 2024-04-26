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

        // ISSUE IS MAYBE THAT I HAVE VELOCITY IF ELSE STATEMENTS THAT ARE GETTING SENT TO GATK WITH THE COMMAND
        """
        java \
        -XX:InitialRAMPercentage=80.0 \
        -XX:MaxRAMPercentage=85.0 \
        -jar \$GATK_DIR/GenomeAnalysisTK.jar \
        -T BaseRecalibrator \
        -R ${referenceGenome} \
        -I ${bam} \
        --out ${sampleId}.recal.matrix \
        -nct 5 \
        -knownSites ${dbSnp} \
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

/*
        """
        gatk \
            --java-options "-XX:InitialRAMPercentage=80.0 -XX:MaxRAMPercentage=85.0" \
            BaseRecalibrator \
            --input $bam \
            --output ${params.sampleId}.${params.libraryId}.${params.sequencingTarget}.bqsr_recalibartion.table \
            --reference $params.referenceGenome \
            --known-sites $params.dbSnp \
            --known-sites $params.goldStandardIndels \
            --known-sites $params.knownIndels \
            --deletions-default-quality 45 \
            --indels-context-size 3 \
            --insertions-default-quality 45 \
            --low-quality-tail 3 \
            --maximum-cycle-value 500 \
            --mismatches-context-size 2 \
            --mismatches-default-quality -1  \
            --quantizing-levels 16 \
            -L chr1 \
            -L chr2 \
            -L chr3 \
            -L chr4 \
            -L chr5 \
            -L chr6 \
            -L chr7 \
            -L chr8 \
            -L chr9 \
            -L chr10 \
            -L chr11 \
            -L chr12 \
            -L chr13 \
            -L chr14 \
            -L chr15 \
            -L chr16 \
            -L chr17 \
            -L chr18 \
            -L chr19 \
            -L chr20 \
            -L chr21 \
            -L chr22 \
            -L chrX \
            -L chrY \
            -L chrM

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}_${task.index}':
            gatk: \$(gatk --version | grep GATK | awk '{print \$6}')
        END_VERSIONS
        """
        */