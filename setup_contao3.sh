#!/bin/bash
# Script spécifique pour Contao 3.5
set -e

# --- COULEURS ANSI ET FORMATAGE ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# --- CONFIGURATION ---
GITHUB_PAT=$(cat ~/.gh_token 2>/dev/null || echo "")

# Réinitialisation (évite les bugs quand le script est sourcé)
PROJECT_NAME=""
SELECTED_REPO=""
REPO_LIST=()
SKIP_SETUP=false

# --- 0. BASCULEMENT PHP 7.4 ---
echo -e "${CYAN}## 🚀 DÉMARRAGE DU SETUP CONTAO 3.5 ##${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -x "$SCRIPT_DIR/switch-php.sh" ]; then
    "$SCRIPT_DIR/switch-php.sh" contao3
else
    echo -e "${RED}Erreur : switch-php.sh introuvable dans $SCRIPT_DIR.${NC}"
    exit 1
fi

# --- 0. MENU DE SÉLECTION ---
echo -e "${CYAN}Quel type d'exécution souhaitez-vous ?${NC}"
echo -e "  0. Tout lancer (défaut)"
echo -e "  1. Sélection du dépôt"
echo -e "  2. Clonage et Base de données"
echo -e "  3. Configuration .env"
echo -e "  4. Installations (npm/composer/bower) et Build"
echo -e "  5. Configuration des permissions"
echo -e "  6. Optimisation .htaccess (exclusion domaine local)"
echo -e "  7. Configuration Apache"
echo -e "  8. Synchronisation rsync"
read -p "Votre choix [0-8] (Entrée = 0) : " STEP_CHOICE
[ -z "$STEP_CHOICE" ] && STEP_CHOICE=0

# On s'assure de démarrer depuis le dossier personnel
cd "$HOME"

# --- 1. SÉLECTION DU DÉPÔT ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "1" ]]; then
echo -e "\n${CYAN}1/8. Chargement des dépôts Git BioWeb...${NC}"
# Utilisation d'un fichier temporaire pour éviter les problèmes de subshell
TMP_REPOS=$(mktemp)
gh repo list BioWeb-git --limit 100 | cut -f1 > "$TMP_REPOS"

REPO_LIST=()
while read -r line; do
    [ -n "$line" ] && REPO_LIST+=("$line")
done < "$TMP_REPOS"
rm "$TMP_REPOS"

