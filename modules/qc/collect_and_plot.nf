process COLLECT_AND_PLOT {

    label "COLLECT_AND_PLOT_${params.sampleId}_${params.userId}"

    publishDir "${params.sampleQCDirectory}/qcPlots", mode: 'link'
 
    input:
        val ready1
        val ready2
        val ready3
        val ready4
        val ready5
        val ready6
        path bam
        path bai

    output:
        path "qcPlots/*"
        path "versions.yaml", emit: versions

    script:
        // Create a bunch of soft links to our published qc files to support the formatting used by our old scripts
        String createSoftLinks = """
                                 mkdir -p qcFiles

                                 # Picard multiple metrics files
                                 ln -s --target-directory=qcFiles ${params.sampleQCDirectory}/${params.sampleId}.alignment_summary_metrics.txt 
                                 ln -s --target-directory=qcFiles ${params.sampleQCDirectory}/${params.sampleId}.base_distribution_by_cycle.txt
                                 ln -s --target-directory=qcFiles ${params.sampleQCDirectory}/${params.sampleId}.gc_bias_metrics.txt
                                 ln -s --target-directory=qcFiles ${params.sampleQCDirectory}/${params.sampleId}.gc_bias_summary_metrics.txt
                                 ln -s --target-directory=qcFiles ${params.sampleQCDirectory}/${params.sampleId}.insert_size_metrics.txt
                                 ln -s --target-directory=qcFiles ${params.sampleQCDirectory}/${params.sampleId}.quality_yield_metrics.txt

                                 # Samtools flagstat/ stats files
                                 ln -s --target-directory=qcFiles ${params.sampleQCDirectory}/${params.sampleId}.flagstat.output.txt
                                 ln -s --target-directory=qcFiles ${params.sampleQCDirectory}/${params.sampleId}.onTarget.stats.txt
                                 
                                 # Picard coverage metrics files
                                 ln -s ${params.sampleQCDirectory}/${params.sampleId}.BASEQ0.MAPQ20.picard.coverage.txt qcFiles/${params.sampleId}.MIN0.wgs_metrics.txt
                                 ln -s ${params.sampleQCDirectory}/${params.sampleId}.BASEQ10.MAPQ20.picard.coverage.txt qcFiles/${params.sampleId}.MIN10.wgs_metrics.txt
                                 ln -s ${params.sampleQCDirectory}/${params.sampleId}.BASEQ20.MAPQ20.picard.coverage.txt qcFiles/${params.sampleId}.MIN20.wgs_metrics.txt
                                 ln -s ${params.sampleQCDirectory}/${params.sampleId}.BASEQ30.MAPQ20.picard.coverage.txt qcFiles/${params.sampleId}.MIN30.wgs_metrics.txt
                                 ln -s ${params.sampleQCDirectory}/${params.sampleId}.BASEQ20.MAPQ0.picard.coverage.txt qcFiles/${params.sampleId}.MAPQ0.wgs_metrics.txt

                                 # Picard coverage metrics by chromosome files
                                 for file in ${params.sampleQCDirectory}/${params.sampleId}.BASEQ20.MAPQ20.chr*
                                 do 
                                    # Extract just the chromosome number to use in the old file format
                                    tail="\${file##*MAPQ20.}"
                                    chr="\${tail%.picard*}"
                                    ln -s \${file} qcFiles/${params.sampleId}.wgsMetrics.Q20.\${chr}.txt
                                 done
                                 """

        """
        mkdir -p ${params.sampleQCDirectory}/qcPlots
        SCRIPT_DIR=\$( cd -- "\$( dirname -- "\${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
        mkdir -p \${SCRIPT_DIR}/qcPlots
        $createSoftLinks 


        perl ${params.softwareDirectory}/collect.qc.metrics.core.picard.2.18.10.pl ${params.sampleId} \${SCRIPT_DIR} ${params.sequencingTargetBedFile}
        ${params.softwareDirectory}/run_R_plotQC.v5.sh \${SCRIPT_DIR} ${params.sampleId}

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            R: \$(R --version | grep '^R version' | awk '{print \$3}')
        END_VERSIONS
        """

}