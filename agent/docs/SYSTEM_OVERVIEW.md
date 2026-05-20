# System Guide – Global Rules + Flagship Skills

Ton nouveau système de collaboration avec agents (Antigravity, Claude, etc.).

---

## 📦 What You Have

| File | Purpose |
|------|---------|
| **RULES.global.md** | Universal constraints + flagship skill definitions (/grill-me, /tdd, /diagnose, context-verbosity-fix) |
| **templates/prompt_master.md** | Ready-to-paste prompt for Antigravity (combines RULES + CONTEXT) |
| **docs/skill_examples.md** | Concrete examples + copy/paste templates for each skill |
| **templates/examples/context_contao5.md** | Project-specific context (Contao 5) |

---

## 🚀 Getting Started

### Step 1: Prepare Your Context Files
Organize your projects:
```
~/projects/
  ├── my-contao-project/
  │   ├── RULES.global.md          ← Link or copy from master
  │   ├── context_contao5.md       ← Project-specific
  │   └── docs/api/                ← Local Contao docs
  ├── my-next-project/
  │   ├── RULES.global.md
  │   ├── context_nextjs.md
  │   └── docs/                    ← Local project docs
```

### Step 2: Personalize Master Prompt
Edit `templates/prompt_master.md`:
```markdown
### Load: RULES.global
- URL: https://your-repo/RULES.global.md

### Load: Project-Specific CONTEXT.md
- Path: /home/pouet/projects/my-contao-project/context_contao5.md

### Load: Local Documentation
- Path: /home/pouet/projects/my-contao-project/docs/api/
```

### Step 3: Use in Antigravity
```
1. Open Antigravity
2. Copy content from templates/prompt_master.md (after filling paths)
3. Paste into "Project Context" field (or chat if no dedicated field)
4. Add your request
5. Agent loads RULES.global + CONTEXT automatically
```

---

## 🎯 The Four Flagship Skills

### 1. 🎯 /grill-me – Before Structural Changes

**Trigger:** "Should I...", "Before I...", ambiguous requirements

**Agent asks 5 questions:**
1. Scope/impact?
2. Dependencies?
3. Backward compat?
4. Performance?
5. Options/preference?

**You answer. Then agent proceeds.**

**Example:**
```
You: "Add a new field to articles"
Agent: 🎯 Grilling: [5 questions]
You: [Answer]
Agent: Based on answers, here's the plan: [code]
```

---

### 2. 🧪 /tdd – Complex Features

**Trigger:** "Build X feature", "How would you...", "Complex component"

**Agent asks for acceptance criteria first:**
- What does user see?
- Interactions?
- Edge cases?
- Accessibility needs?

**Then:** Pseudocode → Implementation

**Example:**
```
You: "Create responsive carousel"
Agent: 
🧪 /tdd Acceptance Criteria:
✅ Show 1 item
✅ Auto-advance 5s
✅ Keyboard nav
... [pseudocode] ...

Then I'll code + style.
```

---

### 3. 🔍 /diagnose – Broken Things

**Trigger:** "Broken", "Not working", "Weird behavior"

**Agent follows 6-step methodology:**
1. Isolate (when did it break?)
2. Reproduce (reliably?)
3. Inspect (DevTools findings?)
4. Hypothesize (root causes?)
5. Test (minimal repro?)
6. Fix (target root, not symptom)

**Example:**
```
You: "Menu button doesn't work"
Agent:
🔍 /diagnose
1️⃣ Isolate: Is this new code?
2️⃣ Reproduce: Consistent?
... [asks for DevTools screenshot] ...
6️⃣ Fix: [Shows corrected code]
```

---

### 4. 🗜️ context-verbosity-fix – Trim Context

**Trigger:** "Context too long", "Reduce tokens", "This is redundant"

**Agent shows:**
- Before (verbose)
- After (trimmed)
- Token savings

**Example:**
```
You: "Can you trim the SCSS section in context?"
Agent:
🗜️ Before: [4 paragraphs]
🗜️ After: [2 sentences + table]
Saves: ~45% tokens
```

---

## 📋 File Permissions Pattern

All contexts follow this structure:

```markdown
## File Permissions Matrix

### ✅ EDIT
files/client/scss/client.scss
files/client/js/shared.js
templates/client/**/*.html5

### 📖 SCAN ONLY
files/client/scss/_variables.scss
src/ (read patterns, don't modify)

### 🚫 DON'T TOUCH
src/
config/
migrations/
composer.json
.env*
```

**Agent checks this first.** If you don't have it, create it.

---

## 💬 Communication Modes

### Mode 1: Direct (Default)
- Snippets first
- Minimal explanation
- Prefix with skill icon (🎯, 🧪, 🔍, 🗜️)

