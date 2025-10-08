# -----------------------------
# Étape 4 : Configuration
# -----------------------------
echo "=== Copie des fichiers de configuration ==="
sudo cp ./config/kibana.yml /etc/kibana/kibana.yml
sudo cp ./config/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
sudo cp ./config/snort-to-elastic.conf /etc/syslog-ng/conf.d/
sudo cp ./config/syslog-ng.conf /etc/syslog-ng/

echo "=== Configuration du nom du nœud maître Elasticsearch ==="
read -p "Entrez le nom du nœud maître Elasticsearch (ex: serverproject1) : " master_node
if grep -q '^cluster\.initial_master_nodes:' /etc/elasticsearch/elasticsearch.yml; then
    sudo sed -i "s/^cluster\.initial_master_nodes:.*/cluster.initial_master_nodes: [\"${master_node}\"]/" /etc/elasticsearch/elasticsearch.yml
else
    echo "cluster.initial_master_nodes: [\"${master_node}\"]" | sudo tee -a /etc/elasticsearch/elasticsearch.yml
fi

# -----------------------------
# Étape 5 : Activation des services
# -----------------------------
echo "=== Activation et démarrage des services ==="

sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

# Attendre qu'Elasticsearch soit actif avant Kibana
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

# -----------------------------
# Étape 6 : Vérification des versions
# -----------------------------
echo "=== Vérification des versions installées ==="
echo "Elasticsearch : $(dpkg -l | grep elasticsearch | awk '{print $3}')"
echo "Kibana        : $(dpkg -l | grep kibana | awk '{print $3}')"
echo "Syslog-ng     : $(dpkg -l | grep syslog-ng | awk '{print $3}' | head -n1)"
echo "Snort         : $(dpkg -l | grep snort | awk '{print $3}')"

# -----------------------------
# Fin du script
# -----------------------------
echo ""
echo "=== ✅ Installation terminée avec succès ==="
echo "Les services Elasticsearch, Kibana, Syslog-ng et Snort sont démarrés."
echo ""
echo "Tu peux accéder à Kibana via : http://localhost:5601"