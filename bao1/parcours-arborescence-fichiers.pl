#/usr/bin/perl
<<DOC; 
Votre Nom : 
JANVIER 2005
 usage : perl parcours-arborescence-fichiers repertoire-a-parcourir
 Le programme prend en entr�e le nom du r�pertoire contenant les fichiers
 � traiter
 Le programme construit en sortie un fichier structur� contenant sur chaque
 ligne le nom du fichier et le r�sultat du filtrage :
<FICHIER><NOM>du fichier</NOM></FICHIER><CONTENU>du filtrage</CONTENU></FICHIER>
DOC

use warnings;
use File::Slurp;
use Encode;
require Encode::Detect;
use HTML::Entities;
use XML::LibXML;
use Data::Dumper;
use Try::Tiny;

# contient le contenu extrait des fichiers rss
@out_list = (); # je sais, les variables globales c'est mal...

sub main
{
	my ($rep, $proc) = @_;
		
	# on s'assure que le nom du r�pertoire ne se termine pas par un "/"
	$rep=~ s/[\/]$//;

	my $output_xml="SORTIE.xml";
	if (!open (FILEOUT,">$output_xml")) { die "Pb a l'ouverture du fichier $output_xml"};
	my $output_txt="sortie.txt";
	if (!open (TXT_OUT,">$output_txt")) { die "Pb a l'ouverture du fichier $output_txt"};

	parcours_arborescence_fichiers($rep, $proc);

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

	exit 0;
}

# param $path : chemin du dossier dont les fichiers sont analys�s
# param $proc : r�f�rence vers la fonction d'extraction qui op�re sur des fragments XML
sub parcours_arborescence_fichiers {
    my ($path, $proc) = @_;
    opendir(DIR, $path) or die "can't open $path: $!\n";
    
    my @files = readdir(DIR);
    closedir(DIR);
    
    foreach my $file (@files) {    
		next if $file =~ /^\.\.?$/;
		$file = $path."/".$file;
		if (-d $file) {
	    	parcours_arborescence_fichiers($file, $proc);
		}
		if (-f $file) {
			if($file =~ /\.xml$/i)
			{
				my $file_content = read_file($file);
				$file_content = decode("Detect", $file_content);
				clean_txt(\$file_content);
				
				my @titles = $proc->($file_content, "title");
				push(@out_list, [clean(remove_outer_tag($titles[0])), "rubrique"]);
				
				foreach $item($proc->($file_content, "item"))
				{
					# en r�alit� on poss�de d�j� tous les titres du fichiers dans @titles
					# mais on risque une d�synchronisation si le nombre de balises titres
					# pr�c�dent le premier item n'est pas constant
					my @titre = $proc->($item, "title");
					my @descr = $proc->($item, "description");
					push(@out_list, [clean(remove_outer_tag($titre[0])), "titre"]);
					push(@out_list, [clean(remove_outer_tag($descr[0])), "description"]);
				}
			}
		}
    }
}

# param $content : texte xml � traiter
# param $tag : nom (sans crochets) du tag xml dont il faut r�cup�rer le contenu
# return : la liste des contenus du tag contenu dans le texte
# note : la balise qui entoure le XML � extraire n'est pas retir�e par cette fonction
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
	
	push @$list, substr($content, $start_tag_index, 
			$end_tag_index - $start_tag_index);
	
	$content = substr($content, $end_tag_index + length($end_tag));
	
	extract_tag_content_helper($content, $tag, $list);
}

# param $content : texte xml � traiter
# param $tag : nom (sans crochets) du tag xml dont il faut r�cup�rer le contenu
# return : la liste des contenus du tag contenu dans le texte
sub extract_rss
{
	my ($content, $tag) = @_;
	
	my @list = ();
	my $parser = new XML::LibXML;
	
	try {
    	my $xml_doc = $parser->parse_string($content);

		foreach	$t ($xml_doc->getElementsByTagName($tag))
		{
			push @list, $t->toStringEC14N;
		}
	} catch {
        warn "Erreur dans extract_rss : $_";
	};
	
	return @list;
}

# param $str : enl�ve de la cha�ne s�lectionn� la balise qui est cens� l'entourer
# exemple : remove_outer_tag(<a>text</a>) -> text
sub remove_outer_tag
{
	my ($str) = @_;
	
	if($str =~ /^(<[^>]+>)/)
	{
		my $size = length $1;
		return substr($str, $size, length($str) - (2 * $size + 1));
	}
}

# param $text_ref : r�f�rence vers une cha�ne � nettoyer
sub clean_txt
{
	my ($text_ref) = @_;
	# suppression de <![CDATA[ ]]>
	$$text_ref =~ s/<!\[CDATA\[//g;
	$$text_ref =~ s/\]\]>//g;
	# suppression des balises <a>, </a> et <img>
	# il ne faut pas supprimer toutes les balises, car le programme en a besoin de certaines
	$$text_ref =~ s/<a[^>]*>//ig;
	$$text_ref =~ s/<\/a>//ig;
	$$text_ref =~ s/<img[^>]*>//ig;
	# remplacement des & en entit�s html
	$$text_ref =~ s/&/&amp;/g;
	
	# pour une raison inconnue il faut l'appeler plusieurs fois pour avoir le r�sultat escompt�
	decode_entities($$text_ref);
	decode_entities($$text_ref); 
	decode_entities($$text_ref);
}

sub clean
{
	my ($text) = @_;
	
	$text =~ s/<p>//ig;
	$text =~ s/<\/p>//ig;
	
	return $text;
}

main($ARGV[0], \&extract_rss);