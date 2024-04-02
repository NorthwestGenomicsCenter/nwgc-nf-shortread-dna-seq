#!/usr/bin/perl
#
#  Collect the QC metrics from the files generated in run.QC.suite.sh
#    (picard, samtools, contamination....)
#
#
my $scriptName = "collect.qc.metrics";

my $sample = $ARGV[0];
my $inputDir = "$ARGV[1]/qcFiles";
my $bed = $ARGV[2];
if ( @ARGV != 3 ) {
	die "--usage: $scriptName.pl <file prefix (s.1.2 or sample#)> <full path to QC files directory> <path to target bed file>\n";
}

my $outputDir = "$inputDir";

my @qualArray = (0,10,20,30);
my @chromArray = ("X","Y", 1 ... 22);

my $covered1x = "NA";
my $covered10x = "NA";
my $covered15x = "NA";
my $covered20x = "NA";
my $covered30x = "NA";
my $overlapLoss = "NA";
my $dupRate = "NA";

my $outputFile = "$outputDir/$sample.qcMetricsSummary.txt";
open(OUT,">$outputFile") || die "can't open QC metrics summary file: $outputFile\n";

my $readSummaryFile = "$outputDir/$sample.readSummary.txt";
open(RDSUM,">$readSummaryFile") || die "can't open read summary file: $readSummaryFile\n";

my $coverageOutFile = "$outputDir/$sample.coverageUniformity.txt";
open(COVOUT,">$coverageOutFile") || die "can't open coverage uniformity file: $coverageOutFile\n";
print COVOUT "depth\tsites\trawDpth\n";

my $covCorrectionConstant = 1; #default

foreach my $qual (@qualArray) {
	
	my $covFile = "$inputDir/$sample.MIN$qual.wgs_metrics.txt";
	if (-e $covFile) 
	{
		my $lineCount = 0;
		open(COV,$covFile) || die "can't open wgs metrics file: $covFile\n";
		while(<COV>)
		{
			$lineCount++;
			my $line = "$_";
			chomp($line);

			if ($lineCount == 8) {
				
				my @lineArray = split(/\t/,$line);
				
                my $meanCov = 0;
				if ((1 - $lineArray[11]) > 0) {
					$meanCov = $lineArray[1] * (1 - $lineArray[6] - $lineArray[9])/(1 - $lineArray[11]);
				}
                my $meanCovStr = sprintf("%8.4f",$meanCov);
                print OUT "meanCov\:\t$meanCovStr\n";
				my $meanQ20Cov = 0;
				if ((1 - $lineArray[11]) > 0) {
					$meanQ20Cov = $lineArray[1] * (1 - $lineArray[6] - $lineArray[9] - $lineArray[8])/(1 - $lineArray[11]);
				}
				my $meanQ20CovStr = sprintf("%8.4f",$meanQ20Cov);
				print OUT "MIN$qual\:\t$meanQ20CovStr\n";
				#print OUT "$lineArray[1]\t$lineArray[5]\t$lineArray[9]\t$lineArray[8]\t$lineArray[11]\n";
				
				if ($qual == 20) 
				{
					$covered1x = $lineArray[12];
					$covered10x = $lineArray[14];
					$covered15x = $lineArray[15];
					$covered20x = $lineArray[16];
					$covered30x = $lineArray[18];
					
					$overlapLoss = $lineArray[9];
					$dupRate = $lineArray[6];
					
					$covCorrectionConstant = 1;
					if ((1 - $lineArray[11]) > 0) {
						$covCorrectionConstant = (1 - $lineArray[6] - $lineArray[9])/(1 - $lineArray[11]);
					}
				
				} else {
				
					last;
				
				}
								
			}
			
			if ($qual == 20 && $lineCount > 11 && $line ne "") {
				#print COVOUT "$line\n";
				(my $depth, my $instances) = split(/\t/,$line);
				my $newDepthStr = sprintf("%6.3f",$depth*$covCorrectionConstant);
				print COVOUT "$newDepthStr\t$instances\t$depth\n";
			}

		}
		close COV;
				
	}
	else
	{
		print OUT "$covFile does not exist\n";
	}
}

close COVOUT;


