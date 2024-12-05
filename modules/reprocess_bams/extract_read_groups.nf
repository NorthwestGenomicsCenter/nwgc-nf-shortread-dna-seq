process EXTRACT_READ_GROUPS {
    executor "local"

	input:
		path bamOrCram

	output:
		tuple env("READ_GROUP_PUS"), env("READ_GROUPS")

	script:
		// This is needed because crams have a fasta file that comes in with them.
		file = bamOrCram[0]
		"""
		READ_GROUPS=\$(samtools view -H ${file} | grep '^@RG')
		READ_GROUP_PUS=\$(samtools view -H ${file} | grep '^@RG' | grep -o "PU:\\S*")
		"""
}
