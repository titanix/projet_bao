use strict;
use warnings;
use File::Slurp;


my $usage = 'Usage : build_site <template_file> <content_dir>';
#if(length(@ARGV) != 2)
#{
#	print "Incorrect number of arguments\n";
#	print $usage, "\n";
#	exit 1;
#}

my $template = $ARGV[0];
$template = read_file($template); # on lit le contenu de la template
my $dir = $ARGV[1];

opendir(DIR, $dir) || die "Can't open directory $dir\n";
while(my $file = readdir(DIR))
{
	next if $file =~ /^\..*$/;
	if($file =~ /\.html$/)
	{
		$file = "$dir/$file";
		if(-f $file)
		{
			my $file_content = read_file($file);
			my $result = $template;
			$result =~ s/CONTENT_PLACEHOLDER/$file_content/;
			write_result($result, "$dir/build/", $file);
		}
	}
}
closedir(DIR);

# param $content : contenu à écrire dans la sortie
# param $dir : répertoire de base dans lequel écrire le fichier
# param $name : nom du fichier d'où est originaire le contenu
sub write_result
{
	my ($content, $dir, $name) = @_;
	$name =~ /\/(.+?).html/;
	my $temp = "build/$1.html";
	open(FILE_OUT, ">$temp") or die "Shit happened!";
	print FILE_OUT $content;
	close(FILE_OUT);
}
