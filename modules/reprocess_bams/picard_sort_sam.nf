process PICARD_SORT_SAM {
	tag "PICARD_SORT_SAM_${sampleId}_${userId}"

	input:
        	tuple path(bam)
        	tuple val(sampleId), val(userId)

    	output:
        	path "${sampleId}_${userId}_queryname.bam", emit: sorted_bam

    	script:
        	"""
        	SORT_ORDER=\$(samtools view -H "${bam}" | grep "^@HD" | sed -n 's/.*SO:\\([a-z]*\\).*/\\1/p')
        
        	if [[ "\$SORT_ORDER" == "queryname" ]]; then
            		cp "${bam}" "${sampleId}_${userId}_queryname.bam"
        	else
            		java -XX:InitialRAMPercentage=80 -XX:MaxRAMPercentage=85 \
                		-jar \$PICARD_DIR/picard.jar SortSam \
                		--INPUT ${bam} \
                		--OUTPUT ${sampleId}_${userId}_queryname.bam \
                		--SORT_ORDER queryname \
                		--VALIDATION_STRINGENCY SILENT
        	fi
        	"""	
}
