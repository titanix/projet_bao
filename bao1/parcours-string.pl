require 'lib-parcours-common.pl';
require 'lib-parcours-string.pl';

if(!defined$ARGV[0])
{
	print "Il manque un argument au script.\n";
	print "usage : perl parcours-string.pl <nom_repertoire>\n";
	exit 1;
}

main($ARGV[0], \&extract_tag_content);
