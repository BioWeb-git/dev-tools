# Skill Examples Library – Flagship Workflows

Exemples réutilisables pour `/grill-me`, `/tdd`, `/diagnose`, `context-verbosity-fix`.

---

## 🎯 /grill-me Examples

### Example 1: Adding DB Field (Contao)
```
User: "Add a 'featured' checkbox to articles"

🎯 Grilling:
1. Existing articles in production? (Migration needed?)
2. Frontend impact? (Display logic needed?)
3. Admin UI only, or public-facing?
4. Backward compat: default value for old records?
5. Your preference: DCA checkbox + migration, or just DCA?
```

**If user answers:** "Yes, 50k articles, needs migration + migration script"
→ Then you can suggest: DCA change + Doctrine migration + backfill script

---

### Example 2: Refactoring Shared.js
```
User: "The menu toggle is janky, let me rewrite it"

🎯 Grilling:
1. Current menu markup—how is it structured? (Show HTML)
2. Which browsers/devices must work? (iOS Safari? IE?)
3. Current behavior: toggle + close on outside click?
4. Any dependencies? (jQuery? Other scripts?)
5. Want to preserve current DOM, or can restructure?
```

---

### Example 3: Styling Decision
```
User: "Should I use BEM or utility classes for cards?"

🎯 Grilling:
1. Project standard? (Bootstrap utilities + BEM mix?)
2. Performance target? (File size vs maintainability)
3. Designer/team consensus?
4. Responsive complexity? (Multiple breakpoint rules?)
5. Reusability: card used in 10 places or 1?
```

---

## 🧪 /tdd Examples

### Example 1: Modal Component (Contao)
```
User: "Build an accessible modal popup"

🧪 /tdd Acceptance Criteria:
✅ Backdrop dark overlay on page
✅ Modal centered, sized ~500px wide
✅ Close button (X) + keyboard ESC
✅ Focus trap (Tab stays within modal)
✅ ARIA labels: role=dialog, aria-labelledby
✅ Responsive: full-width on mobile

Pseudocode (shared.js):
class Modal {
  constructor(el, options) { ... }
  open() { ... }        // Show + focus trap
  close() { ... }       // Hide + restore focus
  handleKeyDown(e) { ... }  // ESC to close
  handleBackdropClick(e) { ... }
}

Then write actual implementation + SCSS
```

---

### Example 2: Form Validation (Contao)
```
User: "Add real-time email validation"

🧪 /tdd Acceptance Criteria:
✅ Input changes → validate on blur
✅ Show error message if invalid
✅ Disable submit until valid
✅ Success state: green border
✅ Server-side validation too (never trust client)

Pseudocode (shared.js):
class FormValidator {
  validateEmail(input) { ... }       // Regex + AJAX check
  onBlur(e) { ... }                 // Trigger validate
  updateUI(isValid) { ... }         // Show/hide errors
  onSubmit(form) { ... }            // Final check
}

Then code + SCSS + template
```

---

### Example 3: Carousel Component (Contao)
```
User: "Infinite testimonial carousel, auto-rotate"

🧪 /tdd Acceptance Criteria:
✅ Show 1 testimonial at a time
✅ Auto-advance every 5s (pauseable on hover)
✅ Prev/next buttons
✅ Keyboard: arrow keys
✅ Dots/indicators for each testimonial
✅ is-animated class support (fade in on view)

Pseudocode (shared.js):
class Carousel {
  constructor(el, options = {}) { ... }
  next() { ... }
  prev() { ... }
  goTo(index) { ... }
  play() { ... }     // Auto-advance
  pause() { ... }
  handleKeyDown(e) { ... }  // Arrow keys
}

Initialize + SCSS animations
```

---

## 🔍 /diagnose Examples

### Example 1: CSS Not Applying
```
Problem: "Padding on hero section isn't responsive"

🔍 /diagnose Protocol:
1️⃣ Isolate: "When did this break? Show git diff of client.scss"
2️⃣ Reproduce: "Open DevTools → Elements → inspect .hero. What computed padding?"
3️⃣ Inspect: "Is the @include mediaquery(tablet) rule visible in compiled CSS?"
4️⃣ Hypothesis: 
   - Breakpoint value wrong? (tablet should be 1000px max-width)
   - Mixin not found? (typo in @include?)
   - CSS not compiled? (compass watch running?)
   - !important rule overriding? (check Bootstrap utilities)
5️⃣ Test: 
   - Add debug: .hero { background: red !important; } inside mixin block
   - Reload. If red appears, mixin works. If not, breakpoint wrong.
6️⃣ Fix: Show corrected line(s) in client.scss

Next time: Always test mixin first before blaming breakpoint.
```

---

### Example 2: JavaScript Not Running
```
Problem: "Menu toggle button doesn't work"

🔍 /diagnose Protocol:
1️⃣ Isolate: "Is this new code, or regression? Show template change"
2️⃣ Reproduce: "Open browser console (F12) → any JS errors? Paste them"
3️⃣ Inspect: 
   - Is script tag loading? (Network tab in DevTools)
   - DOM selector correct? (querySelector('button.menu-toggle') finding element?)
   - Event listener attached? (Add console.log at start of handler)
4️⃣ Hypothesis:
   - Script loading after DOM? (defer attribute on <script>?)
   - Selector mismatch? (DOM class name ≠ JS selector)
   - Event not bubbling? (Delegation issue?)
   - Conflicting script in script.js (Oneo core)?
5️⃣ Test:
   - Add to shared.js: console.log('Menu script loaded')
   - Reload. Check console.
   - Add to click handler: console.log('Click detected')
6️⃣ Fix: Show corrected shared.js lines

Check: Is this in shared.js or script.js? (Should be shared.js ONLY)
```

