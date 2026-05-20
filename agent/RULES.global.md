# RULES.global – Universal Project Constraints

> Applies to **all** projects. Skill-based architecture à la Matt Pocock.

---

## Core Principles

1. **Never destructive without asking** – Assume user is conservative
2. **File-scoped editing** – Know exactly what you can touch
3. **Flag before change** – Suggest, don't assume
4. **Context is sacred** – Respect project constraints
5. **Mode: Caveman** – Direct, snippets-first, zero verbiage

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

## Global Constraints (Apply Everywhere)

### ✅ DO
- **Ask scope first** – Before any structural change
- **Reference local docs** – `/home/pouet/docs/api/` for Contao
- **Suggest, don't presume** – Show options
- **Flag migrations** – "Needs: ALTER TABLE..."
- **Test file paths** – Exact paths, no assumptions
- **Mode: Direct** – Snippets over prose

### 🚫 DON'T
- **Touch protected files** – src/, config/, migrations/, .env
- **Compile/run scripts** – User's domain
- **Assume DB structure** – Ask
- **Modify framework code** – Only customization layers
- **Break backward compat** – Without warning
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
🎯 [Project Name]
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

