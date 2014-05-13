require 'parcours-common.pl';
use strict;
use warnings;
use Data::Dumper;
use Parallel::ForkManager;
use File::Slurp;
use Encode;
require Encode::Detect;
use HTML::Entities;

sub parallel_main
{
	my ($rep) = @_;
	
	if(!defined($rep))
	{
		print "Missing argument repertory\n";
		exit 1;
	}
	
	$rep=~ s/[\/]$//; # on s'assure que le nom du répertoire ne se termine pas par un "/"
	my @files = ();
	my %worker_result = ();

	#build_file_list($rep, \@files);
	build_subdir_list($rep, \@files, 2);
print Dumper("list content [@files]\n");
	exit;
	
	my $pm = Parallel::ForkManager->new(4);

#print Dumper("list content [@files]\n");

	foreach my $file (@files)
	{
		# Forks and returns the pid for the child:
    	my $pid = $pm->start and next;
print $pid;
    	my $file_content = read_file($file);
		$file_content = decode("Detect", $file_content);
		clean_txt(\$file_content);
				
		my @titles = extract_tag_content($file_content, "title");
		#push(@out_list, [clean(remove_outer_tag($titles[0])), "rubrique"]);
				
		#foreach $item($proc->($file_content, "item"))
		#{
		#	my @titre = $proc->($item, "title");
		#	my @descr = $proc->($item, "description");
		#	push(@out_list, [clean(remove_outer_tag($titre[0])), "titre"]);
		#	push(@out_list, [clean(remove_outer_tag($descr[0])), "description"]);
		#}
    	
    	

    	$pm->finish; # Terminates the child process
	}
	$pm->wait_all_children;
	
	
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