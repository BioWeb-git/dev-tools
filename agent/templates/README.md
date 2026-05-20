# 📁 Modèles d'Agent (Templates)

Ce répertoire contient des modèles prêts à l'emploi et des exemples concrets pour configurer les interactions avec vos assistants de développement IA (comme Antigravity).

## 🗂️ Contenu du dossier

| Fichier | Rôle / Description |
| :--- | :--- |
| 📄 [**prompt_master.md**](file:///home/pouet/dev-tools/agent/templates/prompt_master.md) | **Modèle de Prompt Principal**. C'est le bloc de texte de base à copier-coller dans l'IA au début d'une session. Il configure le comportement de l'agent et charge les règles. |
| 📄 [**context_template.md**](file:///home/pouet/dev-tools/agent/templates/context_template.md) | **Modèle de Contexte Projet (Vierge)**. Une structure standardisée à dupliquer et remplir pour vos nouveaux projets afin de définir les permissions de fichiers de l'agent. |
| 📂 [**examples/**](file:///home/pouet/dev-tools/agent/templates/examples/) | **Exemples pratiques par stack**. Contient des modèles de contextes déjà remplis pour des configurations spécifiques. |

---

## 🚀 Comment démarrer un nouveau projet ?

1. **Copiez le modèle de contexte** :
   ```bash
   cp templates/context_template.md ~/projects/mon-nouveau-projet/CONTEXT.md
   ```
2. **Personnalisez-le** en éditant la section *Matrice des Permissions* et *Informations Générales*.
3. **Configurez le Master Prompt** : copiez [templates/prompt_master.md](file:///home/pouet/dev-tools/agent/templates/prompt_master.md) et renseignez le chemin absolu vers le `CONTEXT.md` nouvellement créé.
4. **Commencez la session** avec l'IA en lui fournissant ce Master Prompt.
