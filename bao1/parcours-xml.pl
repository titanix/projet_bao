require 'parcours-common.pl';

use warnings;
use strict;
use XML::LibXML;
use Try::Tiny;

# param $content : texte xml à traiter
# param $tag : nom (sans crochets) du tag xml dont il faut récupérer le contenu
# return : la liste des contenus du tag contenu dans le texte
sub extract_rss
{
	my ($content, $tag) = @_;
	
	my @list = ();
	my $parser = new XML::LibXML;
	
	try {
    	my $xml_doc = $parser->parse_string($content);

		foreach	my $t ($xml_doc->getElementsByTagName($tag))
		{
			push @list, $t->toStringEC14N;
		}
	} catch {
        warn "Erreur dans extract_rss : $_";
	};
	
	return @list;
}

main($ARGV[0], \&extract_rss);