# CONTEXT.md – Contao 5 (Antigravity)

## 1. Quick Facts
- **Stack:** Contao 5.x, PHP 8.4+, Symfony, Doctrine ORM, Bootstrap 5.0.2
- **Task:** Frontend dev, template customization, SCSS styling, RockSolid elements
- **Rule #1:** Never touch database. User handles migrations.
- **Rule #2:** No compilation. User runs `compass watch files/client/scss/`

---

## 2. File Permissions Matrix

### ✅ EDIT (Always safe to modify)
**Thème Client (Spécifique au projet)**
```
files/client/scss/client.scss          ← surcharges spécifiques
files/client/scss/_variables_client.scss ← tokens/couleurs/vars client
files/client/scss/_fonts.scss          ← imports Google Fonts, etc.
files/client/js/shared.js              ← scripts personnalisés ONLY
templates/client/**/*.html5            ← surcharges templates
templates/client/rsce_*.html5          ← templates RSCE custom elements
templates/client/rsce_*_config.php     ← config RSCE (hauteur, options, etc.)
```

### 📖 SCAN ONLY (Read-only, inform user of changes needed)
**Thème Global / Framework**
```
files/client/scss/_variables.scss      ← breakpoints (tablet, mobile, etc.)
files/client/scss/_custom.scss         ← global overrides (si besoin)
files/client/scss/_mixins.scss         ← media query mixins (DO NOT MODIFY)
files/client/scss/_tools.scss
files/client/scss/_variables_bootstrap.scss
files/client/scss/imports.scss
files/client/scss/_main.scss           ← core theme structure (DO NOT MODIFY)
files/client/js/script.js              ← Oneo core (scroll, menu, animations)
```

### 🚫 DO NOT TOUCH
```
templates/oneo/**                      ← Oneo framework templates
src/                                   ← PHP (user's domain)
config/                                ← DCA, services (user's domain)
migrations/                            ← User creates via Doctrine
composer.json, .env*
```

---

## 3. Responsive Design & Breakpoints

**Breakpoints (définis dans `_variables.scss`):**
| Variable | Width | Usage |
|----------|-------|-------|
| `tablet` | 1000px | Tablette et desktop |
| `mobile` | 700px | Téléphone standard |
| `mobile-portrait` | 600px | Téléphone portrait strict |

**Media Query Mixins (dans `_mixins.scss`—DO NOT MODIFY):**
```scss
@include mediaquery(tablet)      { ... }    // max-width: 1000px
@include mediaquery-min(tablet)  { ... }    // min-width: 1000px
@include container(tablet)       { ... }    // Container Queries CSS
```

**⚠️ Important:** Always use mixins from `_mixins.scss`, never raw `@media`. Ensures consistency.

---

## 4. SCSS Workflow

**Your flow:**
1. You edit `client.scss`, `_variables_client.scss`, `_fonts.scss`
2. User runs `compass watch files/client/scss/` in terminal
3. Compiled CSS lands in `files/client/css/` automatically
4. **You never run `compass compile` or invoke npm/gulp**

**When referencing Bootstrap:**
- Bootstrap 5.0.2 vars/mixins are available via `@import` in `imports.scss`
- Suggest changes, don't modify `_variables_bootstrap.scss`

---

## 5. SCSS Variables Best Practices

**_variables_client.scss – Critical Rule:**
```scss
// ✅ Overrides global defaults (correct)
$color-primary: #0066cc;

// ❌ NEVER use !default in _variables_client.scss
$color-primary: #0066cc !default;    // This prevents your custom value from taking effect
```

**Why?** This file overrides framework defaults. `!default` breaks that—your vars won't apply if a global exists elsewhere.

---

## 6. Animation System (is-animated)

Oneo includes a lightweight animation engine in `files/client/js/script.js`.

**How it works:**
1. Add `.is-animated` class to element (via RSCE, template, or inline)
2. Script watches scroll, injects `.in-view` when element is **80% in viewport**
3. `.has-shown` indicates element was viewed at least once
4. Add `.does-repeat` to re-animate on every pass

**Recommended CSS pattern:**
```scss
.votre-element.is-animated {
    opacity: 0;
    transform: translateY(20px);
    transition: all 1s ease;
    
    &.in-view {
        opacity: 1;
        transform: translateY(0);
    }
}
```

