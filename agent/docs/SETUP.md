# 🚀 Guide de Configuration Rapide (SETUP.md)

Ce guide vous explique comment installer et utiliser ce système de développement local sous WSL2 et comment collaborer efficacement avec vos agents IA.

---

## 💻 1. Configuration de l'environnement Local WSL2

### Prérequis
Assurez-vous que votre distribution WSL2 (Ubuntu) dispose des paquets requis :
* Apache2 & MySQL/MariaDB
* PHP (versions 7.4 et 8.1+ installées pour la cohabitation)
* Composer & GitHub CLI (`gh` authentifié via `gh auth login`)

### Rendre les scripts exécutables
Pour que vos scripts fonctionnent correctement, appliquez-leur les permissions d'exécution :
```bash
chmod +x agent/scripts/*.sh
```

### Exécution du tableau de bord
Lancez le tableau de bord interactif pour gérer vos projets :
```bash
./agent/scripts/master_start.sh
```

---

## 🤖 2. Collaboration avec l'Agent IA (Antigravity)

Ce dossier `agent/` contient tout le nécessaire pour que votre assistant de code travaille dans un cadre structuré et sécurisé.

### Étape 1 : Déploiement automatique des règles et outils de l'agent

#### Option A : Pour un projet Contao 5 local (via setup)
Lors de l'installation ou de la maintenance avec la commande `setup`, choisissez l'option **`10. Déployer le système d'agent IA (Symlinks + Context)`** (elle s'exécute aussi automatiquement avec l'option `0` par défaut).

#### Option B : Pour tout autre projet (React, Android, PHP, etc.)
Depuis le dossier `dev-tools`, lancez le script d'initialisation universel :
```bash
./agent/scripts/init_project.sh
```
Ce script interactif vous demandera le chemin de votre projet, le template de contexte à appliquer (`context.md`), et s'occupera d'établir les liens symboliques vers les règles globales et de mettre à jour le `.gitignore` du projet cible.

### Étape 2 : Personnalisation du Contexte Projet
Ouvrez le fichier `context.md` qui a été généré à la racine de votre projet. Personnalisez-le avec les technologies utilisées, vos règles d'architecture et surtout la **Matrice de Permissions** (les dossiers et fichiers que l'agent a le droit de modifier).

### Étape 3 : Initialisation du Prompt
1. Copiez le contenu de [**templates/prompt_master.md**](file:///home/pouet/dev-tools/agent/templates/prompt_master.md).
2. Personnalisez les variables (chemins absolus de votre `context.md` et de votre répertoire de documentation globale).
3. Collez-le dans votre session Antigravity en début de conversation. L'agent sera immédiatement aligné, sécurisé et ultra-performant.
