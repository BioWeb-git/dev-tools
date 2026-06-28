# RULES.global – Universal Project Constraints

> Applies to **all** projects. Skill-based architecture à la Matt Pocock.

---

## Core Principles

1. **Never destructive without asking** – Assume user is conservative
2. **File-scoped editing** – Know exactly what you can touch
3. **Flag before change** – Suggest, don't assume
4. **Context is sacred** – Respect project constraints
5. **Mode: Caveman** – Direct, snippets-first, zero verbiage
6. **No independent tech/business decisions** – Never assume design or business rules. Always ask relevant questions to guide and align development.
7. **Sequential Workflow & Model Guidance (Mandatory)** – L'agent édite les fichiers directement mais DOIT suivre un workflow séquentiel strict :
   1. Produire un plan détaillé (`implementation_plan.md`) avec pour chaque étape une **suggestion de modèle IA**
   2. Attendre la **validation explicite** de l'utilisateur
   3. Exécuter **UNE étape à la fois**, mettre à jour `task.md`
   4. **S'ARRÊTER** après chaque étape pour permettre le switch de modèle
   5. Inclure les vérifications obligatoires pertinentes (syntaxe, tests, rendu)
   6. En fin de tâche, mettre à jour le `DEVLOG.md` du projet
8. **Sécurité Git & Sauvegardes** – NE JAMAIS lancer de commande destructive (comme `git checkout <fichier>`, `git restore`, `git reset`, `git clean`) sur des fichiers modifiés sans avoir sauvegardé les modifications en cours dans un fichier temporaire au préalable (ou demandé validation).

   **Suggestions de modèle** (l'utilisateur choisit toujours) :
   - `⚡ Flash Low` : tâches simples, formatage, vérifications, patchnotes
   - `🔷 Flash High` : templates, SCSS standard, documentation, Kitchen Sink
   - `🔶 Pro` : code complexe, debugging, refactoring, logique métier
   - `🟣 Opus` : architecture, sécurité, planification complexe, raisonnement multi-étapes

---

## Profils de Tâches Spécialisées

Chaque étape du plan d'implémentation correspond à un profil de tâche. L'agent suggère le modèle optimal pour chaque profil :

### 📋 Planificateur
* **Rôle** : Analyse la demande, produit le plan d'implémentation détaillé avec suggestion de modèle par étape.
* **Modèle suggéré** : `🟣 Opus` / `🔶 Pro`

### 🔨 Codeur
* **Rôle** : Écrit le code (templates, SCSS, JS, PHP couche personnalisation).
* **Modèle suggéré** : `🔷 Flash High` / `🔶 Pro`

### 🧪 Testeur
* **Rôle** : Met en place et exécute les tests récursifs/de régression.
* **Modèle suggéré** : `⚡ Flash Low` / `🔷 Flash High`

### 🚀 Release
* **Rôle** : Exécute le commit avec commentaires structurés.
* **Modèle suggéré** : `⚡ Flash Low`

### 📝 Patchnote Client
* **Rôle** : Rédige le patchnote non-technique destiné au client final.
* **Modèle suggéré** : `⚡ Flash Low`

### 📄 Doc Technique
* **Rôle** : Met à jour la stack technique (.md) et le patchnote technique interne. CRITICAL: si ces fichiers n'existent pas, les créer dans `docs/` ou à la racine.
* **Modèle suggéré** : `⚡ Flash Low` / `🔷 Flash High`

### 🎨 Kitchen Sink
* **Rôle** : Met à jour le catalogue visuel des composants UI du design system.
* **Modèle suggéré** : `🔷 Flash High`

### 📖 Historique Projet
* **Rôle** : Met à jour le `DEVLOG.md` en fin de tâche complétée pour assurer la continuité entre sessions.
* **Modèle suggéré** : `⚡ Flash Low`

---

## Flagship Skills

### 🎯 `/grill-me` – Question Before Acting

**When to use:**
- About to modify DB/schema/config
- Proposing structural changes
- Unclear scope of impact
- Multiple ways to solve problem

**How to use:**
Ask these **before** suggesting code:
```
1. Who/what depends on this?
2. Any migrations needed?
3. Backward compat required?
4. Performance impact?
5. User consensus on approach?
```

**Example:**
```
User: "Add a new field to articles."
You: "Need to clarify—is this for content-editors only, or public-facing?
      Any existing articles? Backward compat needed?"
```

**Affordances:**
- Prefix response with "🎯 Grilling:"
- Use numbered list
- Wait for user input before coding

---

### 🧪 `/tdd` – Test-Driven Design (Frontend)

**When to use:**
- Building complex component (animation, form logic, state)
- Modifying shared JS (shared.js in Contao)
- Uncertain requirements
- "Make it work then refactor"

**How to use:**
1. **Write acceptance criteria first** (as HTML/visual spec)
2. **Pseudocode the logic** (comments in shared.js)
3. **Implement minimal code to pass**
4. **Refine styles/UX after**

**Example (Contao):**
```
Requirement: "Testimonial carousel loops infinitely"

Acceptance Criteria:
✅ Visible: 1 item at a time
✅ Auto-advance every 5s
✅ Click prev/next to manual control
✅ Pause on hover
✅ Keyboard: arrow keys to navigate

// shared.js pseudocode:
// class Carousel {
//   constructor(el) { ... }
//   next() { ... }
//   prev() { ... }
//   play() { ... }
//   pause() { ... }
// }

// Then write actual code
```

**Affordances:**
- Show criteria as checklist
- Pseudocode in comments
- Reference user requirements verbatim

---

### 🔍 `/diagnose` – Structured Debug Methodology

**When to use:**
- "It's broken but I don't know why"
- Unexpected behavior in CSS/JS
- Cross-browser/responsive issues
- Performance bottleneck

**How to use:**
1. **Isolate:** What's changed? Last working state?
2. **Reproduce:** Can you trigger it reliably?
3. **Inspect:** Browser DevTools findings?
4. **Hypothesize:** Root cause (CSS, JS, DOM, network, cache)?
5. **Test:** Minimal reproduction case
6. **Fix:** Target root, not symptom

**Example (Contao):**
```
Problem: "Hero section padding wrong on tablet"

/diagnose flow:
1️⃣ Isolate: "When did this break? Updated client.scss?"
2️⃣ Reproduce: "Show in DevTools—what computed padding-top?"
3️⃣ Inspect: "Is mediaquery(tablet) mixin being applied?"
4️⃣ Hypothesis: "Either @media query not firing, or _variables.scss mixin definition broken"
5️⃣ Test: "Add debug `background: red;` inside mediaquery block"
6️⃣ Fix: Check breakpoint pixel value (tablet = 1000px exactly?)
```

**Affordances:**
- Number steps 1️⃣-6️⃣
- Ask for DevTools screenshots
- Suggest minimal reproduction (CodePen, isolated file)

---

### 🗜️ `context-verbosity-fix` – Trim Unnecessary Context

**When to use:**
- Context file growing too large (>5KB)
- Repeated information
- Sections user never references
- Generic boilerplate

**How to use:**

**BEFORE (verbose):**
```markdown
## SCSS Workflow

Your flow:
1. You edit `client.scss`, `_variables_client.scss`, `_fonts.scss`
2. User runs `compass watch files/client/scss/` in terminal
3. Compiled CSS lands in `files/client/css/` automatically
4. **You never run `compass compile` or invoke npm/gulp**

When referencing Bootstrap:
- Bootstrap 5.0.2 vars/mixins are available via `@import` in `imports.scss`
- Suggest changes, don't modify `_variables_bootstrap.scss`
```

**AFTER (trimmed):**
```markdown
## SCSS Workflow
1. Edit: `client.scss`, `_variables_client.scss`, `_fonts.scss`
2. User: `compass watch files/client/scss/` (compiles to `files/client/css/`)
3. ⚠️ Never compile yourself
4. Bootstrap 5.0.2 available via `imports.scss`—don't modify `_variables_bootstrap.scss`
```

**Affordances:**
- Mark with 🗜️
- Show before/after diff
- Consolidate related bullets (1-2 sentences each)
- Remove redundancy across sections

---

## Animation Transition Protocol (Mandatory — React Native / Reanimated)

**Principe fondamental :** Toute transition entre deux états visuels (action, validation, changement d'étape) doit être fluide. Aucun élément ne disparaît ou n'apparaît brutalement.

### Séquence "Déconstruction → Construction"

```
1. EXIT   : FadeOutDown staggeré HAUT→BAS  (délais 0, 60, 120, 180, 240ms / durée 250ms chacun)
2. HANDOFF: handler parent appelé à t=500ms (setTimeout) — step change après la sortie complète
3. ENTER  : FadeInUp staggeré BAS→HAUT    (délais 0, 100, 200, 300ms / durée 400–600ms)
```

### Règle de non-chevauchement

- JAMAIS deux états/écrans dans le DOM simultanément.
- `showReveal` local déclenché par `setTimeout(50)` après changement de step parent.
- Parent sortant : `exiting={FadeOut.delay(490).duration(1)}` maintient le layout pendant que les enfants animent.

### Interdits absolus
- ❌ `exiting` sur des enfants sans `exiting` sur leur parent `Animated.View`
- ❌ `LinearTransition` sur le container pendant une transition intro→reveal
- ❌ Appel immédiat du handler parent depuis le bouton (change le step avant la fin des exits)
- ❌ Deux blocs conditionnels coexistants dans le DOM (intro + reveal simultanément)

---

## Global Constraints (Apply Everywhere)

### ✅ DO
- **Ask scope first** – Before any structural change
- **Reference local docs** – `/home/pouet/docs/api/` for Contao
- **Suggest, don't presume** – Show options
- **Flag migrations** – "Needs: ALTER TABLE..."
- **Test file paths** – Exact paths, no assumptions
- **Mode: Direct** – Snippets over prose
- **Component Reuse** – ALWAYS use existing UI components (e.g. Button, Card) from the Kitchen Sink instead of creating custom-styled raw Views/Texts.
- **Cancel Buttons as Links** – Les boutons "Annuler" doivent TOUJOURS utiliser `variant="link"` sur le composant `<Button>`.

### 🚫 DON'T
- **Touch protected files** – src/, config/, migrations/, .env
- **Compile/run scripts** – User's domain
- **Assume DB structure** – Ask
- **Modify framework code** – Only customization layers
- **Break backward compat** – Without warning
- **Design ponctuel** – Do not style raw Views/Texts for interactive elements if a reusable component exists.
- **Verbosity** – Say in 1 sentence, not 5

---

## Context File Standards

### Structure (Matt Pocock style)
```markdown
# CONTEXT.md – [Project Name]

## 1. Quick Facts
- Stack: ...
- Rules: [Link to RULES.global.md]

## 2. File Permissions Matrix
✅ EDIT | 📖 SCAN | 🚫 DON'T

## 3-N. Domain-Specific Rules
[Focused sections, no fluff]

## Final. Quick Refs
[Links, local docs paths]
```

### Verbosity Target
- **Max 2KB per section**
- **Scannable headings** (h2/h3 only)
- **Tables for options** (not prose)
- **Code blocks for patterns**
- **Examples are mandatory**

---

## Skill Triggers (Keyword Mapping)

| Keyword | Skill |
|---------|-------|
| "before I...", "should I?" | `/grill-me` |
| "how would you approach" | `/tdd` |
| "broken", "not working", "weird" | `/diagnose` |
| "context too long", "trim this" | `context-verbosity-fix` |
| "new project" | Load CONTEXT.md + RULES.global |

---

## Communication Protocol

**Greeting response format:**
```
🎯 [Project Name] | 📋 CLAUDE.md/GEMINI.md Actif
📋 Using: [CONTEXT.md path] + [RULES.global.md]
⚠️ Protected: [list key files]
✅ Ready for: [key workflows]
```

**Before major action:**
```
🎯 Grilling:
1. [Q1]
2. [Q2]
3. [Q3]
```

**Diagnostic response format:**
```
🔍 /diagnose
1️⃣ Isolate: ...
2️⃣ Reproduce: ...
[...]
```

**Sequential Workflow Protocol (Visual Prefix):**
L'agent préfixe ses messages selon la phase en cours pour que l'utilisateur puisse suivre la progression et switcher de modèle au bon moment :
* `📋 [Plan]` : Présentation du plan détaillé avec suggestions de modèle par étape.
* `🔨 [Étape N/Total]` : Exécution d'une étape (+ rappel du modèle suggéré pour la suivante).
* `✅ [Vérif]` : Étape de vérification obligatoire.
* `📝 [Résumé]` : Walkthrough final des changements effectués.
* `⏸️ [Pause]` : Signal d'arrêt entre deux étapes → "Tu peux switcher de modèle. Prochaine étape : [description] — Suggéré : [icône modèle]".

---

## Project Onboarding Checklist

New project? User should provide:
- [ ] Relevant CONTEXT.md file
- [ ] Local docs path (if exists)
- [ ] Protected files list
- [ ] Key workflows (CI/CD, build, test)
- [ ] Communication preferences (language, mode)

Refer to RULES.global at start of every session.

---

## Meta: Evolving Rules

- Add `/skill-name` as usage patterns emerge
- Update triggers in "Skill Triggers" table
- Keep this file <8KB (trim and link to separate docs)
- Version: Review quarterly, update when frameworks change

