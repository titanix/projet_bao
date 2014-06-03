use strict;
use warnings;
use Getopt::Long;
use XML::XPath;

use utf8;
binmode STDOUT, ':encoding(UTF-8)';

my $filename = '<pas de fichier>'; # chemin du fichier à traiter
my $patt_file = 'patterns.txt'; # chemin du fichier de motif
my $use_cordial = 0; # utilise l'ordre des fichiers générés par Cordial
my $help = 0; # affiche l'aide ou non

my $help_text = "usage : perl parcours.pl --file=<fichier_à_traite> [options]\n";

$help_text = <<END;
usage : perl extract_pattern.pl --file=<fichier_à_traiter> [options]

Les options suivantes sont disponibles (formes longues puis courtes) :
--patterns		-p Nom du fichier contenant les motifs à utiliser.
--help			-h Affiche ce message d'aide et quitte le programme.
END

my $res = GetOptions (
	'file=s' => \$filename, 
	'patterns:s' => \$patt_file,
	'help' => \$help);
	
if(! -f $filename)
{
	print "Erreur le fichier suivant est introuvable : $filename\n";
	exit 1;
}

if($help == 1)
{
	print $help_text;
	exit 0;
}

# valeurs par défaut pour TreeTagger
my $word_pos = 0; # position du mot non lemmatisé dans une ligne de données
my $type_pos = 1; # position de l'indication de type dans une ligne de données

if(!open(PAT_FILE, "<:encoding(UTF-8)", $patt_file)) { die $!; }

my $xp = XML::XPath->new(filename =>$filename) or die $!;

my @patterns = ();
my @data = ();

while(<PAT_FILE>)
{
	if (scalar(split(/\s+/, $_)) == 0) { next; } # anti-shit
	$_ =~ s/\R//; # idem
	push(@patterns, [split(/\s/, $_)]); # le peuple veut un tableau de tableau
}

my $nodeset = $xp->find('//element');

foreach my $element ($nodeset->get_nodelist) 
{
	push(@data,
		[$xp->find("./data[\@type='string']", $element)->get_node(1)->string_value(),
		$xp->find("./data[\@type='type']", $element)->get_node(1)->string_value(),
		$xp->find("./data[\@type='lemma']", $element)->get_node(1)->string_value()]);
}

# liste contenant, pour chaque motif, les chaînes de caractères correspondantes trouvées
my @result = ();
# liste temporaire qui contient la suite partielle de catégories syntaxiques
# qui correspondent au motif courant
my @temp = ();
# j'utilise la suite i, k, m pour les boucles plutôt que i, j, k car j ressemble trop à i
my ($i, $k, $m, $r);

for ($m = 0;  $m < scalar(@patterns); $m++, $r = 0) # pour chaque motif
{
	for ($i = 0; $i < scalar(@data); $i++) # pour tous les termes
	{
        for ($k = 0; $k < scalar(@{$patterns[$m]}); $k++) # pour les morceaux du motif
        {
            if ($data[$i + $k][$type_pos] eq $patterns[$m][$k]) # quand tout se déroule comme prévu
            {
            	push (@temp, $data[$i + $k][$word_pos]); # on stocke le mot correspondant
            }
            else # si le motif n'est pas celui qu'on veut, il faut quitter la boucle k
            {
                @temp = ();
                last; # break
            }
            if ($k == (scalar(@{$patterns[$m]}) - 1)) # quand on arrive à la fin du motif
            {
				$result[$m][$r++] = join(' ', @temp);
                @temp = ();
            }
        }
	}
}

for ($i = 0; $i < scalar(@result); $i++) # pour tout les motifs
{
	if (defined(@{$result[$i]}))
	{
		print "* Résultat(s) pour le motif @{$patterns[$i]}\n";
		foreach (@{$result[$i]})
		{
			print "\t$_\n";
		}
	}
	else
	{
		# n'affiche pas de message pour les motifs sans résultats pour lesquels il n'y a pas un
		# motif avec résultat plus loin dans le fichier car le tableau est créé dynamiquement 
		# (Perl est exaspérant ...)
		print "* Aucun résultat pour le motif @{$patterns[$i]}\n";
	}
}
