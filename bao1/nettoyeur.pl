#!/usr/bin/perl
open(FILEINPUT,"$ARGV[0]");
while ($ligne = <FILEINPUT>){
    $ligne=~s/RECHERCHE/REMPLACEMENT/g;
    print $ligne;
}
close(FILEINPUT);
