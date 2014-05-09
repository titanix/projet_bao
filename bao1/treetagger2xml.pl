#!/usr/bin/perl
<<DOC;
Format d\'entree : un texte étiqueté et lemmatisé par tree tagger
Format de Sortie : le même texte au format xml
DOC


# Usage
$ChaineUsage="Usage : tt2xml.pl <Fichier>\n";
if (@ARGV!=1) {
 die $ChaineUsage;
}

&ouvre;
&entete;
&traitement;
&fin;
&ferme;

##############################################################################################
# Récupération des arguments et ouverture des tampons
sub ouvre {
    $FichierEntree=$ARGV[0];
    open(Entree,$FichierEntree);
    $FichierSortie=$FichierEntree . ".xml";
    open(Sortie,">$FichierSortie");
}

# Entête de document XML
sub entete {
    print Sortie "<?xml version=\"1.0\" encoding=\"iso-8859-1\" standalone=\"no\"?>\n";
    print Sortie "<document>\n";
    print Sortie "<article>\n";
}

# Traitement
sub traitement {
    while ($Ligne = <Entree>) {
	if ($Ligne!~/\ô\¯\:\\ô\¯\:\\/) {
	# Remplacement des guillemets par <![CDATA["]]> (évite erreur d'interprétation XML)
	    $Ligne=~s/\"/<![CDATA[\"]]>/g;
	    $Ligne=~s/([^\t]*)\t([^\t]*)\t(.*)/<element>\n <data type=\"type\">$2<\/data>\n <data type=\"lemma\">$3<\/data>\n <data type=\"string\">$1<\/data>\n<\/element>/;
	    print Sortie $Ligne;
	}
    }
}
# Fin de fichier
sub fin {
    print Sortie "</article>\n";
    print Sortie "</document>\n";
}

# Fermeture des tampons
sub ferme {
    close(Entree);
    close(Sortie);
}
