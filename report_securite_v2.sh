#!/bin/bash

# Configuration
EMAIL="contact@bioweb.fr"
FICHIER_LOG="/tmp/rapport_securite.html"
FICHIER_PJ="/tmp/fichiers_suspects.txt"
FICHIER_STATS="$HOME/.stats_veille"
FICHIER_MEMOIRE="$HOME/.seen_suspicious_files"
DOSSIER_LOGS="$HOME/.logs/securite"
HOSTNAME=$(hostname)

# Création des dossiers et fichiers de suivi
mkdir -p "$DOSSIER_LOGS"
[ ! -f "$FICHIER_MEMOIRE" ] && touch "$FICHIER_MEMOIRE"

# Auto-purge préventive des logs > 90 jours
find "$DOSSIER_LOGS" -name "*.log" -mtime +90 -delete 2>/dev/null

# Mode Test
MODE_TEST=false
if [ "$1" == "--test" ] || [ "$1" == "test" ]; then
    MODE_TEST=true
fi

# ----------------------------------------------------------
# 1. Collecte des données & KPI
# ----------------------------------------------------------

# CPU Load & I/O Wait
LOAD=$(uptime | awk -F'average:' '{ print $2 }' | cut -d, -f1 | xargs)
LOAD_ALERT=$(echo "$LOAD > 2.0" | bc -l 2>/dev/null)

IO_WAIT=$(top -bn1 | grep "Cpu(s)" | awk '{print $10}')
IO_ALERT=$(echo "$IO_WAIT > 15.0" | bc -l 2>/dev/null)

# MariaDB (CPU & QPS)
MARIADB_CPU=$(ps aux | grep mariadbd | grep -v grep | awk '{print $3}' | cut -d. -f1)
[ -z "$MARIADB_CPU" ] && MARIADB_CPU=0
[ "$MARIADB_CPU" -gt 80 ] && MARIA_ALERT=1 || MARIA_ALERT=0

MARIADB_QPS=$(mysqladmin status 2>/dev/null | grep -o 'Queries per second avg: [0-9.]*' | awk '{print $5}')
[ -z "$MARIADB_QPS" ] && MARIADB_QPS="0.0"

# Redis Clients
REDIS_CLIENTS=$(redis-cli info clients 2>/dev/null | grep connected_clients | cut -d: -f2 | tr -d '\r')
[ -z "$REDIS_CLIENTS" ] && REDIS_CLIENTS=0
[ "$REDIS_CLIENTS" -eq 0 ] && REDIS_ALERT=1 || REDIS_ALERT=0

# Mémoire RAM
RAM_USAGE=$(free -m | grep Mem | awk '{print $3}')
RAM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
RAM_PCT=$((RAM_USAGE * 100 / RAM_TOTAL))
[ "$RAM_PCT" -gt 85 ] && RAM_ALERT=1 || RAM_ALERT=0
RAM_TEXT="$(free -h | grep Mem | awk '{print $3" / "$2}')"

# Process PHP-FPM
PHPS=$(ps aux | grep php-fpm | grep -v grep | wc -l)
[ "$PHPS" -gt 40 ] && PHP_ALERT=1 || PHP_ALERT=0
if [ -f "$FICHIER_STATS" ]; then
    source "$FICHIER_STATS"
    DIFF_PHP=$((PHPS - OLD_PHPS))
    [ $DIFF_PHP -ge 0 ] && EVOL_PHP="+$DIFF_PHP" || EVOL_PHP="$DIFF_PHP"
else
    EVOL_PHP="N/A"
fi
echo "OLD_PHPS=$PHPS" > "$FICHIER_STATS"

# Disque %
DISK_USAGE=$(df -h / | grep / | awk '{print $5}' | cut -d% -f1)
[ "$DISK_USAGE" -gt 85 ] && DISK_ALERT=1 || DISK_ALERT=0
DISK_TEXT="$DISK_USAGE% ($(df -h / | grep / | awk '{print $4}') libres)"

# Taille du dossier de logs sécurité
TAILLE_LOGS_SEC=$(du -sh "$DOSSIER_LOGS" 2>/dev/null | awk '{print $1}')
[ -z "$TAILLE_LOGS_SEC" ] && TAILLE_LOGS_SEC="0K"

