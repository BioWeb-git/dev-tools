#!/bin/bash
# Script d'orchestration global des tâches de développement WSL

# Définition des couleurs
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}## 🚀 ASSISTANT DE WORKFLOW GLOBAL WSL ##${NC}"

while true; do
    echo -e "\n${BOLD}--- MENU PRINCIPAL ---${NC}"
    echo -e "${GREEN}1) Démarrer les services (Apache/MySQL) - (start_dev.sh)${NC}"
    echo -e "${GREEN}2) Installer un nouveau projet (Contao 4/5) - (setup_projet.sh)${NC}"
    echo -e "${GREEN}3) Installer un projet Contao 3.5 - (setup_contao3.sh)${NC}"
    echo -e "${GREEN}4) Désinstaller un projet existant - (teardown_projet.sh)${NC}"
    echo -e "${RED}5) Quitter l'assistant${NC}"

    echo "----------------------"
    
    read -p "$(echo -e "${CYAN}Choisissez une option (1-4) : ${NC}")" CHOICE

    case "$CHOICE" in
        1)
            echo -e "\n${CYAN}>>> Lancement des services (start_dev.sh)...${NC}"
            if [ -x ./dev-tools/start_dev.sh ]; then 
                source ./dev-tools/start_dev.sh
            else
                echo -e "${RED}ERREUR : Le script start_dev.sh est introuvable ou non exécutable. (Vérifiez le chemin)${NC}"
            fi
            ;;
        2)
            echo -e "\n${CYAN}>>> Lancement de l'installation Contao 4/5 (setup_projet.sh)...${NC}"
            if [ -x ./dev-tools/setup_projet.sh ]; then 
                source ./dev-tools/setup_projet.sh
            else
                echo -e "${RED}ERREUR : Le script setup_projet.sh est introuvable ou non exécutable.${NC}"
            fi
            ;;
        3)
            echo -e "\n${CYAN}>>> Lancement de l'installation Contao 3.5 (setup_contao3.sh)...${NC}"
            if [ -x ./dev-tools/setup_contao3.sh ]; then 
                source ./dev-tools/setup_contao3.sh
            else
                echo -e "${RED}ERREUR : Le script setup_contao3.sh est introuvable ou non exécutable.${NC}"
            fi
            ;;
        4)
            echo -e "\n${CYAN}>>> Lancement de la désinstallation (teardown_projet.sh)...${NC}"
            if [ -x ./dev-tools/teardown_projet.sh ]; then
                source ./dev-tools/teardown_projet.sh
            else
                echo -e "${RED}ERREUR : Le script teardown_projet.sh est introuvable ou non exécutable.${NC}"
            fi
            ;;
        5)
            echo -e "${GREEN}Assistant terminé. Au revoir !${NC}"
            break
            ;;
        *)
            echo -e "${RED}Choix invalide. Veuillez entrer un chiffre entre 1 et 5.${NC}"
            ;;

    esac
done