print OUT "coverage (uncorrected):\n";
print OUT " ->  1x:\t$covered1x\n";
print OUT " -> 10x:\t$covered10x\n";
print OUT " -> 15x:\t$covered15x\n";
print OUT " -> 20x:\t$covered20x\n";
print OUT " -> 30x:\t$covered30x\n";

print OUT "\noverlap:\t$overlapLoss\n";
print OUT "dupRate:\t$dupRate\n";

my $q20OutFile = "$outputDir/$sample.q20sByChrom.txt";
open(Q20OUT,">$q20OutFile") || die "can't open Q20s by chrom file: $q20OutFile\n";
print Q20OUT "chrom\tmeanQ20\n";

print OUT "\nQ20s:\n";

foreach my $chrom (@chromArray) {
	
	my $covFile = "$inputDir/$sample.wgsMetrics.Q20.chr$chrom.txt";
	if (-e $covFile) 
	{
		my $lineCount = 0;
		open(COV,$covFile) || die "can't open wgs metrics file: $covFile\n";
		while(<COV>)
		{
			$lineCount++;
			if ($lineCount == 8) {
				
				my $line = "$_";
				chomp($line);
				my @lineArray = split(/\t/,$line);
				
				my $meanCov = 0;
				if ((1 - $lineArray[11]) > 0) {
					$meanCov = $lineArray[1] * (1 - $lineArray[6] - $lineArray[9] - $lineArray[8])/(1 - $lineArray[11]);
				}
				my $meanCovStr = sprintf("%8.4f",$meanCov);
				print Q20OUT "$chrom\t$meanCovStr\n";
				print OUT "chr$chrom\t$meanCovStr\n";
				#print OUT "$lineArray[1]\t$lineArray[5]\t$lineArray[9]\t$lineArray[8]\t$lineArray[11]\n";
				
				last;
				
			}

		}
		close COV;
				
	}
	else
	{
		print OUT "$covFile does not exist\n";
	}
}
close Q20OUT;

my $flagstatFile = "$inputDir/$sample.flagstat.output.txt";
open(FLG,$flagstatFile) || die "can't open flagstat file: $flagstatFile\n";
my $totalReads = 0;
my $mappedReads = 0;
my $suppleReads = 0;
my $pairedReads = 0;
my $propPairedReads = 0;
while(<FLG>) 
{

	my $line = "$_";
	chomp($line);
	my @lineArray = split(/\s+/,$line);

	if ($lineArray[4] eq "total") {
		$totalReads = $lineArray[0];
	}
	if ($lineArray[3] eq "supplementary") {
		$suppleReads = $lineArray[0];
	}
	if ($lineArray[3] eq "mapped") {
		$mappedReads = $lineArray[0];
	}
	if ($lineArray[3] eq "properly") {
		$propPairedReads = $lineArray[0];
	}
	if ($lineArray[3] eq "paired") {
		$pairedReads = $lineArray[0];
	}

}
close FLG;


my $mappedFrac = "NA";
my $trueTotalReads = $totalReads - $suppleReads;
my $trueMappedReads = $mappedReads - $suppleReads;
if ($trueTotalReads > 0) 
{
	$mappedFrac = sprintf("%8.6f",$trueMappedReads/$trueTotalReads);
}
my $propPairedFrac = "NA";
if ($pairedReads > 0) 
{
	$propPairedFrac = sprintf("%8.6f",$propPairedReads/$pairedReads);	
}

print OUT "\n mapped:\t$mappedFrac\nprpPr'd:\t$propPairedFrac\n";
print OUT "total:\t$trueTotalReads\n";
print OUT "mapped:\t$trueMappedReads (flagstat)\n";
print OUT "(supplementary):\t$suppleReads\n";

print RDSUM "total\t$trueTotalReads\n";
print RDSUM "mapped\t$trueMappedReads\n";


my $onTgtStatsFile = "$inputDir/$sample.onTarget.stats.txt";
open(TGT,$onTgtStatsFile) || die "can't open on target stats file: $onTgtStatsFile\n";

