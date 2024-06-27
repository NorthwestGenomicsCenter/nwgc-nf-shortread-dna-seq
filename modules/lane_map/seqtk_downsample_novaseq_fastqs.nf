process SEQTK_DOWNSAMPLE_NOVASEQ_FASTQS {
	tag "SEQTK_DOWNSAMPLE_NOVASEQ_FASTQS_${flowCell}_${lane}_${library}_${userId}"
	
	publishDir "${publishDirectory}", mode: "link", pattern: "downsampled_${fastq1}"
	publishDir "${publishDirectory}", mode: "link", pattern: "downsampled_${fastq2}"
	
	input:
		tuple path(fastq1), path(fastq2), val(flowCell), val(lane), val(library), val(sampleId), val(userId), val(readGroup), val(readLength), val(readType), val(publishDirectory)
		val novaseqQCDownsamplingAmount
		
	output:
		tuple path("downsampled_${fastq1}"), path("downsampled_${fastq2}"), val(flowCell), val(lane), val(library), val(sampleId), val(userId), val(readGroup), val(readLength), val(readType), val(publishDirectory), emit: flowCellLaneLibraryTuple
	
	script:
		"""
		seqtk sample -s100 ${fastq1} ${novaseqQCDownsamplingAmount} | gzip > downsampled_${fastq1}
        seqtk sample -s100 ${fastq2} ${novaseqQCDownsamplingAmount} | gzip > downsampled_${fastq2}
		"""
}