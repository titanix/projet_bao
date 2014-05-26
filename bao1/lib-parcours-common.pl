
use Data::Dumper;

use warnings;
use File::Slurp;
use Encode;
require Encode::Detect;
use HTML::Entities;
use Time::HiRes qw(time);
require('treetagger2xml-utf8.pl');
# contient le contenu extrait des fichiers rss
@out_list = (); # je sais, les variables globales c'est mal...
my $processed_files = 0;

sub main
{
	my ($conf_ref, $proc) = @_;
	
	my $rep = $conf_ref->{'work_dir'};
	my $out_dir = $conf_ref->{'out_dir'};
	my $start = time();
	
	$rep=~ s/[\/]$//; 	# on s'assure que le nom du répertoire ne se termine pas par un "/"
	
	my %result = ();
	parcours_arborescence_fichiers($rep, $proc, \%result);
	
	
write_result_new(\%result, '');
	exit;
	
	my $outfile = write_result(\@out_list, $out_dir);
	my $tagger_outfile = "$conf_ref->{'out_dir'}/tagger_result.txt";

	system("tree-tagger-french-utf8 < $outfile > $tagger_outfile");
	treetagger_to_xml($tagger_outfile, 'utf-8');
	
	my $end = time();
	printf("Temps d'exécution : %.2f\n", $end - $start);

	exit 0;
}

sub write_result_new
{
	my ($hash_ref, $output_dir) = @_;
	
	#my %hash = %$hash_ref;
	
	foreach my $rub (keys(%$hash_ref)) {
   		print "Rubrique [$rub] \n";
   		
   		# %{$hash_ref->{$rub}}, vraiment ? il m'a fallu 20 minutes de recherche pour
   		# trouver cette syntaxe, quelle langage de MERDE.
   		foreach my $title (keys(%{$hash_ref->{$rub}}))
   		{
   			#print "\t$title\n"; # OK
   			print %{$hash_ref->{$rub}}->{$title};
   			
   			#, %{$hash_ref->{$rub}{$title}}, "\n";
   		}
   		
   		#foreach my $title (keys(%$hash_ref->{$rub}))
   		#{
   		#	print "\t$title", %$hash_ref->{$rub}{$title}, "\n";
   		#}
   		
   		#foreach my $title (keys(%$hash_ref{$rub})) {
   		#	print "\t$title", "\n"; #$result{$rub}{$title}, "\n";
   		#}
	}
}

# param $path : chemin du dossier dont les fichiers sont analysés
# param $proc : référence vers la fonction d'extraction qui opère sur des fragments XML
sub parcours_arborescence_fichiers {
    my ($path, $proc, $hash_ref) = @_;
    opendir(DIR, $path) or die "can't open $path: $!\n";
    
    my @files = readdir(DIR);
    closedir(DIR);
    
    foreach my $file (@files) {    
		next if $file =~ /^\.\.?$/;
		next if $file =~ /^fil/;
		$file = $path."/".$file;
		if (-d $file) {
	    	parcours_arborescence_fichiers($file, $proc, $hash_ref);
		}
		if (-f $file) {
			if($file =~ /\.xml$/i)
			{
				my $file_content = read_file($file);
				$file_content = decode("Detect", $file_content);
				
				my @titles = $proc->($file_content, "title");
				#push(@out_list, [clean(remove_outer_tag($titles[0])), "rubrique"]);
				my $category = clean(remove_outer_tag($titles[0]));
				
				foreach $item($proc->($file_content, "item"))
				{
					# en réalité on possède déjà tous les titres du fichiers dans @titles
					# mais on risque une désynchronisation si le nombre de balises titres
					# précédent le premier item n'est pas constant
						
					my @titre = $proc->($item, "title");
					my @descr = $proc->($item, "description");
					#push(@out_list, [clean(remove_outer_tag($titre[0])), "titre", $category]);
					#push(@out_list, [clean(remove_outer_tag($descr[0])), "description", $category]);
				
					$hash_ref->{$category}{clean(remove_outer_tag($titre[0]))} = clean(remove_outer_tag($descr[0]));
					
					}
				
				print "File [$file] processed.\n"
			}
		}
    }
}

