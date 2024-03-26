// process BWA_SAMSE {

//     label "BWA_SAMSE_${params.sampleId}_${params.libraryId}_${params.userId}"
    
//     input:

//     output:

//     script:
//         """
//         $BWA samse \
// 				$GENOMEREF \
// 				-r $READ_GROUP \
// 		    	<($BWA aln -t $NSLOTS $GENOMEREF -0 $INPUT_1) \
// 		    	$INPUT_1 | \
// 				samblaster --addMateTags -a | \
// 				samtools view -Sbhu - | \
// 				$SAMBAMBA sort \
// 					-t $NSLOTS \
// 					--tmpdir $TMP_DIR \
// 					-o $OUTPUT_FILE \
// 					/dev/stdin

//         """
// }