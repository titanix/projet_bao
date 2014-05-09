#!/usr/bin/perl
open(FILEINPUT,"$ARGV[0]");
while ($ligne = <FILEINPUT>){
    $ligne=~s/<[^>]+>//g;
    print $ligne;
}
close(FILEINPUT);
