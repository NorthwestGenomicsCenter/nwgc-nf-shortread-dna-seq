process COLLECT_AND_PLOT {

    label "COLLECT_AND_PLOT_${params.sampleId}_${params.userId}"

    publishDir "${params.sampleQCDirectory}", mode: 'link'
 
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
        path "versions.yaml", emit: versions

    script:
    
        """
        mkdir -p ${params.sampleDirectory}/qcPlots 

        perl ${params.softwareDirectory}/collect.qc.metrics.core.picard.2.18.10.pl ${params.sampleId} ${params.sampleDirectory} ${params.sequencingTargetBedFile}
        ${params.softwareDirectory}/run_R_plotQC.v5.sh ${params.sampleDirectory} ${params.sampleId}

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            R: "" #put r version here
        END_VERSIONS
        """

}