my $onTgtReads = 0;
my $mappedAndPaired = 0;
my $duplicateReads = 0;
my $mappedBases = 0;
my $unclippedBases = 0;
my $trimmedBases = 0;
my $errorRate = 0;
while(<TGT>) {
	my $line = "$_";
	chomp($line);
	my @lineArray = split(/\t/,$line);
	if ($lineArray[0] eq "SN") {
		#print STDOUT "$lineArray[1]\t$lineArray[2]\n";
		if ($lineArray[1] eq "reads mapped:") {
			$onTgtReads = $lineArray[2];
		}
		if ($lineArray[1] eq "reads mapped and paired:") {
			$mappedAndPaired = $lineArray[2];
		}
		if ($lineArray[1] eq "reads duplicated:") {
			$duplicateReads = $lineArray[2];
		}
		if ($lineArray[1] eq "bases mapped:") {
			$mappedBases = $lineArray[2];
		}
		if ($lineArray[1] eq "bases mapped (cigar):") {
			$unclippedBases  = $lineArray[2];
		}
		if ($lineArray[1] eq "bases trimmed:") {
			$trimmedBases = $lineArray[2];
		}
		if ($lineArray[1] eq "error rate:") {
			$errorRate = $lineArray[2];
		}
		if ($lineArray[0] eq "FFQ") {
			last;
		}
	}
}
close TGT;

my $quals1OutFile = "$outputDir/$sample.qualsBySite.read1.txt";
my $quals2OutFile = "$outputDir/$sample.qualsBySite.read2.txt";

system("cat $onTgtStatsFile | grep ^FFQ | cut -f 2- > $quals1OutFile");
system("cat $onTgtStatsFile | grep ^LFQ | cut -f 2- > $quals2OutFile");

print OUT "on target:\t$onTgtReads\n";
my $uniques = $onTgtReads - $duplicateReads;
print OUT "uniques:\t$uniques\n";
print OUT "mapped bases:\t$mappedBases\n";
print OUT "clean bases:\t$unclippedBases\n";
print OUT "trimmed bases:\t$trimmedBases \n";
print OUT "error rate:\t$errorRate\n";

print RDSUM "on target\t$onTgtReads\n";
print RDSUM "uniques\t$uniques\n";
print RDSUM "mapped bases\t$mappedBases\n";
print RDSUM "clean bases\t$unclippedBases\n";
my $singleEndReads = $onTgtReads - $mappedAndPaired;
print RDSUM "single-ended\t$singleEndReads\n";

my $alignmentFile = "$inputDir/$sample.alignment_summary_metrics.txt";
open(ALGN,$alignmentFile) || die "can't open alignment summary file: $$alignmentFile\n";
my $totalBasesStr = "NA";

while(<ALGN>) 
{
	
	my $line = "$_";
	chomp($line);
	my @lineArray = split(/\t/,$line);
	if ($lineArray[0] eq "PAIR")  #  what is not PE data? what does row header say then?
	{
		$totalBasesStr = sprintf("%7.3f",$lineArray[7]/10e9);
	}	
}
close ALGN;

my $trueTotalReadsStr = sprintf("%7.3f",$trueTotalReads/10e6);
print OUT "  reads:\t$trueTotalReadsStr (M)\n";
print OUT "  bases:\t$totalBasesStr (Gb)\n";

my $mapQ0File = "$inputDir/$sample.MAPQ0.wgs_metrics.txt";
my $mapQ0 = "NA";
if (-e $mapQ0File)
{

	open(MQ0,$mapQ0File) || die "can't open mapping Q0 file: $mapQ0File\n";

	my $lineCount = 0;
	while(<MQ0>) 
	{
		
		my $line = "$_";
		chomp($line);
		my @lineArray = split(/\t/,$line);
		$lineCount++;
		if ($lineCount == 8)  
		{
			$mapQ0File = sprintf("%7.3f",$lineArray[5]);
		}	
	}
	close MQ0;
}

print OUT "  mapQ0:\t$mapQ0File\n";

my $insertFile = "$inputDir/$sample.insert_size_metrics.txt";
my $medianInsert = "NA";

my $insertOutFile = "$outputDir/$sample.insert.txt";
open(INSOUT,">$insertOutFile") || die "can't open insert size output file: $insertOutFile\n";
#print INSOUT "size\tcount\n";  # this is changed because using WGS.MultipleMetrics gives a different output format

