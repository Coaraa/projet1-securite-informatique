# Liste des different senarios pris en charge par nos rules

## Ping

Pour pouvoir tester facilement le fonctionnement de notre systeme (snort elastic shearch et kibana).

rules :

```bash
alert icmp any any -> any any (msg:"ICMP Ping detected"; sid:1000001; rev:1;)
```

## Scan de port

Pour connaitre les possible faille de notre systeme l'attaquant peut vouloir scanner tout les ports de notre machine. Pour cela l'attaquant envoie un paquet SYN a chaque port de notre machine apres quoi il coupe rapidement la connexion.

Détection : On peut donc le detecter en identifiant une grande augmentation du nombre de paquet SYN recu sur une courte periode. Dans notre cas on leve une alerte si on recoit plus de 20 paquet dans un laps de temps inferieur a 60 secondes.

rules :

```bash
alert tcp any any -> $HOME_NET any (msg:"[CUSTOM] Possible SYN scan - many SYNs from single host"; flags:S; threshold: type both, track by_src, count 20, seconds 60; sid:1000010; rev:1;)
```

## SSH brute-force

L'attaquant essaye de deviner le mot de passe d'un utilisateur en envoyant un grand nombre de combinaisons nom d'utilisateur/mot de passe en esperant bien tombé.

Détection : Cette attaque vas generer un grand nombre de tentative de connexion SSH sur le port 22. Si plus de 10 tentative sont realisée en moins de 60 seconde, une alerte sera levé.

rules :

```bash
alert tcp any any -> $HOME_NET 22 (msg:"[CUSTOM] Possible SSH brute-force - many connections to port 22"; flow:to_server; threshold: type both, track by_src, count 10, seconds 60; sid:1000020; rev:1;)
```

## Injection XSS

L'objectif pour l'attaquant est d'injecter son code dans le site et de le faire executer par des utilisateurs normaux pour recuperer plusieurs informations sur ces derniers ou alors les redirigers vers un autre site (probablement malveillant).

Détection : On detecte le motif `script` utiliser dans la balise `<script>`.

rules :

```bash
alert tcp any any -> any 8000 (msg:"XSS <script dans payload brut TCP"; flow:to_server,established; content:"script"; sid:1000030; rev:1;)
```

## Path traversal

Pour acceder a des fichiers normalement innacessible, l'attaquant peut essayer de remonter plus loin que le repertoire racine en manipulant des URL.

Détection : Pour faire cela, la requette de l'attaquant devra contenir `../` ou `%2e%2e%2f`.

rules :

```bash
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] Path Traversal Attempt - double dot slash sequence"; flow:to_server; content:"../"; http_uri; nocase; sid:1000040; rev:1;)
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] Path Traversal Attempt - double dot slash sequence"; flow:to_server; content:"%2e%2e%2f"; http_uri; nocase; sid:1000041; rev:1;)
```

## Injection SQL

Sur un site où le Front envoie des requettes SQL au Back (souvent a travers des formulaires), l'attaquant peut essayer de modifier la requette SQL de sorte qu'il puisse executer ses propre requette sur notre Base de donnée (pour modifier des donnée, extraire des données sensible ou encore suprimer des tables...).

Détection : Il est alors commun de retrouver dans ca requette le motif suivant : `'OR '1'='1`. Nous detectons aussi les motifs :

- `DROP TABLE` : pour supprimer des données.
- `UNION SELECT` : pour recuperer plus de données que prevu initialement.
- `UPDATEXML` : Permet d'extraire des données en generant des erreurs.
- `SLEEP(` ou `waitfor delay`: permetent de deduire des infos sur les données de la base de données en fonction du temps de reponse.
- `--` : permet de commenter une partie de la requette SQL initial pour la modifier.

rules :

```bash
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] SQL Injection - UNION SELECT detected"; flow:to_server; content:"union select"; http_uri; nocase; sid:1000050; rev:1;)
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] SQL Injection - Time-Based Blind SQLi (SLEEP)"; flow:to_server; content:"sleep("; http_uri; nocase; sid:1000051; rev:1;)
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] SQL Injection - Time-Based Blind SQLi (WAITFOR)"; flow:to_server; content:"waitfor delay"; http_uri; nocase; sid:1000052; rev:1;)
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] Simple SQL Injection Attempt - 'OR 1=1'"; flow:to_server; content:"OR 1=1"; http_uri; sid:1000053; rev:1;)
```
