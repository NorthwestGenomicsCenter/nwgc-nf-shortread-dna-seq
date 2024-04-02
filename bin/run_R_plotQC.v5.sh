#!/bin/csh -f
#run R
R --no-save<<Eoi  # implemented June 12, 2012 Sean (along with xvfb-run in submit perl script)

flush.console()
ow <- options("warn")

# turn off scientific notation (do this only for each output file now)
#options(scipen=999)

rootDir <- "$1"
filePrefix <- "$2"

########################
#
#  some user options
#
plotOverlapLoss <- 0 # 1 to add small linear plot of fractional loss due to paired-end read overlap
useSangerColors <- 0 # primary colors for allele plots
forGeneralPublic <- 0 # remove some key elements to make the plot less busy for talks (0 standard)
noAsSingle <- 0 # remove asSingle plot and stats (0 standard)
writeOutputFiles <- 1 # 1 standard, use 0 for testing

########################

alleleNames <- c("A","T","C","G","N")
alleleColors <- c("red","pink","green","palegoldenrod","black")
if (useSangerColors == 1) {
	alleleColors <- c("green","red","blue","yellow","grey")
}

# size for text and axii
textCex <- 1.2
axisCex = 1.5
labelCex = 1.5
mainCex = 1.5

# for title bars
gap <- "          ";

#mapNamesAll <- c("total.incSoftClipped","total.excSoftClipped","mapped.incSoftClipped","mapped.excSoftClipped","onTarget.incSoftClipped","onTarget.excSoftClipped","unique.pe.incSoftClipped","unique.pe.excSoftClipped")
#mapSpacesAll <- c(0,-1,-0.2,-1,-0.2,-1,-0.2,-1)
mapNames <- c("total.incSoftClipped","mapped.incSoftClipped","onTarget.incSoftClipped","unique.pe")
mapNamesAll <- c("total","mapped","on target","clipped","uniques")
mapNames <- c("total","mapped","on target","uniques")
mapLabels <- c("total reads","human","on-target","uniques")
mapColorsAll <- c("lightgreen","seagreen4","lightblue","skyblue4","tan","salmon4","sienna1","orangered")
mapColors <- c("seagreen4","skyblue4","salmon4","orangered")
mapColorsAll <- c("seagreen4","skyblue4","tan","salmon4","orangered")
mapSpacesAll <- c(0,-0.2,-0.2,-1,-0.2)
mapSpaces <- c(0,-0.2,-0.2,-0.2)

# colors for paired and single-end uniqueness comparison
compColors <- c("blue","red")

ltitle=function(x,backcolor="#e8c9c1",forecolor="darkred",cex=2,ypos=0.4){

	par(mar = c(0, 0, 0, 0))
	plot(x=c(-1,1),y=c(0,1),xlim=c(0,1),ylim=c(0,1),type="n",axes=FALSE) 
	polygon(x=c(-2,-2,2,2),y=c(-2,2,2,-2),col=backcolor,border=NA) 
	text(x=0,y=ypos,pos=4,cex=cex,labels=x,col=forecolor) 
	#text(x=0.5*(par("usr")[2]-par("usr")[1]) + par("usr")[1],y=ypos,cex=cex,labels=x,col=forecolor) 

}

# for collecting some stats to plot in summary
coverageSummary <- c()
# default values to save
overlapFrac <- -9
exomeBp <- -9
wtMean <- -9
wtMeanWithZeroes <- -9
minBelow <- 100
totalBelow <- 100
psminBelow <- 100

# create the output file and dashboard file nonetheless (need for database and display)
outputFile <-paste(rootDir,"/qcFiles/",filePrefix,".rCoverageStats.txt", sep="")
output <- c("gt0","ge8")	
if (writeOutputFiles == 1) {
	write(output, outputFile, append = F, ncol = length(output))
}
# create an output file for coverage and complexity stats (stuff that's dependent on how uniqueness is determined)
rOutputFile <-paste(rootDir,"/qcFiles/",filePrefix,".rCovCompStats.txt", sep="")
rOutput <- c("cat","mean","ge8","ge20","q25","q50","q75")	
if (writeOutputFiles == 1) {
	write(rOutput, rOutputFile, append = F, ncol = length(rOutput))
}
# create an output file for misc stats (stuff that's NOT dependent on how uniqueness is determined)
miscOutputFile <-paste(rootDir,"/qcFiles/",filePrefix,".rMiscStats.txt", sep="")
miscOutput <- c("gt0","ovrlpLoss","exomeBp")	
if (writeOutputFiles == 1) {
	write(miscOutput, miscOutputFile, append = F, ncol = length(miscOutput))
}
# create an output file of q20s per chrom 
rQ20File <-paste(rootDir,"/qcFiles/",filePrefix,".rQ20sPerChrom.txt", sep="")
rQ20 <- c("chrom","avgQ20s")	
if (writeOutputFiles == 1) {
	write(rQ20, rQ20File, append = F, ncol = length(rQ20))
}
# create an output file of mean q20s per chrom (just one entry)
rMeanQ20File <-paste(rootDir,"/qcFiles/",filePrefix,".rMeanQ20s.txt", sep="")
rMeanQ20 <- c("mean")	
if (writeOutputFiles == 1) {
    write(rMeanQ20, rMeanQ20File, append = F, ncol = length(rMeanQ20))
}
# create an output file of insert size stats
rInsStatsFile <-paste(rootDir,"/qcFiles/",filePrefix,".rInsertSizeStats.txt", sep="")
rInsStats <- c("mean","median","stdDev","ovrlpLoss")	
if (writeOutputFiles == 1) {
    write(rInsStats, rInsStatsFile, append = F, ncol = length(rInsStats))
}
# create an output file of dup rate
rDupRateFile <-paste(rootDir,"/qcFiles/",filePrefix,".rDupRate.txt", sep="")
rDupRate <- c("dupRate")	
if (writeOutputFiles == 1) {
    write(rDupRate, rDupRateFile, append = F, ncol = length(rDupRate))
}
# create an output file for CSER stats
rCSERStatsFile <-paste(rootDir,"/qcFiles/",filePrefix,".rCSERStats.txt", sep="")
rCSERStats <- c("reads","fracAlligned","DupRate","meanCov","frac.ge.1x","frac.ge.10x","frac.ge.20x","frac.ge.30x","frac.ge.50x","frac.ge.100x","medianCov")	
if (writeOutputFiles == 1) {
    write(rCSERStats, rCSERStatsFile, append = F, ncol = length(rCSERStats))
}
# create an output file for uniformity of coverage
rUniformityOfCoverageStatsFile <-paste(rootDir,"/qcFiles/",filePrefix,".rUniformityOfCoverageStats.txt", sep="")
rUniformityOfCoverageStats <- c("covGT0.2xMean")	
if (writeOutputFiles == 1) {
    write(rUniformityOfCoverageStats, rUniformityOfCoverageStatsFile, append = F, ncol = length(rUniformityOfCoverageStats))
}


pngDir <- paste(rootDir, "/qcPlots", sep="")
filename <- paste(pngDir,"/",filePrefix,".qcSummaryPlots.v4.png", sep="")

mapFile <- paste(rootDir,"/qcFiles/",filePrefix,".readSummary.txt", sep="")