# Bouclier Nginx (444 & 429)
BLOCAGES_444=$(awk '$10 == 444' /var/log/nginx/access.log 2>/dev/null | wc -l)
BLOCAGES_429=$(awk '$10 == 429' /var/log/nginx/access.log 2>/dev/null | wc -l)
TOTAL_INTERCEPTIONS=$((BLOCAGES_444 + BLOCAGES_429))
[ "$BLOCAGES_429" -gt 50 ] && FLOOD_ALERT=1 || FLOOD_ALERT=0

# ----------------------------------------------------------
# 1.5. Détection Générique d'Anomalies de Fichiers avec Acquittement
# ----------------------------------------------------------

# 1. Scripts PHP anormaux dans répertoires publics d'upload/médias (Contao files/, PrestaShop img/upload, WP uploads, Laravel public/storage)
SUSPICIOUS_MEDIA_PHP=$(find /home/forge/*/img /home/forge/*/upload /home/forge/*/uploads /home/forge/*/files /home/forge/*/public/storage /home/forge/*/public/uploads -type f -name "*.php" ! -name "index.php" ! -path "*/quarantine_*" 2>/dev/null)

# 2. Fichiers PHP cachés (.nom.php) hors dossiers vendor/cache/git
SUSPICIOUS_HIDDEN_PHP=$(find /home/forge/ -type f -name ".*.php" ! -path "*/quarantine_*" ! -path "*/.git/*" ! -path "*/vendor/*" ! -path "*/var/cache/*" ! -path "*/system/cache/*" 2>/dev/null)

# 3. Fichiers PHP créés ou modifiés dans les dernières 24h hors répertoires normaux de cache/vendor/framework/templates/releases
SUSPICIOUS_RECENT_PHP=$(find /home/forge/ -type f -name "*.php" -newermt "24 hours ago" \
  ! -path "*/var/cache/*" \
  ! -path "*/system/cache/*" \
  ! -path "*/storage/framework/*" \
  ! -path "*/vendor/*" \
  ! -path "*/templates/*" \
  ! -path "*/releases/*" \
  ! -path "*/quarantine_*" \
  ! -path "*/.git/*" 2>/dev/null | grep -v "/home/forge/rt-respekt.com/index.php")

MALWARE_ALERT=0
TOTAL_SUSPICIOUS_FILES=0
ALL_SUSPICIOUS=$(echo -e "${SUSPICIOUS_MEDIA_PHP}\n${SUSPICIOUS_HIDDEN_PHP}\n${SUSPICIOUS_RECENT_PHP}" | sed '/^$/d' | sort -u)

# Filtrage par mémoire d'acquittement
NEW_SUSPICIOUS=""
KNOWN_SUSPICIOUS=""

if [ -n "$ALL_SUSPICIOUS" ]; then
    while read -r f; do
        [ -z "$f" ] && continue
        FILE_STAMP=$(stat -c "%Y %n" "$f" 2>/dev/null)
        if ! grep -qF "$FILE_STAMP" "$FICHIER_MEMOIRE" 2>/dev/null; then
            NEW_SUSPICIOUS="${NEW_SUSPICIOUS}${f}\n"
            echo "$FILE_STAMP" >> "$FICHIER_MEMOIRE"
        else
            KNOWN_SUSPICIOUS="${KNOWN_SUSPICIOUS}${f}\n"
        fi
    done <<< "$ALL_SUSPICIOUS"
fi

NEW_SUSPICIOUS_CLEAN=$(echo -e "$NEW_SUSPICIOUS" | sed '/^$/d')
KNOWN_SUSPICIOUS_CLEAN=$(echo -e "$KNOWN_SUSPICIOUS" | sed '/^$/d')

# Enregistrement dans le fichier de log permanent si détection
FICHIER_LOG_JOUR="$DOSSIER_LOGS/alertes_$(date +'%Y-%m').log"
PJ_PRESENTE=false
rm -f "$FICHIER_PJ"