if (-e $insertFile)
{

	open(INS,$insertFile) || die "can't open insert size file: $insertFile\n";

	my $lineCount = 0;
	while(<INS>) 
	{
		
		my $line = "$_";
		chomp($line);
		my @lineArray = split(/\t/,$line);
		$lineCount++;
		if ($lineCount == 8)  
		{
			$medianInsert = $lineArray[0];
		}	
		if ($lineCount > 12 && $line ne "") {
			print INSOUT "$line\n";
		}
	}
	close INS;
}
close INSOUT;

print OUT "  insert:\t$medianInsert\n";

my $gcFile = "$inputDir/$sample.gc_bias_summary_metrics.txt";
my $gcNC0to19 = "NA";
my $gcNC20to39 = "NA";
my $gcNC40to59 = "NA";
my $gcNC60to79 = "NA";
my $gcNC80to100 = "NA";
if (-e $gcFile)
{

	open(GC,$gcFile) || die "can't open GC file: $gcFile\n";

	my $lineCount = 0;
	while(<GC>) 
	{
		
		my $line = "$_";
		chomp($line);
		my @lineArray = split(/\t/,$line);
		$lineCount++;
		if ($lineCount == 8)  
		{
			$gcNC0to19 = $lineArray[6];
			$gcNC20to39 = $lineArray[7];
			$gcNC40to59 = $lineArray[8];
			$gcNC60to79 = $lineArray[9];
			$gcNC80to100 = $lineArray[10];
		}	
	}
	close GC;
}

print OUT "\nGC bias (normalized coverage):\n";
print OUT "    0 to 19:\t$gcNC0to19\n";
print OUT "   20 to 39:\t$gcNC20to39\n";
print OUT "   40 to 59:\t$gcNC40to59\n";
print OUT "   60 to 79:\t$gcNC60to79\n";
print OUT "  80 to 100:\t$gcNC80to100\n";

#close OUT;


my $gcFile = "$inputDir/$sample.gc_bias_metrics.txt";
my $gcOutFile = "$outputDir/$sample.gcBias.stats.txt";
open(GCOUT,">$gcOutFile ") || die "can't open gc bias output file: $gcOutFile \n";
print GCOUT "gc\twindows\treadStarts\tmeanQ\tnormCov\terrorBar\n";

if (-e $gcFile)
{

	open(GC,$gcFile) || die "can't open GC details file: $gcFile\n";

	my $lineCount = 0;
	while(<GC>) 
	{
		
		my $line = "$_";
		chomp($line);
		my @lineArray = split(/\t/,$line);
		$lineCount++;
		if ($lineCount > 7 && $line ne "")  
		{
			print GCOUT "$lineArray[2]\t$lineArray[3]\t$lineArray[4]\t$lineArray[5]\t$lineArray[6]\t$lineArray[7]\n"
		}
	}
}
close GC;
close GCOUT;
			
#
# get base by cycle info
#
my $readsFile = "$inputDir/$sample.base_distribution_by_cycle.txt";

my $reads1OutFile = "$outputDir/$sample.reads.read1.txt";
open(RDS1OUT,">$reads1OutFile") || die "can't open reads output file: $reads1OutFile\n";
print RDS1OUT "\tpctA\tpctT\tpctC\tpctG\tpctN\n";
my $reads2OutFile = "$outputDir/$sample.reads.read2.txt";
open(RDS2OUT,">$reads2OutFile") || die "can't open reads output file: $reads2OutFile\n";
print RDS2OUT "\tpctA\tpctT\tpctC\tpctG\tpctN\n";

if (-e $readsFile)
{

	open(RDS,$readsFile) || die "can't open reads input file: $readsFile\n";

	my $lineCount = 0;
	my $readLength = 0;
	while(<RDS>) 
	{
		
		my $line = "$_";
		chomp($line);
		my @lineArray = split(/\t/,$line);
		$lineCount++;
		
		if ($lineCount > 7 && $line ne "") {
			if ($lineArray[0] == 1) {
				print RDS1OUT "$lineArray[1]\t$lineArray[2]\t$lineArray[5]\t$lineArray[3]\t$lineArray[4]\t$lineArray[6]\n";
				if ($lineArray[1] > $readLength) {
					$readLength = $lineArray[1];
				}
			}
			if ($lineArray[0] == 2) {
				print RDS2OUT ($lineArray[1] - $readLength)."\t$lineArray[2]\t$lineArray[5]\t$lineArray[3]\t$lineArray[4]\t$lineArray[6]\n";
			}
		}
	}
	close RDS;
}
close RDS1OUT;
close RDS2OUT;

