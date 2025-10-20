# Liste des différents scénarios pris en charge par nos rules

## Ping

Pour pouvoir tester facilement le fonctionnement de notre système (snort elastic-search et kibana).

rules :

```bash
alert icmp any any -> any any (msg:"ICMP Ping detected"; sid:1000001; rev:1; priority:3;)
```

Priorité : 3 (faible) car ce n'est pas une attaque en soi, mais cela peut être utile pour un attaquant de savoir si une machine est en ligne ou non.

Méthode de test :

Depuis une autre machine, on peut envoyer un ping vers la machine sur laquelle snort est installé.

```bash
ping <adresse_ip_de_la_machine_snort>
```

**Log dans kibana :**
![ping_kibana](img\kibanaPing.png)

## Scan de port

Pour connaitre les possibles failles de notre système, l'attaquant peut vouloir scanner tous les ports de notre machine. Pour cela, l'attaquant envoie un paquet SYN à chaque port de notre machine, après quoi il coupe rapidement la connexion.

Détection : On peut donc le détecter en identifiant une grande augmentation du nombre de paquets SYN reçu sur une courte période. Dans notre cas on lève une alerte si on reçoit plus de 20 paquets dans un laps de temps inférieur a 60 secondes.

rules :

```bash
alert tcp any any -> $HOME_NET any (msg:"[CUSTOM] Possible SYN scan - many SYNs from single host"; flags:S; threshold: type both, track by_src, count 20, seconds 60; sid:1000010; rev:1; priority:2;)
```

Priorité : 2 (moyenne) car un scan de port est souvent synonyme de préparation d'une attaque plus importante.

Méthode de test :

Depuis une autre machine, on peut utiliser l'outil nmap pour scanner les ports de la machine sur laquelle snort est installé.

```bash
nmap -sS -p- <adresse_ip_de_la_machine_snort>
```

**Log dans kibana :**
![scan_kibana](img\kibanaScanPort.png)

## SSH brute-force

L'attaquant essaye de deviner le mot de passe d'un utilisateur en envoyant un grand nombre de combinaisons nom d'utilisateur/mot de passe en espérant bien tomber.

Détection : Cette attaque va générer un grand nombre de tentatives de connexion SSH sur le port 22. Si plus de 20 tentatives sont réalisées en moins de 30 secondes, une alerte sera levée.

rules :

```bash
alert tcp any any -> $HOME_NET 22 (msg:"[CUSTOM] Possible SSH brute-force - many connections to port 22"; flow:to_server; threshold: type both, track by_src, count 20, seconds 30; sid:1000020; rev:1; priority:1;)
```

Priorité : 1 (élevée) car une attaque brute-force réussie peut permettre à un attaquant d'accéder à notre système.

Méthode de test :

Depuis une autre machine, on peut utiliser l'outil hydra pour lancer une attaque brute-force sur le service SSH de la machine sur laquelle snort est installé. Les fichiers `users.txt` et `passwords.txt` contiennent respectivement une liste de noms d'utilisateurs et de mots de passe à tester.

```bash 
hydra -t 64 -f -V -L users.txt -P passwords.txt ssh://<adresse_ip_de_la_machine_snort> -s 22
```
**Log dans kibana :**
![ssh_bruteforce_kibana](img\kibanaBruteForce.png)

## Injection XSS

L'objectif pour l'attaquant est d'injecter son code dans le site et de le faire exécuter par des utilisateurs normaux pour récupérer plusieurs informations sur ces derniers ou alors les rediriger vers un autre site (probablement malveillant).

Détection : On détecte le motif `script` utilisé dans la balise `<script>`.

rules :

```bash
alert tcp any any -> any 8000 (msg:"[CUSTOM] XSS <script dans payload brut TCP"; flow:to_server,established; content:"script"; sid:1000030; rev:1; priority:2;)
```

Priorité : 2 (moyenne) car une attaque XSS peut permettre de récupérer des informations sensibles sur les utilisateurs du site.

Méthode de test :

La commande suivante permet de lancer un serveur web simple sur le port 8000 qui accepte des requêtes POST. Le code du serveur est disponible dans le dossier `python_server`.

```bash
python3 -m simple_server.py 8000
```

Depuis une autre machine, on peut utiliser l'outil curl pour envoyer une requête HTTP contenant une tentative d'injection XSS vers la machine sur laquelle snort est installé.

