require 'lib-parcours-common.pl';
require 'lib-parcours-string.pl';
use strict;
use warnings;
use Data::Dumper;
use Parallel::ForkManager;
use File::Slurp;
use Encode;
require Encode::Detect;
use HTML::Entities;
use Data::GUID;
use Time::HiRes qw(time);
use Digest::MD5 qw(md5_base64);
use Try::Tiny;

# param $rep : répertoire à parcourir
# param $extract_fun : référence vers la fonction d'extration à utiliser
# param[opt] $nb_proc : nombre de processus maximal à forker
# param[opt] $out_dir : répertoire de sortie des fichiers résultats écrits
sub parallel_main
{
	my ($conf_ref, $extract_fun) = @_;
	
	my $rep = $conf_ref->{'work_dir'};
	my $out_dir = $conf_ref->{'out_dir'};
	my $nb_proc = $conf_ref->{'max_proc'};
	my $proc = $extract_fun;
	my $start = time();

	if(!defined()) {
		$nb_proc = 4;
	} else {
		$nb_proc = $nb_proc + 0;
	}
	
	if(!defined($rep))
	{
		print "Missing argument repertory\n";
		exit 1;
	}
	
	$rep=~ s/[\/]$//; # on s'assure que le nom du répertoire ne se termine pas par un "/"
	my @folders = (); # listes des répertoires sur lesquels on travaille
	my %worker_result = ();
	my $pm = Parallel::ForkManager->new($nb_proc, '/Volumes/ramdisk/tmp'); # on travail avec N processus fils, qui sérialisent leurs données dans /tmp
	
	# fonction de callback appelée lors de la terminaison d'un processus fils
  	$pm->run_on_finish(sub {
    	my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data_struc_ref) = @_;
      	# on récupère la référence vers la structure de donnée envoyée par le fils, quand c'est le cas
		if (defined($data_struc_ref)) {
        	$worker_result{Data::GUID->new->as_string} = $data_struc_ref;
		} else {  # problems occuring during storage or retrieval will throw a warning
			print qq|No message received from child process $pid!\n|;
      	}
	});

	build_subdir_list($rep, \@folders, 2); # on construit la liste des répertoires que se partageront les processus fils

	foreach my $folder (@folders)
	{
    	my $pid = $pm->start and next; # on crée un nouveau processus
    	# à partir de maintenant le code est exécuté dans les processus fils
    	
		my @xml_files = (); # on construit la listes des fichiers XML à traiter
		build_file_list($folder, \@xml_files);
		my @out_list = ();	
	
		foreach my $file (@xml_files) {
    		my $file_content = read_file($file);
			$file_content = decode("Detect", $file_content);
				
			my @titles = extract_tag_content($file_content, "title");
			push(@out_list, [clean(remove_outer_tag($titles[0])), "rubrique"]);
				
			foreach my $item($proc->($file_content, "item"))
			{
				my @titre = $proc->($item, "title");
				my @descr = $proc->($item, "description");
				push(@out_list, [clean(remove_outer_tag($titre[0])), "titre"]);
				push(@out_list, [clean(remove_outer_tag($descr[0])), "description"]);
			}
			print "File [$file] processed.\n"
    	}
		$pm->finish(0, \@out_list);  # on met fin au processus enfant
	}
	$pm->wait_all_children;
	
	my @resulting_merged_list = ();
	my @element_hash = ();
	
	# on construit la liste finale de résultat à partir des listes générées par les processus fils
	foreach my $key (keys(%worker_result)) {
		# normalement les valeurs sont des références vers une liste de tableaux
		foreach (${worker_result{$key}})
		{
			foreach my $pair (@{$_}) # super lisible !
			{
				my $hash;
				try {
			 		$hash = md5_base64(encode_utf8($pair->[0])) or die "$!\n";
				} catch { 
					# TODO : faire un truc plus sérieux
					warn "Erreur : $_"; 
				};
				if(!($hash ~~ @element_hash))
				{
					push(@resulting_merged_list, $pair);
					push(@element_hash, $hash);
				}
				# else { print "one item skipped of type $pair->[1]\n"; }
			}
		}
	}

	write_result(\@resulting_merged_list, $out_dir);
	
	my $end = time();
	printf("Temps d'exécution : %.2f\n", $end - $start);
	exit 0;
}

# param $list_ref : référence vers la liste qui contient les couples "contenu/item" à imprimer dans les fichiers de sortie
# param[opt] $output_dir : chemin de base du dossier qui contiendra les fichiers de sorties
# return : le chemin vers le fichier TXT de sortie nouvellement créé
sub write_result
{
	my ($list_ref, $output_dir) = @_;
	
	if(!defined($output_dir)) { $output_dir = "./" }
	
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
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
	close(TXT_OUT);
	
	return $output_txt;
}

# param $dir : répertoire à analyser
# param $list_ref : rférence vers une liste qui contiendra les fichiers
# param[opt] $pattern : motif auquel doivent se conformer les fichiers pour être ajoutés dans la liste
sub build_file_list {
    my ($dir, $list_ref, $pattern) = @_;
    
    if(!defined($pattern))
    {
    	$pattern = '\.xml$';
    }
    opendir(DIR, $dir) or die "can't open $dir: $!\n";
    my @files = readdir(DIR);
    closedir(DIR);

    foreach my $file (@files) {    
		next if $file =~ /^\..*$/;
		next if $file =~ /^fil/;
		$file = $dir."/".$file;

		if (-d $file) {
	    	build_file_list($file, $list_ref);
		}
		if (-f $file) {
			if($file =~ /$pattern/i)
			{
				push(@$list_ref, $file);
			}
		}
    }
}

# construit une liste des répertoires contenus dans le dossier passé en paramètre
# avec une profondeur maximale
sub build_subdir_list {
    my ($dir, $list_ref, $max_depth) = @_;
    build_subdir_list_helper($dir, $list_ref, $max_depth - 1, 0);
}

sub build_subdir_list_helper {
    my ($dir, $list_ref, $max_depth, $depth) = @_;
  
    opendir(DIR, $dir) or die "can't open $dir: $!\n";
    my @files = readdir(DIR);
    closedir(DIR);

    foreach my $file (@files) {    
		next if $file =~ /^\.\.?$/;
		
		$file = $dir."/".$file;
		if (-d $file && ($depth < $max_depth)) {
	    	build_subdir_list_helper($file, $list_ref, $max_depth, $depth + 1);
		}
		else {
			if(-d $file) {
				push(@$list_ref, $file);
			}
		}
    }
}

1;