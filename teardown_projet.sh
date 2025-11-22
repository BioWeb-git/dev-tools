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

# -----------------------------------------------------------------------
echo -e "${RED}## 💣 DÉSINTEGRATION DU PROJET LOCAL ##${NC}"
echo "--------------------------------------------------------"

# --- 0. SÉLECTION DU PROJET ---

echo -e "${CYAN}1/2. Projets locaux disponibles :${NC}"

# 1. Créer un tableau de projets (dossiers, excluant le script lui-même et les fichiers courants)
# On utilise find pour cibler uniquement les dossiers et exclure . et ..
PROJECT_LIST=()
while IFS= read -r dir; do
    # On exclut les dossiers cachés (commençant par .) et les fichiers
    if [[ -d "$dir" && ! "$dir" =~ ^\..* ]]; then
        PROJECT_LIST+=("$dir")
    fi
done < <(ls -d */ 2>/dev/null | sed 's/\///g')

# Vérifier si la liste est vide
if [ ${#PROJECT_LIST[@]} -eq 0 ]; then
    echo -e "${RED}Erreur : Aucun dossier de projet trouvé dans le répertoire courant.${NC}"
    exit 1
fi

# 2. Afficher la liste numérotée
for i in "${!PROJECT_LIST[@]}"; do
    echo "  $((i+1)). ${PROJECT_LIST[i]}"
done
echo "--------------------------------------------------------"

# 3. Demander le choix à l'utilisateur
while true; do
    read -p "$(echo -e "${CYAN}Entrez le NUMÉRO du projet à désinstaller ou (a)nnuler : ${NC}")" CHOICE_NUMBER
    
    if [[ "$CHOICE_NUMBER" == "a" ]]; then
        echo -e "${YELLOW}Désinstallation annulée.${NC}"
        exit 0
    fi
    
    # Vérifier si le choix est un nombre valide dans la plage
    if [[ "$CHOICE_NUMBER" =~ ^[0-9]+$ && "$CHOICE_NUMBER" -ge 1 && "$CHOICE_NUMBER" -le ${#PROJECT_LIST[@]} ]]; then
        # On soustrait 1 car les tableaux Bash sont basés sur 0
        PROJECT_INDEX=$((CHOICE_NUMBER - 1))
        PROJECT_NAME="${PROJECT_LIST[PROJECT_INDEX]}"
        break
    else
        echo -e "${RED}Choix invalide. Veuillez entrer un numéro valide ou 'a'.${NC}"
    fi
done


# Dérivation des variables
DB_NAME="${PROJECT_NAME//-/_}_local"
DOMAIN_LOCAL="${PROJECT_NAME}.test"

echo -e "\n${YELLOW}Configuration du projet à désinstaller :${NC}"
echo -e "${CYAN}  Dossier : ~/$PROJECT_NAME"
echo -e "  Base de données : $DB_NAME"
echo -e "  Virtual Host : ${DOMAIN_LOCAL}.conf${NC}"
echo "--------------------------------------------------------"


read -p "$(echo -e "${RED}Êtes-vous SÛR de vouloir désinstaller '$PROJECT_NAME' ? (oui/non) : ${NC}")" CONFIRMATION

if [[ "$CONFIRMATION" != "oui" ]]; then
    echo -e "${YELLOW}Désinstallation annulée.${NC}"
    exit 0
fi


# -----------------------------------------------------------------------
## 1. NETTOYAGE APACHE, BDD ET RÉPERTOIRE (WSL) ##
# -----------------------------------------------------------------------
echo -e "\n${CYAN}--- 1/2 Suppression Apache, BDD et répertoire local...${NC}"

# 1.1. Désactivation du Virtual Host et redémarrage d'Apache
echo "   Désactivation du site ${DOMAIN_LOCAL} et redémarrage d'Apache..."
sudo a2dissite ${DOMAIN_LOCAL}.conf
sudo service apache2 restart || true

# 1.2. Suppression de la base de données
echo "   Suppression de la base de données ${DB_NAME}..."
sudo mysql -e "DROP DATABASE IF EXISTS ${DB_NAME};"

# 1.3. Suppression du dossier local
echo "   Suppression forcée du répertoire local ~/${PROJECT_NAME}..."
# On utilise cd ~ pour s'assurer qu'on n'est pas dans le dossier qu'on veut supprimer
cd ~
sudo rm -rf "$PROJECT_NAME"

echo -e "${GREEN}✅ Nettoyage WSL terminé (Apache, BDD et dossier local supprimés).${NC}"

# -----------------------------------------------------------------------
## 2. VÉRIFICATION POST-DÉSINTEGRATION (AUTOMATIQUE) ##
# -----------------------------------------------------------------------
echo -e "\n--- VÉRIFICATION POST-DÉSINTEGRATION ---";
echo "Projet ciblé : ${BOLD}$PROJECT_NAME${NC}"; 

# 1. Vérification du dossier local
echo -n "1. Dossier local (~/$PROJECT_NAME) : ";
if ! ls -ld ~/"$PROJECT_NAME" > /dev/null 2>&1; then 
    echo -e "${GREEN}[OK] Supprimé${NC}";
else 
    echo -e "${RED}[ERREUR] Existe toujours${NC}";
fi; 

# 2. Vérification de la Base de Données
echo -n "2. Base de données ($DB_NAME) : ";
if [[ -z $(sudo mysql -N -s -e "SHOW DATABASES LIKE '$DB_NAME';") ]]; then 
    echo -e "${GREEN}[OK] Supprimée${NC}";
else 
    echo -e "${RED}[ERREUR] Existe toujours${NC}"; 
fi; 

# 3. Vérification du fichier VHost Apache (désactivé)
echo -n "3. VHost Apache ($DOMAIN_LOCAL.conf) : ";
if ! sudo a2query -s "$DOMAIN_LOCAL" 2>/dev/null | grep -q 'is enabled'; then 
    echo -e "${GREEN}[OK] Désactivé${NC}";
else 
    echo -e "${RED}[ERREUR] Encore actif${NC}";
fi; 

# 4. Vérification de l'existence du fichier VHost (supprimé)
echo -n "4. Fichier VHost (/etc/apache2/sites-available/) : ";
if ! sudo test -f "/etc/apache2/sites-available/${DOMAIN_LOCAL}.conf"; then 
    echo -e "${GREEN}[OK] Supprimé (ou absent)${NC}";
else 
    echo -e "${RED}[ERREUR] Fichier de configuration toujours présent${NC}"; 
fi; 

echo -e "\n${YELLOW}--- VÉRIFICATION MANUELLE REQUISE (Windows Host) ---${NC}";
echo -e "Veuillez vérifier que l'entrée pour ${BOLD}$DOMAIN_LOCAL${NC} a été retirée du fichier ${BOLD}C:\Windows\System32\drivers\etc\hosts${NC}."

# -----------------------------------------------------------------------
## 3. ÉTAPE MANUELLE FINALE (WINDOWS HOSTS FILE) ##
# -----------------------------------------------------------------------
echo " "
echo -e "${BOLD}====================================================================================${NC}"
echo -e "${GREEN}✅ ÉTAPE FINALE MANUELLE : NETTOYAGE DU FICHIER HOSTS DE WINDOWS${NC}"
echo -e "------------------------------------------------------------------------------------"
echo -e "${CYAN}1. Ouvre le Bloc-notes en MODE ADMINISTRATEUR.${NC}"
echo -e "${CYAN}2. Ouvre le fichier C:\Windows\System32\drivers\etc\hosts${NC}"
echo -e "${CYAN}3. ${RED}SUPPRIME${NC} la ligne associée à ton projet :${NC}"
echo -e "${RED}   [IP_WSL]   ${DOMAIN_LOCAL}${NC}"
echo -e "${CYAN}4. Sauvegarde le fichier et redémarre ton navigateur.${NC}"
echo -e "${BOLD}====================================================================================${NC}"