if [ -n "$NEW_SUSPICIOUS_CLEAN" ]; then
    MALWARE_ALERT=1
    TOTAL_SUSPICIOUS_FILES=$(echo "$NEW_SUSPICIOUS_CLEAN" | wc -l)
    
    # Écriture dans le log serveur horodaté
    {
        echo "=== ALERTE DU $(date +'%Y-%m-%d %H:%M:%S') ($TOTAL_SUSPICIOUS_FILES fichier(s)) ==="
        echo "$NEW_SUSPICIOUS_CLEAN"
        echo ""
    } >> "$FICHIER_LOG_JOUR"
    
    # Création du fichier pour pièce jointe
    echo -e "=== FICHIERS SUSPECTS OU MODIFIÉS DÉTECTÉS LE $(date +'%d/%m/%Y à %H:%M:%S') ===\n" > "$FICHIER_PJ"
    echo "$NEW_SUSPICIOUS_CLEAN" >> "$FICHIER_PJ"
    PJ_PRESENTE=true
fi

# Logique Globale de l'Alerte
if [ "$LOAD_ALERT" == "1" ] || [ "$IO_ALERT" == "1" ] || [ "$MARIA_ALERT" == "1" ] || [ "$REDIS_ALERT" == "1" ] || [ "$RAM_ALERT" == "1" ] || [ "$PHP_ALERT" == "1" ] || [ "$DISK_ALERT" == "1" ] || [ "$FLOOD_ALERT" == "1" ] || [ "$MALWARE_ALERT" == "1" ]; then
    STATUS_COLOR="#e15241"
    if [ "$MALWARE_ALERT" == "1" ]; then
        STATUS_TEXT="🔴 ALERTE SÉCURITÉ : NOUVEAU(X) fichier(s) suspect(s) !"
        SUJET="🔴 $HOSTNAME - NOUVELLE Alerte Sécurité ($TOTAL_SUSPICIOUS_FILES fichier(s))"
    else
        STATUS_TEXT="🔴 ALERTE SERVEUR"
        SUJET="🔴 $HOSTNAME - Alerte Performance"
    fi
else
    STATUS_COLOR="#2ecc71"
    STATUS_TEXT="🟢 TOUT EST OK"
    SUJET="✅ $HOSTNAME - Load $LOAD"
fi

