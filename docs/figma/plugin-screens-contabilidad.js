// Zentto ERP — Contabilidad Screens (Plan de Cuentas + Asientos Contables)
// Paste into: Figma → Plugins → Development → New Plugin → Run once

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

  // ─── Colors ────────────────────────────────────────────────

  const C = {
    primary: '#ff9900',
    secondary: '#232f3e',
    tertiary: '#007185',
    success: '#067D62',
    danger: '#cc0c39',
    darkest: '#131921',
    textDark: '#0f1111',
    textMuted: '#565959',
    border: '#e3e6e6',
    textDimmed: '#9CA3AF',
    bgPage: '#eaeded'
  };

  // Preload all fonts
  await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Medium' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Bold' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Extra Bold' });

  // ─── Shared builders ──────────────────────────────────────

  async function buildSidebar(frame, activeItem) {
    const sidebar = figma.createFrame();
    sidebar.name = 'Sidebar';
    sidebar.resize(260, 900);
    sidebar.x = 0;
    sidebar.y = 0;
    sidebar.fills = [{ type: 'SOLID', color: hexToRgb(C.darkest) }];
    sidebar.clipsContent = true;
    frame.appendChild(sidebar);

    // ZENTTO header
    await createText(sidebar, 'ZENTTO', 20, 20, { size: 22, weight: 700, color: C.primary });

    // Dashboard
    await createText(sidebar, 'Dashboard', 20, 64, { size: 14, weight: 400, color: '#ffffff' });

    // Divider
    createRect(sidebar, 16, 96, 228, 1, { fill: '#ffffff', fillOpacity: 0.1 });

    const sections = [
      {
        header: 'DIARIO', y: 112,
        items: [
          { label: 'Asientos', y: 140 },
          { label: 'Nuevo Asiento', y: 174 },
          { label: 'Recurrentes', y: 208 }
        ]
      },
      {
        header: 'CATÁLOGOS', y: 252,
        items: [
          { label: 'Plan de Cuentas', y: 280 },
          { label: 'Centros de Costo', y: 314 }
        ]
      },
      {
        header: 'OPERACIONES', y: 358,
        items: [
          { label: 'Conciliación Bancaria', y: 386 },
          { label: 'Presupuestos', y: 420 },
          { label: 'Cierre Contable', y: 454 }
        ]
      }
    ];

    for (const section of sections) {
      await createText(sidebar, section.header, 20, section.y, { size: 11, weight: 600, color: '#ffffff', opacity: 0.5 });
      for (const item of section.items) {
        const isActive = item.label === activeItem;
        if (isActive) {
          // Active background
          createRect(sidebar, 0, item.y - 4, 260, 30, { fill: C.primary, fillOpacity: 0.15 });
          // Orange left border
          createRect(sidebar, 0, item.y - 4, 3, 30, { fill: C.primary });
          await createText(sidebar, item.label, 20, item.y, { size: 14, weight: 600, color: C.primary });
        } else {
          await createText(sidebar, item.label, 20, item.y, { size: 14, weight: 400, color: '#ffffff', opacity: 0.7 });
        }
      }
    }

    // User avatar at bottom
    const avatarBg = figma.createEllipse();
    avatarBg.resize(36, 36);
    avatarBg.x = 16;
    avatarBg.y = 848;
    avatarBg.fills = [{ type: 'SOLID', color: hexToRgb(C.primary) }];
    sidebar.appendChild(avatarBg);
    await createText(sidebar, 'RG', 22, 856, { size: 14, weight: 700, color: '#ffffff' });
    await createText(sidebar, 'Raúl González', 62, 856, { size: 13, weight: 400, color: '#ffffff', opacity: 0.8 });

    return sidebar;
  }

  async function buildHeader(frame, breadcrumbParts) {
    const header = figma.createFrame();
    header.name = 'Header';
    header.resize(1180, 64);
    header.x = 260;
    header.y = 0;
    header.fills = [{ type: 'SOLID', color: hexToRgb(C.darkest) }];
    header.clipsContent = true;
    frame.appendChild(header);

    // Breadcrumb
    let bx = 20;
    for (let i = 0; i < breadcrumbParts.length; i++) {
      const part = breadcrumbParts[i];
      const isFirst = i === 0;
      const isLast = i === breadcrumbParts.length - 1;
      const color = isFirst ? C.primary : '#ffffff';
      const op = (!isFirst && !isLast) ? 0.7 : undefined;

      const t = await createText(header, part, bx, 22, {
        size: 14, weight: isLast ? 600 : 400, color
      });
      if (op) t.opacity = op;
      bx += t.width + 4;

      if (!isLast) {
        const sep = await createText(header, ' / ', bx, 22, { size: 14, weight: 400, color: '#ffffff' });
        sep.opacity = 0.5;
        bx += sep.width + 4;
      }
    }

    // Company chip
    createRect(header, 880, 16, 120, 32, { fill: '#ffffff', fillOpacity: 0.1, cornerRadius: 16 });
    await createText(header, 'Demo Corp', 896, 24, { size: 12, weight: 600, color: '#ffffff' });

    // DB chip
    createRect(header, 1010, 16, 60, 32, { fill: C.tertiary, fillOpacity: 0.2, cornerRadius: 16 });
    await createText(header, 'PG', 1028, 24, { size: 12, weight: 700, color: C.tertiary });

    // Notification icon placeholder
    createRect(header, 1090, 20, 24, 24, { fill: '#ffffff', fillOpacity: 0.15, cornerRadius: 4 });
    // Settings icon placeholder
    createRect(header, 1126, 20, 24, 24, { fill: '#ffffff', fillOpacity: 0.15, cornerRadius: 4 });

    return header;
  }

  async function buildPagination(parent, x, y, w, text) {
    const footer = figma.createFrame();
    footer.name = 'Pagination';
    footer.resize(w, 36);
    footer.x = x;
    footer.y = y;
    footer.fills = [{ type: 'SOLID', color: hexToRgb('#f8f9fa') }];
    parent.appendChild(footer);

    await createText(footer, text, 12, 10, { size: 12, weight: 400, color: C.textMuted });

    // Page buttons
    const pages = ['<', '1', '2', '>'];
    let px = w - 120;
    for (const p of pages) {
      const isActive = p === '1';
      createRect(footer, px, 6, 28, 24, {
        fill: isActive ? C.primary : '#ffffff',
        cornerRadius: 12,
        stroke: isActive ? undefined : C.border
      });
      await createText(footer, p, px + (p.length === 1 ? 10 : 8), 10, {
        size: 12, weight: isActive ? 700 : 400, color: isActive ? '#ffffff' : C.textMuted
      });
      px += 32;
    }

    return footer;
  }

  // ═══════════════════════════════════════════════════════════
  // SCREEN 6 — PLAN DE CUENTAS
  // ═══════════════════════════════════════════════════════════
  {
    const frame = figma.createFrame();
    frame.name = 'Screen — Contabilidad: Plan de Cuentas';
    frame.resize(1440, 900);
    frame.x = 7700;
    frame.y = 2000;
    frame.fills = [{ type: 'SOLID', color: hexToRgb(C.bgPage) }];
    frame.clipsContent = true;

    // Sidebar
    await buildSidebar(frame, 'Plan de Cuentas');

    // Header
    await buildHeader(frame, ['Home', 'Contabilidad', 'Plan de Cuentas']);

    // Content area background
    createRect(frame, 260, 64, 1180, 836, { fill: C.bgPage, name: 'Content BG' });

    // ── Context Action Header ──
    await createText(frame, 'Plan de cuentas', 280, 80, { size: 24, weight: 700, color: C.textDark });

    // "Nuevo" button
    createRect(frame, 1300, 78, 100, 36, { fill: C.primary, cornerRadius: 20, name: 'Btn Nuevo' });
    await createText(frame, 'Nuevo', 1330, 88, { size: 14, weight: 600, color: '#ffffff' });

    // ── Filter panel ──
    createRect(frame, 280, 140, 1140, 44, { fill: '#ffffff', stroke: C.border, cornerRadius: 8, name: 'Filter Panel' });

    // Search icon placeholder
    createRect(frame, 292, 152, 16, 16, { fill: C.textDimmed, fillOpacity: 0.3, cornerRadius: 2 });
    await createText(frame, 'Buscar cuenta...', 314, 154, { size: 14, weight: 400, color: C.textDimmed });

    // Filter chips
    createRect(frame, 680, 148, 100, 28, { fill: '#f8f8f8', cornerRadius: 14 });
    await createText(frame, 'Tipo: Todos', 694, 155, { size: 12, weight: 400, color: C.textMuted });

    createRect(frame, 790, 148, 100, 28, { fill: '#f8f8f8', cornerRadius: 14 });
    await createText(frame, 'Nivel: Todos', 802, 155, { size: 12, weight: 400, color: C.textMuted });

    // ── Tabs row ──
    const tabs = ['Todas', 'Activos', 'Pasivos', 'Capital', 'Ingresos/Gastos'];
    let tabX = 280;
    for (let i = 0; i < tabs.length; i++) {
      const isActive = i === 0;
      const t = await createText(frame, tabs[i], tabX, 200, {
        size: 14,
        weight: isActive ? 600 : 400,
        color: isActive ? C.primary : C.textMuted
      });
      if (isActive) {
        createRect(frame, tabX, 220, t.width, 3, { fill: C.primary });
      }
      tabX += t.width + 24;
    }

    // ── Data Grid ──
    const gridX = 280;
    const gridY = 232;
    const gridW = 1140;
    const gridH = 556;

    const gridBg = createRect(frame, gridX, gridY, gridW, gridH, {
      fill: '#ffffff', stroke: C.border, cornerRadius: 8, name: 'Data Grid'
    });
    gridBg.clipsContent = false;

    // Column headers
    createRect(frame, gridX, gridY, gridW, 42, { fill: '#f8f9fa', name: 'Grid Header' });
    createRect(frame, gridX, gridY + 41, gridW, 1, { fill: C.border });

    const colHeaders = [
      { label: 'Código', x: 12, w: 120 },
      { label: 'Descripción', x: 132, w: 600 },
      { label: 'Tipo', x: 780, w: 100 },
      { label: 'Nivel', x: 880, w: 80 },
      { label: 'Acciones', x: 960, w: 120 }
    ];

    for (const col of colHeaders) {
      await createText(frame, col.label, gridX + col.x, gridY + 12, {
        size: 13, weight: 600, color: C.textMuted
      });
    }

    // Data rows
    const rows = [
      { code: '1', desc: 'ACTIVOS', type: 'Deudor', level: '1', nivel: 1 },
      { code: '1.1', desc: 'Activos Corrientes', type: 'Deudor', level: '2', nivel: 2 },
      { code: '1.1.01', desc: 'Caja', type: 'Deudor', level: '3', nivel: 3 },
      { code: '1.1.02', desc: 'Bancos', type: 'Deudor', level: '3', nivel: 3 },
      { code: '1.1.03', desc: 'Cuentas por Cobrar', type: 'Deudor', level: '3', nivel: 3 },
      { code: '1.2', desc: 'Activos No Corrientes', type: 'Deudor', level: '2', nivel: 2 },
      { code: '1.2.01', desc: 'Mobiliario y Equipo', type: 'Deudor', level: '3', nivel: 3 },
      { code: '2', desc: 'PASIVOS', type: 'Acreedor', level: '1', nivel: 1 },
      { code: '2.1', desc: 'Pasivos Corrientes', type: 'Acreedor', level: '2', nivel: 2 },
      { code: '2.1.01', desc: 'Cuentas por Pagar', type: 'Acreedor', level: '3', nivel: 3 },
      { code: '2.1.02', desc: 'Impuestos por Pagar', type: 'Acreedor', level: '3', nivel: 3 },
      { code: '3', desc: 'CAPITAL', type: 'Acreedor', level: '1', nivel: 1 }
    ];

    const rowH = 40;
    const headerH = 42;

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
      const ry = gridY + headerH + i * rowH;
      const isAlt = i % 2 === 1;

      // Alternating row background
      if (isAlt) {
        createRect(frame, gridX, ry, gridW, rowH, { fill: '#fafafa' });
      }

      // Row bottom border
      createRect(frame, gridX, ry + rowH - 1, gridW, 1, { fill: C.border, fillOpacity: 0.5 });

      // Indent based on nivel
      const indent = row.nivel === 1 ? 0 : row.nivel === 2 ? 16 : 32;

      // Style based on nivel
      let codeWeight, codeColor, descWeight, descSize;
      if (row.nivel === 1) {
        codeWeight = 700;
        codeColor = C.primary;
        descWeight = 700;
        descSize = 14;
      } else if (row.nivel === 2) {
        codeWeight = 600;
        codeColor = C.textDark;
        descWeight = 600;
        descSize = 14;
      } else {
        codeWeight = 400;
        codeColor = C.textDark;
        descWeight = 400;
        descSize = 14;
      }

      // Code
      await createText(frame, row.code, gridX + 12, ry + 12, {
        size: 14, weight: codeWeight, color: codeColor
      });

      // Description (with indent)
      await createText(frame, row.desc, gridX + 132 + indent, ry + 12, {
        size: descSize, weight: descWeight, color: row.nivel === 1 ? C.primary : C.textDark
      });

      // Type
      await createText(frame, row.type, gridX + 780, ry + 12, {
        size: 13, weight: 400, color: C.textMuted
      });

      // Level
      await createText(frame, row.level, gridX + 880, ry + 12, {
        size: 13, weight: 400, color: C.textMuted
      });

      // Action icons
      // Eye icon
      createRect(frame, gridX + 960, ry + 10, 20, 20, {
        fill: C.tertiary, fillOpacity: 0.15, cornerRadius: 4, name: 'Icon Eye'
      });

      // Add icon (not for nivel 1 except as simple view)
      if (row.nivel >= 2) {
        createRect(frame, gridX + 986, ry + 10, 20, 20, {
          fill: C.primary, fillOpacity: 0.15, cornerRadius: 4, name: 'Icon Add'
        });
      }
    }

    // ── Pagination footer ──
    await buildPagination(frame, gridX, gridY + gridH, gridW, 'Mostrando 1–25 de 48');
  }

  // ═══════════════════════════════════════════════════════════
  // SCREEN 7 — ASIENTOS CONTABLES
  // ═══════════════════════════════════════════════════════════
  {
    const frame = figma.createFrame();
    frame.name = 'Screen — Contabilidad: Asientos Contables';
    frame.resize(1440, 900);
    frame.x = 9240;
    frame.y = 2000;
    frame.fills = [{ type: 'SOLID', color: hexToRgb(C.bgPage) }];
    frame.clipsContent = true;

    // Sidebar
    await buildSidebar(frame, 'Asientos');

    // Header
    await buildHeader(frame, ['Home', 'Contabilidad', 'Asientos Contables']);

    // Content area background
    createRect(frame, 260, 64, 1180, 836, { fill: C.bgPage, name: 'Content BG' });

    // ── Context Action Header ──
    await createText(frame, 'Asientos contables', 280, 80, { size: 24, weight: 700, color: C.textDark });

    // "Nuevo asiento" button
    createRect(frame, 1250, 78, 150, 36, { fill: C.primary, cornerRadius: 20, name: 'Btn Nuevo Asiento' });
    await createText(frame, 'Nuevo asiento', 1272, 88, { size: 14, weight: 600, color: '#ffffff' });

    // ── Filter panel ──
    createRect(frame, 280, 140, 1140, 44, { fill: '#ffffff', stroke: C.border, cornerRadius: 8, name: 'Filter Panel' });

    // Date range inputs
    await createText(frame, 'Desde:', 296, 154, { size: 12, weight: 600, color: C.textMuted });
    createRect(frame, 340, 148, 130, 28, { fill: '#f8f8f8', cornerRadius: 6, stroke: C.border });
    await createText(frame, '01/03/2026', 350, 155, { size: 12, weight: 400, color: C.textDark });

    await createText(frame, 'Hasta:', 486, 154, { size: 12, weight: 600, color: C.textMuted });
    createRect(frame, 528, 148, 130, 28, { fill: '#f8f8f8', cornerRadius: 6, stroke: C.border });
    await createText(frame, '25/03/2026', 538, 155, { size: 12, weight: 400, color: C.textDark });

    // Filter chips
    createRect(frame, 680, 148, 100, 28, { fill: '#f8f8f8', cornerRadius: 14 });
    await createText(frame, 'Tipo: Todos', 694, 155, { size: 12, weight: 400, color: C.textMuted });

    createRect(frame, 790, 148, 120, 28, { fill: '#f8f8f8', cornerRadius: 14 });
    await createText(frame, 'Estado: Todos', 802, 155, { size: 12, weight: 400, color: C.textMuted });

    // ── Data Grid ──
    const gridX = 280;
    const gridY = 200;
    const gridW = 1140;
    const gridH = 620;

    const gridFrame = createRect(frame, gridX, gridY, gridW, gridH, {
      fill: '#ffffff', stroke: C.border, cornerRadius: 8, name: 'Data Grid'
    });

    // Column headers
    createRect(frame, gridX, gridY, gridW, 42, { fill: '#f8f9fa', name: 'Grid Header' });
    createRect(frame, gridX, gridY + 41, gridW, 1, { fill: C.border });

    const cols = [
      { label: 'ID', x: 12, w: 60 },
      { label: 'Fecha', x: 72, w: 110 },
      { label: 'Tipo', x: 182, w: 100 },
      { label: 'Concepto', x: 282, w: 340 },
      { label: 'Referencia', x: 622, w: 100 },
      { label: 'Debe', x: 722, w: 120, align: 'RIGHT' },
      { label: 'Haber', x: 842, w: 120, align: 'RIGHT' },
      { label: 'Estado', x: 962, w: 100 }
    ];

    for (const col of cols) {
      await createText(frame, col.label, gridX + col.x, gridY + 12, {
        size: 13, weight: 600, color: C.textMuted,
        align: col.align
      });
    }

    // Data rows
    const asientos = [
      { id: '45', fecha: '25/03/2026', tipo: 'DIARIO', concepto: 'Compra de mercancía a proveedor ABC', ref: 'FAC-001', debe: '$5,200.00', haber: '$5,200.00', estado: 'APROBADO' },
      { id: '44', fecha: '24/03/2026', tipo: 'DIARIO', concepto: 'Pago de nómina quincenal marzo', ref: 'NOM-003', debe: '$12,500.00', haber: '$12,500.00', estado: 'APROBADO' },
      { id: '43', fecha: '23/03/2026', tipo: 'AJUSTE', concepto: 'Ajuste por diferencia cambiaria', ref: 'AJU-012', debe: '$890.00', haber: '$890.00', estado: 'APROBADO' },
      { id: '42', fecha: '22/03/2026', tipo: 'DIARIO', concepto: 'Venta de servicios profesionales', ref: 'FAC-089', debe: '$3,400.00', haber: '$3,400.00', estado: 'APROBADO' },
      { id: '41', fecha: '21/03/2026', tipo: 'DIARIO', concepto: 'Pago alquiler oficina marzo', ref: 'REC-045', debe: '$1,800.00', haber: '$1,800.00', estado: 'APROBADO' },
      { id: '40', fecha: '20/03/2026', tipo: 'DIARIO', concepto: 'Depreciación mensual activos fijos', ref: '', debe: '$450.00', haber: '$450.00', estado: 'BORRADOR' },
      { id: '39', fecha: '19/03/2026', tipo: 'DIARIO', concepto: 'Cobro factura cliente XYZ', ref: 'COB-023', debe: '$7,800.00', haber: '$7,800.00', estado: 'APROBADO' },
      { id: '38', fecha: '18/03/2026', tipo: 'CIERRE', concepto: 'Cierre mensual febrero 2026', ref: 'CIE-002', debe: '$45,200.00', haber: '$45,200.00', estado: 'APROBADO' },
      { id: '37', fecha: '17/03/2026', tipo: 'DIARIO', concepto: 'Pago servicios públicos', ref: 'PAG-067', debe: '$320.00', haber: '$320.00', estado: 'ANULADO' }
    ];

    const rowH = 40;
    const headerH = 42;
    // Row 1 (index 0) will be expanded, so rows after it shift by expandH
    const expandH = 120;

    for (let i = 0; i < asientos.length; i++) {
      const row = asientos[i];
      // After row 0, add expandH offset for the detail panel
      const extraOffset = i > 0 ? expandH : 0;
      const ry = gridY + headerH + i * rowH + extraOffset;
      const isAlt = i % 2 === 1;

      if (isAlt) {
        createRect(frame, gridX, ry, gridW, rowH, { fill: '#fafafa' });
      }

      createRect(frame, gridX, ry + rowH - 1, gridW, 1, { fill: C.border, fillOpacity: 0.5 });

      await createText(frame, row.id, gridX + 12, ry + 12, { size: 14, weight: 400, color: C.textDark });
      await createText(frame, row.fecha, gridX + 72, ry + 12, { size: 13, weight: 400, color: C.textDark });
      await createText(frame, row.tipo, gridX + 182, ry + 12, { size: 13, weight: 600, color: C.textMuted });
      await createText(frame, row.concepto, gridX + 282, ry + 12, { size: 13, weight: 400, color: C.textDark, width: 330 });
      await createText(frame, row.ref, gridX + 622, ry + 12, { size: 13, weight: 400, color: C.textMuted });
      await createText(frame, row.debe, gridX + 722, ry + 12, { size: 13, weight: 400, color: C.textDark, width: 110, align: 'RIGHT' });
      await createText(frame, row.haber, gridX + 842, ry + 12, { size: 13, weight: 400, color: C.textDark, width: 110, align: 'RIGHT' });

      // Estado pill
      let pillFill, pillFillOp, pillTextColor;
      if (row.estado === 'APROBADO') {
        pillFill = C.success; pillFillOp = 0.1; pillTextColor = C.success;
      } else if (row.estado === 'BORRADOR') {
        pillFill = '#ffd814'; pillFillOp = 0.15; pillTextColor = '#856d00';
      } else if (row.estado === 'ANULADO') {
        pillFill = C.danger; pillFillOp = 0.1; pillTextColor = C.danger;
      }

      const pillW = row.estado.length * 7 + 16;
      createRect(frame, gridX + 962, ry + 8, pillW, 24, {
        fill: pillFill, fillOpacity: pillFillOp, cornerRadius: 12
      });
      await createText(frame, row.estado, gridX + 970, ry + 14, {
        size: 11, weight: 700, color: pillTextColor
      });
    }

    // ── Expanded detail row (below row 0) ──
    const detailY = gridY + headerH + rowH;
    createRect(frame, gridX, detailY, gridW, expandH, { fill: '#fafafa', name: 'Detail Panel' });
    createRect(frame, gridX, detailY, gridW, 1, { fill: C.border, fillOpacity: 0.3 });
    createRect(frame, gridX, detailY + expandH - 1, gridW, 1, { fill: C.border, fillOpacity: 0.3 });

    // Detail sub-header
    const subCols = [
      { label: 'Cuenta', x: 40 },
      { label: 'Descripción', x: 140 },
      { label: 'Debe', x: 620 },
      { label: 'Haber', x: 740 },
      { label: 'C. Costo', x: 860 }
    ];

    for (const sc of subCols) {
      await createText(frame, sc.label, gridX + sc.x, detailY + 12, {
        size: 12, weight: 600, color: C.textMuted
      });
    }

    createRect(frame, gridX + 30, detailY + 32, gridW - 60, 1, { fill: C.border, fillOpacity: 0.5 });

    // Sub-row 1
    await createText(frame, '1.1.03', gridX + 40, detailY + 44, { size: 13, weight: 400, color: C.textDark });
    await createText(frame, 'Inventario de Mercancías', gridX + 140, detailY + 44, { size: 13, weight: 400, color: C.textDark });
    await createText(frame, '$5,200.00', gridX + 620, detailY + 44, { size: 13, weight: 400, color: C.textDark });
    await createText(frame, '', gridX + 740, detailY + 44, { size: 13, weight: 400, color: C.textDark });
    await createText(frame, 'ADM', gridX + 860, detailY + 44, { size: 13, weight: 600, color: C.textMuted });

    // Sub-row 2
    await createText(frame, '2.1.01', gridX + 40, detailY + 72, { size: 13, weight: 400, color: C.textDark });
    await createText(frame, 'Cuentas por Pagar', gridX + 140, detailY + 72, { size: 13, weight: 400, color: C.textDark });
    await createText(frame, '', gridX + 620, detailY + 72, { size: 13, weight: 400, color: C.textDark });
    await createText(frame, '$5,200.00', gridX + 740, detailY + 72, { size: 13, weight: 400, color: C.textDark });
    await createText(frame, 'ADM', gridX + 860, detailY + 72, { size: 13, weight: 600, color: C.textMuted });

    // ── Totals row ──
    const totalRowCount = asientos.length;
    const totalsY = gridY + headerH + totalRowCount * rowH + expandH;
    createRect(frame, gridX, totalsY, gridW, 40, { fill: '#f8f9fa', name: 'Totals Row' });
    createRect(frame, gridX, totalsY, gridW, 1, { fill: C.border });

    await createText(frame, 'Total', gridX + 282, totalsY + 12, { size: 14, weight: 700, color: C.textDark });
    await createText(frame, '$77,560.00', gridX + 722, totalsY + 12, { size: 14, weight: 700, color: C.textDark, width: 110, align: 'RIGHT' });
    await createText(frame, '$77,560.00', gridX + 842, totalsY + 12, { size: 14, weight: 700, color: C.textDark, width: 110, align: 'RIGHT' });

    // ── Pagination footer ──
    await buildPagination(frame, gridX, totalsY + 40, gridW, 'Mostrando 1–9 de 45');
  }

  figma.closePlugin('Contabilidad screens created successfully.');

})();