if [ ${#REPO_LIST[@]} -eq 0 ]; then
    echo -e "${RED}Erreur : Aucun dépôt trouvé.${NC}"
    exit 1
fi

for i in "${!REPO_LIST[@]}"; do
    echo "  $((i+1)). ${REPO_LIST[i]}"
done

while true; do
    read -p "$(echo -e "${CYAN}Entrez le NUMÉRO du dépôt à cloner : ${NC}")" CHOICE_NUMBER
    if [[ "$CHOICE_NUMBER" =~ ^[0-9]+$ ]] && [ "$CHOICE_NUMBER" -ge 1 ] && [ "$CHOICE_NUMBER" -le "${#REPO_LIST[@]}" ]; then
        SELECTED_REPO="${REPO_LIST[$((CHOICE_NUMBER - 1))]}"
        PROJECT_NAME=$(echo "$SELECTED_REPO" | cut -d'/' -f2)
        break
    fi
    echo -e "${RED}Choix invalide.${NC}"
done


fi

# Si on a sauté l'étape 1, on essaie de deviner PROJECT_NAME s'il n'est pas là
if [ -z "$PROJECT_NAME" ] && [ "$STEP_CHOICE" -gt 1 ]; then
    echo -e "${YELLOW}PROJECT_NAME non défini. Voici les dossiers locaux :${NC}"
    LOCAL_DIRS=($(ls -d */ | sed 's/\///' | head -n 10))
    for i in "${!LOCAL_DIRS[@]}"; do
        echo "  $((i+1)). ${LOCAL_DIRS[i]}"
    done
    while true; do
        read -p "Entrez le NUMÉRO du dossier projet : " DIR_CHOICE
        if [[ "$DIR_CHOICE" =~ ^[0-9]+$ ]] && [ "$DIR_CHOICE" -ge 1 ] && [ "$DIR_CHOICE" -le "${#LOCAL_DIRS[@]}" ]; then
            PROJECT_NAME="${LOCAL_DIRS[$((DIR_CHOICE - 1))]}"
            break
        fi
        echo -e "${RED}Choix invalide.${NC}"
    done
fi

# Dérivation des variables (toujours nécessaire)
if [ -n "$PROJECT_NAME" ]; then
    DOMAIN_LOCAL="${PROJECT_NAME}.test"
    DB_NAME="${PROJECT_NAME//-/_}_test"
    REPO_URL="git@github.com:BioWeb-git/${PROJECT_NAME}.git"
fi

# On entre dans le dossier projet s'il existe déjà (important pour les étapes modulaires)
if [ -d "$PROJECT_NAME" ]; then
    cd "$PROJECT_NAME"
fi

# --- 2. CLONAGE ET BDD ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "2" ]]; then
echo -e "\n${CYAN}2/8. Clonage et Base de données...${NC}"
SKIP_SETUP=false
if [ -d "$PROJECT_NAME" ]; then
    echo -e "${YELLOW}Le dossier $PROJECT_NAME existe déjà.${NC}"
    read -p "Voulez-vous le (s)upprimer, (c)ontinuer (ignorer clone/BDD) ou (a)nnuler ? (s/c/a) : " CHOICE_DEL
    if [[ "$CHOICE_DEL" == "s" ]]; then
        sudo rm -rf "$PROJECT_NAME"
    elif [[ "$CHOICE_DEL" == "c" ]]; then
        echo "   Mise à jour via git pull (optionnel) et passage à la suite..."
        SKIP_SETUP=true
    else
        exit 0
    fi
fi

if [ "$SKIP_SETUP" = false ]; then
    git clone "$REPO_URL" "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO 'root'@'localhost'; FLUSH PRIVILEGES;"
    echo -e "${GREEN}✅ Base de données $DB_NAME prête.${NC}"
else
    cd "$PROJECT_NAME"
    git pull || echo "   Attention : Échec du git pull."
fi

fi

# --- 3. CONFIGURATION .ENV ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "3" ]]; then
if [ "$SKIP_SETUP" = false ] || [ ! -f ".env" ]; then
    echo -e "\n${CYAN}3/8. Configuration du fichier .env...${NC}"
    cat > .env <<EOF_ENV
# Template .env pour Contao 3
DATABASE_NAME=${DB_NAME}
DATABASE_USER=root
DATABASE_PASSWORD=
EOF_ENV

    echo -e "${YELLOW}⚠️  Fichier .env créé. Voici les valeurs à configurer :${NC}"
    echo -e "--------------------------------------------------------"
    echo -e "${CYAN}DB_NAME=\"${DB_NAME}\"${NC}"
    echo -e "${CYAN}DB_USER=\"root\"${NC}"
    echo -e "${CYAN}DB_PASSWORD=\"\"${NC}"
    echo -e "${CYAN}INSTALL_DOMAIN=\"${DOMAIN_LOCAL}\"${NC}"
    echo -e "--------------------------------------------------------"

    read -p "Une fois le fichier mis à jour, appuyez sur [ENTRÉE] pour continuer..."
else
    echo -e "\n${GREEN}✅ Fichier .env déjà présent. On continue.${NC}"
fi

fi

# --- 4. INSTALLATIONS ET BUILD ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "4" ]]; then
echo -e "\n${CYAN}4/8. Installations (npm, composer, bower) et Build...${NC}"

# Chargement de NVM
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    echo "Chargement de NVM..."
    
    # Pour Contao 3.5, on utilise idéalement Node 12 pour la compatibilité node-sass
    NODE_VERSION="14" # On commence par 14 car tu l'as déjà, mais 12 serait mieux
    echo "Basculement vers Node $NODE_VERSION..."
    nvm use $NODE_VERSION || nvm install $NODE_VERSION
else
    echo -e "${YELLOW}⚠️ NVM non trouvé. Tentative avec le Node actuel : $(node -v)${NC}"
fi

if [ -f "package.json" ]; then
    echo "Lancement de npm install..."
    # On force l'utilisation de python2 si disponible pour node-sass
    if command -v python2 >/dev/null 2>&1; then
        npm config set python python2
    else
        echo -e "${YELLOW}⚠️  Python 2 non trouvé. 'node-sass' risque d'échouer.${NC}"
        echo -e "${YELLOW}   Pour corriger : sudo apt install python2-minimal${NC}"
    fi
    npm install || echo -e "${RED}⚠️  Erreur npm install. Si 'node-sass' a échoué, installez python2 ou essayez Node 10.${NC}"
fi

if [ -f "composer.json" ]; then
    echo "Lancement de composer install..."
    composer install --no-dev || {
        echo -e "${YELLOW}⚠️  Certaines extensions PHP manquent (curl, intl...).${NC}"
        echo -e "${YELLOW}   Tentative avec --ignore-platform-reqs...${NC}"
        composer install --no-dev --ignore-platform-reqs
    }
fi

if [ -f "bower.json" ]; then
    echo "Lancement de bower install..."
    bower install --allow-root
fi

if [ -f "system/build/build" ]; then
    echo "Lancement du build..."
    php system/build/build create
fi

fi

# --- 5. PERMISSIONS ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "5" ]]; then
echo -e "\n${CYAN}5/8. Configuration des permissions...${NC}"
# On s'assure que les dossiers sensibles sont accessibles en écriture pour Apache
# Comme www-data est dans le groupe pouet, le 775 suffit
chmod -R 775 assets system/tmp system/logs system/config system/cache 2>/dev/null || true
echo -e "${GREEN}✅ Permissions configurées.${NC}"

fi

# --- 6. OPTIMISATION .HTACCESS ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "6" ]]; then
echo -e "\n${CYAN}6/8. Optimisation du .htaccess (Exclusion domaine local)...${NC}"
if [ -f ".htaccess" ]; then
    echo "   Ajout de la condition d'exclusion pour $DOMAIN_LOCAL..."
    # On commence par nettoyer une éventuelle version précédente
    sed -i "/RewriteCond %{HTTP_HOST} !=${DOMAIN_LOCAL}/d" .htaccess
    # On insère après RewriteRule ^ - [L] (très commun dans Contao 3)
    if grep -q "RewriteRule ^ - \[L\]" .htaccess; then
        sed -i "/RewriteRule \^ - \[L\]/a \  RewriteCond %{HTTP_HOST} !=${DOMAIN_LOCAL}" .htaccess
    else
        # Fallback sur RewriteEngine On si la règle n'est pas trouvée
        sed -i "/RewriteEngine On/a \  RewriteCond %{HTTP_HOST} !=${DOMAIN_LOCAL}" .htaccess
    fi
    echo -e "${GREEN}✅ .htaccess optimisé.${NC}"
else
    echo -e "${YELLOW}⚠️  Aucun fichier .htaccess trouvé.${NC}"
fi

fi

# --- 7. CONFIG APACHE ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "7" ]]; then
echo -e "\n${CYAN}7/8. Configuration Apache...${NC}"
USER_HOME="$HOME"
sudo cat <<EOF_VH | sudo tee /etc/apache2/sites-available/${DOMAIN_LOCAL}.conf > /dev/null
<VirtualHost *:80>
    ServerName ${DOMAIN_LOCAL}
    DocumentRoot ${USER_HOME}/${PROJECT_NAME}
    <Directory ${USER_HOME}/${PROJECT_NAME}>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/${PROJECT_NAME}-error.log
    CustomLog \${APACHE_LOG_DIR}/${PROJECT_NAME}-access.log combined
</VirtualHost>
EOF_VH

sudo a2ensite "${DOMAIN_LOCAL}.conf"
sudo systemctl reload apache2
echo -e "${GREEN}✅ Apache relancé (configuration appliquée).${NC}"

fi

# --- 8. SYNCHRONISATION DES FICHIERS ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "8" ]]; then
echo -e "\n${CYAN}8/8. Synchronisation des fichiers (optionnel)...${NC}"
read -p "$(echo -e "${YELLOW}Voulez-vous synchroniser le dossier /files depuis la production ? (y/n) : ${NC}")" DO_SYNC
if [[ "$DO_SYNC" == "y" ]]; then
    read -p "$(echo -e "${YELLOW}Domaine de production (ex: daquota.fr) : ${NC}")" PROD_DOMAIN
    RSYNC_CMD="rsync -avz forge@54.37.23.174:/home/forge/${PROD_DOMAIN}/files/ ./files/"
    echo -e "Commande suggérée : ${CYAN}$RSYNC_CMD${NC}"
    read -p "Appuyez sur [ENTRÉE] pour lancer la synchro ou Ctrl+C pour annuler..."
    eval $RSYNC_CMD
fi

fi

echo -e "\n${GREEN}✅ ÉTAPE(S) TERMINÉE(S) !${NC}"
echo -e "--------------------------------------------------------"
echo -e "${YELLOW}N'oubliez pas d'ajouter l'entrée suivante dans votre fichier HOSTS Windows :${NC}"
echo -e "::1    ${DOMAIN_LOCAL}"
echo -e "127.0.0.1    ${DOMAIN_LOCAL}"
echo "--------------------------------------------------------"
