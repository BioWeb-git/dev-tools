# 🎯 Système d'Agent de Développement – dev-tools

Bienvenue dans le centre d'automatisation et de collaboration avec vos assistants de développement IA (comme Antigravity). Ce dossier structure les outils d'automatisation locale WSL2 et les fichiers de configuration nécessaires pour guider vos agents.

---

## 🗺️ Navigation dans le système

```
agent/
├── 📖 docs/              ← Guides et méthodologies
│   ├── SYSTEM_OVERVIEW.md ← Fonctionnement global (Règles + Compétences)
│   ├── skill_examples.md  ← Exemples d'utilisation (/grill-me, /tdd, /diagnose)
│   └── SETUP.md           ← Démarrage rapide (WSL2 + Antigravity)
│
├── 📝 templates/         ← Modèles pour l'agent
│   ├── prompt_master.md   ← Template de prompt universel à copier
│   ├── context_template.md ← Modèle de contexte projet vierge
│   └── examples/
│       └── context_contao5.md ← Contexte d'exemple préconfiguré pour Contao 5
│
└── 🐚 scripts/           ← Scripts shell d'automatisation locale
    ├── README.sh.md       ← Liste et rôle détaillé de chaque script
    ├── master_start.sh    ← Tableau de bord interactif principal
    └── [autres scripts]
```

* **Nouveau sur ce système ?** Commencez par lire le guide d'architecture globale : [**docs/SYSTEM_OVERVIEW.md**](file:///home/pouet/dev-tools/agent/docs/SYSTEM_OVERVIEW.md) ou le guide d'installation : [**docs/SETUP.md**](file:///home/pouet/dev-tools/agent/docs/SETUP.md).

---

## 🤖 Guide de démarrage rapide avec l'IA

Vous souhaitez que votre assistant IA (comme Antigravity) collabore sur un de vos projets ? Le déploiement de l'agent est entièrement automatisé.

### Option A : Sur un projet Contao 5 local (via setup)
1. Lors du lancement de votre commande `setup` pour installer ou configurer un projet local, choisissez l'option **`10. Déployer le système d'agent IA (Symlinks + Context)`** (cette étape est aussi exécutée automatiquement si vous choisissez l'option `0` par défaut).
2. Un fichier `context.md` est généré à la racine de votre projet, et les liens symboliques nécessaires vers vos documentations et modèles sont configurés.

### Option B : Sur tout autre type de projet (React, Android, PHP, etc.)
1. Lancez le script interactif et universel :
   ```bash
   ./agent/scripts/init_project.sh
   ```
2. Renseignez le répertoire cible du projet, choisissez le template de contexte le plus adapté et le script s'occupe de tout (génération de `context.md`, configuration des liens symboliques et mise à jour du `.gitignore`).

### Une fois le système déployé :
1. Personnalisez les informations spécifiques à votre projet dans le fichier `context.md` généré à la racine de votre projet.
2. Ouvrez le prompt principal de [**templates/prompt_master.md**](file:///home/pouet/dev-tools/agent/templates/prompt_master.md), adaptez les chemins d'accès vers votre `context.md` et votre répertoire de documentation globale, puis transmettez-le à votre assistant IA en début de session. Il sera instantanément configuré et synchronisé avec votre espace de travail !
