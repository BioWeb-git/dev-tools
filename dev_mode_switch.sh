#!/bin/bash

# --- CONFIGURATION FIXE ---
PROJECTS_DIR="/home/pouet"
APACHE_RESTART="sudo systemctl restart apache2"
# ---------------------------

# =========================================================
# --- FONCTION DE NETTOYAGE (EXÉCUTÉE À LA SORTIE) ---
# =========================================================

cleanup() {
    echo ""
    echo "🧹 Nettoyage : Tentative de réactivation de 000-default.conf..."
    # On utilise a2ensite, si le site est déjà activé, il ne fait rien.
    sudo a2ensite 000-default.conf > /dev/null 2>&1

    echo "🧹 Redémarrage d'Apache pour prendre en compte le changement..."
    eval "$APACHE_RESTART"
    
    echo "✅ Mode DEV terminé. La configuration Apache par défaut est restaurée."
    exit 0
}

# =========================================================
# --- DÉCLENCHEUR : Exécute 'cleanup' si le script est interrompu (Ctrl+C) ou se termine ---
# =========================================================
trap cleanup INT TERM

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
VHOST_FILE="/etc/apache2/sites-available/${PROJECT_NAME}.test.conf"
CSS_PATH="${PROJECTS_DIR}/${PROJECT_NAME}/files/client/css/*.css"
VHOST_NAME="${PROJECT_NAME}.test"

# BROWSER_SYNC_CMD_8000 avec l'exclusion /contao/**
FILE_WATCH_LIST="${CSS_PATH}, ${PROJECTS_DIR}/${PROJECT_NAME}/templates/**/*.html.twig, ${PROJECTS_DIR}/${PROJECT_NAME}/assets/**/*.js"
BROWSER_SYNC_CMD_8000="browser-sync start --proxy \"http://127.0.0.1:8000\" --host \"${VHOST_NAME}\" --files \"${FILE_WATCH_LIST}\" --exclude \"/contao/**\""

# --- CONFIGURATION MYSQL (INCHANGÉE) ---
DB_NAME="${PROJECT_NAME//-/_}_local"
DB_USER="root"
MYSQL_EXEC="mysql -u${DB_USER} ${DB_NAME} -e"
SQL_CLEAR_DNS="UPDATE tl_page SET dns='' WHERE type='root' AND dns='${VHOST_NAME}';"
SQL_SET_DNS="UPDATE tl_page SET dns='${VHOST_NAME}' WHERE type='root' AND (dns='' OR dns IS NULL);"
# -----------------------------------------------------

# 2. Vérification de l'existence du Vhost
if [ ! -f "$VHOST_FILE" ]; then
    echo "🚨 Erreur : Fichier Vhost ${VHOST_FILE} non trouvé pour ce projet."
    echo "Assure-toi que ton Vhost est nommé ${PROJECT_NAME}.test.conf et qu'il est dans sites-available."
    trap - INT TERM 
    exit 1
fi

# 3. Check du port actuel
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
            fi
            # -----------------------------------------------------
            
            # --- Réactivation du 000-default.conf pour le Port 80 ---
            echo "🔧 Réactivation du Vhost 000-default.conf (pour le fallback Port 80)..."
            sudo a2ensite 000-default.conf > /dev/null 2>&1
            # ----------------------------------------------------------------

            eval "$APACHE_RESTART"
            echo "✅ Apache redémarré. Live Reload désactivé."
            echo "Site accessible via : http://${VHOST_NAME}/"
        else
            echo "❌ Erreur de modification/redémarrage."
            trap - INT TERM
            exit 1
        fi

    elif [ "$CHOICE" == "2" ]; then
        # Relancer BrowserSync (en mode 8000)
        
        # --- Désactivation de 000-default.conf pour éviter le conflit ---
        echo "🔧 Désactivation du Vhost 000-default.conf (pour éviter le conflit Port 8000)..."
        sudo a2dissite 000-default.conf > /dev/null 2>&1
        eval "$APACHE_RESTART"
        # -------------------------------------------------------------------------
        
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
    echo "2) Non, annuler."
    
    read -r CHOICE
    
    if [ "$CHOICE" == "1" ]; then
        # Basculer vers le port 8000 (mode Dev)
        echo ""
        echo "🔧 Changement du Vhost ${VHOST_NAME} vers le Port 8000..."
        eval "$SWITCH_CMD"
        if [ $? -eq 0 ]; then
            
            # --- Désactivation du 000-default.conf pour éviter le conflit ---
            echo "🔧 Désactivation du Vhost 000-default.conf (pour éviter le conflit Port 8000)..."
            sudo a2dissite 000-default.conf > /dev/null 2>&1
            # -------------------------------------------------------------------------
            
            # --- RÈGLE SQL : VIDER LE DNS POUR LE DEV ---
            echo "🔧 Suppression du DNS dans Contao (tl_page.dns = '')..."
            eval "$MYSQL_EXEC \"${SQL_CLEAR_DNS}\""
            if [ $? -ne 0 ]; then
                echo "⚠️ Attention: Erreur lors de la suppression du DNS dans la BDD. Continuer..."
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
                trap - INT TERM
                exit 1
            fi
        else
            echo "❌ Erreur lors de la modification du Vhost. Vérifiez les permissions (ou le chemin)."
            trap - INT TERM
            exit 1
        fi
    else
        echo "Annulé. Aucun changement effectué."
    fi

else
    echo "🚨 Erreur: Impossible de déterminer le port actuel dans ${VHOST_FILE}. Vérifiez le format."
    trap - INT TERM
    exit 1
fi

# Pour les chemins qui sortent du IF/ELIF mais qui ne lancent pas BrowserSync, on annule le trap
# et on termine normalement.
trap - INT TERM
exit 0