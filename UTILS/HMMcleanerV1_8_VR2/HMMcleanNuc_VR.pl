#!/usr/bin/env perl

use strict;

#trick for absolute path of the script and so give a way for usefull other scripts
use Cwd 'abs_path';
my $abs_path = abs_path($0);
$abs_path =~ s/\/[^\/]*$/\//g;

my $changeID = 0;
# VR modif: spaces are ignored by most alignment viewers so that sequences seems to be unaligned with this default value => change to -
#my $delchar = " ";
my $delchar = "-";
my $hmmerpath = "";


my $cost1 = -1;
my $cost2 = -1;
my $cost3 = -1;
my $cost4 = -1;

while((@ARGV > 1) and ($ARGV[0]=~ m/^-/)){
	if ($ARGV[0] eq "--no-hmm"){
		$hmmerpath = $abs_path."lib/";
	}
	elsif($ARGV[0] eq "--change-id"){
		$changeID = 1;
	}
	elsif($ARGV[0] eq "--del-char"){
		shift;
		$delchar = $ARGV[0];
	}
	elsif($ARGV[0] eq "--define-cost"){
		shift;
		$cost1 = shift;
		$cost2 = shift;
		$cost3 = shift;
		$cost4 = $ARGV[0];
		if( ($cost1 > $cost2) or ($cost2 > 0) or (0 > $cost3) or ($cost3 > $cost4)){
			print "You should define cost such as : c1 <= c2 <= 0 <= c3 <= c4\n";exit;
		}
	}
	else{
		die $ARGV[0]." is not a valid option, check the README\n";
	}
	shift;
}


# arguments
if ((@ARGV) != 2){
	die "\nCheck the README, format should be:\n./HMMcleanAA.pl <fastafile> <threshold>\n\n";
}
my $fastafile = shift;
my $threshold = shift;

#definition of the default cost
if($cost1 == -1){
	$cost1 = -3;
	$cost2 = -1;
	$cost3 = $threshold/5;
	$cost4 = $threshold/2;
}


#threshold should be over the opposite of cost 2
if ($cost1 <= -$threshold){
	die "\nThreshold is ".$threshold." and should be over ( -1 * c1 )  which is now : ".-$cost1."\n\n";
}

# check if the file exist
open (INFILE,$fastafile) or die "fichier $fastafile inexistant\n";
my @FASTAFILE = <INFILE>;
while($FASTAFILE[0] =~ m/^\#/){
	shift(@FASTAFILE);
}

#read the file
my $taxanumber = -1;
my @taxaname;
my @cooltaxaname;
my @fullseq;
for(my $i=0; $i<=$#FASTAFILE;$i++){
	chomp($FASTAFILE[$i]);
	$FASTAFILE[$i] =~ s/\r//g;

	if($FASTAFILE[$i] =~ s/^>//g){
		$taxanumber++;
		# load the name of the current taxa
		$taxaname[$taxanumber] = $FASTAFILE[$i];
		if($changeID == 1){
			substr($taxaname[$taxanumber],0,0) = "Hmm_".$threshold.'_';
		}

		# to check if the taxa number is already used
		for(my $j=0; $j<$taxanumber;$j++){
			if($taxaname[$taxanumber] eq $taxaname[$j]){
				print $taxaname[$j]." is present twice in the alinment, pos ";
				print $j." and ".$taxanumber." \n";
				exit;
			}
		}

		# build a "cool" name where there is no space and have a fix length
		$cooltaxaname[$taxanumber]=$taxaname[$taxanumber];
		$cooltaxaname[$taxanumber] =~ s/^>//g;
		$cooltaxaname[$taxanumber] =~ s/[ ]*$//g;
		$cooltaxaname[$taxanumber] =~ s/ /_/g;
		$cooltaxaname[$taxanumber] = substr($cooltaxaname[$taxanumber], 0, 48);
		$cooltaxaname[$taxanumber] .= (" " x (49 - length($cooltaxaname[$taxanumber])));
	}
	else{
		# load the current sequence
		$FASTAFILE[$i] =~ s/[\*X\?\-\ ]/-/g;
		$fullseq[$taxanumber] .= $FASTAFILE[$i];
	}
}
close(INFILE);


