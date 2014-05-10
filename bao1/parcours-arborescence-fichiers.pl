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

use warnings;
use File::Slurp;
use Encode;
require Encode::Detect;
use HTML::Entities;

my $rep="$ARGV[0]";
# on s'assure que le nom du rÈpertoire ne se termine pas par un "/"
$rep=~ s/[\/]$//;
@out_list = (); # contient le contenu extrait des fichiers rss

my $output_xml="SORTIE.xml";
if (!open (FILEOUT,">$output_xml")) { die "Pb a l'ouverture du fichier $output_xml"};
my $output_txt="sortie.txt";
if (!open (TXT_OUT,">$output_txt")) { die "Pb a l'ouverture du fichier $output_txt"};

parcours_arborescence_fichiers($rep);

print FILEOUT "<?xml version=\"1.0\" encoding=\"iso-8859-1\" ?>\n";
print FILEOUT '<?xml-stylesheet href="arbo_style.xslt" type="text/xsl"?>', "\n";
print FILEOUT "<PARCOURS>\n";
print FILEOUT "<NOM>Lecailliez ; Genet</NOM>\n";
print FILEOUT "<FILTRAGE>";
foreach $pair(@out_list)
{
	print FILEOUT "<$pair->[1]>$pair->[0]</$pair->[1]>\n";
	print TXT_OUT "$pair->[0]\n";
}
print FILEOUT "</FILTRAGE>\n";
print FILEOUT "</PARCOURS>\n";
close(FILEOUT);

exit;

sub parcours_arborescence_fichiers {
    my ($path) = @_;
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
				$file_content = decode("Detect", $file_content);
				clean_txt(\$file_content);
				
				# pour une raison inconnue il faut l'appeler 2 fois pour avoir le résultat escompté
				decode_entities($file_content);
				decode_entities($file_content); 
				
				my @titles = extract_tag_content($file_content, "title");
				push(@out_list, [$titles[0], "rubrique"]);
				
				foreach $item(extract_tag_content($file_content, "item"))
				{
					# en réalité on possède déjà tous les titres du fichiers dans @titles
					# mais on risque une désynchronisation si le nombre de balises titres
					# précédent le premier item n'est pas constant
					my @titre = extract_tag_content($item, "title");
					my @descr = extract_tag_content($item, "description");
					push(@out_list, [$titre[0], "titre"]);
					push(@out_list, [$descr[0], "description"]);
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
	return @list;
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
	
	push @$list, substr($content, $start_tag_index + length($start_tag), 
			$end_tag_index - length($start_tag) - $start_tag_index);
	
	$content = substr($content, $end_tag_index + length($end_tag));
	
	extract_tag_content_helper($content, $tag, $list);
}

# param text_ref : référence vers une chaîne à nettoyer
sub clean_txt
{
	my ($text_ref) = @_;
	# suppression de <![CDATA[ ]]>
	$$text_ref =~ s/<!\[CDATA\[//g;
	$$text_ref =~ s/\]\]>//g;
	# suppression des balises <a>, </a> et <img>
	$$text_ref =~ s/<a[^>]*>//ig;
	$$text_ref =~ s/<\/a>//ig;
	$$text_ref =~ s/<img[^>]*>//ig;
	# remplacement des & en entités html
	$$text_ref =~ s/&/&amp;/g;
}
