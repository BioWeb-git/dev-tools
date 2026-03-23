#!/bin/bash
set -e

# --- COULEURS ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c] " "$spinstr"
        local spinstr=$temp${spinstr:0:1}
        sleep $delay
        printf "\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

echo -e "${CYAN}## 🗄️ ASSISTANT BASE DE DONNÉES CONTAO ##${NC}"

# Demander le nom de la BDD
read -p "$(echo -e "${CYAN}Nom de la base de données à créer/restaurer : ${NC}")" DB_NAME

if [[ -z "$DB_NAME" ]]; then
    echo -e "${RED}Erreur : Le nom de la base est vide.${NC}"
    exit 1
fi

# --- GESTION MARIADB ---
echo -e "\n${CYAN}--- 1. Création de la Base de Données (MariaDB) ---${NC}"
sudo mysql <<EOF_SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO 'root'@'localhost';
FLUSH PRIVILEGES;
EOF_SQL
echo -e "${GREEN}✅ Base de données prête.${NC}"

# --- RESTORE & MIGRATE ---
echo -e "\n${CYAN}--- 2. Restauration du dump et Migration Contao ---${NC}"

if [ ! -f "vendor/bin/contao-console" ]; then
    echo -e "${RED}Erreur : Tu n'es pas dans la racine d'un projet Contao (vendor/bin/contao-console introuvable).${NC}"
    exit 1
fi

echo "   Exécution de contao:backup:restore et contao:migrate..."
{
    php vendor/bin/contao-console contao:backup:restore -n
    # 'echo 2' pour choisir l'option de migration classique si demandée
    echo 2 | php vendor/bin/contao-console contao:migrate --no-backup -n
} &
spinner $!

echo -e "\n${GREEN}✅ Opération terminée avec succès !${NC}"