# Compute the maximum sequence length and normalize with it !
my $fullseqlength = length($fullseq[0]);
for(my $currenttaxa=1; $currenttaxa<=$taxanumber;$currenttaxa++){
	my $l=length($fullseq[$currenttaxa]);
	if($fullseqlength < $l){
		$fullseqlength=$l;
	}
}
for(my $currenttaxa=0; $currenttaxa<=$taxanumber;$currenttaxa++){
	my $l=$fullseqlength-length($fullseq[$currenttaxa]);
	if( $l> 0){
		$fullseq[$currenttaxa].= '-' x $l;
	}
}







# radical for the outputs
my $rootfile = $fastafile;
$rootfile =~ s/\.[^\.]*$/_Hmm$threshold/g;

# full path of the root for the temp files
my $tempfile = $fastafile;
if(index($tempfile, '/') != -1){
	$tempfile =~ s/^.*\/([^\/\.]*)[^\/]*$/$abs_path\.$1_temp/g;
}
else{
	$tempfile =~ s/(^.*)\.*$/$abs_path\.$1_temp/g;
}



# create file for output
open(FASTA,">$rootfile.fasta") or die ("Error opening $rootfile.fasta");

# create file for log
open(LOG,">$rootfile.log") or die ("Error opening $rootfile.log");

# create file for score
open(SCORE,">$rootfile.score") or die ("Error opening $rootfile.score");

# create file with header for html
#system("cp -f ${abs_path}lib/header.html $rootfile.html");
#open(HTML,">>$rootfile.html") or die ("Error opening $rootfile.html");
#print HTML (" " x 49);for(my $i = 10; $i < $fullseqlength; $i+=10){print HTML (" " x (10 - length("$i"))).$i;};print HTML "\n".(" " x 49);for(my $i = 0; $i < $fullseqlength; $i+=10){print HTML ("=========+")}print HTML "\n";



# write a stockolm file with the sequences
open(STOC,">${tempfile}.stoc") or die ("Error opening ${tempfile}.stoc");
print STOC "# STOCKHOLM 1.0\n";
for(my $i=0; $i<=$taxanumber;$i++){
	print STOC $cooltaxaname[$i].$fullseq[$i]."\n";
}
print STOC "\/\/\n";
close(STOC);



# make the HMM model
system("${hmmerpath}hmmbuild ${tempfile}.hmm ${tempfile}.stoc >> ${tempfile}.poub ");
if( -z "${tempfile}.hmm" ) {print "user interuption or HMMER error with hmmbuild\n";exit;}


my @results;
print "File	taxaname	nb pos erased\n";
for(my $currenttaxa=0; $currenttaxa<=$taxanumber;$currenttaxa++){
	$results[$currenttaxa] = &doit($currenttaxa);
	$results[$currenttaxa] =~ s/[\*X\?\-\ ]/-/g;
}


#It s to detect the positions that are comonly unused ...
my @p;
for(my $pos = index($results[0], '-'); $pos != -1 ;$pos = index($results[0], '-', $pos+1)){
	my $currenttaxa=1;
	push(@p,$pos);
	while($currenttaxa<=$taxanumber){
		if(substr($results[$currenttaxa], $pos, 1) ne '-' ){
			$currenttaxa=$taxanumber;
			pop(@p);
		}
		$currenttaxa++;
	}
}
#print HTML (' ' x 49);
#my $a = 0;
#my $s="";
#foreach (@p) {
#	$s .= (' ' x ($_ - $a - 1))."<span class=\"BL\">\#\<\/span\>";
#	$a=$_;
#}
#$s =~ s/<\/span\><span class=\"BL\">//g;
#print HTML $s;
#print HTML "<br>\n";
#print HTML "</pre></body></html>\n";
#close(HTML);
#print "$rootfile.html wrote\n";



close(LOG);
print "$rootfile.log wrote\n";
close(FASTA);
print "$rootfile.fasta wrote\n";
close(SCORE);
print "$rootfile.score wrote\n";