---

### Example 3: Responsive Layout Broken
```
Problem: "Layout stacks wrong on tablet"

🔍 /diagnose Protocol:
1️⃣ Isolate: "Show screenshot at tablet width (1000px). What's wrong exactly?"
2️⃣ Reproduce: Browser resize to 1000px. Does it match screenshot?"
3️⃣ Inspect: DevTools → measure elements. Flex/grid rules applied?"
4️⃣ Hypothesis:
   - Breakpoint not firing? (Mixin not applied)
   - Conflicting Bootstrap utility? (.d-flex override?)
   - Container not responding? (fixed width? max-width issue?)
   - Font size/spacing cascading unexpectedly?
5️⃣ Test:
   - Disable Bootstrap utilities, check result
   - Add temporary @include mediaquery(tablet) { background: yellow; }
   - Does yellow appear at 1000px? If not, SCSS not compiling.
6️⃣ Fix: Show breakpoint + rule change

Next time: Always isolate Bootstrap utilities first in responsive debugging.
```

---

## 🗜️ context-verbosity-fix Examples

### Example 1: Trim Repetition
```
BEFORE:
## SCSS Workflow

Your flow:
1. You edit `client.scss`, `_variables_client.scss`, `_fonts.scss`
2. User runs `compass watch files/client/scss/` in terminal
3. Compiled CSS lands in `files/client/css/` automatically
4. **You never run `compass compile` or invoke npm/gulp**

When referencing Bootstrap:
- Bootstrap 5.0.2 vars/mixins are available via `@import` in `imports.scss`
- Suggest changes, don't modify `_variables_bootstrap.scss`

---

AFTER:
## SCSS Workflow
1. Edit: `client.scss`, `_variables_client.scss`, `_fonts.scss`
2. User: `compass watch files/client/scss/` (auto-compiles to `files/client/css/`)
3. ⚠️ Never compile. Never modify `_variables_bootstrap.scss`

---

Saves: ~50% tokens, same info.
```

---

### Example 2: Consolidate Lists
```
BEFORE:
### DO
- Edit only SCSS/JS/templates as specified above
- Suggest new RockSolid element classes (user implements in PHP)
- Flag missing migrations ("Need: ALTER TABLE posts ADD COLUMN...")
- Use Contao\Model::findBy() patterns when discussing data access
- Reference template overrides with full path: `templates/client/block_hero.html5`
- Ask for context on data impacts before suggesting schema changes

---

AFTER:
### DO
- Edit SCSS/JS/templates only (per file matrix above)
- Suggest RockSolid classes → user implements PHP logic
- Flag migrations: "Need: ALTER TABLE..."
- Use Contao\Model patterns + full template paths
- Ask scope before schema changes

---

Saves: ~40% tokens.
```

---

### Example 3: Replace Prose with Table
```
BEFORE:
### Breakpoints

The tablet breakpoint is 1000px. This is used with the mediaquery mixin for max-width rules. The mobile breakpoint is 700px, used for standard phones. For portrait phones only, use mobile-portrait at 600px. All three are defined in _variables.scss and should be used with the @include mediaquery() mixin, never raw @media queries.

---

AFTER:
### Breakpoints
| Name | Width | Usage |
|------|-------|-------|
| tablet | 1000px | `@include mediaquery(tablet) { ... }` |
| mobile | 700px | Standard phones |
| mobile-portrait | 600px | Portrait strict |

⚠️ Use mixins, never raw `@media`. Defined in `_variables.scss`.

---

Saves: ~60% tokens, better scannable.
```

---

## Meta: When to Trigger Each Skill

```
USER SAYS                          SKILL
"before I do X"                    /grill-me
"how would you build this"         /tdd
"is it broken"                     /diagnose
"this doc is too long"             context-verbosity-fix
"seems slow/not working"           /diagnose
"should I use X or Y"              /grill-me
"new feature, don't know how"      /tdd
```

---

## Quick Copy/Paste Templates

### /grill-me Template
```
🎯 Grilling:
1. [Q about scope/impact]
2. [Q about dependencies/users]
3. [Q about backward compat/options]
4. [Q about performance/constraints]
5. [Q about user preference/consensus]
```

### /tdd Template
```
🧪 /tdd Acceptance Criteria:
✅ [What user sees]
✅ [Interaction]
✅ [Edge case 1]
✅ [Edge case 2]

Pseudocode (shared.js / client.scss):
class X {
  constructor() { ... }
  method1() { ... }
  method2() { ... }
}

Then write actual code.
```

### /diagnose Template
```
🔍 /diagnose
1️⃣ Isolate: [What changed? When?]
2️⃣ Reproduce: [Confirm reliably]
3️⃣ Inspect: [DevTools findings?]
4️⃣ Hypothesis: [Root cause options]
5️⃣ Test: [Minimal repro? Debug step?]
6️⃣ Fix: [Target root, show code]
```

