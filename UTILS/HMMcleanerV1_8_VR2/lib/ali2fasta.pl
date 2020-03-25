#!/usr/bin/perl -w
##
##Copyright Jean-Christophe Grenier
##University of Montreal
##LAST MODIFIED : 6/11/2008
#
use strict;
#

my $inputFile = "";
my $outputFile = "";

if( @ARGV == 1 ){
        $inputFile = shift;
}
else{
        die "Usage: ./ali2fasta.pl <Input_file>";
}

my @file = split( '\.', $inputFile );
$outputFile .= $file[0] . ".fasta";

open( INPUT, "$inputFile" ) or dieWithUnexpectedError("can't open $inputFile!");
open( OUTPUT, ">$outputFile" ) or dieWithUnexpectedError("can't write to $outputFile!");

while(<INPUT>){
       	my $line = $_;
        if($line =~ /[A-Z]/)
	{
		$line =~ s/ /\n/; #replace * by -
	#	chomp $line;	
		print OUTPUT ">$line";
	}
}
close(INPUT);
close(OUTPUT);

