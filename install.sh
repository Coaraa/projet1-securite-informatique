#!/bin/bash

# Script d'installation et de configuration pour Elasticsearch, Kibana, Syslog-ng et Snort

set -e

echo "=== Mise à jour du système ==="
sudo apt update && sudo apt upgrade -y

echo "=== Téléchargement des paquets requis ==="
mkdir -p ./packages
cd ./packages

wget -nc https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-9.1.4-amd64.deb
wget -nc https://artifacts.elastic.co/downloads/kibana/kibana-9.1.4-amd64.deb

wget -nc http://archive.ubuntu.com/ubuntu/pool/universe/s/syslog-ng/syslog-ng_4.3.1-2build5_all.deb
wget -nc http://archive.ubuntu.com/ubuntu/pool/universe/s/syslog-ng/syslog-ng-mod-http_4.3.1-2build5_amd64.deb

wget -nc http://archive.ubuntu.com/ubuntu/pool/universe/s/snort/snort_2.9.20-0+deb11u1ubuntu1_amd64.deb

cd ..

echo "=== Installation d'Elasticsearch ==="
sudo dpkg -i ./packages/elasticsearch-9.1.4-amd64.deb || sudo apt-get install -f -y

echo "=== Installation de Kibana ==="
sudo dpkg -i ./packages/kibana-9.1.4-amd64.deb || sudo apt-get install -f -y

echo "=== Installation de Syslog-ng ==="
sudo dpkg -i ./packages/syslog-ng_4.3.1-2build5_all.deb || true
sudo dpkg -i ./packages/syslog-ng-mod-http_4.3.1-2build5_amd64.deb || true
sudo apt-get install -f -y

echo "=== Installation de Snort ==="
sudo apt install ./packages/snort_2.9.20-0+deb11u1ubuntu1_amd64.deb -y

echo "=== Copie des fichiers de configuration ==="
sudo cp ./config/kibana.yml /etc/kibana/kibana.yml
sudo cp ./config/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
sudo cp ./config/snort-to-elastic.conf /etc/syslog-ng/conf.d/
sudo cp ./config/syslog-ng.conf /etc/syslog-ng/
sudo cp ./config/snort.conf /etc/snort/
sudo cp ./config/local.rules /etc/snort/rules/

echo "=== Configuration du nom du nœud maître Elasticsearch ==="
read -p "Entrez le nom de votre machine (ex: serverproject1) : " master_node
if grep -q '^cluster\.initial_master_nodes:' /etc/elasticsearch/elasticsearch.yml; then
    sudo sed -i "s/^cluster\.initial_master_nodes:.*/cluster.initial_master_nodes: [\"${master_node}\"]/" /etc/elasticsearch/elasticsearch.yml
else
    echo "cluster.initial_master_nodes: [\"${master_node}\"]" | sudo tee -a /etc/elasticsearch/elasticsearch.yml
fi

echo "=== Activation et démarrage des services ==="

sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

echo "=== Attente du démarrage d'Elasticsearch... ==="
until curl -s http://localhost:9200 >/dev/null 2>&1; do
    sleep 3
    echo "  → Elasticsearch non encore disponible..."
done
echo "✅ Elasticsearch est en ligne."

sudo systemctl enable kibana
sudo systemctl start kibana

sudo systemctl enable syslog-ng
sudo systemctl start syslog-ng

sudo systemctl start snort

echo "=== Vérification des versions installées ==="
echo "Elasticsearch : $(dpkg -l | grep elasticsearch | awk '{print $3}')"
echo "Kibana        : $(dpkg -l | grep kibana | awk '{print $3}')"
echo "Syslog-ng     : $(dpkg -l | grep syslog-ng | awk '{print $3}' | head -n1)"
echo "Snort         : $(dpkg -l | grep snort | awk '{print $3}')"

echo ""
echo "=== ✅ Installation terminée avec succès ==="
echo "Les services Elasticsearch, Kibana, Syslog-ng et Snort sont démarrés."
echo ""
echo "Tu peux accéder à Kibana via : http://localhost:5601"
