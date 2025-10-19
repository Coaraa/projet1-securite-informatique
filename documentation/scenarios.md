# Liste des différents scénarios pris en charge par nos rules

## Ping

Pour pouvoir tester facilement le fonctionnement de notre système (snort elastic-search et kibana).

rules :

```bash
alert icmp any any -> any any (msg:"ICMP Ping detected"; sid:1000001; rev:1;)
```

## Scan de port

Pour connaitre les possibles failles de notre système l'attaquant peut vouloir scanner tous les ports de notre machine. Pour cela l'attaquant envoie un paquet SYN a chaque port de notre machine après quoi il coupe rapidement la connexion.

Détection : On peut donc le détecter en identifiant une grande augmentation du nombre de paquets SYN reçu sur une courte période. Dans notre cas on lève une alerte si on reçoit plus de 20 paquets dans un laps de temps inférieur a 60 secondes.

rules :

```bash
alert tcp any any -> $HOME_NET any (msg:"[CUSTOM] Possible SYN scan - many SYNs from single host"; flags:S; threshold: type both, track by_src, count 20, seconds 60; sid:1000010; rev:1;)
```

## SSH brute-force

L'attaquant essaye de deviner le mot de passe d'un utilisateur en envoyant un grand nombre de combinaisons nom d'utilisateur/mot de passe en espérant bien tomber.

Détection : Cette attaque va générer un grand nombre de tentatives de connexion SSH sur le port 22. Si plus de 10 tentatives sont realisées en moins de 60 secondes, une alerte sera levée.

rules :

```bash
alert tcp any any -> $HOME_NET 22 (msg:"[CUSTOM] Possible SSH brute-force - many connections to port 22"; flow:to_server; threshold: type both, track by_src, count 10, seconds 60; sid:1000020; rev:1;)
```

## Injection XSS

L'objectif pour l'attaquant est d'injecter son code dans le site et de le faire exécuter par des utilisateurs normaux pour récupérer plusieurs informations sur ces derniers ou alors les rediriger vers un autre site (probablement malveillant).

Détection : On détecte le motif `script` utilisé dans la balise `<script>`.

rules :

```bash
alert tcp any any -> any 8000 (msg:"XSS <script dans payload brut TCP"; flow:to_server,established; content:"script"; sid:1000030; rev:1;)
```

## Path traversal

Pour accéder a des fichiers normalement innacessibles, l'attaquant peut essayer de remonter plus loin que le répertoire racine en manipulant des URL.

Détection : Pour faire cela, la requête de l'attaquant devra contenir `../` ou `%2e%2e%2f`.

rules :

```bash
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] Path Traversal Attempt - double dot slash sequence"; flow:to_server; content:"../"; http_uri; nocase; sid:1000040; rev:1;)
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] Path Traversal Attempt - double dot slash sequence"; flow:to_server; content:"%2e%2e%2f"; http_uri; nocase; sid:1000041; rev:1;)
```

## Injection SQL

Sur un site où le Front envoie des requêtes SQL au Back (souvent a travers des formulaires), l'attaquant peut essayer de modifier la requête SQL de sorte qu'il puisse exécuter ses propres requête sur notre Base de données (pour modifier des données, extraire des données sensible ou encore supprimer des tables...).

Détection : Il est alors commun de retrouver dans sa requête le motif suivant : `'OR '1'='1`. Nous détectons aussi les motifs :

- `DROP TABLE` : pour supprimer des données.
- `UNION SELECT` : pour récupérer plus de données que prévu initialement.
- `UPDATEXML` : Permet d'extraire des données en générant des erreurs.
- `SLEEP(` ou `waitfor delay`: permettent de déduire des infos sur les données de la base de données en fonction du temps de réponse.
- `--` : permet de commenter une partie de la requête SQL initiale pour la modifier.

rules :

```bash
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] SQL Injection - UNION SELECT detected"; flow:to_server; content:"union select"; http_uri; nocase; sid:1000050; rev:1;)
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] SQL Injection - Time-Based Blind SQLi (SLEEP)"; flow:to_server; content:"sleep("; http_uri; nocase; sid:1000051; rev:1;)
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] SQL Injection - Time-Based Blind SQLi (WAITFOR)"; flow:to_server; content:"waitfor delay"; http_uri; nocase; sid:1000052; rev:1;)
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] Simple SQL Injection Attempt - 'OR 1=1'"; flow:to_server; content:"OR 1=1"; http_uri; sid:1000053; rev:1;)
```