sub doit{

	my $currenttaxa = shift;


# write a stockolm file with all sequences except the current one
#open(STOCHMM,">${tempfile}_hmm_${currenttaxa}.stoc") or die ("Error opening ${tempfile}_hmm_${currenttaxa}.stoc");
#print STOCHMM "# STOCKHOLM 1.0\n";
#for(my $i=0; $i<=$taxanumber;$i++){
#	if($i != $currenttaxa){print STOCHMM $cooltaxaname[$i].$fullseq[$i]."\n";}
#}
#print STOCHMM "\/\/\n";
#close(STOCHMM);



# make the HMM model
#system("${hmmerpath}hmmbuild --amino ${tempfile}_${currenttaxa}.hmm ${tempfile}_hmm_${currenttaxa}.stoc >> ${tempfile}.poub ");
#if( -z "${tempfile}.hmm" ) {print "user interuption or HMMER error with hmmbuild\n";exit;}


	# we work without gap
	my $currentseq = $fullseq[$currenttaxa];
	$currentseq =~ s/[\*X\?\-\ ]//g;
	my $seqlength = length($currentseq);

	# write a stockolm file with the sequence
	open(STOC1,">${tempfile}$currenttaxa.stoc1") or die ("Error opening ${tempfile}$currenttaxa.stoc1");
	print STOC1 "# STOCKHOLM 1.0\n$cooltaxaname[$currenttaxa]$currentseq\n\/\/\n";
	close(STOC1);

	# use the model to map the sequence on the alignments
	system("${hmmerpath}hmmsearch --notextw ${tempfile}.hmm ${tempfile}$currenttaxa.stoc1 	> ${tempfile}$currenttaxa.res 2>> ${tempfile}.poub");
	if( -z "${tempfile}$currenttaxa.res" ) {print "user interuption or HMMER error with hmmsearch\n";exit;}



	# depending on the option number, the line with the number of domain will change
	my $l = 15;

	# open file resulting from hmmsearch
	open (FILE_RESULT,"${tempfile}$currenttaxa.res") or die "Not able to open ${tempfile}$currenttaxa.res that should result from hmmsearch on ${tempfile}$currenttaxa.hmm and ${tempfile}$currenttaxa.stoc1 \n";
	my @RESULT = <FILE_RESULT>;
	my @start;
	my @end;

	my @starthmm;
	my @endhmm;

	#number of domain detected,
	$RESULT[15] =~ s/ +/ /g;
	$RESULT[15] =~ s/^ //g;
	my $NBdomain = (split(/ /, $RESULT[$l]))[7];
	#print "nb: $NBdomain\n";


	# store in @start and @end the interval index of each domain
	$l+=7;
	for(my $d = 0; $d<$NBdomain;$d++){
		$RESULT[$l] =~ s/ +/ /g;
		$RESULT[$l] =~ s/^ //g;
		#print $RESULT[$l];
		my @tab = split(/ /, $RESULT[$l]);
		push(@start, int($tab[9]));
		push(@end, int($tab[10]));
		push(@starthmm, int($tab[6]));
		push(@endhmm, int($tab[7]));
		$l++;
	}

	# check for ovelapping domains
	for(my $d=0; $d<$NBdomain; $d++){
		for(my $e=$d+1; $e<$NBdomain; $e++){
			my $o = &overlap($starthmm[$d],$endhmm[$d],$starthmm[$e],$endhmm[$e]);
			if($o > 10){
				print STDERR "WARNING  : a domain of $taxaname[$currenttaxa] align at 2 places in $fastafile\n";
				print STDERR "WARNING  : abs. values [ ".max($starthmm[$d],$starthmm[$e])." , ".-max(-$endhmm[$d],-$endhmm[$e])." ]\n";
			}
		}
	}

	$l+=5;
	#read each domains from the file
	my @score;
	for(my $d=0; $d<$NBdomain; $d++){
		# compute the length of the number of caracter to remove in the begin of each line
		my $nbtemp = " ".$start[$d]." ";
 		my @nbtab = split(/$nbtemp/, $RESULT[$l]);
 		my $nbchar = length($nbtab[0])+length($nbtemp);

		$l--;

		$score[$d] = substr($RESULT[$l],$nbchar);
		chomp($score[$d]);
		$l++;
		# the line after have to be read. The dashes are shifting the sequence !
		my $tempseq = substr($RESULT[$l],$nbchar);
		my $pos = index($tempseq, '-');
		while($pos !=-1){
			my $length2=length($tempseq)-1-$pos;
			$tempseq = substr($tempseq, 0, $pos).substr($tempseq, $pos+1, $length2);
			$score[$d] = substr($score[$d], 0, $pos).substr($score[$d], $pos+1, $length2);
			$pos = index($tempseq, '-');
		}
		$l+=6;
	}

	# linkage of the domains
	my $score = " " x ($start[0] - 1);
	for(my $d=0; $d<$NBdomain; $d++){
		$score .= substr($score[$d], (length($score)-$start[$d]+1), ($start[$d] + $end[$d]) );
		if($d+1 != $NBdomain){
			if($end[$d] < $start[$d+1]){
				$score .= " " x ($start[$d+1] - $end[$d]);
			}
		}
	}
	$score .= " " x ($seqlength - length($score));


	# this function return a list of shifts between good and bad positions
	my @shifts = &findshiftusingscore($score, $threshold);

	print SCORE $cooltaxaname[$currenttaxa].$currentseq."\n";
	print SCORE (" " x 49).$score."\n";
	print SCORE (" " x 49).&erasezone($currentseq, @shifts)."\n\n";

	# erased will be the number of removed positions

	my $erased = 0;
	for(my $i = 0; $i < $#shifts; $i+=2){
		$erased += $shifts[$i+1] - $shifts[$i];
	}

	my @gap;
	my $push = 0;
	foreach my $tab(split /-/,$fullseq[$currenttaxa]){
		if( length($tab) == 0){
			$push++;
		}
		else{
			push(@gap, $push);
			push(@gap, length($tab));
			$push = 1;
		}
	}


	&shiftatab(\@shifts, @gap);

	my $result = &erasezone($fullseq[$currenttaxa], @shifts);

	#VR why modifying original taxon name ?
	#$taxaname[$currenttaxa] =~ s/_/ /;
	print FASTA ">".$taxaname[$currenttaxa]."\n".$result."\n";

	print LOG $taxaname[$currenttaxa]."\n";
	for(my $i = 0; $i < $#shifts; $i+=2){
		print LOG "\t".(1+$shifts[$i])."-".$shifts[$i+1]."\n";
	}

	#my $resulthtml = &htmlzone($fullseq[$currenttaxa], @shifts);
	#print HTML $cooltaxaname[$currenttaxa].$resulthtml."\n";

	print $fastafile."\t".$taxaname[$currenttaxa]."\t".$erased."\n";

	return $result;
}

