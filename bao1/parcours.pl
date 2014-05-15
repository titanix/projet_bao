use Getopt::Long;

require 'lib-parcours-common.pl';
require 'lib-parcours-string.pl';
require 'lib-parcours-xml.pl';
require 'lib-parcours-parallel.pl';

#if(!defined$ARGV[0])
#{
#	print "Il manque un argument au script.\n";
#	print "usage : perl parcours-string.pl <nom_repertoire>\n";
#	exit 1;
#}

my $extract_fun = \&extract_tag_content;

my $work_dir = ''; # chemin vers le répertoire à analyser
my $out_dir = '.'; # chemin vers le répertoire de sortie
my $proc = 0; # nombre de processus maximal utilisé
my $xml = 0; # utilisation de l'extraction xml
my $help = 0; # affichage de l'aide

my $help_text = "usage : perl parcours.pl --input_dir=<dossier_entrée> [-]\n";

$help_text = <<END;
usage : perl parcours.pl --input_dir=<dossier_entrée> [options]

Les options suivantes sont disponibles (longues et courtes) :
--xml 				-x	Utilisations de l'extraction xml
--output_dir=<dossier>		-o	Chemin vers le dossier de sortie
--proc=N			-p	Nombre de processus maximal utilisé en parallèle
--verbose			-v	Affichage d'informations complémentaires durant l'exécution
--help				-h	Affichage de ce message d'aide
END

my $res = GetOptions ('input_dir=s' => \$work_dir, 'output_dir:s' => \$out_dir,
	'proc:i' => \$proc, 'xml' => \$xml, 'help' => \$help);
	
print "arg work_dir : $word_dir\n";
print "arg out_dir : $out_dir\n";
print "arg proc : $proc\n";
print "arg xml : $xml\n";
print "arg help : $help\n";	
print "arg verbose : $verbose\n";	
	
if($work_dir eq '')
{
	print "Erreur : le répertoire de travail n'est pas fixé.\n";
	print $help_text;
}

if($xml == 1)
{
	$extract_fun = \&extract_xml;
}
if($proc > 0)
{
	parallel_main($work_dir, $extract_fun, $proc, $out_dir);
}
else
{
	main($work_dir, $extract_fun, $out_dir);
}

#main($ARGV[0], \&extract_tag_content);
