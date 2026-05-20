#!/bin/bash
# Script pour démarrer les services essentiels de développement sous WSL (Apache et MySQL)

# Utilisation des couleurs pour la clarté
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Définir la version de PHP-FPM (Ajustez si nécessaire, ex: php8.1-fpm)
PHP_FPM_SERVICE="php8.3-fpm"
PHP_FPM_DISPLAY="PHP-FPM 8.3"


# Fonction de vérification robuste à trois états
check_and_start() {
    local SERVICE_NAME=$1
    local SERVICE_DISPLAY=$2
    
    echo "1. Démarrage du service $SERVICE_DISPLAY..."
    
    # --- 1. Vérification initiale (Déjà Actif ?) ---
    sudo service "$SERVICE_NAME" status > /dev/null 2>&1
    local STATUS_CODE=$?

    if [ $STATUS_CODE -eq 0 ]; then
        echo -e "${GREEN}  [OK] ${SERVICE_DISPLAY} est déjà actif. Tout va bien !${NC}"
        return
    fi
    
    # --- 2. Tentative de Démarrage (Si non actif) ---
    sudo service "$SERVICE_NAME" start

    # On attend une seconde pour laisser le service s'initialiser
    sleep 1 

    # --- 3. Vérification du Succès (Après tentative) ---
    sudo service "$SERVICE_NAME" status > /dev/null 2>&1
    STATUS_CODE=$?

    if [ $STATUS_CODE -eq 0 ]; then
        echo -e "${GREEN}  [OK] ${SERVICE_DISPLAY} démarré.${NC}"
    else
        # Vraie ERREUR : Le démarrage a échoué
        echo -e "${RED}  [ERREUR] ${SERVICE_DISPLAY} n'a pas démarré. Vérifiez les logs !${NC}"
    fi
}

echo -e "${CYAN}--- DÉMARRAGE DE L'ENVIRONNEMENT DE DÉVELOPPEMENT WSL ---${NC}"

# Lancer la vérification pour Apache, PHP, et MySQL
check_and_start "apache2" "Apache2"
check_and_start "$PHP_FPM_SERVICE" "$PHP_FPM_DISPLAY" # <-- AJOUT DE PHP-FPM
check_and_start "mysql" "MySQL"

echo -e "\n${GREEN}✅ Environnement de développement prêt !${NC}"
echo "--------------------------------------------------------"

# --- NOUVEAU MENU DE CONTRÔLE DES SERVICES ---

echo -e "${CYAN}--- CONTRÔLE RAPIDE DES SERVICES ---${NC}"
read -p "$(echo -e "${CYAN}Que voulez-vous faire ?\n  (1) Redémarrer Apache seul\n  (2) Redémarrer MySQL seul\n  (3) Redémarrer les trois services principaux\n  (4) Quitter\nVotre choix (1/2/3/4) : ${NC}")" QUICK_ACTION_SERVICE

case "$QUICK_ACTION_SERVICE" in
    1)
        echo -e "${YELLOW}Redémarrage d'Apache...${NC}"
        sudo service apache2 restart
        ;;
    2)
        echo -e "${YELLOW}Redémarrage de MySQL...${NC}"
        sudo service mysql restart
        ;;
    3)
        echo -e "${YELLOW}Redémarrage d'Apache, MySQL, et PHP-FPM...${NC}"
        sudo service apache2 restart
        sudo service mysql restart
        sudo service "$PHP_FPM_SERVICE" restart # <-- REDÉMARRAGE DE PHP-FPM
        ;;
    *)
        echo "Opération terminée. Au revoir !"
        ;;
esac