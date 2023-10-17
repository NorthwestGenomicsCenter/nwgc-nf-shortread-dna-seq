process BASE_RECALIBRATOR {

    label "BASE_RECALIBRATOR${params.sampleId}_${params.libraryId}_${params.userId}"

    input:
        path bam

    output:
        path "${params.sampleId}.${params.libraryId}.${params.sequencingTarget}.bqsr_recalibartion.table", emit: bqsr_recalibration_table
        path "versions.yaml", emit: versions

    script:
        def taskMemoryString = "$task.memory"
        def javaMemory = taskMemoryString.substring(0, taskMemoryString.length() - 1).replaceAll("\\s","")

        """
        gatk \
            --java-options "-Xmx$javaMemory" \
            BaseRecalibratorSpark \
            --spark-master local[$task.cpus] \
            --input $bam \
            --output ${params.sampleId}.${params.libraryId}.${params.sequencingTarget}.bqsr_recalibartion.table \
            --reference $params.referenceGenome \
            --known-sites $params.dbSnp \
            --known-sites $params.goldStandardIndels \
            --known-sites $params.knownIndels \
            --deletions_default_quality 45 \
            --indels_context_size 3 \
            --insertions_default_quality 45 \
            --low_quality_tail 3 \
            --maximum_cycle_value 500 \
            --mismatches_context_size 2 \
            --mismatches_default_quality -1  \
            --quantizing_levels 16
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
            -L chrM \

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}_${task.index}':
            gatk: \$(gatk --version | grep GATK | awk '{print \$6}')
        END_VERSIONS
        """

}