### Mode 2: Verbose
- Full explanation
- Why you're doing X
- Tradeoffs, alternatives

### Mode 3: Silent Code
- Just the code
- No talking

**Specify in CONTEXT.md:**
```markdown
## Communication Preference
- Mode: Direct (snippets-first)
- Language: French/English
- Verbosity: Low
```

---

## 🚨 Safety: Protected Files

**These agent CANNOT modify (ever):**
```
src/                    ← Backend PHP
config/                 ← DCA, services
migrations/             ← Database changes (user does these)
composer.json           ← Dependencies
.env*                   ← Secrets
```

**If agent tries to modify these:**
```
❌ Rule Violation
Cannot: Modify src/Elements/CustomElement.php
Reason: Backend PHP is user's domain
Action Needed: You implement this logic, I provide template + styles
```

---

## 📌 Workflow Examples

### Workflow: New Contao Feature

```
1. You: "Create testimonial block"
2. Agent: 🧪 /tdd → shows acceptance criteria
3. You: "Approve criteria"
4. Agent: Codes SCSS + template + RSCE config
5. You: Review, ask changes
6. Agent: Refines with reason
```

### Workflow: Debug CSS Issue

```
1. You: "Logo disappears on mobile"
2. Agent: 🔍 /diagnose → asks 6 questions
3. You: "It works on desktop, breaks <700px, started after I edited client.scss"
4. Agent: Shows suspected lines, asks for DevTools screenshot
5. You: "Here's screenshot" [paste]
6. Agent: Identifies root cause, shows fix
```

### Workflow: Reduce Context Size

```
1. You: "Context is 5KB, feels bloated"
2. Agent: 🗜️ Analyzes file
3. Shows: Before → After comparison
4. You: "Approve changes"
5. Agent: Delivers trimmed version
```

---

## 🎓 Best Practices

### For You (User)

1. **Provide context first** – RULES.global + CONTEXT.md before asking anything
2. **Be specific** – "Create hero" is vague. "Create hero: 100vh, background image, centered text, responsive" is clear
3. **Show screenshots** – For responsive/visual issues, DevTools screenshots help
4. **Approve criteria** – In /tdd workflows, confirm acceptance criteria before coding
5. **Ask /grill-me early** – If unsure, trigger the skill before agent proceeds

### For Agent

1. **Load RULES first** – Check file matrix, protected files, skill triggers
2. **Never assume** – Ask scope before big changes
3. **Snippet-first** – Code before explanation
4. **Reference local docs** – `/home/pouet/docs/api/` before generic patterns
5. **Use skill prefixes** – 🎯, 🧪, 🔍, 🗜️ make responses scannable

---

## 🔧 Customization

### Add New Skill?

1. Define in RULES.global under "Flagship Skills"
2. Add trigger condition in "Skill Triggers" table
3. Add examples in docs/skill_examples.md
4. Update master prompt with keyword mapping

Example new skill: `/compress` (minify CSS/JS without losing readability)

```markdown
### 📦 /compress – Minify Without Harming Readability

**When to use:** "File too big", "Optimize for production"

**How to use:**
1. Identify bloat sources (unused utilities, repetition)
2. Consolidate classes/variables
3. Minify only, never break maintainability
4. Show before/after sizes
```

### Modify Existing Project Context?

Edit context file → Add section → Mark with emoji for visibility

```markdown
## 6. New: Accessibility Requirements

✅ WCAG 2.1 AA compliance required
- Semantic HTML (no <div> instead of <button>)
- Color contrast: 4.5:1 for text, 3:1 for UI
- ARIA labels for dynamic content
```

---

## 📞 Support / Questions

**Context is confusing?** → See docs/skill_examples.md for concrete cases

**Agent not loading RULES?** → Paste RULES content directly into prompt (don't link)

**Skill not triggering?** → Check "Skill Triggers" table in RULES.global, use exact keywords

**Project-specific question?** → Add section to project CONTEXT.md, reference in master prompt

---

## ✅ Checklist: Before Using with Agent

- [ ] RULES.global.md exists and covers your needs
- [ ] templates/prompt_master.md has paths filled in
- [ ] project CONTEXT.md created (file permissions + project rules)
- [ ] docs/skill_examples.md handy for reference
- [ ] Protected files clear (src/, config/, etc.)
- [ ] Communication mode set (Direct, Verbose, Silent)

**Done?** You're ready. Copy/paste master prompt → start session.

---

## Version History

| Date | Change |
|------|--------|
| 2025-05-20 | Initial release (4 flagship skills, master prompt, examples) |

---

**Made with ❤️ for your AI collaboration. Iterate, improve, dominate.** 🚀