```bash
curl -X POST 'http://<adresse_ip_de_la_machine_snort>:8000/submit' -H 'User-Agent: SIEM-TEST-Agent/1.0' --data-urlencode 'username=testuser' --data-urlencode 'comment=<script>XSS_TEST_2025</script>'
```
**Log dans kibana :**
![xss_kibana](img\kibanaxss.png)

## Path traversal

Pour accéder à des fichiers normalement inaccessibles, l'attaquant peut essayer de remonter plus loin que le répertoire racine en manipulant des URL.

Détection : Pour faire cela, la requête de l'attaquant devra contenir `../` ou `%2e%2e%2f`.

rules :

```bash
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] Path Traversal Attempt - double dot slash sequence"; flow:to_server; content:"../"; http_uri; nocase; sid:1000040; rev:1; priority:2;)
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] Path Traversal Attempt - double dot slash sequence"; flow:to_server; content:"%2e%2e%2f"; http_uri; nocase; sid:1000041; rev:1; priority:2;)
```

Priorité : 2 (moyenne) car une attaque de path traversal réussie peut permettre à un attaquant d'accéder à des fichiers sensibles sur le serveur.

Méthode de test :

Toujours avec le même serveur web simple sur le port 8000, on peut utiliser l'outil curl pour envoyer une requête HTTP contenant une tentative de path traversal vers la machine sur laquelle snort est installé.

```bash
curl "http://<adresse_ip_de_la_machine_snort>:8000?file=../../../../etc/passwd"
```
**Log dans kibana :**
![path_traversal_kibana](img\kibanapath.png)

## Injection SQL

Sur un site où le Front envoie des requêtes SQL au Back (souvent à travers des formulaires), l'attaquant peut essayer de modifier la requête SQL de sorte qu'il puisse exécuter ses propres requêtes sur notre base de données (pour modifier des données, extraire des données sensibles ou encore supprimer des tables...).

Détection : Il est alors commun de retrouver dans sa requête le motif suivant : `'OR '1'='1`. Nous détectons aussi les motifs :

- `DROP TABLE` : pour supprimer des données.
- `UNION SELECT` : pour récupérer plus de données que prévu initialement.
- `UPDATEXML` : Permet d'extraire des données en générant des erreurs.
- `SLEEP(` ou `waitfor delay`: permettent de déduire des infos sur les données de la base de données en fonction du temps de réponse.
- `--` : permet de commenter une partie de la requête SQL initiale pour la modifier.

rules :

```bash
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] SQL Injection - UNION SELECT detected"; flow:to_server; content:"union select"; http_uri; nocase; sid:1000050; rev:1; priority:1;)
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] SQL Injection - Time-Based Blind SQLi (SLEEP)"; flow:to_server; content:"sleep("; http_uri; nocase; sid:1000051; rev:1; priority:1;)
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] SQL Injection - Time-Based Blind SQLi (WAITFOR)"; flow:to_server; content:"waitfor delay"; http_uri; nocase; sid:1000052; rev:1; priority:1;)
alert tcp any any -> $HOME_NET 8000 (msg:"[CUSTOM] Simple SQL Injection Attempt - 'OR 1=1'"; flow:to_server; content:"OR 1=1"; http_uri; sid:1000053; rev:1; priority:1;)
```

Priorité : 1 (élevée) car une injection SQL réussie peut compromettre gravement la sécurité de la base de données.

Méthode de test :

Toujours avec le même serveur web simple sur le port 8000, on peut utiliser l'outil curl pour envoyer une requête HTTP contenant une tentative d'injection SQL vers la machine sur laquelle snort est installé.

```bash
# Union select
curl "http://<adresse_ip_de_la_machine_snort>:8000?id=-1+UNION+SELECT+username,password+FROM+users"

# Simple 'OR 1=1'
curl "http://<adresse_ip_de_la_machine_snort>:8000?id=%27%20OR%201=1"

# Time-based blind SQLi pour MySQL
curl "http://<adresse_ip_de_la_machine_snort>:8000?user=admin'%20AND%20(SELECT%201%20FROM%20(SELECT(SLEEP(5)))a)%20A
ND%20'1'='1"

# Time-based blind SQLi pour MSSQL
curl "http://<adresse_ip_de_la_machine_snort>:8000?user=admin'%20;WAITFOR%20DELAY%20'0:0:5'%20--"
```
**Log dans kibana :**
![sql_injection_kibana](img\kibanaSQLinj.png)