# Given two segment a-b and c-d, give the common part size
# assume a<b and c<d
sub overlap{
	my $a = shift;
	my $b = shift;
	my $c = shift;
	my $d = shift;
	my $ret = 0;
	if( ($c <= $b) and ($b <= $d) ){
		$ret = $b-$c;
	}
	if( ($c <= $a) and ($a <= $d) ){
		if($ret == 0){
			$ret = $d-$a;
		}
		else{
			$ret-=$a-$c;
		}
	}
	if( ($a < $c) and ($d < $b) ){
		$ret = $d-$c;
	}
	return $ret;
}

sub max{
	my $a = shift;
	my $b = shift;
	if($a < $b){
		return $b;
	}
	return $a;
}


sub shiftatab{
	my $reftab = shift;
	my @shifts = @_;
	my $index = 0;
	my $push = 0;
	my $level = 0;
	while(scalar(@shifts) != 0) {
			$push += shift(@shifts);
			$level += shift(@shifts);
			while(@$reftab[$index] < $level){
				@$reftab[$index]+=$push;
				$index++;
			}
	}
	@$reftab[-1]+=$push;
}



sub erasezone{
	my $seq = shift;
	my @shifts = @_;
	my $result = "";
	my $a1 = 0;
	while(scalar(@shifts) != 0) {
			my $a2 = shift(@shifts);
			$result .= substr($seq, $a1, $a2-$a1);
			if(scalar(@shifts) != 0) {
				$a1 = shift(@shifts);
			}
			else{
				$a1=length($seq);
			}
			$result .= $delchar x ($a1-$a2);
	}
	$result .= substr($seq, $a1, length($seq)-$a1);
	return $result;
}

