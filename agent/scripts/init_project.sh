#!/bin/bash
# Arrête immédiatement le script si une commande échoue
set -e

# --- COULEURS ANSI ET FORMATAGE ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# --- RÉSOLUTION DYNAMIQUE DES CHEMINS ---
# Trouve le répertoire agent/ à partir de la position du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo -e "${CYAN}## 🤖 INITIALISATION DE L'AGENT IA DANS VOTRE PROJET ##${NC}"
echo "--------------------------------------------------------"

# --- 1. SÉLECTION DU RÉPERTOIRE DU PROJET ---
echo -e "${CYAN}1. Répertoire cible du projet${NC}"
read -p "Entrez le chemin du projet (Entrée = dossier courant '$(pwd)') : " TARGET_INPUT

if [ -z "$TARGET_INPUT" ]; then
    TARGET_DIR="$(pwd)"
else
    # Résolution des chemins avec ~ ou variables
    eval TARGET_DIR="$TARGET_INPUT"
    TARGET_DIR="$(realpath "$TARGET_DIR" 2>/dev/null || echo "$TARGET_DIR")"
fi

# Création du dossier s'il n'existe pas
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}⚠️ Le dossier cible n'existe pas.${NC}"
    read -p "Voulez-vous le créer ? (y/n) : " CREATE_DIR
    if [[ "$CREATE_DIR" == "y" || "$CREATE_DIR" == "Y" ]]; then
        mkdir -p "$TARGET_DIR"
        echo -e "${GREEN}Dossier '$TARGET_DIR' créé.${NC}"
    else
        echo -e "${RED}Erreur : Répertoire cible inexistant. Arrêt du script.${NC}"
        exit 1
    fi
fi

# Se placer dans le répertoire cible
cd "$TARGET_DIR"
echo -e "Projet cible : ${BOLD}$TARGET_DIR${NC}"
echo "--------------------------------------------------------"

# --- 2. SÉLECTION ET COPIE DU TEMPLATE DE CONTEXTE ---
echo -e "${CYAN}2. Choix du modèle de Contexte (context.md)${NC}"

if [ -f "context.md" ]; then
    echo -e "${YELLOW}⚠️ Un fichier 'context.md' existe déjà dans le projet.${NC}"
    read -p "Voulez-vous l'écraser ? (y/n - défaut=n) : " OVERWRITE_CONTEXT
    [ -z "$OVERWRITE_CONTEXT" ] && OVERWRITE_CONTEXT="n"
else
    OVERWRITE_CONTEXT="y"
fi

