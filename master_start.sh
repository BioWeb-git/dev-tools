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
    echo -e "${GREEN}2) Installer un nouveau projet - (setup_projet.sh)${NC}"
    echo -e "${GREEN}3) Désinstaller un projet existant - (teardown_projet.sh)${NC}"
    echo -e "${RED}4) Quitter l'assistant${NC}"
    echo "----------------------"
    
    read -p "$(echo -e "${CYAN}Choisissez une option (1-4) : ${NC}")" CHOICE

    case "$CHOICE" in
        1)
            echo -e "\n${CYAN}>>> Lancement des services (start_dev.sh)...${NC}"
            ./start_dev.sh
            ;;
        2)
            # Utilisation de 'source' pour que la commande cd affecte le terminal hôte
            echo -e "\n${CYAN}>>> Lancement de l'installation (setup_projet.sh)...${NC}"
            if [ -x ./setup_projet.sh ]; then
                source ./setup_projet.sh
            else
                echo -e "${RED}ERREUR : Le script setup_projet.sh est introuvable ou non exécutable.${NC}"
            fi
            ;;
        3)
            echo -e "\n${CYAN}>>> Lancement de la désinstallation (teardown_projet.sh)...${NC}"
            if [ -x ./teardown_projet.sh ]; then
                ./teardown_projet.sh
            else
                echo -e "${RED}ERREUR : Le script teardown_projet.sh est introuvable ou non exécutable.${NC}"
            fi
            ;;
        4)
            echo -e "${GREEN}Assistant terminé. Au revoir !${NC}"
            break
            ;;
        *)
            echo -e "${RED}Choix invalide. Veuillez entrer un chiffre entre 1 et 4.${NC}"
            ;;
    esac
done
