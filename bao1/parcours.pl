use Getopt::Long;

require 'lib-parcours-common.pl';
require 'lib-parcours-string.pl';
require 'lib-parcours-xml.pl';
require 'lib-parcours-parallel.pl';

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
--verbose			-v	Affichage d'informations verbeux [pas implémenté]
--help				-h	Affichage de ce message d'aide
END

my $res = GetOptions ('input_dir=s' => \$work_dir, 'output_dir:s' => \$out_dir,
	'proc:i' => \$proc, 'xml' => \$xml, 'help' => \$help);
	
# en utilisant une telle structure, on peut rajouter plus facilement des paramètres par la suite
my %conf = 
(
	'work_dir' => $work_dir,
	'out_dir' => $out_dir,
	'max_proc' => $proc,
	'use_xml' => $xml
);

if($help == 1)
{
	print $help_text;
	exit 0;
}
if($conf{'work_dir'} eq '')
{
	print "Erreur : le répertoire de travail n'est pas fixé.\n";
	print $help_text;
	exit 1;
}

if($conf{'use_xml'} == 1)
{
	$extract_fun = \&extract_xml;
}
if($conf{'max_proc'} > 0)
{
	parallel_main(\%conf, $extract_fun);
}
else
{
	main(\%conf, $extract_fun);
}
