# Investigacion: Temas WordPress y Patrones CSS para Landing/Blog/SaaS

> Referencia para el sistema de landing pages, blog y templates de Zentto Studio.
> Recopilado 2026-04-01 desde repositorios publicos GitHub + web.

---

## Indice

1. [Temas Landing Page (15)](#1-temas-landing-page)
2. [Temas Blog (15)](#2-temas-blog)
3. [Temas SaaS / Business / Agency (15)](#3-temas-saas--business--agency)
4. [Design Tokens y CSS Custom Properties](#4-design-tokens-y-css-custom-properties)
5. [Patrones CSS por Seccion](#5-patrones-css-por-seccion)
6. [Repos Clave y Colecciones](#6-repos-clave-y-colecciones)
7. [Resumen: Mejores por Caso de Uso](#7-resumen-mejores-por-caso-de-uso)

---

## 1. Temas Landing Page

### Con repo GitHub

| # | Tema | GitHub | Secciones | CSS | Stars |
|---|------|--------|-----------|-----|-------|
| 1 | **OnePress** | [FameThemes/onepress](https://github.com/FameThemes/onepress) | Hero, Services, Stats, Team, Portfolio (Isotope), Blog, Contact | Bootstrap + WOW.js + Flexbox | 20K+ installs |
| 2 | **Shapely** | [ColorlibHQ/shapely](https://github.com/ColorlibHQ/shapely) | Hero parallax, Portfolio, Testimonials, CTA | Bootstrap + SCSS + parallax | 66 stars |
| 3 | **Neve** | [Codeinwp/neve](https://github.com/Codeinwp/neve) | Starter sites completos, Header/Footer builder | CSS Grid + Flexbox + Custom Properties | 100K+ installs |
| 4 | **Air Light** | [digitoimistodude/air-light](https://github.com/digitoimistodude/air-light) | Starter puro (<20KB total) | SCSS modular + sanitize.css | 950+ stars |
| 5 | **Unapp** | [ColorlibHQ/unapp](https://github.com/ColorlibHQ/unapp) | Hero app mockup, Features, Screenshots, Download | Bootstrap mobile-first | — |
| 6 | **Sierra** | [ColorlibHQ/sierra](https://github.com/ColorlibHQ/sierra) | Hero startup, Services, About, Blog | CSS3 custom responsive | — |
| 7 | **Onepager** | [themexpert/onepager](https://github.com/themexpert/onepager) | 7+ Feature blocks, Testimonials, CTA, Maps, WooCommerce | Less + UIKit | — |

### Sin repo (WordPress.org / comerciales gratuitos)

| # | Tema | Secciones | CSS | Notas |
|---|------|-----------|-----|-------|
| 8 | **Astra** | 20+ templates landing, Hero, Pricing, Testimonials | Hook system + CSS modular (<50KB) | 8M+ installs, el mas popular |
| 9 | **GeneratePress** | Via starter sites | CSS ultra-ligero (<10KB) + Custom Properties | Rendimiento maximo |
| 10 | **Blocksy** | Starter sites modernos, 5 layouts | Design tokens CSS + Custom Properties (50-70KB gz) | 6.5M+ descargas |
| 11 | **Kadence** | Header/Footer builder, Starter templates | CSS Grid + Flexbox + Custom Properties | Gutenberg-first |
| 12 | **Catch Fullscreen** | Hero fullscreen, Slider, Portfolio, Testimonials | CSS3 transitions + Flexbox | One-page visual |
| 13 | **One Page Express** | Hero, Services, Pricing, Team, Contact | CSS3 + Flexbox + animaciones | Editor visual integrado |
| 14 | **Blossom Coach** | Hero, Services, Testimonials, CTA, Newsletter | CSS3 + Flexbox | Coaching/freelance |
| 15 | **Twenty Twenty-Three** | Block editor patterns, FSE completo | Custom Properties + Grid + clamp() | Tema oficial WP |

---

## 2. Temas Blog

### Con repo GitHub

| # | Tema | GitHub | Layout | Tipografia | Post Card |
|---|------|--------|--------|------------|-----------|
| 1 | **Underscores (_s)** | [Automattic/_s](https://github.com/Automattic/_s) | Lista vertical clasica | System fonts | Titulo + meta + contenido |
| 2 | **Sage** | [roots/sage](https://github.com/roots/sage) | Flexible (Blade templates) | Tailwind CSS responsive | Blade partials custom |
| 3 | **Understrap** | [understrap/understrap](https://github.com/understrap/understrap) | Grid Bootstrap configurable | Bootstrap 5 + Google Fonts | Thumbnail + meta + extracto |
| 4 | **Timber** | [timber/timber](https://github.com/timber/timber) | Framework Twig | Independiente | `{{ post.thumbnail }}` + `{{ post.preview }}` |
| 5 | **Air-Light** | [digitoimistodude/air-light](https://github.com/digitoimistodude/air-light) | Lista minimal, zero-sidebar | System fonts (<20KB) | Titulo + meta + extracto |
| 6 | **Philosophy** | [ColorlibHQ/philosophy](https://github.com/ColorlibHQ/philosophy) | **Masonry grid** Pinterest-style | Serif body + sans headings | Image overlay + categoria badge |
| 7 | **Stuff** | [ColorlibHQ/stuff](https://github.com/ColorlibHQ/stuff) | Lista simple | Clean sans-serif | Imagen + titulo + extracto |
| 8 | **Sparkling** | [ColorlibHQ/Sparkling](https://github.com/ColorlibHQ/Sparkling) | Lista + sidebar Bootstrap 3 | Google Fonts configurable | Featured image + meta + "Read more" |
| 9 | **CleanBlog** | [deviodigital/cleanblog](https://github.com/deviodigital/cleanblog) | Lista full-width sin sidebar | Serif para lectura larga | Titulo grande + subtitulo + meta |
| 10 | **Neve** | [Codeinwp/neve](https://github.com/Codeinwp/neve) | Grid/Lista toggle, mobile-first | Google + system fonts responsive | Configurable via Customizer |

### Sin repo

| # | Tema | Layout | CSS | Notas |
|---|------|--------|-----|-------|
| 11 | **Astra** | Grid/Lista/Masonry | Dynamic CSS inline (<50KB) | 8M+ installs |
| 12 | **Blocksy** | 5 layouts (Simple, Classic, Grid, Gutenberg, Cover) | Design tokens CSS Custom Properties | Infinite Scroll disponible |
| 13 | **GeneratePress** | Lista + sidebar | Minimal CSS (<10KB) + Custom Properties | Codigo mas limpio |
| 14 | **Flavor Starter** | Grid FSE | theme.json + Custom Properties | 30+ block patterns |
| 15 | **MH Magazine** | Magazine + featured slider + grid | Bootstrap responsive editorial | Review sites, multi-autor |

---

## 3. Temas SaaS / Business / Agency

| # | Tema | GitHub | Tipo | Secciones Clave | CSS Approach |
|---|------|--------|------|-----------------|-------------|
| 1 | **Sage** | [roots/sage](https://github.com/roots/sage) | Starter | Custom (Blade + Tailwind) | Tailwind + Vite |
| 2 | **Flynt** | [flyntwp/flynt](https://github.com/flyntwp/flynt) | Component-based | **Ya usa web components** con custom elements | SCSS por componente |
| 3 | **Neve** | [Codeinwp/neve](https://github.com/Codeinwp/neve) | Multi-proposito | Hero, Features, WooCommerce | CSS Custom Properties + PostCSS |
| 4 | **OceanWP** | [oceanwp/oceanwp](https://github.com/oceanwp/oceanwp) | Multi-proposito | 200+ templates pre-construidos | SCSS + CSS vanilla + Webpack |
| 5 | **Hestia** | GitHub disponible | Material Design | Hero video, Pricing, Portfolio, Team, Testimonials | Material Design CSS + parallax |
| 6 | **Shapely** | [ColorlibHQ/shapely](https://github.com/ColorlibHQ/shapely) | Business | Portfolio, Testimonials, Parallax, CTA | Bootstrap + SCSS |
| 7 | **SaasLauncher** | WordPress.org | SaaS FSE | 70+ secciones, 50+ starter templates | theme.json design tokens |
| 8 | **Blocksy** | Parcial en GitHub | Multi-proposito | Design tokens como nucleo | CSS Custom Properties + Webpack |
| 9 | **SaasStellar** | [stormynight9/saasstellar](https://github.com/stormynight9/saasstellar) | SaaS | **11 temas configurables**, Hero, Pricing, FAQ | Tailwind + shadcn/ui (Remix) |
| 10 | **Awesome Landing Pages** | [PaulleDemon/awesome-landing-pages](https://github.com/PaulleDemon/awesome-landing-pages) | Coleccion | 15+ templates (Finance, AI SaaS, Restaurant, Portfolio) | Tailwind puro, HTML/CSS/JS |
| 11 | **SaaS Landing Page** | [mohitchandel/saas-landing-page](https://github.com/mohitchandel/saas-landing-page) | SaaS | Hero, Features, Pricing, Testimonials, FAQ | Tailwind + DaisyUI + Framer Motion |
| 12 | **GavickPro Portfolio** | [GavickPro/Portfolio-Free-WordPress-Theme](https://github.com/GavickPro/Portfolio-Free-WordPress-Theme) | Portfolio | Grid filtrable, hover effects configurables | Responsive custom + Font Awesome |
| 13 | **Sydney** | WordPress.org | Corporate | Full-screen slider, Services, Team, Testimonials | PHP + JS + CSS responsive |
| 14 | **Gesso WP** | [forumone/gesso-wp](https://github.com/forumone/gesso-wp) | Developer | **CSS vars desde theme.json**, block patterns | SCSS + Webpack + design tokens |
| 15 | **Automattic Themes** | [Automattic/themes](https://github.com/Automattic/themes) | Coleccion | 327+ temas block-based | CSS + SCSS + theme.json |

---

## 4. Design Tokens y CSS Custom Properties

### Sistema completo de tokens (base 0.25rem)

```css
:root {
    /* ============ BASE ============ */
    --base-unit: 0.25rem;

    /* ============ COLORES PRIMITIVOS ============ */
    --color-blue-400: #3498db;
    --color-blue-500: #2980b9;
    --color-blue-600: #2471a3;
    --color-green-500: #2ecc71;
    --color-red-500: #e74c3c;
    --color-gray-1: #FFFFFF;
    --color-gray-2: #EEEEEE;
    --color-gray-3: #D5D5D5;
    --color-gray-4: #BBBBBB;
    --color-gray-5: #A1A1A1;
    --color-gray-6: #888888;
    --color-gray-7: #6F6F6F;
    --color-gray-8: #555555;
    --color-gray-9: #3C3C3C;
    --color-gray-10: #222222;

    /* ============ COLORES SEMANTICOS ============ */
    --color-primary: var(--color-blue-500);
    --color-primary-hover: var(--color-blue-400);
    --color-primary-active: var(--color-blue-600);
    --color-secondary: var(--color-green-500);
    --color-danger: var(--color-red-500);
    --color-foreground: var(--color-gray-10);
    --color-background: var(--color-gray-1);
    --color-muted: var(--color-gray-6);
    --color-border: var(--color-gray-3);
    --color-surface: var(--color-gray-2);

    /* ============ TIPOGRAFIA ============ */
    --font-family-base: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    --font-family-heading: 'Helvetica Neue', Helvetica, Arial, sans-serif;
    --font-family-mono: 'Fira Code', 'Consolas', monospace;

    --font-size-xs:   calc(var(--base-unit) * 3);    /* 12px */
    --font-size-sm:   calc(var(--base-unit) * 3.5);  /* 14px */
    --font-size-base: calc(var(--base-unit) * 4);    /* 16px */
    --font-size-lg:   calc(var(--base-unit) * 5);    /* 20px */
    --font-size-xl:   calc(var(--base-unit) * 6);    /* 24px */
    --font-size-2xl:  calc(var(--base-unit) * 8);    /* 32px */
    --font-size-3xl:  calc(var(--base-unit) * 10);   /* 40px */
    --font-size-4xl:  calc(var(--base-unit) * 12);   /* 48px */
    --font-size-5xl:  calc(var(--base-unit) * 16);   /* 64px */

    --font-weight-light: 300;
    --font-weight-normal: 400;
    --font-weight-medium: 500;
    --font-weight-semibold: 600;
    --font-weight-bold: 700;

    --line-height-tight: 1.1;
    --line-height-snug: 1.3;
    --line-height-normal: 1.5;
    --line-height-relaxed: 1.7;

    /* ============ SPACING (escala 4px) ============ */
    --space-1:  calc(var(--base-unit) * 1);   /*  4px */
    --space-2:  calc(var(--base-unit) * 2);   /*  8px */
    --space-3:  calc(var(--base-unit) * 3);   /* 12px */
    --space-4:  calc(var(--base-unit) * 4);   /* 16px */
    --space-5:  calc(var(--base-unit) * 5);   /* 20px */
    --space-6:  calc(var(--base-unit) * 6);   /* 24px */
    --space-8:  calc(var(--base-unit) * 8);   /* 32px */
    --space-10: calc(var(--base-unit) * 10);  /* 40px */
    --space-12: calc(var(--base-unit) * 12);  /* 48px */
    --space-16: calc(var(--base-unit) * 16);  /* 64px */
    --space-20: calc(var(--base-unit) * 20);  /* 80px */
    --space-24: calc(var(--base-unit) * 24);  /* 96px */

    /* ============ BORDER RADIUS ============ */
    --radius-sm:   calc(var(--base-unit) * 1);  /* 4px */
    --radius-md:   calc(var(--base-unit) * 2);  /* 8px */
    --radius-lg:   calc(var(--base-unit) * 3);  /* 12px */
    --radius-xl:   calc(var(--base-unit) * 4);  /* 16px */
    --radius-full: 9999px;

    /* ============ SOMBRAS ============ */
    --shadow-sm:  0 1px 2px rgba(0, 0, 0, 0.05);
    --shadow-md:  0 4px 6px -1px rgba(0, 0, 0, 0.1);
    --shadow-lg:  0 10px 15px -3px rgba(0, 0, 0, 0.1);
    --shadow-xl:  0 20px 25px -5px rgba(0, 0, 0, 0.1);

    /* ============ TRANSICIONES ============ */
    --transition-fast:   0.15s ease;
    --transition-normal: 0.3s ease;
    --transition-slow:   0.5s ease;

    /* ============ BREAKPOINTS (referencia) ============ */
    --bp-sm:  544px;
    --bp-md:  768px;
    --bp-lg:  1012px;
    --bp-xl:  1280px;

    /* ============ CONTENT WIDTHS ============ */
    --content-narrow: 65ch;
    --content-default: 1140px;
    --content-wide: 1400px;

    /* ============ SECTION PADDING ============ */
    --section-padding-y: var(--space-16);
    --section-padding-x: var(--space-4);
}

/* Dark theme */
[data-theme="dark"] {
    --color-foreground: #f5f5f5;
    --color-background: #1a1a1a;
    --color-surface: #2a2a2a;
    --color-border: #444444;
    --color-muted: #999999;
}

/* Responsive token adjustments */
@media (max-width: 768px) {
    :root {
        --section-padding-y: var(--space-10);
    }
}
```

### WordPress theme.json → CSS Variables

```json
{
  "version": 2,
  "settings": {
    "color": {
      "palette": [
        { "slug": "primary", "color": "#007bff" },
        { "slug": "secondary", "color": "#6c757d" },
        { "slug": "accent", "color": "#e83e8c" }
      ]
    },
    "typography": {
      "fontSizes": [
        { "slug": "small", "size": "0.875rem" },
        { "slug": "medium", "size": "1rem" },
        { "slug": "large", "size": "1.25rem" },
        { "slug": "x-large", "size": "2rem" }
      ]
    },
    "custom": {
      "spacing": { "small": "1rem", "medium": "2rem", "large": "3rem" }
    }
  }
}
```

Genera automaticamente:
```css
--wp--preset--color--primary: #007bff;
--wp--preset--font-size--small: 0.875rem;
--wp--custom--spacing--small: 1rem;
```

---

## 5. Patrones CSS por Seccion

### 5.1 Hero Section

#### Enfoque A: Pseudo-element overlay (clasico)
```css
.hero {
    position: relative;
    min-height: calc(300px + 15vw);
    display: flex;
    align-items: center;
    padding: var(--section-padding-y) var(--section-padding-x);
    background-size: cover;
    background-position: center;
}

.hero::before {
    content: '';
    position: absolute;
    inset: 0;
    background: linear-gradient(to top,
        rgba(0,0,0,0.85) 0%,
        rgba(0,0,0,0.4) 50%,
        rgba(0,0,0,0.1) 100%);
}

.hero__content {
    position: relative;
    z-index: 1;
    max-width: var(--content-narrow);
    color: #fff;
}

.hero__headline {
    font-size: clamp(1.35rem, 6vw, 2.15rem);
    line-height: var(--line-height-tight);
}
```

#### Enfoque B: CSS Grid stacking (moderno)
```css
.hero {
    display: grid;
    min-height: calc(300px + 15vw);
}

.hero__image,
.hero__content,
.hero::after {
    grid-area: 1 / -1;
}

.hero__image {
    width: 100%; height: 100%;
    object-fit: cover;
}

.hero::after {
    content: '';
    background: linear-gradient(var(--gradient-dir, to top), #000 35%, transparent);
}

.hero__content {
    z-index: 1;
    align-self: end;
    padding: var(--space-8);
    color: #fff;
}

@media (min-width: 800px) {
    .hero { --gradient-dir: to right; }
}
```

### 5.2 Feature Grid (Icon + Title + Description)

```css
.features {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: var(--space-8);
    padding: var(--section-padding-y) var(--section-padding-x);
    max-width: var(--content-wide);
    margin: 0 auto;
}

.feature-card {
    padding: var(--space-8);
    background: var(--color-background);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    transition: transform var(--transition-normal), box-shadow var(--transition-normal);
}

.feature-card:hover {
    transform: translateY(-4px);
    box-shadow: var(--shadow-lg);
}

.feature-card__icon { width: 48px; height: 48px; color: var(--color-primary); margin-bottom: var(--space-4); }
.feature-card__title { font-size: var(--font-size-lg); font-weight: var(--font-weight-semibold); margin-bottom: var(--space-2); }
.feature-card__desc { color: var(--color-muted); line-height: var(--line-height-normal); }
```

### 5.3 Pricing Table

```css
.pricing {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: var(--space-6);
    padding: var(--section-padding-y) var(--section-padding-x);
    max-width: var(--content-default);
    margin: 0 auto;
    align-items: start;
}

.pricing-card {
    border: 1px solid var(--color-border);
    border-radius: var(--radius-xl);
    padding: var(--space-8);
    text-align: center;
    background: var(--color-background);
    transition: box-shadow var(--transition-normal), transform var(--transition-normal);
}

.pricing-card--featured {
    border-color: var(--color-primary);
    transform: scale(1.05);
    box-shadow: var(--shadow-lg);
}

.pricing-card--featured::before {
    content: 'Popular';
    position: absolute;
    top: 0; left: 50%;
    transform: translate(-50%, -50%);
    background: var(--color-primary);
    color: #fff;
    padding: var(--space-1) var(--space-4);
    border-radius: var(--radius-full);
    font-size: var(--font-size-sm);
    font-weight: var(--font-weight-semibold);
}

.pricing-card__price {
    font-size: var(--font-size-4xl);
    font-weight: var(--font-weight-bold);
    line-height: var(--line-height-tight);
}

.pricing-card__features li {
    padding: var(--space-2) 0;
    border-bottom: 1px solid var(--color-surface);
    display: flex; align-items: center; gap: var(--space-2);
}

.pricing-card__features li::before {
    content: '\2713';
    color: var(--color-secondary);
    font-weight: bold;
}
```

### 5.4 Testimonials

```css
.testimonials {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: var(--space-6);
    padding: var(--section-padding-y) var(--section-padding-x);
    max-width: var(--content-wide);
    margin: 0 auto;
}

.testimonial-card {
    background: var(--color-background);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding: var(--space-8);
    display: flex; flex-direction: column; gap: var(--space-4);
}

.testimonial-card__quote {
    font-style: italic;
    line-height: var(--line-height-relaxed);
    padding-left: var(--space-6);
    position: relative;
}

.testimonial-card__quote::before {
    content: '\201C';
    position: absolute; left: 0; top: -0.25em;
    font-size: var(--font-size-3xl);
    color: var(--color-primary);
}

.testimonial-card__author {
    display: flex; align-items: center; gap: var(--space-3);
    margin-top: auto;
}

.testimonial-card__avatar {
    width: 48px; height: 48px;
    border-radius: var(--radius-full);
    object-fit: cover;
}

/* Variante carousel CSS-only */
.testimonials--carousel {
    display: flex;
    overflow-x: auto;
    scroll-snap-type: x mandatory;
    gap: var(--space-4);
}

.testimonials--carousel .testimonial-card {
    flex: 0 0 min(90vw, 400px);
    scroll-snap-align: start;
}
```

### 5.5 FAQ Accordion

```css
.faq {
    max-width: var(--content-narrow);
    margin: 0 auto;
    padding: var(--section-padding-y) var(--section-padding-x);
}

.faq__item { border-bottom: 1px solid var(--color-border); }

.faq__question {
    width: 100%;
    display: flex; justify-content: space-between; align-items: center;
    padding: var(--space-5) 0;
    background: none; border: none; cursor: pointer;
    font-size: var(--font-size-base);
    font-weight: var(--font-weight-semibold);
    color: var(--color-foreground);
    text-align: left;
}

.faq__question:hover { color: var(--color-primary); }

.faq__question::after {
    content: '\002B';
    font-size: var(--font-size-xl);
    transition: transform var(--transition-normal);
}

.faq__item.active .faq__question::after {
    content: '\2212';
    transform: rotate(180deg);
}

.faq__answer {
    max-height: 0;
    overflow: hidden;
    transition: max-height 0.3s ease-out;
    color: var(--color-muted);
    line-height: var(--line-height-relaxed);
}

.faq__item.active .faq__answer {
    max-height: 500px;
    padding-bottom: var(--space-5);
}
```

### 5.6 Buttons (Primary / Secondary / Outline / Ghost)

```css
.btn {
    display: inline-flex; align-items: center; justify-content: center; gap: var(--space-2);
    padding: var(--space-3) var(--space-6);
    font-size: var(--font-size-base);
    font-weight: var(--font-weight-medium);
    border: 2px solid transparent;
    border-radius: var(--radius-md);
    cursor: pointer; text-decoration: none;
    transition: background-color var(--transition-fast), color var(--transition-fast),
                border-color var(--transition-fast), box-shadow var(--transition-fast),
                transform var(--transition-fast);
}

.btn:focus-visible { outline: 2px solid var(--color-primary); outline-offset: 2px; }
.btn:active { transform: translateY(1px); }

.btn--primary { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }
.btn--primary:hover { background: var(--color-primary-hover); }

.btn--secondary { background: var(--color-surface); color: var(--color-foreground); border-color: var(--color-border); }
.btn--secondary:hover { background: var(--color-border); }

.btn--outline { background: transparent; color: var(--color-primary); border-color: var(--color-primary); }
.btn--outline:hover { background: var(--color-primary); color: #fff; }

.btn--ghost { background: transparent; color: var(--color-primary); }
.btn--ghost:hover { background: rgba(0,0,0,0.05); }

.btn--sm { padding: var(--space-2) var(--space-4); font-size: var(--font-size-sm); }
.btn--lg { padding: var(--space-4) var(--space-8); font-size: var(--font-size-lg); }
```

### 5.7 Footer (Multi-column + Newsletter)

```css
.footer {
    background: var(--color-gray-10);
    color: var(--color-gray-4);
    padding: var(--space-16) var(--section-padding-x) var(--space-8);
}

.footer__grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: var(--space-8);
    max-width: var(--content-wide);
    margin: 0 auto;
}

.footer__heading {
    font-size: var(--font-size-sm);
    font-weight: var(--font-weight-semibold);
    color: var(--color-gray-1);
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin-bottom: var(--space-4);
}

.footer__links a {
    color: var(--color-gray-5);
    text-decoration: none;
    font-size: var(--font-size-sm);
    transition: color var(--transition-fast);
}
.footer__links a:hover { color: var(--color-gray-1); }

.footer__social a {
    display: flex; align-items: center; justify-content: center;
    width: 36px; height: 36px;
    border-radius: var(--radius-full);
    background: var(--color-gray-8);
    color: var(--color-gray-4);
    transition: background var(--transition-fast);
}
.footer__social a:hover { background: var(--color-primary); color: #fff; }

.footer__bottom {
    max-width: var(--content-wide);
    margin: var(--space-8) auto 0;
    padding-top: var(--space-6);
    border-top: 1px solid var(--color-gray-8);
    display: flex; flex-wrap: wrap; justify-content: space-between;
    font-size: var(--font-size-xs);
}
```

### 5.8 Animaciones (Scroll Reveal)

```css
.animate-on-scroll {
    opacity: 0;
    transform: translateY(40px);
    transition: opacity 0.8s ease, transform 0.8s ease;
}

.animate-on-scroll.is-visible {
    opacity: 1;
    transform: none;
}

/* Staggered children */
.animate-on-scroll.is-visible:nth-child(1) { transition-delay: 0.1s; }
.animate-on-scroll.is-visible:nth-child(2) { transition-delay: 0.2s; }
.animate-on-scroll.is-visible:nth-child(3) { transition-delay: 0.3s; }
.animate-on-scroll.is-visible:nth-child(4) { transition-delay: 0.4s; }

/* Variante: desde la izquierda */
.animate-on-scroll--left {
    opacity: 0;
    transform: translateX(-40px);
    transition: opacity 0.8s ease, transform 0.8s ease;
}
.animate-on-scroll--left.is-visible { opacity: 1; transform: none; }

/* Hover lift generico */
.hover-lift {
    transition: transform var(--transition-normal), box-shadow var(--transition-normal);
}
.hover-lift:hover {
    transform: translateY(-4px);
    box-shadow: var(--shadow-lg);
}
```

**JavaScript (IntersectionObserver):**
```javascript
const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) entry.target.classList.add('is-visible');
    });
}, { threshold: 0.1 });

document.querySelectorAll('.animate-on-scroll, .animate-on-scroll--left')
    .forEach(el => observer.observe(el));
```

### 5.9 Breakpoints (Mobile-First)

```css
/* Base: mobile */
@media (min-width: 544px)  { /* Small tablets */ }
@media (min-width: 768px)  { :root { --section-padding-y: var(--space-16); } }
@media (min-width: 1012px) { :root { --section-padding-y: var(--space-20); } }
@media (min-width: 1280px) { /* Large desktop */ }
```

---

## 6. Repos Clave y Colecciones

### Starters WordPress (codigo fuente)
| Repo | Stars | Enfoque |
|------|-------|---------|
| [Automattic/_s](https://github.com/Automattic/_s) | 11K | Starter clasico (inactivo) |
| [roots/sage](https://github.com/roots/sage) | 13K | Tailwind + Blade + Vite |
| [understrap/understrap](https://github.com/understrap/understrap) | 3.4K | Bootstrap 5 + _s |
| [timber/timber](https://github.com/timber/timber) | 5.6K | Framework Twig |
| [digitoimistodude/air-light](https://github.com/digitoimistodude/air-light) | 950 | Ultra-ligero <20KB |
| [flyntwp/flynt](https://github.com/flyntwp/flynt) | 797 | **Web components nativos** |

### Colecciones de Landing Pages (HTML/CSS puro)
| Repo | Stars | Contenido |
|------|-------|-----------|
| [PaulleDemon/awesome-landing-pages](https://github.com/PaulleDemon/awesome-landing-pages) | — | 15+ templates Tailwind (SaaS, Finance, AI, Restaurant) |
| [nordicgiant2/awesome-landing-page](https://github.com/nordicgiant2/awesome-landing-page) | — | Curated list de landing pages |

### Temas multi-proposito (GitHub)
| Repo | Stars | Tipo |
|------|-------|------|
| [Codeinwp/neve](https://github.com/Codeinwp/neve) | — | CSS Custom Properties + mobile-first |
| [oceanwp/oceanwp](https://github.com/oceanwp/oceanwp) | 301 | 200+ templates, SCSS + Webpack |
| [ColorlibHQ](https://github.com/ColorlibHQ) | — | 10+ temas gratuitos (Shapely, Philosophy, Sparkling, Unapp, Sierra, Flavor) |
| [Automattic/themes](https://github.com/Automattic/themes) | 963 | 327+ temas FSE block-based |

### Frameworks CSS / Component Libraries
| Recurso | Tipo | Notas |
|---------|------|-------|
| **HyperUI** | Tailwind components | Hero, pricing, testimonials, features, footers |
| **Flowbite** | Tailwind UI kit | 400+ secciones con dark mode |
| **Meraki UI** | Tailwind components | 200+ componentes responsive |
| **DaisyUI** | Tailwind plugin | Component library con theming |
| **shadcn/ui** | React/Tailwind | Components headless, 11 temas |

---

## 7. Resumen: Mejores por Caso de Uso

### Para nuestro sistema de landing sections (web components Lit)

| Necesidad | Mejor referencia | Por que |
|-----------|-----------------|---------|
| **Sistema de design tokens** | Blocksy + Gesso WP | CSS Custom Properties como nucleo, mapeable a `--zl-*` |
| **Patron web components** | **Flynt** | Ya usa custom elements con `load:on="visible"` |
| **Hero sections** | OnePress + Neve | Patron overlay + grid stacking bien documentado |
| **Pricing tables** | SaasLauncher + SaasStellar | Pricing section como componente aislado |
| **Feature grids** | Awesome Landing Pages | HTML/CSS puro, conversion directa |
| **Blog layouts** | Philosophy (masonry) + Blocksy (5 layouts) | Multiples variantes configurables |
| **Testimonials** | Hestia + SaaS Landing Page | Cards + carousel CSS-only |
| **FAQ accordion** | Patron `<details>/<summary>` | Nativo HTML, sin JS |
| **Animaciones scroll** | IntersectionObserver pattern | Vanilla JS, usado en Air Light + Flynt |
| **Responsive mobile-first** | Neve + Air Light | CSS Grid + clamp() + Custom Properties |
| **Templates SaaS completos** | SaasStellar (11 temas) | shadcn/ui components, 11 variantes de tokens |
| **Templates variados** | Awesome Landing Pages (15+) | Finance, AI, Restaurant, Portfolio, NGO |
| **Conversion directa a WC** | Awesome Landing Pages + SaasStellar | HTML/CSS puro o React componentizado |

### Prioridad de estudio de codigo

1. **[flyntwp/flynt](https://github.com/flyntwp/flynt)** — web components nativos, estudiar patron de componentes
2. **[PaulleDemon/awesome-landing-pages](https://github.com/PaulleDemon/awesome-landing-pages)** — templates HTML/CSS puro, conversion inmediata
3. **[stormynight9/saasstellar](https://github.com/stormynight9/saasstellar)** — 11 temas + shadcn/ui, design tokens
4. **[Codeinwp/neve](https://github.com/Codeinwp/neve)** — CSS Custom Properties + Header/Footer builder
5. **[digitoimistodude/air-light](https://github.com/digitoimistodude/air-light)** — codigo ultra-limpio <20KB
