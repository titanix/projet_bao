#/usr/bin/perl
<<DOC; 
Votre Nom : 
JANVIER 2005
 usage : perl parcours-arborescence-fichiers repertoire-a-parcourir
 Le programme prend en entrée le nom du répertoire contenant les fichiers
 à traiter
 Le programme construit en sortie un fichier structuré contenant sur chaque
 ligne le nom du fichier et le résultat du filtrage :
<FICHIER><NOM>du fichier</NOM></FICHIER><CONTENU>du filtrage</CONTENU></FICHIER>
DOC

use File::Slurp;
#-----------------------------------------------------------
my $rep="$ARGV[0]";
# on s'assure que le nom du répertoire ne se termine pas par un "/"
$rep=~ s/[\/]$//;
# on initialise une variable contenant le flux de sortie 
my $DUMPFULL1="";
#----------------------------------------
my $output1="SORTIE.xml";
if (!open (FILEOUT,">$output1")) { die "Pb a l'ouverture du fichier $output1"};
#----------------------------------------
&parcours_arborescence_fichiers($rep);	#recurse!
#----------------------------------------
print FILEOUT "<?xml version=\"1.0\" encoding=\"iso-8859-1\" ?>\n";
print FILEOUT "<PARCOURS>\n";
print FILEOUT "<NOM>Votre nom</NOM>\n";
print FILEOUT "<FILTRAGE>".$DUMPFULL1."</FILTRAGE>\n";
print FILEOUT "</PARCOURS>\n";
close(FILEOUT);
exit;

sub parcours_arborescence_fichiers {
    my $path = shift(@_);
    opendir(DIR, $path) or die "can't open $path: $!\n";
    my @files = readdir(DIR);
    closedir(DIR);
    foreach my $file (@files) {
	next if $file =~ /^\.\.?$/;
	$file = $path."/".$file;
	if (-d $file) {
	    &parcours_arborescence_fichiers($file);#recurse!
	}
	if (-f $file) {
#       TRAITEMENT à réaliser sur chaque fichier
#       Insérer ici votre code (le filtreur)

print "$file\n";
		my $file_content = read_file($file);
 &extract_tag_content($file_content, "item");
	    print $i++,"\n";
	}
    }
}

# extrait le contenu d'une balise XML dont le nom lui passé en paramètre
sub extract_tag_content
{
	my $text = @_[0];
	my $tag = @_[1];
	
	if($text =~ /(<$tag>[^<]*<\/$tag>)/)
	{
		return $1;
	}
}
