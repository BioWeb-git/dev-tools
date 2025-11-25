#!/bin/bash

# --- CONFIGURATION FIXE ---
PROJECTS_DIR="/home/pouet"
APACHE_RESTART="sudo systemctl restart apache2"
# ---------------------------

echo "--- 🛠️ Gestion du Mode Dev (WSL) ---"

# 1. Sélection du projet
echo "Projets disponibles dans ${PROJECTS_DIR} :"

# Liste les répertoires dans /home/pouet/ (ignorer les fichiers et les dossiers cachés)
# Et les numérote pour la sélection
select PROJECT_NAME in $(find "$PROJECTS_DIR" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | grep -v '^\.' | sort); do
    if [ ! -z "$PROJECT_NAME" ]; then
        break
    else
        echo "Sélection invalide. Réessaie."
    fi
done

echo "Projet sélectionné : ${PROJECT_NAME}"
echo "--------------------------------------"

# --- CONFIGURATION DYNAMIQUE ---
# Chemins basés sur le nom du projet
VHOST_FILE="/etc/apache2/sites-available/${PROJECT_NAME}.test.conf" # On suppose un vhost PROJECT_NAME.test.conf
CSS_PATH="${PROJECTS_DIR}/${PROJECT_NAME}/files/client/css/*.css"   # Chemin CSS compilé
VHOST_NAME="${PROJECT_NAME}.test"

# BROWSER_SYNC_CMD_8000 est la seule commande fiable en WSL pour le Live Reload (syntaxe corrigée)
#BROWSER_SYNC_CMD_8000="browser-sync start --proxy \"http://127.0.0.1:8000\" --host \"${VHOST_NAME}\""
FILE_WATCH_LIST="${CSS_PATH}, ${PROJECTS_DIR}/${PROJECT_NAME}/templates/**/*.html.twig, ${PROJECTS_DIR}/${PROJECT_NAME}/assets/**/*.js"

BROWSER_SYNC_CMD_8000="browser-sync start --proxy \"http://127.0.0.1:8000\" --host \"${VHOST_NAME}\" --files \"${FILE_WATCH_LIST}\""

# --- CONFIGURATION MYSQL (CORRIGÉE) ---
DB_NAME="${PROJECT_NAME}_local" 
DB_USER="root"

# Commande d'exécution MySQL : utilise root sans mot de passe
MYSQL_EXEC="mysql -u${DB_USER} ${DB_NAME} -e"

# COMMANDES SQL POUR LE DNS CONTAO (tl_page.dns) - PLUS ROBUSTES
# 1. VIDER le DNS (pour le mode DEV/Browsersync) : 
#    Cible la page racine qui a actuellement le VHOST_NAME dans le champ dns.
SQL_CLEAR_DNS="UPDATE tl_page SET dns='' WHERE type='root' AND dns='${VHOST_NAME}';"

# 2. REMETTRE le DNS (pour le mode PROD/Port 80) :
#    Cible la page racine qui n'a pas de DNS et y inscrit le VHOST_NAME.
SQL_SET_DNS="UPDATE tl_page SET dns='${VHOST_NAME}' WHERE type='root' AND (dns='' OR dns IS NULL);"
# -----------------------------------------------------

# 2. Vérification de l'existence du Vhost
if [ ! -f "$VHOST_FILE" ]; then
    echo "🚨 Erreur : Fichier Vhost ${VHOST_FILE} non trouvé pour ce projet."
    echo "Assure-toi que ton Vhost est nommé ${PROJECT_NAME}.test.conf et qu'il est dans sites-available."
    exit 1
fi

# 3. Check du port actuel
# Utilise sed pour extraire le port à partir de la ligne <VirtualHost ...>
CURRENT_PORT=$(grep '<VirtualHost' "$VHOST_FILE" | sed -E 's/.*:([0-9]+)>.*/\1/')

