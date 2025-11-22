# 🚀 Assistant de Workflow Local WSL : Dev-Tools

Ensemble de scripts bash pour créer et supprimer en quelques secondes un projet Contao local propre et complet sous WSL2 (Ubuntu).

**Plus jamais 15-30 minutes perdues à configurer manuellement Apache, MySQL, Virtual Host, .env, BDD et Git !**

---

## ⚙️ Prérequis

Pour utiliser ces scripts, votre environnement WSL2 (Ubuntu) doit être prêt. Assurez-vous d'avoir les outils suivants installés et configurés :

* **WSL2** (avec distribution Ubuntu ou équivalente)
* **Apache2** (Serveur Web)
* **MySQL/MariaDB** (Base de données, accessible via `sudo mysql`)
* **PHP** (Version compatible Contao 5, généralement PHP 8.1+)
* **Composer** (Gestionnaire de dépendances PHP)
* **GitHub CLI (`gh`)** : Installé et authentifié (`gh auth login`).
* **Permissions** : Votre utilisateur doit être capable d'utiliser `sudo` sans entrer un mot de passe trop fréquemment.

---

## 💻 Utilisation et Lancement

Le script principal est **`master_start.sh`**, qui sert de tableau de bord pour toutes les opérations.

**1. Installation des Scripts :**

Assurez-vous que vos scripts sont dans le même dossier et qu'ils sont exécutables :

# Scripts de Gestion de Projet

## Prérequis
chmod +x master_start.sh setup_projet.sh teardown_projet.sh
Lancement Global
Démarrer l’environnement et accéder au menu principal :

bash
Copier le code
./master_start.sh
🔍 Fonctions Détaillées des Scripts
1. master_start.sh
Lanceur de Workflow Principal

Ce script sert de point d’entrée à l’environnement de développement.

# 🛠️ Contao Local Kit – Setup & Teardown ultra-rapide sous WSL2

## Fonctionnalités détaillées

### 1. `master_start.sh` – Tableau de bord principal

- Démarrage intelligent d’Apache2 et MySQL (seulement si nécessaire)
- Messages clairs : déjà actif ou démarré avec succès
- Options rapides :
  - Redémarrer Apache
  - Redémarrer MySQL
  - Redémarrer les deux
- Accès direct à la création ou suppression d’un projet
- Sortie propre du script (Ctrl+C ou « q »)

### 2. `setup_projet.sh` – Création complète d’un projet Contao en une commande

| Étape                  | Action réalisée automatiquement                                                                 |
|-----------------------|-------------------------------------------------------------------------------------------------|
| Dépôt GitHub          | Crée automatiquement `BioWeb-git/nom-du-projet` ou clone un dépôt existant (menu interactif)    |
| Base de données       | · Crée la BDD `[nom-projet]_local`<br>· Détecte si elle existe déjà et propose de la remplacer |
| Fichier `.env.local`  | Généré et pré-configuré automatiquement                                                         |
| Dépendances PHP       | `composer install` exécuté automatiquement                                                      |
| Virtual Host Apache   | Crée + active le fichier `[nom-projet].test.conf` dans `/etc/apache2/sites-available/`         |
| Finalisation          | Rappel clair pour ajouter l’entrée dans `C:\Windows\System32\drivers\etc\hosts` (Windows)       |

### 3. `teardown_projet.sh` – Suppression 100 % propre et sécurisée

| Étape                 | Action (avec confirmation obligatoire à chaque étape)                                           |
|-----------------------|-------------------------------------------------------------------------------------------------|
| Sélection du projet   | Liste interactive numérotée de tous les dossiers projets locaux                                 |
| Base de données       | `DROP DATABASE [nom]_local`                                                                     |
| Virtual Host          | `a2dissite [nom].test` + suppression du fichier de configuration                                |
| Dossier local         | Suppression complète du dossier projet après **double confirmation**                            |
| Sécurité maximale     | Aucune action destructrice sans saisie explicite de `YES`                                       |

## Pourquoi utiliser ces scripts ?

- Vous gagnez **15 à 30 minutes** par projet
- Plus jamais d’oubli de Virtual Host, de BDD ou de `.env`
- Suppression parfaitement propre → **zéro projet orphelin**
- Workflow ultra-fluide et professionnel sous WSL2

## Contribution & support

Issues et Pull Requests sont les bienvenus !  
Projet maintenu avec ❤️ pour la communauté Contao francophone.

**Plus de temps gagné = plus de code de qualité livré.**

Bon dev sous WSL2 ! 🚀
