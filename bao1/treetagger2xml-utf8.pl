use Unicode::String qw(utf8);

# Format d'entrée : un texte étiqueté et lemmatisé par 
# Treetagger et un format d'encodage
# Format de Sortie : le même texte au format xml (en utf-8)

# param $FichierEntree : fichier d'entrée à analyser
# param $encodage : encodage du fichier d'entrée
sub treetagger_to_xml
{
	my ($FichierEntree, $encodage) = @_;

    open(Entree,"<:encoding($encodage)", $FichierEntree);
    $FichierSortie = $FichierEntree . ".xml";
    open(Sortie,">:encoding(utf-8)", $FichierSortie);
    
	#print Sortie "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\"?>\n";
    #print Sortie "<document>\n";
    #print Sortie "<article>\n";
    
    while ($Ligne = <Entree>)
    {
		if (uc($encodage) ne "UTF-8" || uc($encodage) ne "UTF8")
		{
			utf8($Ligne);
		}
		if ($Ligne !~ /\ô\¯\:\\ô\¯\:\\/) 
		{
			# Remplacement des guillemets par <![CDATA["]]> (évite erreur d'interprétation XML)
	    	$Ligne =~ s/\"/<![CDATA[\"]]>/g;
	    	$Ligne =~ s/([^\t]*)\t([^\t]*)\t(.*)/<element>\n <data type=\"type\">$2<\/data>\n <data type=\"lemma\">$3<\/data>\n <data type=\"string\">$1<\/data>\n<\/element>/g;
	    	$Ligne =~ s/<unknown>/unknown/g;
	    	$Ligne =~ s/<img .*>/img<\/data>/g;
	    	$Ligne =~ s/<\/a>/unknown/g;
	    	$Ligne =~ s/<a href.*>/url<\/data>/g;
			$Ligne =~ s/&/ampersand/g;
	    	print Sortie $Ligne;
		}
    }
    
    #print Sortie "</article>\n";
    #print Sortie "</document>\n";
    
    close(Entree);
    close(Sortie);
    
	ferme;
}

1;