#!/bin/bash

# Configuration
EMAIL="contact@bioweb.fr"
FICHIER_LOG="/tmp/etat_serveur.txt"
FICHIER_STATS="$HOME/.stats_veille"

# 1. Collecte des données globales
LOAD=$(uptime | awk -F'average:' '{ print $2 }' | cut -d, -f1 | xargs)
PHPS=$(ps aux | grep php-fpm | grep -v grep | wc -l)

# 2. Calcul du comparatif (si le fichier existe)
if [ -f "$FICHIER_STATS" ]; then
    source "$FICHIER_STATS"
    DIFF_PHP=$((PHPS - OLD_PHPS))
    [ $DIFF_PHP -ge 0 ] && EVOL_PHP="(+$DIFF_PHP)" || EVOL_PHP="($DIFF_PHP)"
else
    EVOL_PHP="(N/A)"
fi

# Sauvegarde immédiate pour le prochain tour
echo "OLD_PHPS=$PHPS" > "$FICHIER_STATS"

# 3. Génération du Dashboard
{
echo "=========================================================="
echo "          🚀 DASHBOARD EXPERT SÉCURITÉ : $(hostname)     "
echo "          Généré le : $(date +'%d/%m/%Y à %H:%M:%S')"
echo "=========================================================="

echo -e "\n📍 [1] PERFORMANCES DU SERVEUR"
echo "----------------------------------------------------------"
echo "EXPLICATION : État de santé général."
echo "----------------------------------------------------------"
echo "  Charge CPU (Load) : $LOAD"
echo "  Process PHP       : $PHPS actifs $EVOL_PHP"
echo "  Mémoire RAM       : $(free -h | grep Mem | awk '{print $3" / "$2}')"
echo "  Espace Disque     : $(df -h / | grep / | awk '{print $5" utilisé ("$4" libres)"}')"

echo -e "\n🛡️ [2] FAIL2BAN : ANALYSE DES PRISONS"
echo "----------------------------------------------------------"
echo "EXPLICATION : Tes barrières automatiques."
echo "----------------------------------------------------------"

JAILS=$(sudo fail2ban-client status | grep "Jail list" | sed "s/ //g" | cut -d: -f2 | sed "s/,/ /g")

for JAIL in $JAILS; do
    STATUS=$(sudo fail2ban-client status "$JAIL")
    BANNED=$(echo "$STATUS" | grep "Currently banned" | grep -oE '[0-9]+')
    FAILED=$(echo "$STATUS" | grep "Currently failed" | grep -oE '[0-9]+')
    
    # Récupération de l'ancienne valeur pour le comparatif des bans
    VAR_NAME="OLD_BAN_${JAIL//-/_}"
    OLD_BVAL="${!VAR_NAME}"
    
    if [ -n "$OLD_BVAL" ]; then
        DIFF_B=$((BANNED - OLD_BVAL))
        [ $DIFF_B -ge 0 ] && EVOL_B="(+$DIFF_B)" || EVOL_B="($DIFF_B)"
    else
        EVOL_B="(N/A)"
    fi
    
    # Sauvegarde pour demain
    echo "$VAR_NAME=$BANNED" >> "$FICHIER_STATS"

    case $JAIL in
        "bad-bots") DESC="Bannit les robots qui génèrent des redirections (301) en boucle." ;;
        "wp-honeypot") DESC="Piège WordPress : Bannit ceux qui cherchent du WP sur Contao." ;;
        "contao-tag-flood") DESC="Protège contre l'abus des tags et injections d'étoiles (*)." ;;
        "nginx-forbidden") DESC="Bannit l'accès aux fichiers système (.env, .git, .config)." ;;
        "nginx-badrequests") DESC="Détecte les injections de scripts (.php, .sql, .asp)." ;;
        "block-category-crawler") DESC="Limite les robots sur la recherche (/search, related/)." ;;
        "nginx-upstream-timeout") DESC="Bannit les IPs qui font planter tes scripts PHP." ;;
        "sshd") DESC="Protège l'accès direct au serveur (SSH)." ;;
        *) DESC="Protection active sur ce service." ;;
    esac

    printf "  %-22s : %-3s bans %-7s | %-3s échecs\n" "[$JAIL]" "$BANNED" "$EVOL_B" "$FAILED"
    echo "  └─ Rôle : $DESC"
    echo ""
done

echo -e "🧱 [3] FIREWALL RÉSEAU (Iptables)"
echo "----------------------------------------------------------"
echo "EXPLICATION : Blocages manuels prioritaires (Alibaba Cloud)."
echo "----------------------------------------------------------"
echo "  Pkts | Bytes | Réseau / IP Bloquée"
sudo iptables -L INPUT -v -n | grep -E "DROP|REJECT" | head -n 5 | awk '{printf "  %-4s | %-5s | %-15s\n", $1, $2, $8}'

echo -e "\n🚀 [4] TOP 10 DES AGRESSEURS (Nginx 301)"
echo "----------------------------------------------------------"
echo "EXPLICATION : Les IPs les plus actives sur tes redirections."
echo "----------------------------------------------------------"
echo "  Req. | Adresse IP      | Hébergeur (WHOIS)"
tail -n 2000 /var/log/nginx/access.log | grep " 301 " | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10 | while read count ip; do
    INFO=$(whois $ip 2>/dev/null | grep -iE "org-name|organization|owner|asname" | head -n 1 | cut -d: -f2 | xargs | cut -c1-20)
    printf "  %-4s | %-15s | %-20s\n" "$count" "$ip" "${INFO:-Inconnu}"
done

echo -e "\n=========================================================="
echo "  CONSEIL : Si le 'Load' monte brusquement, vérifie la section [4]."
echo "=========================================================="
} > $FICHIER_LOG

# Envoi du mail
mail -a "From: contact@bioweb.fr" -s "Rapport Santé Serveur" "$EMAIL" < $FICHIER_LOG

# Ping du Heartbeat Forge
curl -s "https://forge.laravel.com/relays/heartbeat/01kpdd8209ja1rjzgzefe8f4xf/ping" > /dev/null

# Nettoyage
rm $FICHIER_LOG