close RDSUM;

#
#  grab the target name from the BED file path
#
my @bedArray = split(/\//,$bed);
my $targetStr = $bedArray[@bedArray - 2];
system("echo $targetStr > $outputDir/$sample.target.txt");

#
# make the target summary file for use with weighted Q20 calculation
#
my $tgtSummaryFile = "$outputDir/$sample.targetSummary.txt";
open(TGT,">$tgtSummaryFile") || die "can't open target summary file: $tgtSummaryFile\n";
print TGT "chr\tsites\n";

open(BED,$bed) || die "can't open bed file: $bed\n";

my %tgtHash = ();
while(<BED>) {
	my $line = "$_";
	chomp($line);
	(my $chrStr, my $start, my $stop) = split(/\t/,$line);
	$chrStr =~ s/chr//;
	$tgtHash{$chrStr} += $stop - $start;	
}
close BED;

foreach my $chr (sort {$a <=> $b} keys(%tgtHash)) {
	print TGT "$chr\t$tgtHash{$chr}\n";
}
close TGT;
#
# use the new coverage uniformity distribution values to recalculate cov10,20,.....
#
my @covNArray = (1,5,10,15,20,25,30,40,50,60,70,80,90,100);
my %covNHash = ();

foreach my $covN (@covNArray) {
	$covNHash{$covN} = "NA";  #default
}

open(COVOUT,$coverageOutFile) || die "can't open coverage uniformity file: $coverageOutFile\n";

my @covArray = ();
my @covValArray = ();
my $totalSites = 0;

while(<COVOUT>) {
	my $line = "$_";
	chomp($line);
	(my $depth, my $value) = split(/\t/,$line);
	if ($depth ne "depth") {
		#print STDOUT "$depth\t$value\n";
		push(@covArray,$depth);
		push(@covValArray,$value);
		$totalSites += $value;
	}	
}
close COVOUT;

foreach my $covN (@covNArray) {

	my $totalNSites = 0;

	for (my $i = 0; $i < (@covArray - 1); $i++) { # restrict it to i-1 so array doesn't go out of bounds below

		if ($covArray[$i] <= $covN) { # do this each time, but only the last time will count

			$totalNSites += $covValArray[$i];
			if ($covArray[$i+1] > $covN) {
				$extraSites = 0;
				if (($covArray[$i+1] - $covArray[$i]) != 0){ 
					$extraSites = $covValArray[$i+1]*($covN - $covArray[$i])/($covArray[$i+1] - $covArray[$i]);  # interpolate 
				}
				$totalNSites += $extraSites;
				
				if ($totalSites > 0 ){
					$covNHash{$covN} = sprintf("%8.6f",1.0 - ($totalNSites/$totalSites));
				}

				last;
			}
		}
					
	}
}
#print STDOUT "covs:\t".@covArray."\n";

my $covFile = "$inputDir/$sample.MIN20.wgs_metrics.txt";
my $correctedCovFile = "$inputDir/$sample.MIN20.corrected.wgs_metrics.txt";
open(COROUT,">$correctedCovFile") || die "can't open corrected wgs metrics file: $correctedCovFile\n";

if (-e $covFile) 
{
	my $lineCount = 0;
	open(COV,$covFile) || die "can't open wgs metrics file: $covFile\n";
	while(<COV>)
	{
		$lineCount++;
		my $line = "$_";

		if ($lineCount == 8) {
			
			my @lineArray = split(/\t/,$line);
			for (my $i = 0; $i <= 11; $i++) {
				print COROUT "$lineArray[$i]\t";
			}
			foreach my $covN (@covNArray) {
				print COROUT "$covNHash{$covN}\t";
			}
			print COROUT "$lineArray[26]\t$lineArray[27]";
			
		} else {
			
			print COROUT "$line";

		}
	}
	close COV;
}


print OUT "\ncoverage (corrected):\n";
print OUT " ->  1x:\t$covNHash{1}\n";
print OUT " -> 10x:\t$covNHash{10}\n";
print OUT " -> 15x:\t$covNHash{15}\n";
print OUT " -> 20x:\t$covNHash{20}\n";
print OUT " -> 30x:\t$covNHash{30}\n";


close OUT