# ----------------------------------------------------------
# 2. Construction du Mail HTML
# ----------------------------------------------------------
{
echo "<!DOCTYPE html>"
echo "<html>"
echo "<head><meta name='viewport' content='width=device-width, initial-scale=1.0'></head>"
echo "<body style='margin:0; padding:10px; background-color:#f4f6f7; font-family:-apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,Helvetica,Arial,sans-serif; color:#333;'>"

# Header Status
echo "<div style='background-color:$STATUS_COLOR; color:#ffffff; padding:15px; text-align:center; font-weight:bold; font-size:18px; border-radius:6px 6px 0 0;'>"
echo "  $STATUS_TEXT — $HOSTNAME"
echo "  <div style='font-size:11px; font-weight:normal; margin-top:5px;'>Généré le $(date +'%d/%m/%Y à %H:%M:%S')</div>"
echo "</div>"

# Grille uniforme de KPI (4 lignes x 2 colonnes)
echo "<div style='background:#ffffff; padding:15px; border-radius:0 0 6px 6px; box-shadow:0 1px 3px rgba(0,0,0,0.1); margin-bottom:15px;'>"
echo "  <table cellpadding='0' cellspacing='0' width='100%' style='width:100%; border-collapse:collapse;'>"
# Ligne 1 : CPU Load & CPU I/O Wait
echo "    <tr>"
echo "      <td width='50%' style='padding:12px; border-bottom:1px solid #edf2f7; border-right:1px solid #edf2f7;'>"
echo "        <span style='font-size:11px; color:#718096; text-transform:uppercase;'>Load CPU</span><br>"
echo "        <span style='font-size:20px; font-weight:bold; color:$( [ "$LOAD_ALERT" == "1" ] && echo "#e15241" || echo "#2d3748" );'>$LOAD</span>"
echo "      </td>"
echo "      <td width='50%' style='padding:12px; border-bottom:1px solid #edf2f7;'>"
echo "        <span style='font-size:11px; color:#718096; text-transform:uppercase;'>CPU I/O Wait</span><br>"
echo "        <span style='font-size:20px; font-weight:bold; color:$( [ "$IO_ALERT" == "1" ] && echo "#e15241" || echo "#2d3748" );'>$IO_WAIT%</span>"
echo "      </td>"
echo "    </tr>"
# Ligne 2 : MariaDB CPU & MariaDB QPS
echo "    <tr>"
echo "      <td width='50%' style='padding:12px; border-bottom:1px solid #edf2f7; border-right:1px solid #edf2f7;'>"
echo "        <span style='font-size:11px; color:#718096; text-transform:uppercase;'>MariaDB CPU</span><br>"
echo "        <span style='font-size:20px; font-weight:bold; color:$( [ "$MARIA_ALERT" == "1" ] && echo "#e15241" || echo "#2d3748" );'>$MARIADB_CPU%</span>"
echo "      </td>"
echo "      <td width='50%' style='padding:12px; border-bottom:1px solid #edf2f7;'>"
echo "        <span style='font-size:11px; color:#718096; text-transform:uppercase;'>MariaDB QPS (Moy)</span><br>"
echo "        <span style='font-size:20px; font-weight:bold; color:#2d3748;'>$MARIADB_QPS</span>"
echo "      </td>"
echo "    </tr>"
# Ligne 3 : RAM & Redis
echo "    <tr>"
echo "      <td width='50%' style='padding:12px; border-bottom:1px solid #edf2f7; border-right:1px solid #edf2f7;'>"
echo "        <span style='font-size:11px; color:#718096; text-transform:uppercase;'>Mémoire RAM</span><br>"
echo "        <span style='font-size:18px; font-weight:bold; color:$( [ "$RAM_ALERT" == "1" ] && echo "#e15241" || echo "#2d3748" );'>$RAM_TEXT</span>"
echo "      </td>"
echo "      <td width='50%' style='padding:12px; border-bottom:1px solid #edf2f7;'>"
echo "        <span style='font-size:11px; color:#718096; text-transform:uppercase;'>Clients Redis</span><br>"
echo "        <span style='font-size:18px; font-weight:bold; color:$( [ "$REDIS_ALERT" == "1" ] && echo "#e15241" || echo "#2d3748" );'>$REDIS_CLIENTS</span>"
echo "      </td>"
echo "    </tr>"
# Ligne 4 : Disque & PHP Process
echo "    <tr>"
echo "      <td width='50%' style='padding:12px; border-right:1px solid #edf2f7;'>"
echo "        <span style='font-size:11px; color:#718096; text-transform:uppercase;'>Disque (/)</span><br>"
echo "        <span style='font-size:18px; font-weight:bold; color:$( [ "$DISK_ALERT" == "1" ] && echo "#e15241" || echo "#2d3748" );'>$DISK_TEXT</span>"
echo "        <div style='font-size:10px; color:#a0aec0; margin-top:2px;'>Logs sécu : $TAILLE_LOGS_SEC</div>"
echo "      </td>"
echo "      <td width='50%' style='padding:12px;'>"
echo "        <span style='font-size:11px; color:#718096; text-transform:uppercase;'>Process PHP-FPM</span><br>"
echo "        <span style='font-size:18px; font-weight:bold; color:$( [ "$PHP_ALERT" == "1" ] && echo "#e15241" || echo "#2d3748" );'>$PHPS actifs</span> <span style='font-size:11px; color:#718096;'>($EVOL_PHP)</span>"
echo "      </td>"
echo "    </tr>"
echo "  </table>"
echo "</div>"

# Section Scan Générique de Fichiers Suspects
echo "<div style='background:#ffffff; padding:15px; border-radius:6px; box-shadow:0 1px 3px rgba(0,0,0,0.1); margin-bottom:15px;'>"
echo "  <h3 style='margin-top:0; font-size:14px; color:#4a5568; border-bottom:2px solid #edf2f7; padding-bottom:8px;'>🔍 DÉTECTION GÉNÉRIQUE D'ANOMALIES (Toutes Technologies)</h3>"

if [ "$MALWARE_ALERT" == "1" ]; then
    echo "  <p style='font-size:13px; color:#e15241; margin:5px 0 10px 0; font-weight:bold;'>🚨 NOUVEAU(X) FICHIER(S) SUSPECT(S) DÉTECTÉ(S) ($TOTAL_SUSPICIOUS_FILES) :</p>"
    
    # Synthèse groupée par domaine / projet
    echo "  <div style='background:#fff5f5; border:1px solid #feb2b2; padding:10px; border-radius:4px; margin-bottom:10px;'>"
    echo "    <table width='100%' style='border-collapse:collapse; font-size:12px;'>"
    echo "      <thead><tr style='color:#718096; border-bottom:1px solid #fed7d7;'><th style='text-align:left; padding:4px;'>Projet / Site</th><th style='text-align:right; padding:4px;'>Fichiers modifiés</th></tr></thead>"
    echo "      <tbody>"
    echo "$NEW_SUSPICIOUS_CLEAN" | awk -F'/' '{print $4}' | sort | uniq -c | while read nb site; do
        echo "        <tr style='border-bottom:1px solid #fff5f5;'><td style='padding:4px; font-weight:bold; color:#c53030;'>📁 $site</td><td style='padding:4px; text-align:right; font-weight:bold; color:#e15241;'>$nb fichier(s)</td></tr>"
    done
    echo "      </tbody>"
    echo "    </table>"
    echo "  </div>"

    # Affichage des chemins : si <= 5 en entier, si > 5 les 5 premiers + mention pièce jointe
    echo "  <div style='background:#f7fafc; border:1px solid #e2e8f0; padding:10px; border-radius:4px; font-family:monospace; font-size:11px; color:#4a5568; word-break:break-all;'>"
    if [ "$TOTAL_SUSPICIOUS_FILES" -le 5 ]; then
        while read -r f; do
            [ -n "$f" ] && echo "• $f<br>"
        done <<< "$NEW_SUSPICIOUS_CLEAN"
    else
        echo "$NEW_SUSPICIOUS_CLEAN" | head -n 5 | while read -r f; do
            [ -n "$f" ] && echo "• $f<br>"
        done
        RESTE=$((TOTAL_SUSPICIOUS_FILES - 5))
        echo "<div style='margin-top:6px; color:#718096; font-style:italic;'>📎 ... et $RESTE autre(s) fichier(s) (voir la liste complète en pièce jointe .txt)</div>"
    fi
    echo "  </div>"
fi

if [ -n "$KNOWN_SUSPICIOUS_CLEAN" ]; then
    TOTAL_KNOWN=$(echo "$KNOWN_SUSPICIOUS_CLEAN" | wc -l)
    echo "  <p style='font-size:12px; color:#718096; margin:12px 0 4px 0;'>ℹ️ Fichier(s) récemment modifié(s) déjà connus / acquittés ($TOTAL_KNOWN) :</p>"
    echo "  <div style='background:#edf2f7; border:1px solid #cbd5e0; padding:8px; border-radius:4px; font-family:monospace; font-size:11px; color:#4a5568; word-break:break-all;'>"
    if [ "$TOTAL_KNOWN" -le 3 ]; then
        while read -r f; do
            [ -n "$f" ] && echo "✓ $f<br>"
        done <<< "$KNOWN_SUSPICIOUS_CLEAN"
    else
        echo "$KNOWN_SUSPICIOUS_CLEAN" | head -n 3 | while read -r f; do
            [ -n "$f" ] && echo "✓ $f<br>"
        done
        RESTE_KNOWN=$((TOTAL_KNOWN - 3))
        echo "<div style='margin-top:4px; color:#718096; font-style:italic;'>✓ ... et $RESTE_KNOWN autre(s) fichier(s) acquitté(s)</div>"
    fi
    echo "  </div>"
fi

if [ "$MALWARE_ALERT" == "0" ] && [ -z "$KNOWN_SUSPICIOUS_CLEAN" ]; then
    echo "  <p style='font-size:13px; color:#2ecc71; margin:5px 0 0 0; font-weight:bold;'>🟢 Aucun fichier PHP/backdoor anormal détecté (Contao 3/5, PrestaShop, Laravel & Custom OK).</p>"
fi
echo "</div>"

# Section Fail2ban
echo "<div style='background:#ffffff; padding:15px; border-radius:6px; box-shadow:0 1px 3px rgba(0,0,0,0.1); margin-bottom:15px;'>"
echo "  <h3 style='margin-top:0; font-size:14px; color:#4a5568; border-bottom:2px solid #edf2f7; padding-bottom:8px;'>🛡️ FAIL2BAN : ANALYSE DES PRISONS</h3>"

JAILS=$(sudo fail2ban-client status | grep "Jail list" | sed "s/ //g" | cut -d: -f2 | sed "s/,/ /g")
for JAIL in $JAILS; do
    STATUS=$(sudo fail2ban-client status "$JAIL")
    BANNED=$(echo "$STATUS" | grep "Currently banned" | grep -oE '[0-9]+')
    FAILED=$(echo "$STATUS" | grep "Currently failed" | grep -oE '[0-9]+')
    
    VAR_NAME="OLD_BAN_${JAIL//-/_}"
    OLD_BVAL="${!VAR_NAME}"
    if [ -n "$OLD_BVAL" ]; then
        DIFF_B=$((BANNED - OLD_BVAL))
        [ $DIFF_B -ge 0 ] && EVOL_B="+$DIFF_B" || EVOL_B="$DIFF_B"
    else
        EVOL_B="N/A"
    fi
    echo "$VAR_NAME=$BANNED" >> "$FICHIER_STATS"

    echo "<div style='padding:8px 0; border-bottom:1px solid #f7fafc; font-size:13px;'>"
    echo "  <strong style='color:#2d3748;'>[$JAIL]</strong> : "
    echo "  <span style='background:#edf2f7; padding:2px 6px; border-radius:4px; font-weight:bold;'>$BANNED bans</span> "
    echo "  <span style='font-size:11px; color:#718096;'>($EVOL_B)</span> | <span style='color:#718096;'>$FAILED échecs</span>"
    echo "</div>"
done
echo "</div>"

# Section Le Bouclier Nginx (444 & 429)
echo "<div style='background:#ffffff; padding:15px; border-radius:6px; box-shadow:0 1px 3px rgba(0,0,0,0.1); margin-bottom:15px;'>"
echo "  <h3 style='margin-top:0; font-size:14px; color:#4a5568; border-bottom:2px solid #edf2f7; padding-bottom:8px;'>🛡️ LE BOUCLIER NGINX (Coupures 444 & 429)</h3>"
echo "  <p style='font-size:13px; color:#2d3748; margin:5px 0 15px 0;'><b>Total intercepté aujourd'hui :</b> <span style='color:#e15241; font-weight:bold;'>$TOTAL_INTERCEPTIONS</span> requêtes bloquées net (Bouclier: $BLOCAGES_444 | Flood: $BLOCAGES_429).</p>"

# Tableau des IPs Attaquantes
echo "  <p style='font-size:12px; font-weight:bold; color:#4a5568; margin-bottom:5px;'>Top 5 des vrais attaquants (IPs) :</p>"
echo "  <div style='width:100%; overflow-x:auto; -webkit-overflow-scrolling:touch; margin-bottom:15px;'>"
echo "    <table width='100%' style='border-collapse:collapse; font-size:12px; text-align:left; min-width:320px;'>"
echo "      <thead>"
echo "        <tr style='color:#718096; border-bottom:1px solid #edf2f7;'>"
echo "          <th style='padding:6px 4px; width:45px;'>Tirs</th>"
echo "          <th style='padding:6px 4px; width:110px;'>IP</th>"
echo "          <th style='padding:6px 4px;'>Hébergeur</th>"
echo "        </tr>"
echo "      </thead>"
echo "      <tbody>"

awk '$10 == 444 || $10 == 429 {print $2}' /var/log/nginx/access.log 2>/dev/null | sort | uniq -c | sort -nr | head -n 5 | while read count ip; do
    INFO=$(timeout 1 whois $ip 2>/dev/null | grep -iE "org-name|organization|owner|asname" | head -n 1 | cut -d: -f2 | xargs | cut -c1-20)
    echo "      <tr style='border-bottom:1px solid #f7fafc;'>"
    echo "        <td style='padding:6px 4px; font-weight:bold; color:#e15241;'>$count</td>"
    echo "        <td style='padding:6px 4px; font-family:monospace; white-space:nowrap;'>$ip</td>"
    echo "        <td style='padding:6px 4px; color:#4a5568; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;'>${INFO:-Inconnu}</td>"
    echo "      </tr>"
done
echo "      </tbody>"
echo "    </table>"
echo "  </div>"

# Tableau des URLs Cibles
echo "  <p style='font-size:12px; font-weight:bold; color:#4a5568; margin-bottom:5px;'>Top Cibles (Ce que les bots cherchent) :</p>"
echo "  <div style='width:100%; overflow-x:auto; -webkit-overflow-scrolling:touch;'>"
echo "    <table width='100%' style='border-collapse:collapse; font-size:12px; text-align:left; min-width:320px;'>"
echo "      <thead>"
echo "        <tr style='color:#718096; border-bottom:1px solid #edf2f7;'>"
echo "          <th style='padding:6px 4px; width:45px;'>Bloqués</th>"
echo "          <th style='padding:6px 4px;'>Cibles (URLs)</th>"
echo "        </tr>"
echo "      </thead>"
echo "      <tbody>"

awk '$10 == 444 || $10 == 429 {print $8}' /var/log/nginx/access.log 2>/dev/null | sort | uniq -c | sort -nr | head -n 5 | while read count url; do
    echo "      <tr style='border-bottom:1px solid #f7fafc;'>"
    echo "        <td style='padding:6px 4px; font-weight:bold; color:#4a5568;'>$count</td>"
    echo "        <td style='padding:6px 4px; font-family:monospace; color:#2b6cb0; word-break:break-all;'>$url</td>"
    echo "      </tr>"
done
echo "      </tbody>"
echo "    </table>"
echo "  </div>"
echo "</div>"

echo "</body>"
echo "</html>"
} > $FICHIER_LOG

