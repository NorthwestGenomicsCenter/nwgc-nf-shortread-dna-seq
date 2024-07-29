process EXTRACT_READ_GROUPS {
    executor "local"

	input:
		path bam

	output:
		tuple env("READ_GROUP_PUS"), env("READ_GROUPS")

	script:

		"""
		READ_GROUPS=\$(samtools view -H ${bam} | grep '^@RG')
		READ_GROUP_PUS=\$(samtools view -H ${bam} | grep '^@RG' | grep -o "PU[^\\S]*")
		"""
}