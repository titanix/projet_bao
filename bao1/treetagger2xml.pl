#!/usr/bin/perl
<<DOC;
Format d\'entree : un texte �tiquet� et lemmatis� par tree tagger
Format de Sortie : le m�me texte au format xml
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
# R�cup�ration des arguments et ouverture des tampons
sub ouvre {
    $FichierEntree=$ARGV[0];
    open(Entree,$FichierEntree);
    $FichierSortie=$FichierEntree . ".xml";
    open(Sortie,">$FichierSortie");
}

# Ent�te de document XML
sub entete {
    print Sortie "<?xml version=\"1.0\" encoding=\"iso-8859-1\" standalone=\"no\"?>\n";
    print Sortie "<document>\n";
    print Sortie "<article>\n";
}

# Traitement
sub traitement {
    while ($Ligne = <Entree>) {
	if ($Ligne!~/\�\�\:\\�\�\:\\/) {
	# Remplacement des guillemets par <![CDATA["]]> (�vite erreur d'interpr�tation XML)
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
