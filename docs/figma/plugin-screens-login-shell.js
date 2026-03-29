// Zentto ERP — App Screens: Login, Home, Shell Layout
// Paste into: Figma → Plugins → Development → New Plugin → Run once
// Frames start at y=2000 (below investor deck)

(async () => {

  // ─── Helpers ───────────────────────────────────────────────

  function hexToRgb(hex) {
    hex = hex.replace('#', '');
    return {
      r: parseInt(hex.substring(0, 2), 16) / 255,
      g: parseInt(hex.substring(2, 4), 16) / 255,
      b: parseInt(hex.substring(4, 6), 16) / 255
    };
  }

  function getFontStyle(weight) {
    const map = { 400: 'Regular', 500: 'Medium', 600: 'Semi Bold', 700: 'Bold', 800: 'Extra Bold' };
    return map[weight] || 'Regular';
  }

  async function createText(parent, text, x, y, opts = {}) {
    const style = getFontStyle(opts.weight || 400);
    await figma.loadFontAsync({ family: 'Inter', style });
    const t = figma.createText();
    t.fontName = { family: 'Inter', style };
    t.characters = text;
    t.fontSize = opts.size || 16;
    t.fills = [{ type: 'SOLID', color: hexToRgb(opts.color || '#000000') }];
    if (opts.opacity !== undefined) t.opacity = opts.opacity;
    t.x = x;
    t.y = y;
    if (opts.width) {
      t.resize(opts.width, t.height);
      t.textAutoResize = 'HEIGHT';
    }
    if (opts.align) t.textAlignHorizontal = opts.align;
    if (opts.letterSpacing) t.letterSpacing = { value: opts.letterSpacing, unit: 'PIXELS' };
    if (opts.name) t.name = opts.name;
    parent.appendChild(t);
    return t;
  }

  function createRect(parent, x, y, w, h, opts = {}) {
    const r = figma.createRectangle();
    r.x = x;
    r.y = y;
    r.resize(w, h);
    if (opts.fill) {
      const c = hexToRgb(opts.fill);
      const fillObj = { type: 'SOLID', color: c };
      if (opts.fillOpacity !== undefined) fillObj.opacity = opts.fillOpacity;
      r.fills = [fillObj];
    } else {
      r.fills = [];
    }
    if (opts.cornerRadius !== undefined) r.cornerRadius = opts.cornerRadius;
    if (opts.stroke) {
      r.strokes = [{ type: 'SOLID', color: hexToRgb(opts.stroke) }];
      r.strokeWeight = opts.strokeWeight || 1;
    }
    if (opts.opacity !== undefined) r.opacity = opts.opacity;
    if (opts.name) r.name = opts.name;
    parent.appendChild(r);
    return r;
  }

  function createCircle(parent, x, y, size, opts = {}) {
    const e = figma.createEllipse();
    e.x = x;
    e.y = y;
    e.resize(size, size);
    if (opts.fill) {
      const fillObj = { type: 'SOLID', color: hexToRgb(opts.fill) };
      if (opts.fillOpacity !== undefined) fillObj.opacity = opts.fillOpacity;
      e.fills = [fillObj];
    } else {
      e.fills = [];
    }
    if (opts.opacity !== undefined) e.opacity = opts.opacity;
    if (opts.name) e.name = opts.name;
    parent.appendChild(e);
    return e;
  }

  function makeScreen(index, name) {
    const f = figma.createFrame();
    f.name = name;
    f.resize(1440, 900);
    f.x = index * 1540;
    f.y = 2000;
    f.clipsContent = true;
    return f;
  }

  // Preload all fonts
  await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Medium' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Bold' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Extra Bold' });


  // ═══════════════════════════════════════════════════════════
  // SCREEN 1 — LOGIN PAGE
  // ═══════════════════════════════════════════════════════════
  {
    const screen = makeScreen(0, 'Screen — Login');
    // Background
    createRect(screen, 0, 0, 1440, 900, { fill: '#eaeded', name: 'bg' });

    // Animated gradient ellipses
    createCircle(screen, -200, -100, 800, { fill: '#d2f1df', fillOpacity: 0.3, name: 'gradient-green' });
    createCircle(screen, 900, 400, 600, { fill: '#d3d7fa', fillOpacity: 0.3, name: 'gradient-purple' });
    createCircle(screen, 400, 500, 700, { fill: '#bad8f4', fillOpacity: 0.3, name: 'gradient-blue' });

    // Card shadow
    createRect(screen, 474, 124, 500, 660, { fill: '#000000', fillOpacity: 0.1, cornerRadius: 16, name: 'card-shadow' });

    // Login card
    const cardX = 470;
    const cardY = 120;
    createRect(screen, cardX, cardY, 500, 660, { fill: '#ffffff', cornerRadius: 16, stroke: '#e3e6e6', name: 'login-card' });

    // 1. Logo section
    // Orange circle
    createCircle(screen, cardX + 222, cardY + 30, 56, { fill: '#ff9900', name: 'logo-circle' });
    // "Z" in circle
    await createText(screen, 'Z', cardX + 222, cardY + 30, { weight: 800, size: 24, color: '#ffffff', width: 56, align: 'CENTER', name: 'logo-z' });

    // "ZENTTO" text
    await createText(screen, 'ZENTTO', cardX, cardY + 100, { weight: 800, size: 20, color: '#0f1111', width: 500, align: 'CENTER', letterSpacing: 4, name: 'logo-text' });

    // Subtitle
    await createText(screen, 'Sistema de Administración', cardX, cardY + 128, { weight: 500, size: 14, color: '#565959', width: 500, align: 'CENTER', name: 'logo-subtitle' });

    // 2. Credentials text
    await createText(screen, 'Ingresa tus credenciales', cardX, cardY + 170, { weight: 400, size: 16, color: '#565959', width: 500, align: 'CENTER', name: 'credentials-text' });

    // 3. Form fields
    // Usuario
    await createText(screen, 'Usuario', cardX + 40, cardY + 210, { weight: 600, size: 14, color: '#0f1111', name: 'label-usuario' });
    createRect(screen, cardX + 40, cardY + 232, 420, 44, { fill: '#ffffff', stroke: '#e3e6e6', cornerRadius: 8, name: 'input-usuario' });
    await createText(screen, 'Ingresa tu usuario', cardX + 52, cardY + 244, { weight: 400, size: 14, color: '#9CA3AF', name: 'placeholder-usuario' });

    // Empresa / Sucursal
    await createText(screen, 'Empresa / Sucursal', cardX + 40, cardY + 294, { weight: 600, size: 14, color: '#0f1111', name: 'label-empresa' });
    createRect(screen, cardX + 40, cardY + 316, 420, 44, { fill: '#ffffff', stroke: '#e3e6e6', cornerRadius: 8, name: 'select-empresa' });
    await createText(screen, '001 - Zentto Demo / 001 - Principal', cardX + 52, cardY + 328, { weight: 400, size: 14, color: '#0f1111', name: 'value-empresa' });
    // Dropdown arrow (triangle approximation)
    createRect(screen, cardX + 436, cardY + 332, 10, 10, { fill: '#565959', name: 'dropdown-arrow' });

    // Contraseña
    await createText(screen, 'Contraseña', cardX + 40, cardY + 378, { weight: 600, size: 14, color: '#0f1111', name: 'label-password' });
    createRect(screen, cardX + 40, cardY + 400, 420, 44, { fill: '#ffffff', stroke: '#e3e6e6', cornerRadius: 8, name: 'input-password' });
    await createText(screen, '••••••••', cardX + 52, cardY + 412, { weight: 400, size: 14, color: '#0f1111', name: 'value-password' });
    // Eye icon
    createCircle(screen, cardX + 440, cardY + 414, 8, { fill: '#565959', name: 'eye-icon-circle' });
    createRect(screen, cardX + 436, cardY + 418, 16, 2, { fill: '#565959', name: 'eye-icon-line' });

    // 4. Remember device checkbox
    createRect(screen, cardX + 40, cardY + 460, 18, 18, { fill: '#ff9900', stroke: '#e3e6e6', cornerRadius: 3, name: 'checkbox' });
    // Checkmark (small white lines)
    createRect(screen, cardX + 44, cardY + 470, 4, 2, { fill: '#ffffff', name: 'check-1' });
    createRect(screen, cardX + 47, cardY + 467, 2, 7, { fill: '#ffffff', name: 'check-2' });
    await createText(screen, 'Recordar este dispositivo', cardX + 66, cardY + 462, { weight: 400, size: 14, color: '#565959', name: 'remember-text' });

    // 5. Forgot password link
    await createText(screen, 'Olvidé mi contraseña', cardX + 280, cardY + 462, { weight: 400, size: 14, color: '#007185', name: 'forgot-link' });

    // 6. Turnstile placeholder
    createRect(screen, cardX + 40, cardY + 500, 420, 50, { fill: '#f8f8f8', stroke: '#e3e6e6', cornerRadius: 8, name: 'turnstile-box' });
    // Cloudflare icon placeholder
    createRect(screen, cardX + 48, cardY + 512, 24, 24, { fill: '#f48120', cornerRadius: 4, name: 'cf-icon' });
    await createText(screen, '✓ Verificación completada', cardX + 80, cardY + 514, { weight: 400, size: 14, color: '#067D62', name: 'turnstile-text' });

    // 7. Submit button
    createRect(screen, cardX + 40, cardY + 568, 420, 48, { fill: '#ff9900', cornerRadius: 24, name: 'submit-btn' });
    await createText(screen, 'Iniciar Sesión', cardX + 40, cardY + 582, { weight: 600, size: 16, color: '#ffffff', width: 420, align: 'CENTER', name: 'submit-text' });

    // 8. Bottom links
    await createText(screen, '¿No tienes cuenta?', cardX + 40, cardY + 630, { weight: 400, size: 14, color: '#565959', name: 'no-account-text' });
    await createText(screen, 'Registrarme', cardX + 190, cardY + 630, { weight: 600, size: 14, color: '#007185', name: 'register-link' });

    await createText(screen, '¿Necesitas recuperar acceso?', cardX + 40, cardY + 652, { weight: 400, size: 14, color: '#565959', name: 'recover-text' });
    await createText(screen, 'Recuperar contraseña', cardX + 260, cardY + 652, { weight: 600, size: 14, color: '#007185', name: 'recover-link' });
  }


  // ═══════════════════════════════════════════════════════════
  // SCREEN 2 — HOME / APP SELECTOR
  // ═══════════════════════════════════════════════════════════
  {
    const screen = makeScreen(1, 'Screen — Home / App Selector');
    createRect(screen, 0, 0, 1440, 900, { fill: '#eaeded', name: 'bg' });

    // ── Sidebar collapsed (72×900) ──
    createRect(screen, 0, 0, 72, 900, { fill: '#131921', name: 'sidebar' });

    // Logo circle
    createCircle(screen, 16, 16, 40, { fill: '#ff9900', name: 'sidebar-logo' });
    await createText(screen, 'Z', 16, 24, { weight: 700, size: 18, color: '#ffffff', width: 40, align: 'CENTER', name: 'sidebar-logo-z' });

    // Hamburger icon (3 lines)
    createRect(screen, 24, 72, 24, 2, { fill: '#ffffff', fillOpacity: 0.7, name: 'hamburger-1' });
    createRect(screen, 24, 80, 24, 2, { fill: '#ffffff', fillOpacity: 0.7, name: 'hamburger-2' });
    createRect(screen, 24, 88, 24, 2, { fill: '#ffffff', fillOpacity: 0.7, name: 'hamburger-3' });

    // Nav icon placeholders
    const navIconYs = [140, 188, 236, 284, 332, 380];
    for (let i = 0; i < navIconYs.length; i++) {
      const isActive = i === 0;
      createRect(screen, 24, navIconYs[i], 24, 24, {
        fill: '#ffffff',
        fillOpacity: isActive ? 1.0 : 0.3,
        cornerRadius: 4,
        name: `nav-icon-${i}`
      });
      if (isActive) {
        createRect(screen, 0, navIconYs[i] - 8, 4, 40, { fill: '#ff9900', name: 'active-indicator' });
      }
    }

    // Bottom avatar
    createCircle(screen, 16, 840, 40, { fill: '#eaeded', name: 'avatar' });
    await createText(screen, 'RG', 16, 852, { weight: 700, size: 14, color: '#565959', width: 40, align: 'CENTER', name: 'avatar-initials' });

    // ── Header (x=72, 1368×64) ──
    createRect(screen, 72, 0, 1368, 64, { fill: '#131921', name: 'header' });
    // Header bottom border
    createRect(screen, 72, 63, 1368, 1, { fill: '#ffffff', fillOpacity: 0.08, name: 'header-border' });

    // Breadcrumb
    await createText(screen, 'Home', 92, 22, { weight: 500, size: 14, color: '#ff9900', name: 'breadcrumb' });

    // Company chip
    createRect(screen, 172, 16, 220, 32, { fill: '#ff9900', cornerRadius: 16, name: 'company-chip' });
    await createText(screen, '001/001 - Zentto Demo', 184, 22, { weight: 600, size: 13, color: '#131921', name: 'company-chip-text' });

    // DB chip
    createRect(screen, 412, 16, 120, 32, { fill: '#ffffff', fillOpacity: 0.12, cornerRadius: 16, name: 'db-chip' });
    await createText(screen, 'BD: zentto_demo', 424, 22, { weight: 400, size: 13, color: '#ffffff', opacity: 0.85, name: 'db-chip-text' });

    // Right side icon circles
    const iconXs = [1272, 1312, 1352, 1392];
    for (let i = 0; i < iconXs.length; i++) {
      createCircle(screen, iconXs[i], 18, 28, { fill: '#ffffff', fillOpacity: 0.05, name: `header-icon-${i}` });
      createRect(screen, iconXs[i] + 4, 22, 20, 20, { fill: '#ffffff', fillOpacity: 0.3, cornerRadius: 4, name: `header-icon-inner-${i}` });
    }
    // Notification badge on 3rd icon (bell)
    createCircle(screen, 1372, 18, 8, { fill: '#cc0c39', name: 'notif-badge' });

    // ── Content Area (x=72, y=64, 1368×836) ──
    createRect(screen, 72, 64, 1368, 836, { fill: '#eaeded', name: 'content-bg' });

    // Title
    await createText(screen, 'Módulos', 112, 94, { weight: 700, size: 28, color: '#0f1111', name: 'title' });

    // Admin banner
    createRect(screen, 112, 139, 1288, 36, { fill: '#eff6ff', stroke: '#bfdbfe', cornerRadius: 8, name: 'admin-banner' });
    await createText(screen, 'Modo administrador activo', 128, 149, { weight: 600, size: 13, color: '#1e40af', name: 'admin-banner-text' });

    // App grid
    const modules = [
      // Row 1
      [
        { name: 'Contabilidad', color: '#875A7B', letter: 'C' },
        { name: 'Nómina', color: '#00A09D', letter: 'N' },
        { name: 'Bancos', color: '#E67E22', letter: 'B' },
        { name: 'Inventario', color: '#27AE60', letter: 'I' }
      ],
      // Row 2
      [
        { name: 'Ventas', color: '#3498DB', letter: 'V' },
        { name: 'Compras', color: '#F39C12', letter: 'C' },
        { name: 'POS', color: '#9B59B6', letter: 'P' },
        { name: 'Restaurante', color: '#E84393', letter: 'R' }
      ],
      // Row 3
      [
        { name: 'E-Commerce', color: '#0984E3', letter: 'E' },
        { name: 'Auditoría', color: '#2D3436', letter: 'A' },
        { name: 'CRM', color: '#E74C3C', letter: 'C' },
        { name: 'Ajustes', color: '#7F8C8D', letter: 'A' }
      ]
    ];

    const gridStartX = 112;
    const gridStartY = 194;
    const cardW = 300;
    const cardH = 120;
    const gap = 24;

    for (let row = 0; row < modules.length; row++) {
      for (let col = 0; col < modules[row].length; col++) {
        const mod = modules[row][col];
        const cx = gridStartX + col * (cardW + gap);
        const cy = gridStartY + row * (cardH + gap);

        // Card bg
        createRect(screen, cx, cy, cardW, cardH, { fill: '#ffffff', stroke: '#e3e6e6', cornerRadius: 12, name: `card-${mod.name}` });

        // Colored circle
        createCircle(screen, cx + 120, cy + 16, 60, { fill: mod.color, name: `circle-${mod.name}` });

        // Letter in circle
        await createText(screen, mod.letter, cx + 120, cy + 30, { weight: 700, size: 24, color: '#ffffff', width: 60, align: 'CENTER', name: `letter-${mod.name}` });

        // Module name
        await createText(screen, mod.name, cx, cy + 88, { weight: 600, size: 14, color: '#0f1111', width: cardW, align: 'CENTER', name: `name-${mod.name}` });
      }
    }

    // Copyright
    await createText(screen, '© Zentto 2026', 72, 854, { weight: 400, size: 12, color: '#565959', width: 1368, align: 'CENTER', name: 'copyright' });
  }


  // ═══════════════════════════════════════════════════════════
  // SCREEN 3 — SHELL LAYOUT (SIDEBAR EXPANDED)
  // ═══════════════════════════════════════════════════════════
  {
    const screen = makeScreen(2, 'Screen — Shell Layout (Sidebar Expanded)');
    createRect(screen, 0, 0, 1440, 900, { fill: '#eaeded', name: 'bg' });

    // ── Sidebar expanded (260×900) ──
    createRect(screen, 0, 0, 260, 900, { fill: '#131921', name: 'sidebar-expanded' });

    // Header area
    // Hamburger icon
    createRect(screen, 20, 22, 20, 2, { fill: '#ffffff', fillOpacity: 0.7, name: 'hamburger-1' });
    createRect(screen, 20, 28, 20, 2, { fill: '#ffffff', fillOpacity: 0.7, name: 'hamburger-2' });
    createRect(screen, 20, 34, 20, 2, { fill: '#ffffff', fillOpacity: 0.7, name: 'hamburger-3' });

    // Logo circle
    createCircle(screen, 56, 14, 36, { fill: '#ff9900', name: 'sidebar-logo' });
    await createText(screen, 'Z', 56, 22, { weight: 700, size: 16, color: '#ffffff', width: 36, align: 'CENTER', name: 'sidebar-logo-z' });

    // ZENTTO text
    await createText(screen, 'ZENTTO', 100, 14, { weight: 800, size: 14, color: '#ffffff', name: 'sidebar-title' });
    await createText(screen, 'Sistema Administrador', 100, 34, { weight: 400, size: 11, color: '#ffffff', opacity: 0.5, name: 'sidebar-subtitle' });

    // Divider
    createRect(screen, 16, 64, 228, 1, { fill: '#ffffff', fillOpacity: 0.1, name: 'divider-1' });

    // Nav items
    const navItems = [
      { type: 'header', label: 'ZENTTO', y: 80 },
      { type: 'item', label: 'Dashboard', y: 100, active: true },
      { type: 'divider', y: 148 },
      { type: 'header', label: 'MÓDULOS', y: 160 },
      { type: 'item', label: 'Contabilidad', y: 180 },
      { type: 'item', label: 'Nómina', y: 224 },
      { type: 'item', label: 'Bancos', y: 268 },
      { type: 'item', label: 'Inventario', y: 312 },
      { type: 'item', label: 'Ventas', y: 356 },
      { type: 'item', label: 'Compras', y: 400 },
      { type: 'item', label: 'POS', y: 444 },
      { type: 'divider', y: 492 },
      { type: 'header', label: 'RECURSOS', y: 500 },
      { type: 'item', label: 'Reportes', y: 520 },
      { type: 'item', label: 'Configuración', y: 564 }
    ];

    for (const item of navItems) {
      if (item.type === 'header') {
        await createText(screen, item.label, 20, item.y, { weight: 400, size: 11, color: '#ffffff', opacity: 0.4, name: `nav-header-${item.label}` });
      } else if (item.type === 'divider') {
        createRect(screen, 16, item.y, 228, 1, { fill: '#ffffff', fillOpacity: 0.1, name: `nav-divider-${item.y}` });
      } else if (item.type === 'item') {
        if (item.active) {
          // Active background
          createRect(screen, 16, item.y, 228, 44, { fill: '#ff9900', fillOpacity: 0.15, cornerRadius: 8, name: `nav-active-bg` });
          // Left border
          createRect(screen, 0, item.y, 4, 44, { fill: '#ff9900', name: 'nav-active-border' });
        }
        // Icon placeholder
        createRect(screen, 36, item.y + 12, 20, 20, { fill: '#ffffff', fillOpacity: item.active ? 0.9 : 0.3, cornerRadius: 4, name: `nav-icon-${item.label}` });
        // Label
        await createText(screen, item.label, 68, item.y + 13, {
          weight: item.active ? 600 : 400,
          size: 14,
          color: '#ffffff',
          opacity: item.active ? 1.0 : 0.7,
          name: `nav-label-${item.label}`
        });
      }
    }

    // Footer: user section
    createCircle(screen, 16, 840, 40, { fill: '#eaeded', name: 'sidebar-avatar' });
    await createText(screen, 'RG', 16, 852, { weight: 700, size: 14, color: '#565959', width: 40, align: 'CENTER', name: 'sidebar-avatar-initials' });
    await createText(screen, 'Raúl González', 66, 840, { weight: 600, size: 14, color: '#ffffff', name: 'sidebar-user-name' });
    await createText(screen, 'Administrador', 66, 860, { weight: 400, size: 12, color: '#ffffff', opacity: 0.5, name: 'sidebar-user-role' });

    // ── Header (x=260, 1180×64) ──
    createRect(screen, 260, 0, 1180, 64, { fill: '#131921', name: 'header' });
    createRect(screen, 260, 63, 1180, 1, { fill: '#ffffff', fillOpacity: 0.08, name: 'header-border' });

    // Breadcrumb
    await createText(screen, 'Home', 280, 22, { weight: 500, size: 14, color: '#ff9900', name: 'breadcrumb' });

    // Company chip
    createRect(screen, 360, 16, 220, 32, { fill: '#ff9900', cornerRadius: 16, name: 'company-chip' });
    await createText(screen, '001/001 - Zentto Demo', 372, 22, { weight: 600, size: 13, color: '#131921', name: 'company-chip-text' });

    // DB chip
    createRect(screen, 600, 16, 120, 32, { fill: '#ffffff', fillOpacity: 0.12, cornerRadius: 16, name: 'db-chip' });
    await createText(screen, 'BD: zentto_demo', 612, 22, { weight: 400, size: 13, color: '#ffffff', opacity: 0.85, name: 'db-chip-text' });

    // Right side icons
    const headerIconXs = [1284, 1324, 1364, 1404];
    for (let i = 0; i < headerIconXs.length; i++) {
      createCircle(screen, headerIconXs[i], 18, 28, { fill: '#ffffff', fillOpacity: 0.05, name: `header-icon-${i}` });
      createRect(screen, headerIconXs[i] + 4, 22, 20, 20, { fill: '#ffffff', fillOpacity: 0.3, cornerRadius: 4, name: `header-icon-inner-${i}` });
    }
    createCircle(screen, 1384, 18, 8, { fill: '#cc0c39', name: 'notif-badge' });

    // ── Content Area (x=260, y=64, 1180×836) ──
    createRect(screen, 260, 64, 1180, 836, { fill: '#eaeded', name: 'content-bg' });

    // Dashboard title
    await createText(screen, 'Dashboard', 300, 94, { weight: 700, size: 28, color: '#0f1111', name: 'title' });

    // 4 stat cards
    const stats = [
      { label: 'Ventas Hoy', value: '$1,234.56', color: '#ff9900' },
      { label: 'Facturas', value: '47', color: '#007185' },
      { label: 'Clientes', value: '312', color: '#067D62' },
      { label: 'Productos', value: '1,845', color: '#232f3e' }
    ];

    const statCardW = 260;
    const statGap = 20;
    const statStartX = 300;
    const statStartY = 144;

    for (let i = 0; i < stats.length; i++) {
      const sx = statStartX + i * (statCardW + statGap);
      const stat = stats[i];

      // Card
      createRect(screen, sx, statStartY, statCardW, 100, { fill: '#ffffff', stroke: '#e3e6e6', cornerRadius: 12, name: `stat-card-${stat.label}` });

      // Label
      await createText(screen, stat.label, sx + 20, statStartY + 16, { weight: 400, size: 14, color: '#565959', name: `stat-label-${stat.label}` });

      // Value
      await createText(screen, stat.value, sx + 20, statStartY + 44, { weight: 800, size: 28, color: stat.color, name: `stat-value-${stat.label}` });
    }
  }

  figma.closePlugin();
})();
