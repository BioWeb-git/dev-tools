#!/bin/bash
# Arrête immédiatement le script si une commande échoue (mode robuste)
set -e

# --- COULEURS ANSI ET FORMATAGE ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# --- CONFIGURATION (TOKEN GITHUB) ---
# Le jeton est lu depuis un fichier externe pour éviter de l'exposer dans Git
GITHUB_PAT=$(cat ~/.gh_token 2>/dev/null || echo "")

# Fonction de spinner (pour feedback visuel)
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

# -----------------------------------------------------------------------
# On s'assure de démarrer depuis le dossier personnel pour éviter de cloner dans n'importe quel sous-dossier
cd "$HOME"

echo -e "${CYAN}## 🚀 DÉMARRAGE DE L'ASSISTANT CONTAO LOCAL ##${NC}"
echo "--------------------------------------------------------"

# --- 0. MENU DE SÉLECTION ---
echo -e "${CYAN}Quel type d'exécution souhaitez-vous ?${NC}"
echo -e "  0. Tout lancer (défaut)"
echo -e "  1. Acquisition du code (Action 1/2 + Sélection dépôt)"
echo -e "  2. Gestion Base de données"
echo -e "  3. Configuration .env"
echo -e "  4. Configuration Auth GitHub (auth.json)"
echo -e "  5. Installations (Composer)"
echo -e "  6. Permissions et ACLs"
echo -e "  7. Migration BDD"
echo -e "  8. Synchronisation Rsync"
echo -e "  9. Configuration Apache"
read -p "Votre choix [0-9] (Entrée = 0) : " STEP_CHOICE
[ -z "$STEP_CHOICE" ] && STEP_CHOICE=0

# --- 1. DÉFINITION DES VARIABLES (INPUT UTILISATEUR) ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "1" ]]; then

read -p "$(echo -e "${CYAN}1/3. Quel type de projet souhaitez-vous lancer ?\n  (1) Cloner dépôt existant\n  (2) Créer nouveau à partir de modèle Contao 5\nVotre choix (1/2) : ${NC}")" CHOICE_ACTION

# Vérification que le choix est bien 1 ou 2
if [[ "$CHOICE_ACTION" != "1" && "$CHOICE_ACTION" != "2" ]]; then
    echo -e "${RED}Erreur : Choix d'action invalide. Le script est arrêté.${NC}"
    exit 1
fi

