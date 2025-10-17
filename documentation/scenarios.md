# Liste des different senarios pris en charge par nos rules

## Scan de port

Pour connaitre les possible faille de notre systeme l'attaquant peut vouloir scanner tout les ports de notre machine. Pour cela l'attaquant envoie un paquet SYN a chaque port de notre machine apres quoi il coupe rapidement la connexion.

Détection : On peut donc le detecter en identifiant une grande augmentation du nombre de paquet SYN recu sur une courte periode. Dans notre cas on leve une alerte si on recoit plus de 20 paquet dans un laps de temps inferieur a 60 secondes.

## SSH brute-force

L'attaquant essaye de deviner le mot de passe d'un utilisateur en envoyant un grand nombre de combinaisons nom d'utilisateur/mot de passe en esperant bien tombé.

Détection : Cette attaque vas generer un grand nombre de tentative de connexion SSH sur le port 22. Si plus de 10 tentative sont realisée en moins de 60 seconde, une alerte sera levé.

## Injection XSS

L'objectif pour l'attaquant est d'injecter son code dans le site et de le faire executer par des utilisateurs normaux pour recuperer plusieurs informations sur ces derniers ou alors les redirigers vers un autre site (probablement malveillant).

Détection : On detecte le motif `script` utiliser dans la balise `<script>`.

## Injection SQL

Sur un site où le Front envoie des requettes SQL au Back (souvent a travers des formulaires), l'attaquant peut essayer de modifier la requette SQL de sorte qu'il puisse executer ses propre requette sur notre Base de donnée (pour modifier des donnée, extraire des données sensible ou encore suprimer des tables...). 

Détection : Il est alors commun de retrouver dans ca requette le motif suivant : `'OR '1'='1`. Nous detectons aussi les motifs :

- `DROP TABLE` : pour supprimer des données.
- `UNION SELECT` : pour recuperer plus de données que prevu initialement.
- `UPDATEXML` : Permet d'extraire des données en generant des erreurs.
- `SLEEP(` ou `waitfor delay`: permetent de deduire des infos sur les données de la base de données en fonction du temps de reponse.
- `--` : permet de commenter une partie de la requette SQL initial pour la modifier.

## Path traversal

Pour acceder a des fichiers normalement innacessible, l'attaquant peut essayer de remonter plus loin que le repertoire racine en manipulant des URL.

Détection : Pour faire cela, la requette de l'attaquant devra contenir `../` ou `%2e%2e%2f`.