# param $list_ref : référence vers la liste qui contient les couples "contenu/item" à imprimer dans les fichiers de sortie
# param[opt] $output_dir : chemin de base du dossier qui contiendra les fichiers de sorties
# return : le chemin vers le fichier TXT de sortie nouvellement créé
sub write_result
{
	my ($list_ref, $output_dir) = @_;
	
	if(!defined($output_dir)) { $output_dir = "./" }
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	
	my $output_txt="$output_dir/sortie_$mday-$months[$mon]-$hour-$min-$sec.txt";
	if (!open (TXT_OUT, ">:encoding(UTF-8)", $output_txt)) { die "Pb a l'ouverture du fichier $output_txt"};

	# on va créer un fichier par rubrique
	my %files = ();

	foreach my $pair(@$list_ref)
	{
		my $cat = clean_cat_name($pair->[2]);
		if(!exists($files{$cat})) {
			my $encoding = "UTF-8";
			if(!open($files{$cat}, ">:encoding($encoding)", "$output_dir/${cat}_$mday-$months[$mon]-$hour-$min-$sec.xml")) { die $! ; }
			print {$files{$cat}} "<?xml version=\"1.0\" encoding=\"$encoding\" ?>\n";
			print {$files{$cat}} '<?xml-stylesheet href="arbo_style.xslt" type="text/xsl"?>', "\n";
			print {$files{$cat}} "<parcours>";
		}
		print {$files{$cat}} "<$pair->[1]><![CDATA[$pair->[0]]]></$pair->[1]>\n";
		print TXT_OUT "$pair->[0]\n";
	}
	
	foreach my $fh (values(%files)) {
		print $fh "</parcours>\n";
		close($fh);
	}
	
	print "Fichier xml généré : $output_xml\n";
	return $output_txt;
}

# param $str : une chaîne à nettoyer
# return : retourne une chaine qu'il est possible d'utiliser sur un système de fichier
# et dans le shell sans trop d'ennuis ultérieurs
sub clean_cat_name
{
	my ($str) = @_;
	
	$str =~ s/[\s]+//g;
	$str =~ s/://g; # Windows fait la tronche avec des : dans les noms de fichier
	return $str;
}

# param $str : enlève de la chaîne sélectionné la balise qui est censé l'entourer
# exemple : remove_outer_tag(<a>text</a>) -> text
sub remove_outer_tag
{
	my ($str) = @_;
	
	if(defined($str) && $str =~ /^(<[^>]+>)/)
	{
		my $size = length $1;
		return substr($str, $size, length($str) - (2 * $size + 1));
	}
}

# param $text_ref : référence vers une chaîne à nettoyer
sub clean_txt
{
	my ($text_ref) = @_;
	
	decode_entities($$text_ref); # de cette manière, on va pouvoir supprimer les balises HTML encodés dans le contenu

	# suppression de <![CDATA[ ]]>
	$$text_ref =~ s/<!\[CDATA\[//g;
	$$text_ref =~ s/\]\]>//g;
	# suppression des balises <a>, </a>, <img> et <br> et ses variantes
	# il ne faut pas supprimer toutes les balises, car le programme en a besoin de certaines
	$$text_ref =~ s/<a[^>]*>//ig;
	$$text_ref =~ s/<\/a>//ig;
	$$text_ref =~ s/<img[^>]*>//ig;
	$$text_ref =~ s/<br[^>]*>//ig;
	# remplacement des & en entités html
	$$text_ref =~ s/&/&amp;/g;
	
	# pour une raison inconnue il faut l'appeler plusieurs fois pour avoir le résultat escompté
	decode_entities($$text_ref);
	decode_entities($$text_ref); 
	decode_entities($$text_ref);
}

sub clean_txt_copy
{
	my ($text) = @_;
	
	decode_entities($text); # de cette manière, on va pouvoir supprimer les balises HTML encodés dans le contenu

	# suppression de <![CDATA[ ]]>
	$text =~ s/<!\[CDATA\[//g;
	$text =~ s/\]\]>//g;
	# suppression des balises <a>, </a>, <img> et <br> et ses variantes
	# il ne faut pas supprimer toutes les balises, car le programme en a besoin de certaines
	$text =~ s/<a[^>]*>//ig;
	$text =~ s/<\/a>//ig;
	$text =~ s/<img[^>]*>//ig;
	$text =~ s/<br[^>]*>//ig;
	# remplacement des & en entités html
	$text =~ s/&/&amp;/g;
	
	# pour une raison inconnue il faut l'appeler plusieurs fois pour avoir le résultat escompté
	decode_entities($text);
	decode_entities($text); 
	decode_entities($text); 
	
	return $text;
}

sub clean
{
	my ($text) = @_;
	
	$text = clean_txt_copy($text);
	
	$text =~ s/<p>//ig;
	$text =~ s/<\/p>//ig;
	
	return $text;
}

1; #nécessaire pour que l'importation puisse être réalisé dans d'autres fichiers perl
