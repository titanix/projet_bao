#!/usr/bin/perl
open(FILEINPUT,"$ARGV[0]");
while ($ligne = <FILEINPUT>){
	if ($ligne=~/REGEXP/) {
             print $ligne;
     }
}
close(FILEINPUT) ;
