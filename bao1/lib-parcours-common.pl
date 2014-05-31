use warnings;
use File::Slurp;
use Encode;
require Encode::Detect;
use HTML::Entities;
use Time::HiRes qw(time);
require('treetagger2xml-utf8.pl');
use Data::GUID;

# contient le contenu extrait des fichiers rss
@out_list = (); # conservé pour la compatibilité avec le parcours parallèle
my $processed_files = 0;

sub main
{
	my ($conf_ref, $proc) = @_;
	
	my $rep = $conf_ref->{'work_dir'};
	my $out_dir = $conf_ref->{'out_dir'};
	my $start = time();
	
	$rep=~ s/[\/]$//; # on s'assure que le nom du répertoire ne se termine pas par un "/"
	
	my %result = ();
	parcours_arborescence_fichiers($rep, $proc, \%result);
	my $outfile = write_result_xml(\%result, $out_dir, $conf_ref);
	
	if($conf_ref->{'treetagger'})
	{
		my @txt_files = write_result_txt(\%result, $out_dir, $conf_ref);
	
		foreach (@txt_files)
		{
			system("tree-tagger-french-utf8 < $_ > $_.tagged");
			treetagger_to_xml("$_.tagged", 'utf-8');
		
			my $temp_content = read_file("$_.tagged.xml", binmode => ':utf8');	# on obtient le contenu du fichier résultant
			unlink("$_.tagged.xml"); # on supprime le fichier
		
			# on encapsule le fichier lus dans du xml ayant la même structure que les fichiers 
			# générés par BAO1 (write_result_xml)
			my $encoding = "UTF-8";
			my $filename = "$_.tagged.xml";
			$filename =~ s/\.txt\.tagged\.xml/\.tagged\.xml/;
			if(!open(TEMP_XML, ">:encoding($encoding)", $filename)) { die $! ; }
			print TEMP_XML "<?xml version=\"1.0\" encoding=\"$encoding\" ?>\n";
			print TEMP_XML '<?xml-stylesheet href="arbo_style.xslt" type="text/xsl"?>', "\n";
			print TEMP_XML "<parcours>\n";
			print TEMP_XML "<nom>Lecailliez ; Genet</nom>\n";
			print TEMP_XML "<items>\n";
			print TEMP_XML $temp_content;
			print TEMP_XML "</items>\n";
			print TEMP_XML "</parcours>\n";
			# suppression des fichiers temporaires
			unlink("$_");
			unlink("$_.tagged");
		}
	}
	
	my $end = time();
	printf("Temps d'exécution : %.2f\n", $end - $start);

	exit 0;
}

# étant donné la couche objet minable de Perl, je vais me contenter d'un copier-coller-modifier
# plutôt que d'une refactorisation de la fonction
# écrit les fichiers de chaque rubrique sous forme de fichier texte
# param : hash_ref : référence vers une table de hashage qui à chaque clefs (rubrique)
# associe une table de hashage telle que titre => description, dans le contexte de notre projet
sub write_result_txt
{
	my ($hash_ref, $output_dir, $conf_ref) = @_;
	my $out_dir = $conf_ref->{'out_dir'};
	
	if(!defined($output_dir)) { $output_dir = "./" }
	
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
	my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	
	my %files = (); 	# on va créer un fichier TXT par rubrique
	my @result = ();

	foreach my $rub (keys(%$hash_ref))
	{
		my $cat = clean_cat_name($rub);
		my $encoding = "UTF-8";
		my $filename = "$output_dir/${cat}_$mday-$months[$mon]-$hour-$min-$sec.txt";
		if(!open($files{$cat}, ">:encoding($encoding)", $filename)) { die $! ; }
		push(@result, $filename);
		
		foreach my $title (keys(%{$hash_ref->{$rub}}))
   		{
			print {$files{$cat}} "$title\n";
   			print {$files{$cat}} "$hash_ref->{$rub}{$title}\n";
   		}
	}
	
	foreach my $fh (values(%files)) 
	{
		close($fh);
	}
	return @result;
}

# créer un fichier XML par rubrique + un fichier TXT qui contient le contenu de tout le corpus
# param : hash_ref : référence vers une table de hashage qui à chaque clefs (rubrique)
# associe une table de hashage telle que titre => description, dans le contexte de notre projet
sub write_result_xml
{
	my ($hash_ref, $output_dir, $conf_ref) = @_;
	my $out_dir = $conf_ref->{'out_dir'};
	
	if(!defined($output_dir)) { $output_dir = "./" }
	
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
	my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my $output_txt="$output_dir/sortie_$mday-$months[$mon]-$hour-$min-$sec.txt";
	
	if (!open (TXT_OUT, ">:encoding(UTF-8)", $output_txt)) { die "Pb a l'ouverture du fichier $output_txt"};
	my %files = (); 	# on va créer un fichier XML par rubrique

	foreach my $rub (keys(%$hash_ref))
	{
		my $cat = clean_cat_name($rub);
		my $encoding = "UTF-8";
		my $filename = "$output_dir/${cat}_$mday-$months[$mon]-$hour-$min-$sec.xml";
		if(!open($files{$cat}, ">:encoding($encoding)", $filename)) { die $! ; }
		print {$files{$cat}} "<?xml version=\"1.0\" encoding=\"$encoding\" ?>\n";
		print {$files{$cat}} '<?xml-stylesheet href="arbo_style.xslt" type="text/xsl"?>', "\n";
		print {$files{$cat}} "<parcours>\n";
		print {$files{$cat}} "<nom>Lecailliez ; Genet</nom>\n";
		print {$files{$cat}} "<items>\n";
		
		foreach my $title (keys(%{$hash_ref->{$rub}}))
   		{
   			print {$files{$cat}} "<item>\n";
			print {$files{$cat}} "<title><![CDATA[$title]]></title>\n";
   			print {$files{$cat}} "<description><![CDATA[$hash_ref->{$rub}{$title}]]></description>\n";
			print {$files{$cat}} "</item>\n";
			
			print TXT_OUT $title, "\n";
   			print TXT_OUT %{$hash_ref->{$rub}}->{$title}, "\n";		
   		}
	}
	
	foreach my $fh (values(%files)) 
	{
		print $fh "</items>\n";
		print $fh "</parcours>\n";
		close($fh);
	}
	close(TXT_OUT);
	
	print "Fichier xml généré : $output_xml\n";
	return $output_txt;
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
				my $category = clean(remove_outer_tag($titles[0]));
				
				foreach $item($proc->($file_content, "item"))
				{
					my @titre = $proc->($item, "title");
					my @descr = $proc->($item, "description");
					
					$hash_ref->{$category}{clean(remove_outer_tag($titre[0]))} = clean(remove_outer_tag($descr[0]));
				}
				
				print "File [$file] processed.\n"
			}
		}
    }
}

# param $content : contenu textuel à traiter
# return : résultat l'étiquetage
sub treetagger_helper
{
	my ($content) = @_;
	
	my $temp_in = Data::GUID->new->as_string; # fichier qui contient les données à traiter
	my $temp_out = $temp_in . '.txt'; # fichier après traitement de treetagger
	$temp_in .= '.tmp';
	open(TEMP, ">:encoding(UTF-8)", $temp_in);
	print TEMP $content;
	close(TEMP);
	
	system("tree-tagger-french-utf8 < $temp_in > $temp_out");
	treetagger_to_xml($temp_out, 'utf-8');
	my $file_content = read_file("$temp_out.xml");
	
	unlink($temp_in);
	unlink($temp_out);
	unlink("$temp_out.xml");
	
	return $file_content;
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
