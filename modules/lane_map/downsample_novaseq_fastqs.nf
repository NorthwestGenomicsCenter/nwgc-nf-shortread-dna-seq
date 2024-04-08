process DOWNSAMPLE_NOVASEQ_FASTQS {
	tag "DOWNSAMPLE_NOVASEQ_FASTQS_${flowCell}_${lane}_${library}_${userId}"
	
	publishDir "${publishDirectory}", mode: "link", pattern: "downsampled_${flowCell}.${lane}.${library}_0.1.fq"
	publishDir "${publishDirectory}", mode: "link", pattern: "downsampled_${flowCell}.${lane}.${library}_0.2.fq"
	
	input:
		tuple path(fastq1), path(fastq2), val(flowCell), val(lane), val(library), val(userId), val(readGroup), val(readLength), val(readType), val(publishDirectory)
		val novaseqQCDownsamplingPercentage
		
	output:
		tuple path("downsampled_${flowCell}.${lane}.${library}_0.1.fq.gz"), path("downsampled_${flowCell}.${lane}.${library}_0.2.fq.gz"), val(flowCell), val(lane), val(library), val(userId), val(readGroup), val(readLength), val(readType), val(publishDirectory), emit: flowCellLaneLibraryTuple
	
	script:
		"""
		python /net/nwgc/vol1/software/bin/pegasys/randomReadSubSample.py \
		-f1 $fastq1 \
		-f2 $fastq2 \
		--sample-size $novaseqQCDownsamplingPercentage \
		--gzip-output 1 \
		--output-prefix downsampled_${flowCell}.${lane}.${library}
		"""
}