---

## 7. Contao Vocabulary

| Term | Action |
|------|--------|
| **DCA** | Data schema + admin form. Never hardcode SQL. |
| **RockSolid Element** | Custom block in page editor. Create via PHP classes + templates. |
| **Template Materialization** | Override bundle template by copying to `templates/` with same name. |
| **Migration** | Doctrine DB alter. User runs. You flag what needs changing. |
| **Frontend Module** | Dynamic content block. Templates in `templates/modules/`. |
| **Custom Element** | New RockSolid block. Create in `src/Elements/CustomElement.php` + template. |

---

## 8. DO / DON'T

### ✅ DO
- Edit only SCSS/JS/templates as specified above
- Suggest new RockSolid element classes (user implements in PHP)
- Flag missing migrations ("Need: ALTER TABLE posts ADD COLUMN...")
- Use Contao\Model::findBy() patterns when discussing data access
- Reference template overrides with full path: `templates/client/block_hero.html5`
- Ask for context on data impacts before suggesting schema changes

### 🚫 DON'T
- Modify PHP files (src/, config/, migrations/)
- Compile SCSS manually
- Suggest `console` commands that modify DB (leave for user)
- Add npm dependencies
- Touch `templates/oneo/`
- Write raw SQL
- Assume database structure—ask

---

## 9. RockSolid Elements Pattern

When creating custom elements:

```scss
// In files/client/scss/client.scss
.element-my-custom {
  // Styles here
}
```

```html5
<!-- In templates/client/rsce_my_custom.html5 -->
<div class="element-my-custom">
  {{content}}
</div>
```

**Config RSCE (PHP):**
```php
// templates/client/rsce_my_custom_config.php
$GLOBALS['TL_RSCE']['my_custom'] = [
    'label' => 'My Custom Element',
    'types' => ['article'],
    'row' => [
        'fields' => [
            'height' => ['type' => 'select', 'options' => ['small', 'medium', 'large']],
        ]
    ]
];
```

**For pure PHP logic:** Flag for user. Example:
> "New element: CustomTestimonial. User: create `src/Elements/CustomTestimonial.php`, then I'll add template (rsce_testimonial.html5) + config + styles."

---

## 10. Header & Logo Responsive Notes

**Header Fixed (Oneo behavior):**
- JS injects `padding-top` inline on `.page-header`
- For transparent header overlay: force `padding-top: 0 !important` in CSS

**Logo Responsive:**
- Verify logo size/readability below 1000px (tablet breakpoint)
- Test in `client.scss` with responsive rules using `@include mediaquery(tablet)`

---

## 11. RSCE & Custom Element Guidelines

- **Configs:** PHP files in `templates/client/rsce_*_config.php`
- **Templates:** HTML5 files in `templates/client/rsce_*.html5`
- **Styles:** Add classes to `client.scss` (not `_custom.scss` unless global impact)
- **Options:** Adjust via config (height, variant, etc.), verify CSS classes exist

---

## 12. Communication Rules

- **Mode:** Direct, snippet-first, zero fluff
- **Before DB changes:** Ask "Who uses this? Any migrations needed?"
- **On conflicts:** Show both options, let user pick
- **Compass watch:** Never assume it's running—mention if compilation needed

---

## 13. Contao Security Checklist

- ✅ Form validation: Use `InputFilter` (Contao) + HTML5 `required`, `pattern`
- ✅ Template escaping: `{{ variable }}` (auto-escaped), `{!! raw !!}` (explicit trust only)
- ✅ No direct `$_GET/$_POST`—use Contao's routing + request object
- ✅ CSRF tokens in forms via `{{ csrf_token }}`

---

## 14. Performance Notes

- Minimize SCSS nesting (max 3 levels)
- Use Bootstrap 5 utility classes first, SCSS as fallback
- No inline JS in templates—use `files/client/js/shared.js`
- Lazy-load images: mark with `loading="lazy"` in templates

---

## 15. Quick Refs

**Contao 5 Docs:** https://docs.contao.org/dev/  
**Local API Docs:** `/home/pouet/docs/api/`  
**Compass:** User manages `compass watch files/client/scss/`
