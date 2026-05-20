# CONTEXT.md – [Nom du Projet]

Ce fichier sert de source de vérité pour le comportement, les permissions et les workflows de l'agent IA travaillant sur ce projet.

## 1. Informations Générales
- **Stack Technique :** [ex: React, Next.js, Node.js, PHP, Symfony, Docker, Tailwind CSS]
- **Tâches assignées :** [ex: Développement frontend, écriture de composants, styling CSS]
- **Règle #1 :** [Règle critique 1, ex: Ne jamais toucher à la base de données directement]
- **Règle #2 :** [Règle critique 2, ex: Ne pas installer de package sans validation via l'outil de scan]

---

## 2. Matrice des Permissions de Fichiers

### ✅ MODIFICATION AUTORISÉE (Sûr d'éditer)
```
[Spécifier les chemins vers les fichiers que l'agent est encouragé à éditer, ex :
src/components/**/*.tsx
src/styles/**/*.css
]
```

### 📖 LECTURE SEULE (Scan uniquement, informer l'utilisateur des modifications requises)
```
[Spécifier les fichiers que l'agent peut lire mais pas modifier directement, ex :
package.json
src/types/index.d.ts
]
```

### 🚫 ACCÈS INTERDIT (Ne jamais lire ni modifier)
```
[Spécifier les fichiers ou dossiers exclus, ex :
.env*
config/secrets/
migrations/
]
```

---

## 3. Préférences de Communication

- **Mode de communication :** [Direct (snippets de code d'abord) / Verbeux (explications détaillées)]
- **Langue de travail :** Français
- **Niveau de verbosité :** Faible (uniquement l'essentiel)

---

## 4. Workflows Clés & Commandes Utiles

- **Lancement du serveur de dev :** `npm run dev` ou `docker-compose up`
- **Exécution des tests :** `npm run test`
- **Processus de build :** `npm run build`

> [!NOTE]
> Toujours utiliser le préfixe de compétence approprié (🎯, 🧪, 🔍, 🗜️) pour structurer vos réponses.
