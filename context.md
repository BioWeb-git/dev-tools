# CONTEXT.md – dev-tools

Ce fichier sert de source de vérité pour le comportement, les permissions et les workflows de l'agent IA travaillant sur ce projet.

## 1. Informations Générales
- **Stack Technique :** Bash (Shell Scripting), WSL2 (Ubuntu), Markdown (Documentation), Git.
- **Tâches assignées :** Automatisation locale, maintenance des scripts d'administration WSL2, configuration d'agents de codage et mise à jour de la documentation d'assistance.
- **Règle #1 :** Ne jamais faire de modifications en dehors du répertoire `dev-tools/` sans validation explicite.
- **Règle #2 :** Toujours valider les modifications de scripts shell interactivement dans un sous-dossier de test isolé avant de clore une tâche.

---

## 2. Matrice des Permissions de Fichiers

### ✅ MODIFICATION AUTORISÉE (Sûr d'éditer)
```
agent/scripts/*.sh             ← scripts d'automatisation
agent/docs/**/*.md             ← documentations d'aide
agent/templates/**/*.md        ← modèles de contexte et prompt master
agent/README.md                ← index d'accueil
```

### 📖 LECTURE SEULE (Scan uniquement, informer l'utilisateur des modifications requises)
```
~/.bashrc                      ← vérification et alignement des alias
```

### 🚫 ACCÈS INTERDIT (Ne jamais lire ni modifier)
```
[Dossiers système d'Apache, de MySQL ou répertoires globaux d'Ubuntu hors workspace]
```

---

## 3. Préférences de Communication
- **Mode de communication :** Direct et concis.
- **Langue de travail :** Français.
- **Niveau de verbosité :** Faible (focus sur le code et les scripts).

---

## 4. Workflows Clés & Commandes Utiles
- **Tester les scripts :** `./agent/scripts/[nom_du_script].sh`
- **Recharger la configuration du shell :** `source ~/.bashrc`
- **Vérifier la syntaxe bash :** `bash -n agent/scripts/[nom_du_script].sh`
