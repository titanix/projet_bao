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

sub parallel_main
{
	my ($rep, $nb_proc) = @_;

	if(!defined()) {
		$nb_proc = 4;
	} else {
		$nb_proc = $nb_proc + 0;
	}
	
	my $start = time();
	my $proc = \&extract_tag_content;
	
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
			clean_txt(\$file_content);
				
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
	
	foreach my $key (keys(%worker_result)) {
		# normalement les valeurs sont des références vers une liste de tableaux
		foreach (${worker_result{$key}})
		{
			foreach my $pair (@{$_}) # super lisible !
			{
				my $hash;
				try {
			 		$hash = md5_base64(decode_utf8($pair->[0])) or die "$!\n";
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

	write_result(\@resulting_merged_list);
	
	my $end = time();
	printf("Temps d'exécution : %.2f\n", $end - $start);
	exit 0;
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

# construit une liste des répertoire contenu dans le dossier passé en paramètre
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

if(!defined($ARGV[0]))
{
	print "Il manque un argument au script.\n";
	print "usage : perl parcours-parallel.pl <nom_repertoire>\n";
	exit 1;
}

parallel_main(@ARGV);