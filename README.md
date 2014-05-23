projet_bao
==========

Projet universitaire master TAL M1

Organisation
------------

Le dossier est constitué de plusieurs répertoires, ayant chacun un but précis :
* baoN, qui contient les sources relatives au projet boite à outil N
* site, qui contient les sources pour construire le site, ainsi que le résultat ainsi produit

Installation de BAO1
--------------------

Pour fonctionner, le script de parcours de BAO1 a besoin de plusieurs modules complémentaires, présents sur CPAN.
Un script qui installe le programme cpan-minus et les modules tiers non présents dans une installation OS X de base
est fourni ; il se nomme install_dep.sh.
Il est a lancer en tant que root.

Construction du site
---------------------------

Pour générer une nouvelle version du site après modification du fichier template ou d'un fichier de contenu, il suffit d'utiliser make.
