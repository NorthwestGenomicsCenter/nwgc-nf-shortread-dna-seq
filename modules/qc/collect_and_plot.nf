process COLLECT_AND_PLOT {

    tag "COLLECT_AND_PLOT_${sampleId}_${userId}"

    publishDir "${publishDirectory}/qcPlots", mode: 'link'
 
    input:
        tuple path(alignment_summary_metrics), path(base_distribution_by_cycle), path(gc_bias_metrics), path(gc_bias_summary_metrics), path(insert_size_metrics), path(quality_yield_metrics)
        path flagstat
        path stats
        path pcm_mapq
        path pcm_baseq_files
        path pcm_chrom_files
        tuple path(bam), path(bai), val(sampleId), val(libraryId), val(userId), val(publishDirectory)
        path sequencingTargetBedFile

    output:
        path "qcPlots/*"
        path "versions.yaml", emit: versions

    script:
        String libraryIdString = ""
        if (libraryId != null) {
            libraryIdString = ".${libraryId}"
        }
        // Create a bunch of soft links to our published qc files to support the formatting used by our old scripts
        String createSoftLinks = """
                                 mkdir -p qcFiles

                                 # Picard multiple metrics files
                                 mv ${alignment_summary_metrics} qcFiles/
                                 mv ${base_distribution_by_cycle} qcFiles/
                                 mv ${gc_bias_metrics} qcFiles/
                                 mv ${gc_bias_summary_metrics} qcFiles/
                                 mv ${insert_size_metrics} qcFiles/
                                 mv ${quality_yield_metrics} qcFiles/

                                 # Samtools flagstat/ stats files
                                 mv ${flagstat} qcFiles/
                                 mv ${stats} qcFiles/
                                 
                                 # Picard coverage metrics custom mapping quality file
                                 mv ${pcm_mapq} qcFiles/${sampleId}${libraryIdString}.MAPQ0.wgs_metrics.txt

                                 # Picard coverage metrics custom base quality files
                                 for file in ${pcm_baseq_files}
                                 do 
                                    # Extract just the BaseQ number to use in the old file format
                                    tail="\${file##*.BASEQ}"
                                    baseQ="\${tail%.MAPQ*}"
                                    mv \${file} qcFiles/${sampleId}${libraryIdString}.MIN\${baseQ}.wgs_metrics.txt
                                 done

                                 # Picard coverage metrics by chromosome files
                                 for file in ${pcm_chrom_files}
                                 do 
                                    # Extract just the chromosome number to use in the old file format
                                    tail="\${file##*MAPQ20.}"
                                    chr="\${tail%.picard*}"
                                    mv \${file} qcFiles/${sampleId}${libraryIdString}.wgsMetrics.Q20.\${chr}.txt
                                 done
                                 """

        """
        mkdir -p ${publishDirectory}/qcPlots
        SCRIPT_DIR=\$( cd -- "\$( dirname -- "\${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
        mkdir -p \${SCRIPT_DIR}/qcPlots
        $createSoftLinks 


        collect.qc.metrics.core.picard.2.18.10.pl ${sampleId}${libraryIdString} \${SCRIPT_DIR} ${sequencingTargetBedFile}
        run_R_plotQC.v5.sh \${SCRIPT_DIR} ${sampleId}${libraryIdString}

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            R: \$(R --version | grep '^R version' | awk '{print \$3}')
        END_VERSIONS
        """

}
/*
mv ${pcm_baseq_0} qcFiles/${sampleId}${libraryIdString}.MIN0.wgs_metrics.txt
mv ${pcm_baseq_10} qcFiles/${sampleId}${libraryIdString}.MIN10.wgs_metrics.txt
mv ${pcm_baseq_20} qcFiles/${sampleId}${libraryIdString}.MIN20.wgs_metrics.txt
mv ${pcm_baseq_30} qcFiles/${sampleId}${libraryIdString}.MIN30.wgs_metrics.txt
*/