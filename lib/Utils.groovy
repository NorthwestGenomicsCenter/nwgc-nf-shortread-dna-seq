public class Utils {
	// TODO: MAKE THIS WORK WITH MULTIPLE 
    public static Object formatParamsForInclusion(label, value) {
        if(value != null && !value.isEmpty()) {
            return [(label): value]
        }
        return
    }

    /////////////////////////////////////////
    //  Format Star Input
    ////////////////////////////////////////
    public static String formatFastq1InputForStar(flowCellLaneLibraries) {
        def fastq1s = []
        flowCellLaneLibraries.each { flowCellLaneLibrary ->
            if (flowCellLaneLibrary.fastq1) {
                fastq1s.add(flowCellLaneLibrary.fastq1)
            }
            else {
                throw new Exception("There is no fastq1 defined for library: " + flowCellLaneLibrary.library)
            }
        }

        return fastq1s.join(",")
    }

    public static String formatFastq2InputForStar(flowCellLaneLibraries) {
        def fastq2s = []
        flowCellLaneLibraries.each { flowCellLaneLibrary ->
            if (flowCellLaneLibrary.fastq2) {
                fastq2s.add(flowCellLaneLibrary.fastq2)
            }
            else {
                throw new Exception("There is no fastq2 defined for library: " + flowCellLaneLibrary.library)
            }
        }

        return fastq2s.join(",")
    }

    public static String formatReadGroupInputForStar(sequencingCenter, sequencingPlatform, sampleId, flowCellLaneLibraries) {
        def readGroups = defineReadGroups(sequencingCenter, sequencingPlatform, sampleId, flowCellLaneLibraries)
        return readGroups.join(" , ")
    }
    
    public static defineReadGroups(sequencingCenter, defaultSequencingPlatform, sampleId, flowCellLaneLibraries) {

        // Set up default values 
        def defaultDate = new Date().format('yyyy-MM-dd')
        def defaultSequencingCenter = "Unknown"
 
        def readGroups = []
        flowCellLaneLibraries.eachWithIndex { flowCellLaneLibrary, index ->
            // Verify flowCell, lane and library are defined
            if (!flowCellLaneLibrary.flowCell || !flowCellLaneLibrary.lane || !flowCellLaneLibrary.library) {
                    throw new Exception("A flowCellLaneLibrary is missing a flowCell, lane or libary defintion")
            }

            // Set up the values need to build the tags            
            def flowCell = flowCellLaneLibrary.flowCell
            def lane = flowCellLaneLibrary.lane
            def library = flowCellLaneLibrary.library
            def dateString = flowCellLaneLibrary.runDate ? flowCellLaneLibrary.runDate : defaultDate
            def sequencingCenterString = sequencingCenter != null ? sequencingCenter : defaultSequencingCenter
            def sequencingPlatform = flowCellLaneLibrary.sequencingPlatform ? flowCellLaneLibrary.sequencingPlatform : defaultSequencingPlatform

            // Create the tags 
            def readGroupTags = []
            readGroupTags.add("ID:" + flowCell + "." + lane  + "." + library)
            readGroupTags.add("CN:" + sequencingCenterString)
            readGroupTags.add("PL:" + sequencingPlatform)
            readGroupTags.add("PU:" + flowCell + "." + lane  + "." + library)
            readGroupTags.add("LB:" + library)
            readGroupTags.add("SM:" + sampleId)
            // readGroupTags.add('"DT:' + dateString + '"')

            // Create the read group to the 
            readGroups.add("'@RG\\t" + readGroupTags.join("\\t") + "'")
        }

        return readGroups
    }

    public static defineReadGroup(sequencingCenter, defaultSequencingPlatform, sampleId, flowCellLaneLibrary) {

        // Set up default values 
        def defaultDate = new Date().format('yyyy-MM-dd')
 
        // Verify flowCell, lane and library are defined
        if (!flowCellLaneLibrary.flowCell || !flowCellLaneLibrary.lane || !flowCellLaneLibrary.library) {
                throw new Exception("A flowCellLaneLibrary is missing a flowCell, lane or libary defintion")
        }

        // Set up the values need to build the tags            
        def flowCell = flowCellLaneLibrary.flowCell
        def lane = flowCellLaneLibrary.lane
        def library = flowCellLaneLibrary.library
        def dateString = flowCellLaneLibrary.runDate ? flowCellLaneLibrary.runDate : defaultDate
        def sequencingPlatform = flowCellLaneLibrary.sequencingPlatform ? flowCellLaneLibrary.sequencingPlatform : defaultSequencingPlatform

        // Create the tags 
        def readGroupTags = []
        readGroupTags.add("ID:" + flowCell + "." + lane  + "." + library)
        readGroupTags.add("CN:" + sequencingCenter)
        readGroupTags.add("PL:" + sequencingPlatform)
        readGroupTags.add("PU:" + flowCell + "." + lane  + "." + library)
        readGroupTags.add("LB:" + library)
        readGroupTags.add("SM:" + sampleId)
        // readGroupTags.add('"DT:' + dateString + '"')

        return "'@RG\\t" + readGroupTags.join("\\t") + "'"
    }

    /////////////////////////////////////////
    //  Validation
    ////////////////////////////////////////
    public static validateInputParams(parameters) {

        // User
        if (!parameters.userId) {throw new Exception("userId is null or empty")}
        if (!parameters.userEmail) {throw new Exception("userEmail is null or empty")}

        // Sample
        if (!parameters.sampleId) {throw new Exception("sampleId is null or empty")}
        if (!parameters.sampleDirectory) {throw new Exception("sampleDirectory is null or empty")}

        // FastqxQC
        if (parameters.stepsToRun.contains("FastxQC")) {
            // FlowCellLaneLibraries
            verifyFlowCellLaneLibraries(parameters.flowCellLaneLibraries)
        }

        // STAR
        if (parameters.stepsToRun.contains("STAR")) {
            // FlowCellLaneLibraries
            verifyFlowCellLaneLibraries(parameters.flowCellLaneLibraries)

            // STAR files
            if (!parameters.starDirectory) {throw new Exception("starDirectory is null or empty")}
            if (!parameters.referenceGenome) {throw new Exception("referenceGenome is null or empty")}
            if (!parameters.rsemReferencePrefix) {throw new Exception("rsemReferencePrefix is null or empty")}
            if (!parameters.gtfFile) {throw new Exception("gtfFile is null or empty")}
        }

        // Analysis
        if (parameters.stepsToRun.contains("Analysis") && !parameters.stepsToRun.contains("STAR")) {
            def customAnalysisToRun = parameters.customAnalysisToRun

            // analysisStarBam - needed for QC, VCF, or BigWig
            if (!customAnalysisToRun || customAnalysisToRun.contains("QC") || customAnalysisToRun.contains("VCF") || customAnalysisToRun.contains("BigWig")) {
                if (!parameters.analysisStarBam) {throw new Exception("analysisStarBam is null or empty")}
            }

            // analysisTranscriptomeBam - needed for RSEM
            if (!customAnalysisToRun || customAnalysisToRun.contains("RSEM")) {
                if (!parameters.analysisTranscriptomeBam) {throw new Exception("analysisTranscriptomeBam is null or empty")}
            }

            // analysisSpliceJunctionsTab - needed for RSEM
            if (!customAnalysisToRun || customAnalysisToRun.contains("Junctions")) {
                if (!parameters.analysisSpliceJunctionsTab) {throw new Exception("analysisSpliceJunctionsTab is null or empty")}
            }
        }
    }

    private static verifyFlowCellLaneLibraries(flowCellLaneLibraries) {
        // FlowCellLaneLibraries
        if (!flowCellLaneLibraries) {throw new Exception("flowCellLaneLibraries is null or empty")}

        // FlowCellLaneLibrary required fields
        flowCellLaneLibraries.each { flowCellLaneLibrary ->
            if (!flowCellLaneLibrary.fastq1) {throw new Exception("fastq1 missing from flowCellLaneLibrary")}
            if (!flowCellLaneLibrary.fastq2) {throw new Exception("fastq2 missing from flowCellLaneLibrary")}
            if (!flowCellLaneLibrary.flowCell) {throw new Exception("flowCell missing from flowCellLaneLibrary")}
            if (!flowCellLaneLibrary.lane) {throw new Exception("lane missing from flowCellLaneLibrary")}
            if (!flowCellLaneLibrary.library) {throw new Exception("library missing from flowCellLaneLibrary")}
        }
    }
}