if [[ "$OVERWRITE_CONTEXT" == "y" || "$OVERWRITE_CONTEXT" == "Y" ]]; then
    # Scanner uniquement les fichiers de contexte existants dans agent/templates (exclut prompt_master)
    TEMPLATE_FILES=()
    while IFS= read -r file; do
        TEMPLATE_FILES+=("$file")
    done < <(find "${AGENT_DIR}/templates" -type f -name "*context_*.md" | sort)

    if [ ${#TEMPLATE_FILES[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️ Aucun modèle de contexte trouvé dans '${AGENT_DIR}/templates'. Création d'un context.md vide...${NC}"
        touch context.md
    else
        echo "Sélectionnez le modèle de contexte le plus adapté à votre projet :"
        for i in "${!TEMPLATE_FILES[@]}"; do
            # Rendre le chemin relatif à templates/ pour un affichage plus propre
            REL_PATH="${TEMPLATE_FILES[i]#${AGENT_DIR}/templates/}"
            
            # Définir une description claire en fonction du fichier
            case "$REL_PATH" in
                "context_template.md")
                    DESC="Modèle standard universel (React, Next.js, Android, PHP, etc.)"
                    ;;
                "examples/context_contao5.md")
                    DESC="Modèle d'exemple optimisé pour Contao 5"
                    ;;
                *)
                    DESC="Modèle personnalisé ($REL_PATH)"
                    ;;
            esac
            
            echo -e "  $((i+1)). ${BOLD}${REL_PATH}${NC} : ${DESC}"
        done
        echo -e "  0. Ne pas créer de context.md"

        while true; do
            read -p "Votre choix [0-${#TEMPLATE_FILES[@]}] (Entrée = 1) : " TEMPLATE_CHOICE
            [ -z "$TEMPLATE_CHOICE" ] && TEMPLATE_CHOICE=1

            if [[ "$TEMPLATE_CHOICE" == "0" ]]; then
                echo "Aucun fichier de contexte n'a été créé."
                break
            elif [[ "$TEMPLATE_CHOICE" =~ ^[0-9]+$ && "$TEMPLATE_CHOICE" -ge 1 && "$TEMPLATE_CHOICE" -le ${#TEMPLATE_FILES[@]} ]]; then
                SELECTED_TEMPLATE="${TEMPLATE_FILES[$((TEMPLATE_CHOICE - 1))]}"
                cp "$SELECTED_TEMPLATE" "context.md"
                echo -e "${GREEN}✅ Fichier 'context.md' créé à partir de '$(basename "$SELECTED_TEMPLATE")'.${NC}"
                break
            else
                echo -e "${RED}Choix invalide. Veuillez saisir un nombre entre 0 et ${#TEMPLATE_FILES[@]}.${NC}"
            fi
        done
    fi
else
    echo "Fichier 'context.md' existant conservé."
fi
echo "--------------------------------------------------------"

# --- 3. CRÉATION DES LIENS SYMBOLIQUES ---
echo -e "${CYAN}3. Création des liens symboliques (Symlinks)${NC}"
echo "Création de RULES.global.md..."
ln -sf "${AGENT_DIR}/RULES.global.md" "RULES.global.md"

echo "Création des dossiers d'aide (.dev-tools-templates et .dev-tools-docs)..."
ln -sfn "${AGENT_DIR}/templates" ".dev-tools-templates"
ln -sfn "${AGENT_DIR}/docs" ".dev-tools-docs"
echo -e "${GREEN}✅ Liens symboliques créés avec succès.${NC}"

echo "Génération du prompt actif personnalisé (prompt_active.md)..."
sed -e "s|\[INSERT: RULES.global.md path or link\]|${TARGET_DIR}/RULES.global.md|g" \
    -e "s|\[INSERT: context.md path, e.g., /home/pouet/docs/context-contao5.md\]|${TARGET_DIR}/context.md|g" \
    -e "s|\[INSERT: local api docs path, e.g., /home/pouet/docs/api/\]|${TARGET_DIR}/.dev-tools-docs/|g" \
    "${AGENT_DIR}/templates/prompt_master.md" > prompt_active.md
echo -e "${GREEN}✅ Fichier 'prompt_active.md' généré à la racine.${NC}"
echo "--------------------------------------------------------"

# --- 4. MISE À JOUR DU .GITIGNORE ---
echo -e "${CYAN}4. Configuration du .gitignore${NC}"
read -p "Voulez-vous ajouter les dossiers/fichiers d'assistance de l'agent au .gitignore ? (y/n - défaut=y) : " UPDATE_GITIGNORE
[ -z "$UPDATE_GITIGNORE" ] && UPDATE_GITIGNORE="y"

if [[ "$UPDATE_GITIGNORE" == "y" || "$UPDATE_GITIGNORE" == "Y" ]]; then
    # S'assurer que le fichier .gitignore existe
    touch .gitignore
    
    RULES_TO_IGNORE=(".dev-tools-templates" ".dev-tools-docs" "task.md" "walkthrough.md" "implementation_plan.md" "prompt_active.md")
    ADDED_ANY=false
    
    for rule in "${RULES_TO_IGNORE[@]}"; do
        if ! grep -q "^$rule" .gitignore 2>/dev/null; then
            echo "$rule" >> .gitignore
            ADDED_ANY=true
        fi
    done
    
    if [ "$ADDED_ANY" = true ]; then
        echo -e "${GREEN}✅ Fichier .gitignore mis à jour avec succès.${NC}"
    else
        echo "Les exclusions étaient déjà présentes dans le .gitignore."
    fi
else
    echo "Mise à jour du .gitignore ignorée."
fi

echo "--------------------------------------------------------"
echo -e "${GREEN}🎉 INITIALISATION DE L'AGENT IA RÉUSSIE !${NC}"
echo -e "Votre projet est maintenant prêt à accueillir n'importe quel agent de codage IA."
echo -e "Règles globales liées : ${BOLD}RULES.global.md${NC}"
echo -e "Templates à disposition : ${BOLD}.dev-tools-templates/${NC}"
echo -e "Fiche de contexte projet active : ${BOLD}context.md${NC}"
echo "--------------------------------------------------------"
echo -e "${YELLOW}${BOLD}👉 ÉTAPE SUIVANTE :${NC}"
echo -e "  Ouvrez et copiez le contenu du fichier généré : ${BOLD}prompt_active.md${NC}"
echo -e "  Collez-le dans votre assistant IA (comme Antigravity) en début de session."
echo -e "  L'IA se chargera de tout scanner et configurer automatiquement !"
echo "--------------------------------------------------------"