if [[ "$CHOICE_ACTION" == "1" ]]; then
    echo -e "\n${CYAN}2/3. Chargement des dépôts Git accessibles... (max. 100)${NC}"
    
    # 1. Récupérer la liste des dépôts OWNER/NAME
    REPO_LIST=()
    while IFS=$'\t' read -r full_name description _; do
        REPO_LIST+=("$full_name")
    done < <(gh repo list BioWeb-git --limit 100) # gh doit être installé et authentifié

    # Vérifier si la liste est vide
    if [ ${#REPO_LIST[@]} -eq 0 ]; then
        echo -e "${RED}Erreur : Aucun dépôt Git trouvé ou vous n'êtes pas authentifié ('gh auth login'). Le script est arrêté.${NC}"
        exit 1
    fi
    
    # 2. Afficher la liste numérotée
    echo "--------------------------------------------------------"
    for i in "${!REPO_LIST[@]}"; do
        echo "  $((i+1)). ${REPO_LIST[i]}"
    done
    echo "--------------------------------------------------------"

    # 3. Demander le choix et définir PROJECT_NAME
    while true; do
        read -p "$(echo -e "${CYAN}Entrez le NUMÉRO du dépôt à cloner ou (a)nnuler : ${NC}")" CHOICE_NUMBER
        
        if [[ "$CHOICE_NUMBER" == "a" ]]; then
            echo -e "${YELLOW}Opération annulée.${NC}"
            exit 0
        fi
        
        # Validation du numéro
        if [[ "$CHOICE_NUMBER" =~ ^[0-9]+$ && "$CHOICE_NUMBER" -ge 1 && "$CHOICE_NUMBER" -le ${#REPO_LIST[@]} ]]; then
            PROJECT_INDEX=$((CHOICE_NUMBER - 1))
            FULL_REPO_NAME="${REPO_LIST[PROJECT_INDEX]}"
            
            # PROJECT_NAME prend le nom du dépôt seulement (après le dernier '/')
            PROJECT_NAME="${FULL_REPO_NAME##*/}"
            echo -e "${GREEN}Dépôt sélectionné : ${FULL_REPO_NAME} (Nom du projet : $PROJECT_NAME)${NC}"
            break
        else
            echo -e "${RED}Choix invalide. Veuillez entrer un numéro valide ou 'a'.${NC}"
        fi
    done
    read -p "$(echo -e "${CYAN}3/3. URL Externe (ex: site.bioweb.fr ou www.domaine-client.fr) : ${NC}")" DOMAIN_EXTERNAL
elif [[ "$CHOICE_ACTION" == "2" ]]; then
    # --- CORRECTION : SAISIE DU NOM DU PROJET (2/3) ---
    echo -e "\n${CYAN}2/3. Entrez le nom du nouveau projet (ex: mon-site-client) : ${NC}"
    read -p "$(echo -e "${CYAN}Nom du projet : ${NC}")" PROJECT_NAME
    
    # Validation minimale pour PROJECT_NAME
    if [[ -z "$PROJECT_NAME" ]]; then
        echo -e "${RED}Erreur : Le nom du projet ne peut pas être vide. Le script est arrêté.${NC}"
        exit 1
    fi
    # --- FIN DE LA CORRECTION ---

    DEFAULT_EXTERNAL="https://${PROJECT_NAME}.bioweb.fr"
    read -p "$(echo -e "${CYAN}3/3. URL Externe (Entrée = ${BOLD}$DEFAULT_EXTERNAL${NC}${CYAN}) : ${NC}")" DOMAIN_EXTERNAL_INPUT

    if [[ -z "$DOMAIN_EXTERNAL_INPUT" ]]; then
        DOMAIN_EXTERNAL="$DEFAULT_EXTERNAL"
    else
        DOMAIN_EXTERNAL="$DOMAIN_EXTERNAL_INPUT"
    fi
fi
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
    PROJECT_NAME_SAFE="${PROJECT_NAME//-/_}"
    DB_NAME="${PROJECT_NAME_SAFE}_local"
    REPO_URL="git@github.com:BioWeb-git/${PROJECT_NAME}.git"
    USER_HOME="$HOME"
fi

# On entre dans le dossier projet s'il existe déjà (important pour les étapes modulaires)
if [ -d "$PROJECT_NAME" ]; then
    cd "$PROJECT_NAME"
fi

# --- 2. ACQUISITION DU CODE ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "1" ]]; then


# Dérivation des variables internes
DOMAIN_LOCAL="${PROJECT_NAME}.test"
PROJECT_NAME_SAFE="${PROJECT_NAME//-/_}"
DB_NAME="${PROJECT_NAME_SAFE}_local"
REPO_URL="git@github.com:BioWeb-git/${PROJECT_NAME}.git"
REPO_FULL_NAME="BioWeb-git/${PROJECT_NAME}"
APACHE_LOG_DIR="/var/log/apache2"
USER_HOME="$HOME"

echo -e "\n${YELLOW}Configuration résumée :${NC}"
echo -e "${CYAN}  Dossier/Dépôt : $PROJECT_NAME"
echo -e "  Domaine Local : http://${DOMAIN_LOCAL}"
echo -e "  Base de données : ${DB_NAME}${NC}"
echo "--------------------------------------------------------"


# -----------------------------------------------------------------------
## 📦 ÉTAPE 1 : ACQUISITION DU CODE ET BASE DE DONNÉES ##
# -----------------------------------------------------------------------

echo -e "\n${CYAN}--- 1. Acquisition du code et gestion des conflits ---${NC}"

# 1.1. Gestion du Dossier du Projet (Clonage ou Pull/Création)
SHOULD_CLONE=true
CODE_ACQUIRED=false

if [ -d "$PROJECT_NAME" ]; then
    echo -e "${YELLOW}⚠️ Le dossier $PROJECT_NAME existe déjà localement.${NC}"
    
    # 1. Choix du mode (s/a ou s/p/a)
    if [[ "$CHOICE_ACTION" == "2" ]]; then
        read -p "$(echo -e "${CYAN}Voulez-vous le (s)upprimer et recréer ou (a)nnuler ?\nVotre choix (s/a) : ${NC}")" CHOICE_PROJECT
    else
        read -p "$(echo -e "${CYAN}Voulez-vous le (s)upprimer, (p)ull (mettre à jour), ou (a)nnuler ?\nVotre choix (s/p/a) : ${NC}")" CHOICE_PROJECT
    fi
    
    # 2. Exécution de l'action
    if [[ "$CHOICE_PROJECT" == "s" ]]; then
        echo "   Suppression forcée du dossier..."
        sudo rm -rf "$PROJECT_NAME"
    
    elif [[ "$CHOICE_PROJECT" == "p" && "$CHOICE_ACTION" != "2" ]]; then
        echo "   Mise à jour via git pull..."
        cd "$PROJECT_NAME"
        git pull
        CODE_ACQUIRED=true
        cd ..
    
    elif [[ "$CHOICE_PROJECT" == "a" ]]; then
        echo -e "${RED}Opération annulée par l'utilisateur. Le script s'arrête.${NC}"
        exit 0
    
    else
        echo -e "${RED}Choix non reconnu ou action non permise. Le script est arrêté.${NC}"
        exit 1
    fi
fi

# Si le code n'est PAS acquis (acquisition nécessaire)
if [ "$CODE_ACQUIRED" = false ]; then
    
    if [[ "$CHOICE_ACTION" == "2" ]]; then
        # OPTION 2: Création d'un nouveau dépôt à partir du modèle
        echo "   Création du dépôt '$PROJECT_NAME' sur GitHub..."
        
        if gh repo view "$REPO_FULL_NAME" > /dev/null 2>&1; then
            echo -e "${RED}⚠️ Le dépôt $REPO_FULL_NAME existe déjà sur GitHub.${NC}"
            read -p "$(echo -e "${CYAN}Voulez-vous le (c)loner (réutiliser) ou (a)nnuler ?\nVotre choix (c/a) : ${NC}")" CHOICE_REMOTE

            if [[ "$CHOICE_REMOTE" != "c" ]]; then
                echo -e "${RED}Opération annulée par l'utilisateur.${NC}"
                SHOULD_CLONE=false
                exit 0
            fi
            
        else
            echo "   Dépôt distant non trouvé. Création lancée..."
            gh repo create "BioWeb-git/$PROJECT_NAME" --public --template BioWeb-git/contao5
            
            # Polling pour gérer la condition de course (template copy)
            echo "   Vérification et attente que le modèle soit prêt (polling)..."
            until git ls-remote "${REPO_URL}" main | grep -q 'refs/heads/main'; do
                echo "   Template en cours de copie... Attente de 5 secondes."
                sleep 5
            done
            echo -e "${GREEN}   Modèle copié. Dépôt prêt pour le clonage.${NC}"
        fi
        
    elif [[ "$CHOICE_ACTION" == "1" ]]; then
        # OPTION 1: Clonage d'un dépôt existant
        echo "   Clonage du dépôt existant : ${REPO_URL}..."
    
    # Note: La vérification que CHOICE_ACTION soit 1 ou 2 est faite au tout début.
    fi
fi

# Exécution unique du clonage après toutes les vérifications / créations
if [ "$SHOULD_CLONE" = true ] && [ "$CODE_ACQUIRED" = false ]; then
    git clone "${REPO_URL}" "$PROJECT_NAME"
    CODE_ACQUIRED=true
fi


fi

# --- 3. GESTION DE LA BDD ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "2" ]]; then
echo -e "\n${CYAN}--- 2. Gestion de la Base de Données ---${NC}"
DB_EXISTS=$(sudo mysql -N -s -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${DB_NAME}'")

if [ -n "$DB_EXISTS" ]; then
    echo -e "${YELLOW}⚠️ La base de données $DB_NAME existe déjà.${NC}"
    read -p "$(echo -e "${CYAN}Voulez-vous la (r)ecréer (supprimer/recréer) ou la (g)arder ?\nVotre choix (r/g) : ${NC}")" CHOICE_DB

    if [[ "$CHOICE_DB" == "r" ]]; then
        echo "   Recréation forcée de la base de données..."
        sudo mysql <<EOF_SQL
DROP DATABASE IF EXISTS ${DB_NAME};
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO 'root'@'localhost';
FLUSH PRIVILEGES;
EOF_SQL
    else
        echo "   Base de données existante conservée."
    fi
else
    echo "   Création initiale de la base de données..."
    sudo mysql <<EOF_SQL
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO 'root'@'localhost';
FLUSH PRIVILEGES;
EOF_SQL
fi

# On se place dans le dossier du projet pour la suite
cd "$PROJECT_NAME"

fi

# --- 4. CONFIGURATION .ENV ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "3" ]]; then
echo -e "\n${CYAN}--- 3. Configuration du fichier .env ---${NC}"

# 1. Définir le contenu de la chaîne de MAPPING selon le choix
if [[ "$CHOICE_ACTION" == "2" ]]; then
    FINAL_JSON='{"contao5.test":"http://'${DOMAIN_LOCAL}'","'${DOMAIN_EXTERNAL}'":"http://'${DOMAIN_LOCAL}'"}'
else
    FINAL_JSON='{"'${DOMAIN_EXTERNAL}'":"http://'${DOMAIN_LOCAL}'"}'
fi

WRITE_FILE=true
if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠️ Le fichier .env existe déjà.${NC}"
    read -p "$(echo -e "${CYAN}Voulez-vous l'(e)craser ou le (g)arder ?\nVotre choix (e/g) : ${NC}")" CHOICE_ENV

    if [[ "$CHOICE_ENV" == "g" ]]; then
        echo "   Fichier .env existant conservé."
        WRITE_FILE=false
    fi
fi

# 2. Écriture effective du fichier
if [ "$WRITE_FILE" = true ]; then
    echo "   Création/Écrasement du fichier .env..."
    
    cat > .env <<EOF_ENV
# --- Environnement local du développeur ---
APP_ENV=dev
APP_SECRET="fOhPbKiWWImKQjOjyjiwFAj85ChaRUPr2ROETpO9lLeP9EjIPKWSHCm1SuWFlJkK"
DATABASE_URL="mysql://root:@127.0.0.1:3306/${DB_NAME}?serverVersion=mariadb-10.11.14"
MAILER_TRANSPORT_MAILTRAP="smtp://b9d7f854abecb6:06f11e8524f487@smtp.mailtrap.io:2525"
MAILER_TRANSPORT_MAILJET="smtp://a631077a5dfab1a416d3af197905e94f:0da4f04bb1bd337f5e33506702b47688@in-v3.mailjet.com:25"
ROUTER_REQUEST_CONTEXT_HOST="${DOMAIN_LOCAL}"
ROUTER_REQUEST_CONTEXT_SCHEME="http"
DNS_MAPPING='$(echo "$FINAL_JSON")'
EOF_ENV
fi

fi

# --- 5. CONFIGURATION AUTH GITHUB ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "4" ]]; then
echo -e "\n${CYAN}--- 4. Configuration de l'authentification GitHub (auth.json) ---${NC}"
if [ -n "$GITHUB_PAT" ]; then
    echo "   Génération du fichier auth.json..."
    cat > auth.json <<EOF_AUTH
{
    "github-oauth": {
        "github.com": "$GITHUB_PAT"
    }
}
EOF_AUTH
    
    # Sécurité : Si auth.json n'est pas dans le .gitignore, on l'ajoute
    if ! grep -q "auth.json" .gitignore 2>/dev/null; then
        echo "   Ajout de auth.json au .gitignore..."
        echo "/auth.json" >> .gitignore
    fi
else
    echo -e "${YELLOW}⚠️ Aucun GITHUB_PAT défini dans le script. Pensez à le configurer si nécessaire.${NC}"
fi

fi

# --- 6. INSTALLATION DES DÉPENDANCES ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "5" ]]; then

echo -e "\n${CYAN}--- Installation des dépendances et ACLs...${NC}"

# 2.1. Installation des dépendances (avec feedback visuel)
echo "   Installation des dépendances... (cela peut prendre quelques minutes)"
composer install --no-dev --no-progress --no-ansi --no-interaction --optimize-autoloader --prefer-dist &
spinner $!
echo -e "${GREEN}Dependencies installées.${NC}"

fi

# --- 7. PERMISSIONS ET ACLS ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "6" ]]; then
echo "   Application des permissions et gestion de l'héritage du groupe..."

# On s'assure que tout appartient à ton utilisateur 'pouet' et au groupe 'www-data'
sudo chown -R pouet:www-data .

# On donne les droits d'écriture au groupe (pour que le Manager puisse agir)
sudo chmod -R 775 .

# LE POINT CLÉ : On force l'héritage du groupe www-data sur tous les futurs dossiers/fichiers
# (Le Sticky Bit sur le groupe)
sudo find . -type d -exec chmod g+s {} +

# Optionnel : On garde les ACLs en complément pour la sécurité des accès
sudo setfacl -R -m u:www-data:rwX -m u:pouet:rwX .
sudo setfacl -dR -m u:www-data:rwX -m u:pouet:rwX .

fi

# --- 8. RESTAURATION ET MIGRATION BDD ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "7" ]]; then
echo "   Restauration et migration de la base de données..."
{
    php vendor/bin/contao-console contao:backup:restore -n
    echo 2 | php vendor/bin/contao-console contao:migrate --no-backup -n
} &
spinner $!
echo -e "${GREEN}Migration terminée.${NC}"

fi

# --- 9. SYNCHRONISATION DES FICHIERS ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "8" ]]; then
echo -e "\n${CYAN}--- Synchronisation des fichiers (optionnel)...${NC}"
read -p "$(echo -e "${YELLOW}Voulez-vous synchroniser le dossier /files depuis la production ? (y/n) : ${NC}")" DO_SYNC
if [[ "$DO_SYNC" == "y" ]]; then
    read -p "$(echo -e "${YELLOW}Domaine de production (ex: example.com) : ${NC}")" PROD_DOMAIN
    RSYNC_CMD="rsync -avz forge@54.37.23.174:/home/forge/www.${PROD_DOMAIN}/files/ ./files/"
    echo -e "Commande suggérée : ${CYAN}$RSYNC_CMD${NC}"
    read -p "Appuyez sur [ENTRÉE] pour lancer la synchro ou Ctrl+C pour annuler..."
    eval $RSYNC_CMD
fi

fi

# --- 10. CONFIGURATION APACHE ---
if [[ "$STEP_CHOICE" == "0" || "$STEP_CHOICE" == "9" ]]; then

echo -e "\n${CYAN}--- Configuration Apache...${NC}"

# 3.1. Création du fichier Virtual Host
echo "   Création du Virtual Host pour ${DOMAIN_LOCAL}..."
sudo cat <<EOF_VH | sudo tee /etc/apache2/sites-available/${DOMAIN_LOCAL}.conf > /dev/null
<VirtualHost *:80>
    ServerName ${DOMAIN_LOCAL}
    ServerAdmin webmaster@localhost
    DocumentRoot ${USER_HOME}/${PROJECT_NAME}/public
    
    <Directory ${USER_HOME}/${PROJECT_NAME}/public>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/${PROJECT_NAME}-error.log
    CustomLog ${APACHE_LOG_DIR}/${PROJECT_NAME}-access.log combined
</VirtualHost>
EOF_VH

# 3.2. Activation du site et redémarrage du serveur
echo "   Activation du site et redémarrage d'Apache..."
sudo a2ensite ${DOMAIN_LOCAL}.conf
sudo a2dissite 000-default.conf
sudo service apache2 restart &
spinner $!
echo -e "${GREEN}Apache redémarré.${NC}"

fi

# --- 11. FINALISATION GITHUB ---
if [[ "$STEP_CHOICE" == "0" ]]; then
if [[ "$CHOICE_ACTION" == "2" ]]; then
    echo -e "\n${GREEN}--- Finalisation du nouveau dépôt GitHub (First commit) ---${NC}"

    echo "   1. Création de la sauvegarde initiale de la base de données..."
    php vendor/bin/contao-console contao:backup:create

    echo "   2. Commit des fichiers d'installation..."
    git add .
    git commit -m "Initial setup from template, ready for development."

    echo "   3. Pousse vers GitHub..."
    git push origin main
    echo -e "${GREEN}   ✅ Dépôt initialisé et poussé.${NC}"
fi
fi

cd ..

echo -e "\n${GREEN}--- INSTALLATION TERMINÉE DANS WSL ! ---${NC}"

# -----------------------------------------------------------------------
## 📝 ÉTAPE MANUELLE FINALE (WINDOWS HOSTS FILE) ##
# -----------------------------------------------------------------------
echo " "
echo -e "${BOLD}====================================================================================${NC}"
echo -e "${GREEN}✅ ÉTAPE FINALE MANUELLE : MODIFICATION DU FICHIER HOSTS DE WINDOWS${NC}"
echo -e "------------------------------------------------------------------------------------"
echo -e "${CYAN}1. Récupère l'adresse IP actuelle de ton WSL en lançant :${NC} hostname -I"
echo -e "${CYAN}2. Ouvre le Bloc-notes en MODE ADMINISTRATEUR.${NC}"
echo -e "${CYAN}3. Ouvre le fichier C:\Windows\System32\drivers\etc\hosts${NC}"
echo -e "${CYAN}4. Ajoute la ligne suivante (utilise l'IP que tu as récupérée à l'étape 1) :${NC}"
echo -e "   [TON_IP_WSL]   ${DOMAIN_LOCAL}"
echo -e "${CYAN}Exemple : ::1   ${DOMAIN_LOCAL}${NC}"
echo -e "${CYAN}5. Redémarre ton navigateur et accède à : ${BOLD}http://${DOMAIN_LOCAL}${NC}"
echo -e "${BOLD}====================================================================================${NC}"
