# 🐚 Scripts d'Automatisation Shell

Ce répertoire regroupe l'ensemble des scripts bash conçus pour automatiser la configuration, l'exécution et le nettoyage de vos environnements locaux sous WSL2 (Ubuntu).

---

## 🛠️ Tableau de bord & Orchestration

### 📄 [**master_start.sh**](file:///home/pouet/dev-tools/agent/scripts/master_start.sh)
C'est le point d'entrée principal. Il lance un menu interactif dans le terminal permettant d'orchestrer toutes les autres tâches de développement sans avoir à retenir les noms de chaque script individuel.

---

## 🚀 Services & Environnement de Dev

### 📄 [**start_dev.sh**](file:///home/pouet/dev-tools/agent/scripts/start_dev.sh)
* **Rôle** : Vérifie et démarre les services Apache2 et MySQL sous WSL2 de manière intelligente (uniquement s'ils ne sont pas déjà en cours d'exécution).

### 📄 [**switch-php.sh**](file:///home/pouet/dev-tools/agent/scripts/switch-php.sh)
* **Rôle** : Bascule rapidement et proprement les versions de PHP actives sous Ubuntu (nécessaire pour la compatibilité entre Contao 3.5 sous PHP 7.4 et Contao 5 sous PHP 8.3+).

---

## 📦 Cycle de vie des Projets

### 📄 [**setup_project.sh**](file:///home/pouet/dev-tools/agent/scripts/setup_project.sh)
* **Rôle** : Crée ou clone un projet Contao 4/5 de bout en bout en une seule commande. 
* **Actions** : Gestion BDD, génération `.env` et `auth.json` GitHub, `composer install`, configuration des permissions ACL robustes, création du Virtual Host Apache, et optionnellement **déploiement du système d'agent IA (liens symboliques + configuration de contexte)**.

### 📄 [**init_project.sh**](file:///home/pouet/dev-tools/agent/scripts/init_project.sh)
* **Rôle** : Script universel d'initialisation du système d'agent IA sur n'importe quel projet (React, Android, PHP, etc.).
* **Actions** : Demande le répertoire cible, propose de choisir un template de contexte (`context.md`) parmi ceux disponibles, déploie les liens symboliques vers les règles globales et les dossiers d'aide, et configure le `.gitignore`.

### 📄 [**setup_contao5.sh**](file:///home/pouet/dev-tools/agent/scripts/setup_contao5.sh)
* **Rôle** : Ancien script `setup_contao3.sh` optimisé pour installer et configurer proprement un projet historique sous Contao 3.5. Bascule automatiquement sur PHP 7.4 et Node 14.

### 📄 [**teardown_project.sh**](file:///home/pouet/dev-tools/agent/scripts/teardown_project.sh)
* **Rôle** : Supprime 100% proprement un projet local existant.
* **Actions** : Propose un menu interactif des dossiers locaux, supprime la BDD, désactive et supprime le Virtual Host Apache, et efface les fichiers locaux après double confirmation de sécurité (`YES`).

---

## 💾 Utilitaires de données & Modes

### 📄 [**db_restore.sh**](file:///home/pouet/dev-tools/agent/scripts/db_restore.sh)
* **Rôle** : Permet de restaurer rapidement des sauvegardes ou dumps SQL dans votre base de données locale.

### 📄 [**dev_mode_switch.sh**](file:///home/pouet/dev-tools/agent/scripts/dev_mode_switch.sh)
* **Rôle** : Utilitaire permettant d'activer ou de désactiver instantanément le mode debug de Symfony/Contao et de vider les caches applicatifs.

---

## ⚙️ Exécution des scripts

Tous les scripts doivent posséder les permissions d'exécution. Si nécessaire, appliquez-les via :
```bash
chmod +x agent/scripts/*.sh
```
Pour lancer l'assistant global, exécutez simplement :
```bash
./agent/scripts/master_start.sh
```
