process COLLECT_AND_PLOT {

    tag "COLLECT_AND_PLOT_${sampleId}_${userId}"

    publishDir "${publishDirectory}/qcPlots", mode: 'link'
 
    input:
        val ready1
        val ready2
        val ready3
        val ready4
        val ready5
        val ready6
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
                                 ln -s --target-directory=qcFiles ${publishDirectory}/${sampleId}${libraryIdString}.alignment_summary_metrics.txt 
                                 ln -s --target-directory=qcFiles ${publishDirectory}/${sampleId}${libraryIdString}.base_distribution_by_cycle.txt
                                 ln -s --target-directory=qcFiles ${publishDirectory}/${sampleId}${libraryIdString}.gc_bias_metrics.txt
                                 ln -s --target-directory=qcFiles ${publishDirectory}/${sampleId}${libraryIdString}.gc_bias_summary_metrics.txt
                                 ln -s --target-directory=qcFiles ${publishDirectory}/${sampleId}${libraryIdString}.insert_size_metrics.txt
                                 ln -s --target-directory=qcFiles ${publishDirectory}/${sampleId}${libraryIdString}.quality_yield_metrics.txt

                                 # Samtools flagstat/ stats files
                                 ln -s --target-directory=qcFiles ${publishDirectory}/${sampleId}${libraryIdString}.flagstat.output.txt
                                 ln -s --target-directory=qcFiles ${publishDirectory}/${sampleId}${libraryIdString}.onTarget.stats.txt
                                 
                                 # Picard coverage metrics files
                                 ln -s ${publishDirectory}/${sampleId}${libraryIdString}.BASEQ0.MAPQ20.picard.coverage.txt qcFiles/${sampleId}${libraryIdString}.MIN0.wgs_metrics.txt
                                 ln -s ${publishDirectory}/${sampleId}${libraryIdString}.BASEQ10.MAPQ20.picard.coverage.txt qcFiles/${sampleId}${libraryIdString}.MIN10.wgs_metrics.txt
                                 ln -s ${publishDirectory}/${sampleId}${libraryIdString}.BASEQ20.MAPQ20.picard.coverage.txt qcFiles/${sampleId}${libraryIdString}.MIN20.wgs_metrics.txt
                                 ln -s ${publishDirectory}/${sampleId}${libraryIdString}.BASEQ30.MAPQ20.picard.coverage.txt qcFiles/${sampleId}${libraryIdString}.MIN30.wgs_metrics.txt
                                 ln -s ${publishDirectory}/${sampleId}${libraryIdString}.BASEQ20.MAPQ0.picard.coverage.txt qcFiles/${sampleId}${libraryIdString}.MAPQ0.wgs_metrics.txt

                                 # Picard coverage metrics by chromosome files
                                 for file in ${publishDirectory}/${sampleId}${libraryIdString}.BASEQ20.MAPQ20.chr*
                                 do 
                                    # Extract just the chromosome number to use in the old file format
                                    tail="\${file##*MAPQ20.}"
                                    chr="\${tail%.picard*}"
                                    ln -s \${file} qcFiles/${sampleId}${libraryIdString}.wgsMetrics.Q20.\${chr}.txt
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