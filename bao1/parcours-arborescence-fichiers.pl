#/usr/bin/perl
<<DOC; 
Votre Nom : 
JANVIER 2005
 usage : perl parcours-arborescence-fichiers repertoire-a-parcourir
 Le programme prend en entrÈe le nom du rÈpertoire contenant les fichiers
 ‡ traiter
 Le programme construit en sortie un fichier structurÈ contenant sur chaque
 ligne le nom du fichier et le rÈsultat du filtrage :
<FICHIER><NOM>du fichier</NOM></FICHIER><CONTENU>du filtrage</CONTENU></FICHIER>
DOC

#use strict;
use warnings;
use File::Slurp;
use Encode 'decode';

my $rep="$ARGV[0]";
# on s'assure que le nom du rÈpertoire ne se termine pas par un "/"
$rep=~ s/[\/]$//;
# on initialise une variable contenant le flux de sortie 
$DUMPFULL1="";

my $output1="SORTIE.xml";
if (!open (FILEOUT,">$output1")) { die "Pb a l'ouverture du fichier $output1"};

parcours_arborescence_fichiers($rep);

print FILEOUT "<?xml version=\"1.0\" encoding=\"iso-8859-1\" ?>\n";
print FILEOUT "<PARCOURS>\n";
print FILEOUT "<NOM>Lecailliez ; Genet</NOM>\n";
print FILEOUT "<FILTRAGE>".$DUMPFULL1."</FILTRAGE>\n";
print FILEOUT "</PARCOURS>\n";
close(FILEOUT);
exit;

print $DUMPFULL1;

sub parcours_arborescence_fichiers {
    my ($path, $output) = @_;
    opendir(DIR, $path) or die "can't open $path: $!\n";
    
    my @files = readdir(DIR);
    closedir(DIR);
    
    foreach my $file (@files) {
		next if $file =~ /^\.\.?$/;
		$file = $path."/".$file;
		if (-d $file) {
	    	&parcours_arborescence_fichiers($file);
		}
		if (-f $file) {
			if($file =~ /\.xml$/i)
			{
				my $file_content = read_file($file);
				$file_content = decode("iso-8859-1", $file_content); 
				
				my @channel_title = extract_tag_content($file_content, "title");
				$DUMPFULL1 .= "<rubrique>${channel_title[0]}</rubrique>\n";
				
				foreach $item(extract_tag_content($file_content, "item"))
				{
					my @titre = extract_tag_content($item, "title");
					my @descr = extract_tag_content($item, "description");
					$DUMPFULL1 .= "<titre>${titre[0]}</titre>\n";
					$DUMPFULL1 .= "<description>${descr[0]}</description>\n";
				}
			}
		}
    }
}

# param content : texte xml à traiter
# param tag : nom (sans crochets) du tag xml dont il faut récupérer le contenu
# return : la liste des contenus du tag contenu dans le texte
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
	
	extract_tag_content_helper($content, $tag, $list);
}

