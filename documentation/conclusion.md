# Analyse et conclusion

Dans cette section, nous allons analyser l'architecture mise en place pour la détection des attaques en identifiant ses limites, en proposant des pistes d'amélioration et des perspectives basées sur la veille technologique.

## Limites actuelles du système

Bien que notre système offre une meilleure visibilité et une détection plus rapide des attaques, il présente certaines limites :

| Limite | Description |
|--------|-------------|   
| Faible sécurité | Lors de la mise en place de l'architecture, nous avons désactivé certaines mesures de sécurité pour faciliter les tests et le développement. Cela peut exposer le système à des vulnérabilités. |
| Abscence d'alertes en temps réel | Le système actuel ne génère pas d'alertes en temps réel, ce qui peut retarder la réponse aux incidents de sécurité. En effet, il est nécessaire de consulter les rapports manuellement pour identifier les menaces. |
| Couverture des menaces | Le système peut ne pas détecter toutes les formes d'attaques mais seulement celles pour lesquelles des règles spécifiques ont été définies. |
| Faux positifs | La détection basée sur des règles peut générer des faux positifs, ce qui peut entraîner une surcharge de travail pour les équipes de sécurité. |


## Pistes d'amélioration

Pour surmonter ces limites, plusieurs pistes d'amélioration peuvent être envisagées :

| Amélioration | Description |
|--------------|-------------|
| Renforcement de la sécurité | Réactiver et renforcer les mesures de sécurité du système pour protéger contre les vulnérabilités potentielles. |
| Système d'alertes en temps réel | Développer un système d'alertes en temps réel pour notifier immédiatement les équipes de sécurité en cas de détection d'une menace. |
| Mise à jour régulière des règles | Mettre en place un processus de mise à jour continue des règles de détection pour inclure les dernières menaces et vulnérabilités. |
| Intégration de l'IA | Utiliser des techniques d'intelligence artificielle pour améliorer la détection des menaces et réduire les faux positifs. |



## Perspectives et veille technologique

Pour rester à la pointe de la sécurité informatique, il est essentiel de maintenir une veille technologique active. On peut envisager les perspectives suivantes :

- Surveillance des tendances en cybersécurité
- Collaboration avec la communauté de la sécurité informatique  
- Adoption de nouvelles technologies comme l'IA et la blockchain
- Tests et audits réguliers


En conclusion, bien que notre système de détection des attaques présente certaines limites, il offre une première base pour la sécurité informatique.