if (file.exists(mapFile)) { # does it exist?

    map <- read.table(mapFile, header = F, sep = "\t")

    if (length(map[,1]) > 1) { # are there any valid entries in it

 		read1File <- paste(rootDir,"/qcFiles/",filePrefix,".reads.read1.txt", sep="")
		reads1 <- as.matrix(read.table(read1File, header = T))
 		read2File <- paste(rootDir,"/qcFiles/",filePrefix,".reads.read2.txt", sep="")
		reads2 <- as.matrix(read.table(read2File, header = T))
		#
		gcFile <- paste(rootDir,"/qcFiles/",filePrefix,".gcBias.stats.txt", sep="")
		gc <- read.table(gcFile, header = TRUE)
		#
        covFile <- paste(rootDir,"/qcFiles/",filePrefix,".coverageUniformity.txt", sep="")
        cov <- read.table(covFile, header = T)
        #
        quals1File <- paste(rootDir,"/qcFiles/",filePrefix,".qualsBySite.read1.txt",sep = "")
        quals1 <- read.table(quals1File, header = F)
        quals2File <- paste(rootDir,"/qcFiles/",filePrefix,".qualsBySite.read2.txt",sep = "")
        quals2 <- read.table(quals2File, header = F)
        #
        q20sFile <- paste(rootDir,"/qcFiles/",filePrefix,".q20sByChrom.txt", sep="")
        q20s <- read.table(q20sFile, header = TRUE)
        #
        tgtSumFile <- paste(rootDir,"/qcFiles/",filePrefix,".targetSummary.txt", sep="")
        tgtSum<- read.table(tgtSumFile, header = TRUE)
        #
        allInsertFile <- paste(rootDir,"/qcFiles/",filePrefix,".insert.txt", sep="")
        allIns <- read.table(allInsertFile, header = T)
		#
        mapped <- map[,1] == "uniques"
        uniqueReads <- map[mapped,2]	
		#
        # get target
        targetFile <-paste(rootDir,"/qcFiles/",filePrefix,".target.txt", sep="")
        if (file.exists(targetFile)) { 
            targetMatrix <- read.table(targetFile)
            target <- targetMatrix[1,1]
        } else {
            target <- "NA"
        }
        
        jpeg(file=filename, width = 1600, height = 1070, units = "px",type=c("cairo"))
		layout(matrix(c(1,1,1,1,2,4,9,11,6,6,2,4,9,11,6,6,2,4,9,11,10,8,2,4,9,11,7,8,2,4,9,11,7,8,3,5),ncol=6), widths=c(2/22,5/22,3/22,3/22,8/22,1/22), heights=c(lcm(1),3/16,3.8/16,4.2/16,2.5/16,2.5/16))
        if (forGeneralPublic == 1) {
            layout(matrix(c(1,1,1,1,8,9,7,2,4,4,8,9,7,2,5,6,8,9,7,3,5,6,8,9),ncol=4), widths=c(2/20,7/20,12/20,1/20), heights=c(lcm(1),4/16,3.8/16,4.2/16,lcm(0.5),4/16))
        }
        
        #########################################
        # mapped or not (1)   (N) = location in layout matrix
        #########################################

        par(mar = c(8, 2, 4, 3) + 0.1)
        lastMap <- 0
        totalRdVec <- map[,1] == "total"
        mappedVec <- map[,1] == "mapped"
        onTargetVec <- map[,1] == "on target"
        uniqueVec <- map[,1] == "uniques"
        singleVec <- map[,1] == "single-ended"
        yUpper <- map[which(totalRdVec),2]
        yUpperStr <- sprintf("%3.0f",as.integer(yUpper))
        if (yUpper >= 1e3) {
            yUpperStr <- sprintf("%3.0f",as.integer(yUpper/1e3))
            yUpperStr <- paste(yUpperStr,"k",sep="")
        }
        if (yUpper >= 1e6) {
            yUpperStr <- sprintf("%3.0f",as.integer(yUpper/1e6))
            yUpperStr <- paste(yUpperStr,"M",sep="")
        }
        if (yUpper >= 1e9) {
            yUpperStr <- sprintf("%3.0f",as.integer(yUpper/1e9))
            yUpperStr <- paste(yUpperStr,"G",sep="")
        }

        total <- map[which(totalRdVec),2]
        totalToKeep <- total
        #
        # fractions 
        #
        mappedFracStr <- "NA"
        onTargetFracStr <- "NA"
        uniqueFracStr <- "NA"
        onTarget2MappedFracStr <- "NA"
        unique2MappedFracStr <- "NA"
        unique2OnTargetFracStr <- "NA"
        dupFrac <- "NA"
        if (map[which(totalRdVec),2] > 0) {
            mappedFracStr <- sprintf("%d",round(100*map[which(mappedVec),2]/map[which(totalRdVec),2]))
            onTargetFracStr <- sprintf("%d",round(100*map[which(onTargetVec),2]/map[which(totalRdVec),2]))
            uniqueFracStr <- sprintf("%d",round(100*map[which(uniqueVec),2]/map[which(totalRdVec),2]))
        }
        if (map[which(mappedVec),2] > 0) {
            onTarget2MappedFracStr <- sprintf("%d",round(100*map[which(onTargetVec),2]/map[which(mappedVec),2]))
            unique2MappedFracStr <- sprintf("%d",round(100*map[which(uniqueVec),2]/map[which(mappedVec),2]))
        }
        if (map[which(onTargetVec),2] > 0) {
            dupFrac <- (1 - map[which(uniqueVec),2]/map[which(onTargetVec),2])
            unique2OnTargetFracStr <- sprintf("%d",round(100*map[which(uniqueVec),2]/map[which(onTargetVec),2]))
        }
        mapVector <- c()
        for (mapResult in 1:length(mapNames)) { 	
            mapped <- map[,1] == mapNames[mapResult]
            mapVector[mapResult] <- map[mapped,2]
        }
        mapVectorAll <- c()
        for (mapResult in 1:length(mapNamesAll)) { 
			if (mapNamesAll[mapResult] == "clipped") {
				mapVectorAll[mapResult] <- map[map[,1] == "on target",2]    # default to same value
				if (map[map[,1] == "mapped bases",2] > 0) {
					mapVectorAll[mapResult] <- map[map[,1] == "on target",2]*(map[map[,1] == "clean bases",2]/map[map[,1] == "mapped bases",2])
				}
			} else {
            	mapped <- map[,1] == mapNamesAll[mapResult]
            	mapVectorAll[mapResult] <- map[mapped,2]
			}
        }
        #barplot(mapVectorAll, col = mapColorsAll, ylim = c(0,yUpper), xlab="",ylab="",main="", axes = F,beside = T, space = mapSpaces)
        barplot(mapVector, col = mapColors, ylim = c(0,yUpper), xlab="",ylab="",main="", axes = F,beside = T, space = mapSpaces)
        mainTitle <- paste("mapping\nsummary", sep="")
        title(xlab = "", ylab = "", main = mainTitle, cex.main = mainCex)
        yUpperStr <- "100%"
        ticLength <- 0.1*(par("usr")[2] - par("usr")[1])
        xTicHi <- par("usr")[2]
        xTicLo <- par("usr")[2] - ticLength
        lines(c(xTicLo,xTicHi), c(yUpper,yUpper), xpd = TRUE)
        text(par("usr")[2],par("usr")[4] , labels = yUpperStr, xpd = TRUE, cex = textCex, pos = 4)
        abline(h=par("usr")[3])
        text(par("usr")[2],par("usr")[3] , labels = "0", xpd = TRUE, cex = textCex, pos = 4)
        #
        # display fractions 
        #
        yFracDrop <- 0.02*(par("usr")[4] - par("usr")[3]) + par("usr")[3]
        cexFrac <- 1.5
        colFrac <- "white"
        xFracPos <- 0.14*(par("usr")[2] - par("usr")[1]) + par("usr")[1]
        text(xFracPos, map[which(totalRdVec),2], labels = "%", xpd = TRUE, cex = cexFrac, pos = 1, col = colFrac)
        xFracPos <- 0.36*(par("usr")[2] - par("usr")[1]) + par("usr")[1]
        text(xFracPos, map[which(mappedVec),2], labels = mappedFracStr, xpd = TRUE, cex = cexFrac, pos = 1, col = colFrac)
        xFracPos <- 0.57*(par("usr")[2] - par("usr")[1]) + par("usr")[1]
        text(xFracPos, map[which(onTargetVec),2], labels = onTargetFracStr, xpd = TRUE, cex = cexFrac, pos = 1, col = colFrac)
        xFracPos <- 0.80*(par("usr")[2] - par("usr")[1]) + par("usr")[1]
        text(xFracPos, map[which(uniqueVec),2], labels = uniqueFracStr, xpd = TRUE, cex = cexFrac, pos = 1, col = colFrac)

        par(new = F)

        # add some tick marks to signify the fraction of reads
        tics <- 10
        ticMutliplier <- 1 
        ticSize <- 0.08*ticMutliplier
        ticLength <- ticSize*(par("usr")[2] - par("usr")[1])
        xTicLo <- par("usr")[2] - ticLength
        xTicHi <- par("usr")[2]
        for (i in 1:(tics-1)) {
            yTic <- (i/tics)*(par("usr")[4] - par("usr")[3]) + par("usr")[3]
            if (i == 5) {
                yTicStr <- "50%"
                text(par("usr")[2],yTic , labels = yTicStr, xpd = TRUE, cex = textCex, pos = 4)
            }
            lines(c(xTicLo,xTicHi), c(yTic,yTic), xpd = TRUE)
        }
        #
        # draw tick mark showing fraction unpaired reads
        #
        fracUnpaired <- map[which(singleVec),2]/map[which(onTargetVec),2]
        yTic <- (fracUnpaired)*(par("usr")[4] - par("usr")[3]) + par("usr")[3]
        lines(c(xTicLo+0.5*ticLength,xTicHi), c(yTic,yTic), xpd = TRUE, col = mapColors[2], lwd = 4)
        text(xTicHi,yTic , labels = "SE", xpd = TRUE, cex = textCex,col = mapColors[2], pos = 4)

        mapKeyCounter <- 1
        for (j in  1:length(mapNames)) {

            label <- paste(mapLabels[j],": ",sep = "")
            numberStr <- format(mapVector[j], big.mark = ",")

            ylocation <- par("usr")[3] - j*0.02*par("usr")[4] 
            xOffset <- par("usr")[2] - par("usr")[1] 
            text(par("usr")[1] - 0.10*xOffset, ylocation, labels = label, col = mapColors[j], xpd = TRUE, cex = textCex, pos = 4)
            text(par("usr")[2] + 0.10*xOffset, ylocation, labels = numberStr, col = mapColors[j], xpd = TRUE, cex = textCex, pos = 2)

        }
        #ylocation <- par("usr")[3] - (length(mapNames) + 1)*0.02*par("usr")[4] 
        #text(0.5*(par("usr")[2] - par("usr")[1]) + par("usr")[1], ylocation, labels = "(lighter shades: soft-clipped)", col = "black", xpd = TRUE, cex = textCex)
        ylocation <- par("usr")[3] - (length(mapNames) + 1)*0.02*par("usr")[4] 
        text(0.5*(par("usr")[2] - par("usr")[1]) + par("usr")[1], ylocation, labels = "(SE = fraction single-ended)", col = mapColors[2], xpd = TRUE, cex = textCex)

        if (writeOutputFiles == 1) {
            options(scipen=999)
            write(dupFrac, rDupRateFile, append = T, ncol = 1)  # only entry in this file so append = F
            options(scipen=0)
        }

        #########################################
        # alleles at read positions - read 1 (2)
        #########################################

        par(mar = c(4, 0, 3, 0))
        alleles <- t(reads1)
        barplot(alleles, beside = T, col = alleleColors, xlab = "", ylab = "", main = "",axes = F, cex.names = textCex)
        mainTitle <- paste("allele distribution per cycle", sep="")
        title(xlab = "", ylab = "read 1", main = mainTitle, cex.main = mainCex, cex.lab = labelCex, xpd = T)
        legend(0.97*par("usr")[2],0.7*par("usr")[4],alleleNames, fill = alleleColors, bg = "white", cex = textCex, xpd = T)
		readLabelSize <- 2
		yLabPosy <- 0.5*(par("usr")[4]-par("usr")[3])+par("usr")[3]
		yLabPosx <- 0.02*(par("usr")[2]-par("usr")[1])+par("usr")[1]
		text(yLabPosx, yLabPosy, "read\n1", cex = readLabelSize, xpd = T, font = 2)
		
        sumOfAlleles <- c()
        cycles <- length(alleles[1,])
        for (i in 1:length(alleles[,1])) {
            sumOfAlleles[i] <- sum(as.numeric(alleles[i,]), na.rm = T)
        }
        
        #########################################
        # overall allele dist (3) 
        #########################################

        par(mar = c(4, 0.5, 3, 1) + 0.1)
        barplot(sumOfAlleles, beside = T, col = alleleColors, xlab = "", ylab = "", main = "",space = 0, axes = F)
        mainTitle <- paste("overall", sep="")
        title(xlab = "", ylab = "", main = mainTitle, cex.main = mainCex, cex.lab = labelCex)
 

        #########################################
        # alleles at read positions - read 2 (4)
        #########################################

        par(mar = c(5, 0, 2, 0))
        alleles <- t(reads2)
        barplot(alleles, beside = T, col = alleleColors, xlab = "", ylab = "", main = "",axes = F, cex.names = textCex)
        mainTitle <- paste("allele distribution per cycle", sep="")
        title(xlab = "cycle", ylab = "read 2", main = "", cex.main = mainCex, cex.lab = labelCex)
		yLabPosy <- 0.5*(par("usr")[4]-par("usr")[3])+par("usr")[3]
		text(yLabPosx, yLabPosy, "read\n2", cex = readLabelSize, xpd = T, font = 2)

        sumOfAlleles <- c()
        for (i in 1:length(alleles[,1])) {
            sumOfAlleles[i] <- sum(as.numeric(alleles[i,]), na.rm = T)
        }
        
        #########################################
        # overall allele dist (5) 
        #########################################

        par(mar = c(5, 0.5, 2, 1) + 0.1)
        barplot(sumOfAlleles, beside = T, col = alleleColors, xlab = "", ylab = "", main = "",space = 0, axes = F)

        #########################################
        # GC content (6) 
        #########################################

		par(mar = c(5, 5, 4, 5))

		qColor <- c("red")
		#gcWindowColor <- c("powderblue")
		gcWindowColor <- c("darkgreen")
		gcWindowColor <- c("darkolivegreen4")
		normCovColor <- c("blue")

		if (length(gc[,5]) > 0) {
		#
		#  normalized coverage
		#

			plot(gc[,5]~gc[,1], ylim = c(0,2), pch = 15, col = normCovColor, xlab = "GC% of 100 bp windows", ylab = "fraction of normalized coverage", main = "",axes = T, cex.lab = labelCex, cex.axis = axisCex)
			# hack: we draw arrows but with very special "arrowheads" for error bars
			arrows(gc[,1], gc[,5]-gc[,6], gc[,1], gc[,5]+gc[,6], length=0.05, angle=90, code=3)
			abline(v = 50, lty = "dashed", col = "gray")
			abline(h = 1, lty = "dashed", col = "gray")
			par(new = T)


		#
		#  GC windows
		#
			rangeStart <- 0
			rangeStop <- 100
			rangeVec <- gc[,1] > rangeStart & gc[,1] < rangeStop
			yMax <- 4*max(gc[rangeVec,2])

			xx <- c(rev(gc[rangeVec,1]), gc[rangeVec,1])
			yy <- c(c(1:length(gc[rangeVec,1])*0), gc[rangeVec,2])
			plot(gc[,2]~gc[,1], type = "l", ylim = c(0,yMax), col = gcWindowColor, xlab = "", ylab = "", main = "",axes = F)
			polygon(xx, yy, col = gcWindowColor, border=NA)
			par(new = T)


		#
		#  mean Q
		#

			plot(gc[,4]~gc[,1], type = "l", ylim = c(0,40), col = qColor, lwd = 3, xlab = "", ylab = "", main = "",axes = F)
			#par(new = T)
		    title(main = "GC content", cex.main = mainCex)
			qVec <- seq(0,40,by = 10)
		    axis(4, qVec, at = qVec,  col = qColor, col.ticks = qColor, cex.axis = axisCex, col.axis = qColor, xpd = F)
		    mtext("mean base quality", side=4, line=3, col = qColor, cex = labelCex)
			
			legendText <- c("normalized coverage","mean base quality","window at GC%")
			legendColors <- c(normCovColor,qColor,gcWindowColor)
			legend("topleft", inset = 0.05, legendText, fill = legendColors, cex = labelCex)
        
        } else { # fail GC plot

            compFail <- c()
            for (i in 1:20) {
                compFail[i] <- 0
            }
            
			message <- "FAILED\nTO PLOT"
            
            barplot(compFail, ylim = c(0,1), xlab = "", ylab = "", main = "", cex.axis = axisCex)
            text(par("usr")[2]/2,par("usr")[4]/2,message, cex = 5)
            
        }


        #########################################
        # insert size (7) 
        #########################################

        if (plotOverlapLoss == 1) { # need to make room for axis on right
            par(mar = c(4, 3, 5, 4) + 0.1)
        } else {
            par(mar = c(4, 3, 5, 1) + 0.1)
        }
        insertColors <- c(mapColors[1])
        #
        pairs <- 0
        if (file.exists(allInsertFile)) {
            if (file.info(allInsertFile)\$size > 0) {
                pairs <- sum(as.numeric(allIns[1:length(allIns),2]), na.rm = T)
            } 
        }
        if (pairs == 0) {
            inserts <- c()
            for (i in 1:20) {
                inserts[i] <- 0
            }
            if (sum(as.numeric(inserts[1:length(inserts)]), na.rm = T) == 0) {
                titleText <- "insert size distribution"
                titleText <- paste(titleText,"(NOT AVAILABLE -- NO PAIRED-END READS?)")
            }
            barplot(inserts, col = "blue", xlab = "", ylab = "", main = "", cex.axis = axisCex)

            if (writeOutputFiles == 1) {
                options(scipen=999)
                rInsStats <- c(-9,-9,-9,-9)
                write(rInsStats, rInsStatsFile, append = T, ncol = length(rInsStats))
                options(scipen=0)
            }

        } else {
        
            # calculate median (need to expand insert file as data points)
            allInsValues <- sum(as.numeric(allIns[,2]))
            insertCounter <- 0
			for (i in 1:length(allIns[,1])) {
                insertCounter <- as.numeric(insertCounter) + as.numeric(allIns[i,2])
                if (as.numeric(as.numeric(insertCounter)/as.numeric(allInsValues)) >= 0.5) {
                    allInsMedian <- allIns[i,1]
                    break
                }
            }

            xUpper <- 3*allInsMedian
            #xUpper <- max(allIns[,1])
            xLower <- min(allIns[allIns[,1] > 0,1])
            #
            insVec <- allIns[,1] >= xLower & allIns[,1] <= xUpper
            plot(allIns[insVec,2]~allIns[insVec,1], axes = F, type = "l", lwd = 2, col =	insertColors[1], xlab="",ylab="",main="", xlim = c(xLower,xUpper))
            par(new = T)
            plot(allIns[insVec,2]~allIns[insVec,1], yaxt = "n", type = "l", lwd = 2, col =	insertColors[2], xlab="",ylab="",main="", xlim = c(xLower,xUpper), cex.axis = axisCex)
            # calculate means
            allInsSum <- format(sum(as.numeric(allIns[,2]), na.rm = T), big.mark = ",")
            totalRds <- map[map[,1] == "total",2]
            targets <- map[map[,1] == "onTarget",2]
            allInsFrac <- sprintf("%4.1f",100*sum(as.numeric(allIns[,2]), na.rm = T)/totalRds)
            allInsSum <- paste(allInsSum," (",allInsFrac,"% of all reads)",sep = "")
            #legend("topright", title = "total valid paired-ends", legend =  c(allInsSum), fill= insertColors, bg="white", cex = 1.5, inset = 0.05)
            # calculate standard deviation
            allInsMean <- as.numeric(weighted.mean(allIns[insVec,1],allIns[insVec,2]), na.rm = T)
            insertSizes <- 0
            sumOfDeviations <- 0
            for (insertSize in 1:length(allIns[insVec,1])) {
                if (allIns[insertSize,1] > 0) {
                    insertSizes <- insertSizes + allIns[insertSize,2]
                    sumOfDeviations <- sumOfDeviations + as.numeric(allIns[insertSize,2]*((allIns[insertSize,1] - allInsMean)*(allIns[insertSize,1] - allInsMean)))
                }
            }
            allStdDev <- 0
            if (insertSizes > 0) {
                allStdDev <- sqrt(as.numeric(sumOfDeviations/(insertSizes - 1)))
            }
            allMeanText <- sprintf("%5.1f",allInsMean)
            allMeanText <- paste("mean = ",allMeanText," bp", sep = "")
            text(0.7*(par("usr")[2] - par("usr")[1]) + par("usr")[1],0.8*(par("usr")[4]-par("usr")[3]) + par("usr")[3], allMeanText,cex = 1.5,pos = 4)				
            allMedianText <- sprintf("%3d",allInsMedian)
            allMedianText <- paste("median = ",allMedianText," bp", sep = "")
            text(0.7*(par("usr")[2] - par("usr")[1]) + par("usr")[1],0.7*(par("usr")[4]-par("usr")[3]) + par("usr")[3], allMedianText,cex = 1.5,pos = 4)				
            allStdDevText <- sprintf("%4.1f",allStdDev)
            allStdDevText <- paste("standard deviation = ",allStdDevText," bp", sep = "")
            text(0.7*(par("usr")[2] - par("usr")[1]) + par("usr")[1],0.6*(par("usr")[4]-par("usr")[3]) + par("usr")[3], allStdDevText,cex = 1.5,pos = 4)				


            # calculate fractional loss to paired-end overlap (on-target reads only)
            overlapVec <- allIns[,1] < 2*cycles 
            overlapFrac <- sum(as.numeric(allIns[overlapVec,2]*(2*cycles - allIns[overlapVec,1])), na.rm = T)/(2*cycles*sum(as.numeric(allIns[,2]), na.rm = T))
            overlapFracStr <- sprintf("%4.1f",100*overlapFrac)
            overlapText <- paste("overlap loss: ",overlapFracStr,"%",sep = "")
            text(0.7*(par("usr")[2] - par("usr")[1]) + par("usr")[1],0.5*(par("usr")[4]-par("usr")[3]) + par("usr")[3], overlapText,cex = 1.5,pos = 4)		
            if (plotOverlapLoss == 1) { # plots the straight line representing fractional loss for each insert size
                par(new=T)
                plot(allIns[overlapVec,2]*(2*cycles - allIns[overlapVec,1])/(2*cycles*allIns[overlapVec,2])~allIns[overlapVec,1],type = "l", col = "red", lty = "dashed",xlim = c(xLower,xUpper), ylim = c(0,.5), xlab="",ylab="",main="",yaxt = "n",xaxt = "n")
                axis(4,col = "red",col.axis ="red", ylab = "loss")
            }
            
            titleText <- "insert size distribution"
			if (writeOutputFiles == 1) {
                options(scipen=999)
                rInsStats <- c(allInsMean,allInsMedian,allStdDev,overlapFrac)
                write(rInsStats, rInsStatsFile, append = T, ncol = length(rInsStats))
                options(scipen=0)
            }
        }
        mainTitle <- paste(titleText, sep="") # in case it's needed
        par(adj = 1)
        title(xlab = "end-end width (bp)", cex.lab = labelCex)
        par(adj = 0.5)
        title(ylab = "", main = mainTitle, cex.main = mainCex)


        #########################################
        # uniformity (8) 
        #########################################

        par(mar = c(6, 4, 3, 1) + 0.1)	
        minToPlot <- 1
        minDepth <- 8 # for SNP calls
        quarts <- c(1:3/4)	
        quartColors <- c("gray61","gray71","gray81","gray91")
        psquartColors <- c("pink3","pink2","pink1","pink")
        quartiles <- c()
        fullquartiles <- c()
        psquartiles <- c()
        for (q in 1:length(quarts)){ # default values
            quartiles <- -99
            fullquartiles <- -99
            psquartiles <-  -99
        }
        
        # may change if plotting individual stats
        #uniformity_maxUpper <- 2*length(reads1[,1])
        uniformity_maxUpper <- 100
        
        if (length(cov[,2]) > 1) {

	        vec <- cov[,1] >= minToPlot
	        if ( as.logical(max(cov[vec,2]))) {
	            yUpper <- 1.1*max(cov[vec,2])
	        } else {
	            yUpper <- 1
	        }
	        peakCoverage <- which.max(cov[vec,2])
	        if (peakCoverage*3 > uniformity_maxUpper) {
	            uniformity_xUpper <- peakCoverage*3
	        } else {
	            uniformity_xUpper <- uniformity_maxUpper
	        }
	        plot(cov[vec,2]~cov[vec,1], type = "l", lwd = 2, col = compColors[1], xlab = "", ylab = "", main = "", xlim  = c(0,uniformity_xUpper), ylim  = c(0,yUpper), cex.axis = axisCex, axes = F)

	        mainTitle <- paste("target coverage uniformity (zero coverage excluded from plot)", sep="")
	        par(adj = 1)
	        title(xlab = "coverage", cex.lab = labelCex)
	        par(adj = 0.5)
	        title(ylab = "bases", main = mainTitle, cex.main = mainCex, cex.lab = labelCex)
	        # find fraction with zero coverage
	        zeroCov <- cov[(cov[,1] == 0),2]
	        if (sum(as.numeric(cov[,1] == 0), na.rm = T) == 0) {
	            zeroCov <- 0
	        }
	        exomeBp <- sum(as.numeric(cov[,2]), na.rm = T)
	        coverageSummary[1] <- zeroCov/exomeBp
	        zeroStr <- sprintf("%4.1f", 100*zeroCov/exomeBp)
	        zeroStr <- paste(zeroStr,"%",sep = "")
	        # quartiles
	        reduced <- cov[vec,2]
	        #quartSums <- sum(as.numeric(reduced), na.rm = T)*quarts
	        quartSums <- sum(as.numeric(cov[(minToPlot+1):length(cov[,2]),2]), na.rm = T)*quarts
	        #for (j in (length(quarts)):1) {
		    for (j in (length(quarts) + 1):1) {
	            wrote <- 0
	            for (i in 1:length(cov[,2])) {
	                if (sum(as.numeric(cov[(minToPlot+1):i,2]), na.rm = T) > quartSums[j] && wrote == 0 || j == (length(quarts) + 1)) {
	                    if (j < (length(quarts) + 1)) {
	                        quartiles[j] <- sprintf("%4.1f",cov[i,1])
	                        wrote <- 1
	                    }
	                    yy <- c(c((minToPlot+1):i*0), cov[i:(minToPlot+1),2])
	                    xx <- c(cov[(minToPlot+1):i,1], cov[i:(minToPlot+1),1])
	                    polygon(xx, yy, col = quartColors[j], border=NA)
						
	                }
	            }
	        }
	        full <- cov[,2]
	        fullquartSums <- sum(as.numeric(full), na.rm = T)*quarts
	        for (j in (length(quarts) + 1):1) {
	            wrote <- 0
	            for (i in 1:length(full)) {
	                if (sum(as.numeric(full[1:i]), na.rm = T) > fullquartSums[j] && wrote == 0 || j == (length(quarts) + 1)) {
	                    if (j < (length(quarts) + 1)) {
	                        fullquartiles[j] <- sprintf("%4.1f",cov[i,1])
	                        wrote <- 1
	                    }
	                }
	            }
	        }
	        minDepth <- 10
	        m20Depth <- 20
			for (i in 1:length(cov[,1])) {
				if (cov[i,1] <= minDepth) { # do this each time, but only the last time will count
					minSum <- sum(as.numeric(cov[(minToPlot+1):i,2]), na.rm = T)
					extraSites <- 0
					if (cov[(i+1),1] > minDepth){ 					
						extraSites <- cov[(i+1),2]*(minDepth - cov[i,1])/(cov[(i+1),1] - cov[i,1]) # interpolate to next point to get closer to true number of sites						
				 	}
					allSum <- minSum + extraSites
			        minBelow <- 100*allSum/sum(as.numeric(cov[(minToPlot+1):length(cov[,2]),2]), na.rm = T)
				}
				if (cov[i,1] <= m20Depth) { # do this each time, but only the last time will count
					m20Sum <- sum(as.numeric(cov[(minToPlot+1):i,2]), na.rm = T)					
					extra20Sites <- 0
					if (cov[(i+1),1] > m20Depth){ 					
						extra20Sites <- cov[(i+1),2]*(m20Depth - cov[i,1])/(cov[(i+1),1] - cov[i,1]) # interpolate to next point to get closer to true number of sites
					}
					all20Sum <- m20Sum + extra20Sites
			        m20Below <- 100*all20Sum/sum(as.numeric(cov[(minToPlot+1):length(cov[,2]),2]), na.rm = T)
				}
				
			}
	        minStr  <- sprintf("%4.1f", (100-minBelow))
	        minStr <- paste(minStr,"%",sep = "")
	        m20Str  <- sprintf("%4.1f", (100-m20Below))
	        m20Str <- paste(m20Str,"%",sep = "")
	        coverageSummary[2] <- (allSum + zeroCov)/exomeBp
	        totalBelow <- 100*(allSum + zeroCov)/exomeBp
	        totalStr <- sprintf("%4.1f", (100-totalBelow))
	        totalStr <- paste("(",totalStr,"%)",sep = "")
	        totalBelow20 <- 100*(all20Sum + zeroCov)/exomeBp
	        total20Str <- sprintf("%4.1f", (100-totalBelow20))
	        total20Str <- paste("(",total20Str,"%)",sep = "")
	        #minStr <- paste(minStr,"% (",totalStr,"%) < ", minDepth," (min for SNPs)",sep = "")
	        #text(0.7*par("usr")[2],(0.7-(length(quarts)+1.5)*0.1)*par("usr")[4], minStr,cex = 1.5,pos = 4)
	        text(1,0.05*par("usr")[4],"quartiles", pos = 4, cex = textCex) 

	        # re-plot coverage lines above everything (dashed for pseudo so it appears to be in th background)
	        par(new=T)
	        plot(cov[vec,2]~cov[vec,1], type = "l", lwd = 2, col = compColors[1], xlab = "", ylab = "", main = "", xlim  = c(0,uniformity_xUpper), ylim  = c(0,yUpper), cex.axis = axisCex)
	        # calc and display mean
	        wtMean <- weighted.mean(cov[vec,1],cov[vec,2])
	        wtMeanStr <- sprintf("%4.1f", wtMean)
	        wtMeanStr <- paste(wtMeanStr,"x",sep = "")
	        wtMeanWithZeroes <- weighted.mean(cov[,1],cov[,2])
	        wtMeanWithZeroesStr <- sprintf("%4.1f", wtMeanWithZeroes)
	        wtMeanWithZeroesStr <- paste("(",wtMeanWithZeroesStr,"x)",sep = "")

	        # calc and display median
	        peCovValues <- sum(as.numeric(cov[,2]))
	        peCovCounter <- 0
	        peCovMedian <- 0
	        for (i in 1:length(cov[,1])) {
	            peCovCounter <- as.numeric(peCovCounter) + as.numeric(cov[i,2])
	            if (as.numeric(as.numeric(peCovCounter)/as.numeric(peCovValues)) >= 0.5) {
	                peCovMedian <- cov[i,1]
	                break
	            }
	        }
	        peCovMedianStr <- paste("(",as.integer(peCovMedian),"x)",sep = "")

	        # following true as long at minToPlot = 1 above
	        peCovNoZeroValues <- sum(as.numeric(cov[vec,2]))
	        peCovNoZeroCounter <- 0
	        peCovNoZeroMedian <- 0
	        for (i in which(vec)) {
	            peCovNoZeroCounter <- as.numeric(peCovNoZeroCounter) + as.numeric(cov[i,2])
	            if (as.numeric(as.numeric(peCovNoZeroCounter)/as.numeric(peCovNoZeroValues)) >= 0.5) {
	                peCovNoZeroMedian <- cov[i,1]
	                break
	            }
	        }
	        peCovNoZeroMedianStr <- paste(as.integer(peCovNoZeroMedian),"x",sep = "")

	        # in table form
	        tableXLocs <- c(0.7,0.87,0.95)
	        tableYTop <- 0.9
	        tableYStep <- 0.1
	        tableYLoc <- tableYTop
	        # means
	        text(tableXLocs[1]*par("usr")[2],tableYLoc*par("usr")[4],"mean (inc 0x):",cex = 1.5,pos = 4)
	            text(tableXLocs[2]*par("usr")[2],tableYLoc*par("usr")[4],wtMeanStr,cex = 1.5, col = compColors[1])
	            text(tableXLocs[3]*par("usr")[2],tableYLoc*par("usr")[4],wtMeanWithZeroesStr,cex = 1.5, col = compColors[1])
	        tableYLoc <- tableYLoc - tableYStep
	        # means
	        text(tableXLocs[1]*par("usr")[2],tableYLoc*par("usr")[4],"median:",cex = 1.5,pos = 4)
	        text(tableXLocs[2]*par("usr")[2],tableYLoc*par("usr")[4],peCovNoZeroMedianStr,cex = 1.5, col = compColors[1])
	        text(tableXLocs[3]*par("usr")[2],tableYLoc*par("usr")[4],peCovMedianStr,cex = 1.5, col = compColors[1])
	        tableYLoc <- tableYLoc - tableYStep
	        # quartiles  
		    quartStrs <- c()
		    quartStrs[1] <- expression("75%" >= "")
		    quartStrs[2] <- expression("50%" >= "")
		    quartStrs[3] <- expression("25%" >= "")
	        for (j in 1:(length(quarts))) { 
	            text(0.7*par("usr")[2],tableYLoc*par("usr")[4], quartStrs[j],cex = 1.5,pos = 4)		
	            quartilesStr <- paste ("",quartiles[j],"x",sep = "")
	            text(tableXLocs[2]*par("usr")[2],tableYLoc*par("usr")[4],quartilesStr,cex = 1.5, col = compColors[1])
	            fullquartilesStr <- paste ("(",fullquartiles[j],"x)",sep = "")
	            text(tableXLocs[3]*par("usr")[2],tableYLoc*par("usr")[4],fullquartilesStr,cex = 1.5, col = compColors[1])
	            tableYLoc <- tableYLoc - tableYStep
	        }
	        # SNP depth
		    gt8Text <- expression("target" >= "10x") 
		    gt20Text <- expression("target" >= "20x") 



	        text(tableXLocs[1]*par("usr")[2],tableYLoc*par("usr")[4],gt8Text,cex = 1.5,pos = 4)
	        text(tableXLocs[2]*par("usr")[2],tableYLoc*par("usr")[4],minStr,cex = 1.5, col = compColors[1])
	        text(tableXLocs[3]*par("usr")[2],tableYLoc*par("usr")[4],totalStr,cex = 1.5, col = compColors[1])
	        tableYLoc <- tableYLoc - tableYStep
	        # depth 20 stats
	        text(tableXLocs[1]*par("usr")[2],tableYLoc*par("usr")[4],gt20Text,cex = 1.5,pos = 4)
	            text(tableXLocs[2]*par("usr")[2],tableYLoc*par("usr")[4],m20Str,cex = 1.5, col = compColors[1])
	            text(tableXLocs[3]*par("usr")[2],tableYLoc*par("usr")[4],total20Str,cex = 1.5, col = compColors[1])
	        tableYLoc <- tableYLoc - tableYStep
	        # 0x stats 
	        zeroStr <- paste("(zero coverage: ",zeroStr," of target)",sep = "")
	        text(tableXLocs[2]*par("usr")[2],tableYLoc*par("usr")[4],zeroStr,cex = 1.5)
	        tableYLoc <- tableYLoc - tableYStep

	        covFull <- sum(as.numeric(cov[,2]))
	        if (covFull > 0) {
	            covGe1 <- sprintf("%6.4f",((sum(as.numeric(cov[(cov[,1] >= 1),2]))/covFull)))
	            covGe10 <- sprintf("%6.4f",((sum(as.numeric(cov[(cov[,1] >= 10),2]))/covFull)))
	            covGe20 <- sprintf("%6.4f",((sum(as.numeric(cov[(cov[,1] >= 20),2]))/covFull)))
	            covGe30 <- sprintf("%6.4f",((sum(as.numeric(cov[(cov[,1] >= 30),2]))/covFull)))
	            covGe50 <- sprintf("%6.4f",((sum(as.numeric(cov[(cov[,1] >= 50),2]))/covFull)))
	            covGe100 <- sprintf("%6.4f",((sum(as.numeric(cov[(cov[,1] >= 100),2]))/covFull)))
	        }

	        allReads <- map[which(map[,1] == "total"),2]
	        allignedReads <- map[which(map[,1] == "mapped"),2]
	        fracAlligned <- sprintf("%6.4f",((allignedReads/allReads)))

	        wtMeanFull <- weighted.mean(cov[,1],cov[,2])
	        wtMeanFullStr <- sprintf("%4.1f", wtMeanFull)
	        dupRateStr <- sprintf("%6.4f",dupFrac)

	        uniformityOfCoverage <- sprintf("%6.4f",((sum(as.numeric(cov[(cov[,1] >= 0.2*wtMean),2]))/covFull)))

	        if (writeOutputFiles == 1) {
	            options(scipen=999)
	            rOutput <- c("asPairs",wtMean,(1-(minBelow/100)),(1-(m20Below/100)),quartiles[1],quartiles[2],quartiles[3])
	            write(rOutput, rOutputFile, append = T, ncol = length(rOutput))
	            w0Output <- c("with0x",wtMeanWithZeroes,(1-(totalBelow/100)),(1-(totalBelow20/100)),fullquartiles[1],fullquartiles[2],fullquartiles[3])
	            write(w0Output, rOutputFile, append = T, ncol = length(w0Output))
	            rCSERStats<- c(allReads,fracAlligned,dupRateStr,wtMeanFullStr,covGe1,covGe10,covGe20,covGe30,covGe50,covGe100,peCovMedian)
	            write(rCSERStats, rCSERStatsFile, append = T, ncol = length(rCSERStats), sep="\t")
	            rUniformityOfCoverageStats<- c(uniformityOfCoverage)
	            write(rUniformityOfCoverageStats, rUniformityOfCoverageStatsFile, append = T, ncol = length(rUniformityOfCoverageStats), sep="\t")
        
	            miscOutput <- c((1-coverageSummary[2]), overlapFrac, exomeBp)	
	            write(miscOutput, miscOutputFile, append = T, ncol = length(miscOutput))
	            options(scipen=0)
	        }
        
        } else { # fail coverage plot
            covFail <- c()
            for (i in 1:20) {
                covFail[i] <- 0
            }

            message <- "FAILED TO PLOT"
            barplot(covFail, ylim = c(0,1), xlab = "", ylab = "", main = "", cex.axis = axisCex)
            text(par("usr")[2]/2,par("usr")[4]/2,message, cex = 5)

            if (writeOutputFiles == 1) {
                options(scipen=999)
                rOutput <- c("asPairs",-9,-9,-9,-9,-9,-9)
                write(rOutput, rOutputFile, append = T, ncol = length(rOutput))
                w0Output <- c("with0x",-9,-9,-9,-9,-9,-9)
                write(w0Output, rOutputFile, append = T, ncol = length(w0Output))
                psOutput <- c("asSingles",-9,-9,-9,-9,-9,-9)
                write(psOutput, rOutputFile, append = T, ncol = length(psOutput))
                rCSERStats<- c(-9,-9,-9,-9,-9,-9,-9,-9,-9,-9,-9)
                write(rCSERStats, rCSERStatsFile, append = T, ncol = length(rCSERStats), sep="\t")
                rUniformityOfCoverageStats<- c(-9)
                write(rUniformityOfCoverageStats, rUniformityOfCoverageStatsFile, append = T, ncol = length(rUniformityOfCoverageStats), sep="\t")

                miscOutput <- c(-9,-9,-9,-9,-9,-9,-9,-9,-9)	
                write(miscOutput, miscOutputFile, append = T, ncol = length(miscOutput))
                options(scipen=0)
            }

        }

        #########################################
        # title (9)
        #########################################

        ltitle(paste("-- Quality Control Summary --",gap," sample: ",filePrefix,gap,"target: ",target, sep=""),cex=1.6,ypos=0.4)        

 

        #########################################
        # quality by cycle plot (10)
        #########################################

    	par(mar = c(4, 4, 5, 0) + 0.1)        

        if (length(quals1[,2]) > 1) {
        
	        qPlotLines <- c("solid","dashed")

	        qualBySite1 <- c()
			for (i in 1:cycles) {
				totalBases <- 0
				totalQ <- 0
				for (j in 2:length(quals1[1,])) {
					totalBases <- totalBases + quals1[i,j]
					totalQ <- totalQ + (j-1)*quals1[i,j]
				}
				qualBySite1[i] <- 0
				if (totalBases > 0) {
					qualBySite1[i] <- totalQ/totalBases
				}
			}
	        qualBySite2 <- c()
			for (i in 1:cycles) {
				totalBases <- 0
				totalQ <- 0
				for (j in 2:length(quals2[1,])) {
					totalBases <- totalBases + quals2[i,j]
					totalQ <- totalQ + (j-1)*quals2[i,j]
				}
				qualBySite2[i] <- 0
				if (totalBases > 0) {
					qualBySite2[i] <- totalQ/totalBases
				}
			}

	        xLower <- 0
	        xUpper <- cycles
	        yLower <- 0
	        yUpper <- 40
            
	        #qPlotColor <- mapColors[2]
	        qPlotColor <- "red"
			

	        plot(qualBySite1, ylim = c(yLower,yUpper), xlim = c(xLower,xUpper), lwd = 2, type = "l", lty = qPlotLines[1], col = qPlotColor, ylab = "", xlab = "", axes = F, cex.axis = axisCex)
			par(new = T)
			plot(qualBySite2, ylim = c(yLower,yUpper), xlim = c(xLower,xUpper), lwd = 2, type = "l", lty = qPlotLines[2], col = qPlotColor, ylab = "", xlab = "", axes = T, cex.axis = axisCex)
	        title(ylab = "mean quality (Q)", xlab = "cycle", main = "mean quality score per cycle", cex.main = mainCex, cex.lab = labelCex)
    		legend("bottomleft",inset = 0.05, c("read 1","read 2"), lty = qPlotLines, col = "red", cex = 1.5)

            par(xpd = F)

        } else { # fail error plot
		
            errorFail <- c()
            for (i in 1:20) {
                errorFail[i] <- 0
            }
            message <- "FAILED\nTO PLOT"
            barplot(errorFail, ylim = c(0,1), xlab = "", ylab = "", main = "", cex.axis = axisCex)
            text(par("usr")[2]/2,par("usr")[4]/2,message, cex = 5)
        
        }

    
        #########################################
        # average Q20 base calls per chrom (11)
        #########################################

        par(mar = c(5, 5, 4, 2))
        
        qMatrixToSave <- c(-99)
        namesToSave <- q20s[,1]
        qMeanToSave <- -99

        if (sum(as.numeric(q20s[,2]), na.rm = T) > 0 ) {
        
	        qMatrix <- matrix(nrow = length(q20s[,2]), ncol = 1)
	        qMatrix[,1] <- as.numeric(q20s[,2])
	        qMatrixToSave <- qMatrix[,1]
	        qTrans <- t(qMatrix)
	        names <- q20s[,1]
	        catColors <- c("salmon4")
	        barplot(qTrans, col = catColors, xlab = "", ylab = "", main = "", names.arg = names, cex.axis = axisCex, cex.names = axisCex)
	        title(xlab = "chromosome", ylab = "Q20s", main = "average .ge.Q20 base calls per target site", cex.main = mainCex, cex.lab = labelCex )
	        #sites <- sum(as.numeric(q20s[,4]), na.rm = T)
	        #allMean <- sum(as.numeric(as.numeric(q20s[,2])+as.numeric(q20s[,3]))/sites, na.rm = T)
	        totalSitesInTarget <- 0
	        totalQ20s <- 0
	        for (chromOfInt in namesToSave) {
	            totalSitesInTarget <- totalSitesInTarget + sum(tgtSum[which(as.character(tgtSum[,1]) == chromOfInt),2])
	            totalQ20s <- totalQ20s + sum(tgtSum[which(as.character(tgtSum[,1]) == chromOfInt),2])*q20s[which(as.character(q20s[,1]) == chromOfInt),2]
	        }
	        allMean <- 0
	        if (totalSitesInTarget > 0) {  # this will be a weighted mean
	          allMean <- totalQ20s/totalSitesInTarget
	        }
	        qMeanToSave <- allMean
	        lines(c(par("usr")[1],0), c(allMean,allMean), col = catColors[1],lwd = 4)
	        if (allMean >= 10) {
	            allMeanStr <- round(allMean)
	        } else {
	            if (allMean >= 0.1) {
	                allMeanStr <- sprintf("%3.1f",allMean)
	            } else {
	                allMeanStr <- sprintf("%6.4f",allMean)
	            }    
	        }
	        meanStr <- paste("weighted mean = ", allMeanStr, sep = "")
	        text((par("usr")[1]-0)/2,1.1*par("usr")[4], meanStr ,pos = 4, xpd = T, cex = 1.2*axisCex)	
            
        } else { # fail q20s plot
        
            q20sFail <- c()
            for (i in 1:20) {
                q20sFail[i] <- 0
            }
            message <- "FAILED TO PLOT"
            barplot(q20sFail, ylim = c(0,1), xlab = "", ylab = "", main = "", cex.axis = axisCex)
            text(par("usr")[2]/2,par("usr")[4]/2,message, cex = 5)
        
        }

        if (writeOutputFiles == 1) {
            options(scipen=999)
            for (line in 1:length(qMatrixToSave)) {
                rQ20 <- c(as.character(namesToSave[line]),qMatrixToSave[line])
                write(rQ20, rQ20File, append = T, ncol = length(rQ20))
            }
            write(qMeanToSave, rMeanQ20File, append = F, ncol = 1)  # only entry in this file so append = F
            options(scipen=0)
        }
                    
        dev.off()       

        output <- c((1 - coverageSummary[1]),(1 - coverageSummary[2]))
        if (writeOutputFiles == 1) {
            options(scipen=999)
            write(output, outputFile, append = T, ncol = length(output))
            options(scipen=0)
        }
	
    } else { # end of if there are no reads in the read Summary file

        #########################################
        # no total reads in summary file
        #########################################

        output <- c(-99,-99)   # full fail code
        if (writeOutputFiles == 1) {
            options(scipen=999)
            write(output, outputFile, append = T, ncol = length(output))
            options(scipen=0)
        }

        jpeg(file=filename, width = 1600, height = 800, units = "px",type=c("cairo"))
        layout(matrix(c(1,2),ncol=1), widths=c(2/20,18/20), heights=c(lcm(1),1))

        ltitle(paste("-- Quality Control Summary --",gap," sample: ",filePrefix,gap,"average cluster density = NA clusters/tile",gap,"target: NA", sep=""),cex=1.6,ypos=0.4)
        # create dummy plot for text
        inserts <- c()
        for (i in 1:20) {
        inserts[i] <- 0
        }
        text <- "NO READS IN\n SUMMARY FILE"
        barplot(inserts,ylim = c(0,1), xlab = "", ylab = "", main = "", cex.axis = axisCex)
        text(par("usr")[2]/2,par("usr")[4]/2,text, cex = 10)

    }

} else { # end of if file.exists(mapFile)

	#########################################
	# if no read summary file
	#########################################

	output <- c(-99,-99)   # full fail code
	if (writeOutputFiles == 1) {
        options(scipen=999)
		write(output, outputFile, append = T, ncol = length(output))
        options(scipen=0)
	}
	
	jpeg(file=filename, width = 1600, height = 800, units = "px",type=c("cairo"))
	layout(matrix(c(1,2),ncol=1), widths=c(2/20,18/20), heights=c(lcm(1),1))

    ltitle(paste("-- Quality Control Summary --",gap," sample: ",filePrefix,gap,"average cluster density = NA clusters/tile",gap,"target: NA", sep=""),cex=1.6,ypos=0.4)
	# create dummy plot for text
	inserts <- c()
	for (i in 1:20) {
		inserts[i] <- 0
	}
	text <- "INCOMPLETE NUMBER\n OF FILES CREATED"
	barplot(inserts,ylim = c(0,1), xlab = "", ylab = "", main = "", cex.axis = axisCex)
	text(par("usr")[2]/2,par("usr")[4]/2,text, cex = 10)
}

#unitLength
#allelex1
#allelex2
#length(alleleVec)

j <- 4
    for (i in 1:length(cov[,2])) {
        if (sum(as.numeric(cov[(minToPlot+1):i,2]), na.rm = T) > quartSums[j] && wrote == 0 || j == (length(quarts) + 1)) {
            if (j < (length(quarts) + 1)) {
                quartiles[j] <- sprintf("%4.1f",cov[i,1])
                wrote <- 1
            }
            yy <- c(c((minToPlot+1):i*0), cov[i:(minToPlot+1),2])
            xx <- c(cov[(minToPlot+1):i,1], cov[i:(minToPlot+1),1])
        }
    }
	yy
	xx


length(quarts)

warnings()
options(ow) # reset

Eoi

#end R code
