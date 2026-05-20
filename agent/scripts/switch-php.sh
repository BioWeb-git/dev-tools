#!/bin/bash

# Couleurs pour le terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [ "$1" == "contao3" ]; then
    echo -e "${BLUE}Basculement vers l'environnement Contao 3 (PHP 7.4)...${NC}"
    sudo a2dismod php8.3 > /dev/null 2>&1
    sudo a2enmod php7.4 > /dev/null 2>&1
    sudo update-alternatives --set php /usr/bin/php7.4 > /dev/null 2>&1
    sudo systemctl restart apache2
    echo -e "${GREEN}Prêt ! PHP 7.4 activé (Apache + Terminal).${NC}"

elif [ "$1" == "contao5" ]; then
    echo -e "${BLUE}Basculement vers l'environnement Contao 5 (PHP 8.3)...${NC}"
    sudo a2dismod php7.4 > /dev/null 2>&1
    sudo a2enmod php8.3 > /dev/null 2>&1
    sudo update-alternatives --set php /usr/bin/php8.3 > /dev/null 2>&1
    sudo systemctl restart apache2
    echo -e "${GREEN}Prêt ! PHP 8.3 activé (Apache + Terminal).${NC}"

else
    echo "Usage: ./switch-php.sh [contao3|contao5]"
fi