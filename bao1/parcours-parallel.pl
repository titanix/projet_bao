require 'parcours-common.pl';
use strict;
use warnings;
use Data::Dumper;
use Parallel::ForkManager;
use File::Slurp;
use Encode;
require Encode::Detect;
use HTML::Entities;
use Data::GUID;

sub parallel_main
{
	my ($rep) = @_;
	my $proc = \&extract_tag_content;
	
	if(!defined($rep))
	{
		print "Missing argument repertory\n";
		exit 1;
	}
	
	$rep=~ s/[\/]$//; # on s'assure que le nom du répertoire ne se termine pas par un "/"
	my @folders = (); # listes des répertoires sur lesquels on travaille
	my %worker_result = ();
	my $pm = Parallel::ForkManager->new(3, '/tmp/');
	
	
	
	# fonction de callback d'un processus fils
  $pm -> run_on_finish ( # called BEFORE the first call to start()
    sub {
      my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data_structure_reference) = @_;

      # retrieve data structure from child
      if (defined($data_structure_reference)) {  # children are not forced to send anything
        #my $string = ${$data_structure_reference};  # child passed a string reference
        $worker_result{Data::GUID->new->as_string} = @$data_structure_reference;
        #print "$string\n";
      } else {  # problems occuring during storage or retrieval will throw a warning
        print qq|No message received from child process $pid!\n|;
      }
    }
  );

	

	build_subdir_list($rep, \@folders, 2);
#print "dir list built\n";
#exit;
	foreach my $folder (@folders)
	{
		# Forks and returns the pid for the child:
    	my $pid = $pm->start and next;
		my @xml_files = (); # on construit la listes des fichiers XML à traiter
		build_file_list($folder, \@xml_files);
		#my $guid = Data::GUID->new->as_string; # clefs des résultats du processus
		my @out_list = ();	
	
		foreach my $file (@xml_files) {
#print "working on file $file\n";
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
    	}
    	
    	#$worker_result{Data::GUID->new->as_string} = @out_list;
		# send it back to the parent process
		$pm->finish(0, \@out_list);  # note that it's a scalar REFERENCE, not the scalar itself



    	$pm->finish; # Terminates the child process
	}
	$pm->wait_all_children;
	
	print "finished!\n";
	print length(keys(%worker_result)), "\n";
	foreach my $k (keys(%worker_result)) {
		print "Clef=$k Valeur=$worker_result{$k}\n";
	}

	
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
		$end_tag_index - $start_tag_index + length($end_tag));
	
	$content = substr($content, $end_tag_index + length($end_tag));
	
	extract_tag_content_helper($content, $tag, $list);
}


parallel_main($ARGV[0]);