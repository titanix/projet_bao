#!/usr/bin/perl

open(FILEINPUT,"$ARGV[0]");
my $tag = $ARGV[1];

while ($ligne = <FILEINPUT>){
if ($ligne=~/(<$tag>[^<]*<\/$tag>)/) {
             print $1;
     }
}
close(FILEINPUT);