# -----------------------------------------------------------------
# --- GESTION DES CHOIX EN MODE PORT 8000 (DEV) ---
# -----------------------------------------------------------------
if [ "$CURRENT_PORT" == "8000" ]; then
    MODE="DEV (Live Reload)"
    TARGET_PORT="80"
    TARGET_MODE="PROD/Test (Port 80)"
    ACTION="repasser au Port 80"
    SWITCH_CMD="sudo sed -i 's/:8000>/:80>/g' \"$VHOST_FILE\""
    
    echo "Statut actuel du Vhost ${VHOST_NAME}: Port ${CURRENT_PORT} (${MODE})."
    echo "------------------------------------------------------------"
    echo "Voulez-vous :"
    echo "1) Oui, ${ACTION} au Port ${TARGET_PORT} (${TARGET_MODE})."
    echo "2) Relancer Live Reload (Garder Port 8000)."
    echo "3) Non, annuler."
    
    read -r CHOICE
    
    if [ "$CHOICE" == "1" ]; then
        # Basculer vers le port 80 (mode Prod)
        echo ""
        echo "🔧 Changement du Vhost ${VHOST_NAME} vers le Port 80..."
        eval "$SWITCH_CMD"
        if [ $? -eq 0 ]; then
            
            # --- RÈGLE SQL : REMETTRE LE DNS POUR LA PROD ---
            echo "🔧 Restauration du DNS dans Contao (tl_page.dns = ${VHOST_NAME})..."
            eval "$MYSQL_EXEC \"${SQL_SET_DNS}\""
            if [ $? -ne 0 ]; then
                echo "⚠️ Attention: Erreur lors de la restauration du DNS dans la BDD. Continuer..."
            else
                # Ajout d'une confirmation visuelle
                echo "✅ DNS Contao rétabli : ${VHOST_NAME}"
            fi
            # -----------------------------------------------------

            eval "$APACHE_RESTART"
            echo "✅ Apache redémarré. Live Reload désactivé."
            echo "Site accessible via : http://${VHOST_NAME}/"
        else
            echo "❌ Erreur de modification/redémarrage."
            exit 1
        fi

    elif [ "$CHOICE" == "2" ]; then
        # Relancer BrowserSync
        echo ""
        echo "🚀 Relancement du mode DEV (Live Reload) sur Port 8000 et Proxy 3000..."
        echo "Accès DEV : http://${VHOST_NAME}:3000/ (ou http://localhost:3000/)"
        echo "---"
        eval "$BROWSER_SYNC_CMD_8000"
        
    elif [ "$CHOICE" == "3" ]; then
        # Annuler
        echo "Annulé. Aucun changement effectué."
        
    else
        echo "Choix invalide. Aucun changement effectué."
    fi

# -----------------------------------------------------------------
# --- GESTION DES CHOIX EN MODE PORT 80 (PROD/TEST) ---
# -----------------------------------------------------------------
elif [ "$CURRENT_PORT" == "80" ]; then
    MODE="PROD/Test (Port 80)"
    TARGET_PORT="8000"
    TARGET_MODE="DEV (Live Reload)"
    ACTION="passer au Port 8000"
    SWITCH_CMD="sudo sed -i 's/:80>/:8000>/g' \"$VHOST_FILE\""

    echo "Statut actuel du Vhost ${VHOST_NAME}: Port ${CURRENT_PORT} (${MODE})."
    echo "------------------------------------------------------------"
    echo "Voulez-vous ${ACTION} ?"
    echo "1) Oui, passer au Port ${TARGET_PORT} (${TARGET_MODE})."
    echo "2) Non, annuler." # Pas d'option relance car le mode 80 est instable pour BS
    
    read -r CHOICE
    
    if [ "$CHOICE" == "1" ]; then
        # Basculer vers le port 8000 (mode Dev)
        echo ""
        echo "🔧 Changement du Vhost ${VHOST_NAME} vers le Port 8000..."
        eval "$SWITCH_CMD"
        if [ $? -eq 0 ]; then
            
            # --- RÈGLE SQL : VIDER LE DNS POUR LE DEV ---
            echo "🔧 Suppression du DNS dans Contao (tl_page.dns = '')..."
            eval "$MYSQL_EXEC \"${SQL_CLEAR_DNS}\""
            if [ $? -ne 0 ]; then
                echo "⚠️ Attention: Erreur lors de la suppression du DNS dans la BDD. Continuer..."
            else
                # Ajout d'une confirmation visuelle
                echo "✅ DNS Contao supprimé."
            fi
            # -----------------------------------------------------

            echo "✅ Vhost modifié. Redémarrage d'Apache..."
            eval "$APACHE_RESTART"
            if [ $? -eq 0 ]; then
                echo "✅ Apache redémarré avec succès."
                echo ""
                echo "🚀 Lancement du mode DEV (Live Reload) sur Port 8000 et Proxy 3000..."
                echo "Accès DEV : http://${VHOST_NAME}:3000/ (ou http://localhost:3000/)"
                echo "---"
                eval "$BROWSER_SYNC_CMD_8000"
            else
                echo "❌ Erreur lors du redémarrage d'Apache. Veuillez vérifier les logs."
                exit 1
            fi
        else
            echo "❌ Erreur lors de la modification du Vhost. Vérifiez les permissions (ou le chemin)."
            exit 1
        fi
    else
        echo "Annulé. Aucun changement effectué."
    fi

else
    echo "🚨 Erreur: Impossible de déterminer le port actuel dans ${VHOST_FILE}. Vérifiez le format."
    exit 1
fi