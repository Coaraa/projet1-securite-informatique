# Dashboard Kibana

Les dashboards Kibana permettent de visualiser et d'analyser les données de manière interactive. Ils offrent une vue d'ensemble des métriques clés et des tendances, facilitant ainsi la prise de décision basée sur les données.

## Création de nouveaux champs

Aller dans Data view > Add a field to this data view

Le nommer `Log_Type` et copier le script suivant dans le champ `Set value` :

```
if (doc.containsKey('message.keyword') && !doc['message.keyword'].empty) {
  def m = /\[\d+:\d+:\d+\]\s*(\[CUSTOM\]\s*)?([^\[]+?)\s*\[\*\*\]/.matcher(doc['message.keyword'].value);
  if (m.find()) {
    emit(m.group(2).trim());
  }
}
```

Sauvegarder le champ.

Cela permettra de filtrer les logs par type d'alerte dans les dashboards.
On peut voir qu'il retrouve bien les différents types d'attaques que nous avons testées.
![création champ logType](img\resultLogType.png)


De même, on crée un champ `Source_IP` avec le script suivant :

```
if (doc.containsKey('message.keyword') && !doc['message.keyword'].empty) {
  def m = /\{[A-Z0-9\-]+\}\s+([0-9a-fA-F\.:]+)/.matcher(doc['message.keyword'].value);
  if (m.find()) {
    emit(m.group(1));
  }
}

```
Cela permettra de voir si les attaques viennent de la même IP ou pas.
On peut voir qu'il retrouve bien les adresses IP sources des attaques.
![création champ sourceIP](img\resultSourceIP.png)


## Exportation du dashboard
Dans stack Management > Saved Objects 

Sélectionner le dashboard puis cliquer sur Export.

Un fichier `.ndjson` sera téléchargé, il pourra être importé dans une autre instance de Kibana.


## Importation du dashboard
Dans stack Management > Saved Objects > Importer

Sélectionner le fichier `.ndjson`.

Le dashboard sera importé et disponible dans l'onglet Dashboard de Kibana.

Si vous importez le dashboard du fichier `Dashboard.ndjson` fourni dans le dépôt, vous devriez obtenir un dashboard similaire à celui-ci :
![dashboard kibana](img\dashboard_kibana.png)

Il ne faut pas oublier de modifier la fenêtre de temps en haut à droite pour inclure toutes les données.