# ----------------------------------------------------------
# 3. Routage : Envoi ou Dry-Run
# ----------------------------------------------------------
if [ "$MODE_TEST" = true ]; then
    echo "=== MODE TEST ACTIF ==="
    echo "Rapport HTML généré localement sans envoi."
    echo "Fichier disponible ici : $FICHIER_LOG"
    [ -f "$FICHIER_PJ" ] && echo "Pièce jointe générée ici : $FICHIER_PJ"
else
    # Construction de l'email MIME complet compatible Sendmail/Postfix
    BOUNDARY="===_SECOPS_BOUNDARY_$(date +%s)_==="
    FICHIER_MIME="/tmp/email_complet.eml"
    
    {
        echo "From: contact@bioweb.fr"
        echo "To: $EMAIL"
        echo "Subject: $SUJET"
        echo "MIME-Version: 1.0"
        
        if [ "$PJ_PRESENTE" = true ] && [ -f "$FICHIER_PJ" ]; then
            echo "Content-Type: multipart/mixed; boundary=\"$BOUNDARY\""
            echo ""
            echo "--$BOUNDARY"
            echo "Content-Type: text/html; charset=UTF-8"
            echo "Content-Transfer-Encoding: 8bit"
            echo ""
            cat "$FICHIER_LOG"
            echo ""
            echo "--$BOUNDARY"
            echo "Content-Type: text/plain; charset=UTF-8; name=\"fichiers_suspects.txt\""
            echo "Content-Disposition: attachment; filename=\"fichiers_suspects.txt\""
            echo "Content-Transfer-Encoding: base64"
            echo ""
            base64 "$FICHIER_PJ"
            echo ""
            echo "--$BOUNDARY--"
        else
            echo "Content-Type: text/html; charset=UTF-8"
            echo "Content-Transfer-Encoding: 8bit"
            echo ""
            cat "$FICHIER_LOG"
        fi
    } > "$FICHIER_MIME"

    # Envoi via sendmail natif
    /usr/sbin/sendmail -t -oi < "$FICHIER_MIME"
         
    curl -s "https://forge.laravel.com/relays/heartbeat/01kpdd8209ja1rjzgzefe8f4xf/ping" > /dev/null
    rm -f "$FICHIER_LOG" "$FICHIER_PJ" "$FICHIER_MIME"
fi
