use strict;
use warnings;

my $filename = "test.txt";

if(!open(PAT_FILE, "<:encoding(UTF-8)", "patterns.txt")) { die $! ; }
if(!open(DATA_FILE, $filename)) { die $! ; }
#if(!open(DATA_FILE, "<:encoding(UTF-8)", $filename)) { die $! ; }

my @patterns = ();
my @data = ();
my $word_pos = 0; # position du mot non lemmatisé dans une ligne de données
my $type_pos = 1; # position de l'indication de type dans une ligne de données

while(<PAT_FILE>)
{
	if (scalar(split(/\s+/, $_)) == 0) { next; } # anti-shit
	$_ =~ s/\R//; # idem
	push(@patterns, [split(/\s/, $_)]); # le peuple veut un tableau de tableau
}

while (<DATA_FILE>) {
	if ($_ =~ /^\S+\s+\S+\s+\S+$/) # on vérifie que les données sont conformes à nos attentes
	{
		$_ =~ s/\R//;
		push(@data, [split(/\s+/)]);
	}
}

# liste contenant, pour chaque motif, les chaînes de caractères correspondantes trouvées
my @result = ();
# liste temporaire qui contient la suite partielle de (type?) qui correspondent au motif courant
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
            if ($k == (scalar(@{$patterns[$m]}) - 1)) # quand on arrives à la fin du motif
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

