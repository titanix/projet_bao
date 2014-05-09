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

#use strict;
use warnings;
use File::Slurp;
use Encode 'decode';

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

			if($file =~ /\.xml$/i)
			{
				my $file_content = read_file($file);
				
				$file_content = decode("iso-8859-1", $file_content); 
				
				foreach $item(extract_tag_content($file_content, "item"))
				{
					print "----------------------------\n";
					print $item, "\n";
					print "----------------------------\n";
				#exit 0;
				}

			}
		}
    }
}

sub extract_tag_content
{
	my ($content, $tag) = @_;
	my @list = ();
	extract_tag_content_helper($content, $tag, \@list);
	return reverse(@list);
}

sub extract_tag_content_helper
{
	my ($content, $tag, $list) = @_;
	
	my $start_tag = "<$tag>";
	my $end_tag = "</$tag>";
	my $start_tag_index = index($content, $start_tag);	
	my $end_tag_index = index $content, $end_tag;
		
	if($start_tag_index == -1)
	{
		return;
	}
	
	unshift @$list, substr($content, $start_tag_index + length($start_tag), 
			$end_tag_index - length($start_tag) - $start_tag_index);
	
	$content = substr($content, $end_tag_index + length($end_tag));
	
	if($TRACE)
	{
	print "DEBUG ", length($end_tag), "\n";
	
	print "next text length ", length($content), "\n";
	print "start tag index ", $start_tag_index, "\n";
	print "end tag index ", $end_tag_index, "\n";
	print "---", "\n";
	}

	extract_tag_content_helper($content, $tag, $list);
}