sub htmlzone{
	my $seq = shift;
	my @shifts = @_;
	my $result = "";
	my $a1 = 0;
	while(scalar(@shifts) != 0) {
			my $a2 = shift(@shifts);
			my $s = substr($seq, $a1, $a2-$a1);
			$s =~ s/([A-Z])/\<span class=${1}\>${1}\<\/span\>/g;
			$result .= $s;
			if(scalar(@shifts) != 0) {
				$a1 = shift(@shifts);
			}
			else{
				$a1=length($seq);
			}
			if($a1-$a2 > 0){
				my $s = substr($seq, $a2, $a1-$a2);
				$s =~ s/([A-Z])/\<span class=${1}\>${1}\<\/span\>/g;
				$s =~ s/(\-+)/\<\/span\>${1}\<span class=bgy\>/g;
				$result .= "\<span class=bgy\>".$s."\<\/span\>";
			}
	}
	$result .= substr($seq, $a1, length($seq)-$a1);
	return $result;
}

sub findshiftusingscore{
	my($score, $threshold) = @_;
	my $shift = -1;
	my $val = $threshold;
	my $weareerasing = 0;
	my @shifts;
	for(my $pos=0; $pos != length($score); $pos++){
		my $c = substr($score, $pos, 1);
		if($c eq " "){
			$val+=$cost1;
		}
		elsif($c eq "+"){
			$val+=$cost2;
		}
		elsif($c =~ /[a-z]/){
			$val+=$cost3;
		}
		elsif($c =~ /[A-Z]/){
			$val+=$cost4;
		}
		else{
			print "\n Probleme, le résultat de Hmmer comporte le caractère: -".$c."-"."\n";
			exit;
		}
		if($val < 0){
			$val=0;
		}
		if($val>$threshold){
			$val=$threshold;
		}
		if($weareerasing==0){
			if($val==0){
				push(@shifts, $shift);
				$shift = -1;
				$weareerasing = 1;
			}
			elsif($val == $threshold){
				$shift = -1;
			}
			elsif($shift == -1){
				$shift=$pos;
			}
		}
		else{
			if($val == 0){
				$shift = -1;
			}
			else{
				if($shift == -1){
					$shift = $pos;
				}
				if($val==$threshold){
					push(@shifts, $shift);
					$weareerasing=0;
					$shift=-1;
				}
			}
		}
	}
	push(@shifts, length($score));
	#foreach (@shifts) {print "$_ ";}print "\n";
	return(@shifts);
}

# useless function taking a sequence, to reverse it, used to test reversibility
sub reversestring{
	print "warning this function has not been tested and will not be okay with other xml tag";
	my $seq = shift;
	my $result = "";
	for(my $pos=length($seq)-1; $pos >= 0; $pos--){
		my $c = substr($seq, $pos, 1);
		if($c eq '>'){
			if(substr($seq, $pos-1, 1) eq 'n'){
				$result .= "<span class=B>";
				$pos-=6;
			}
			else{
				$result .= "<\/span>";
				$pos-=13;
			}
		}
		else{
			$result .= substr($seq, $pos, 1);
		}
	}
	return $result;
}



# useless function taking a sequence, a character and the lengths of gap and sequence and introducing the gaps in the sequence
# table must have the sum of each impair
sub shiftaseq{
	my $seq = shift;
	my $char = shift;
	my @gaps = @_;
	my $result = "";
	my $pos = 0;
	while(scalar(@gaps) != 0) {
			my $a = shift(@gaps);
			$result .= $char x ($a);
			$a = shift(@gaps);
			$result .= substr($seq, $pos, $a);
			$pos+=$a;
	}
	return $result;
}

# clean the temporary files
system("rm -f ${tempfile}*");

exit;
