// Figma Plugin — Slides 6-10 (Investor Deck)
// Paste this entire script into Figma > Plugins > Development > New Plugin > Run

(async () => {
  // ── Helpers ──────────────────────────────────────────────────────────

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

  // ── Colors ───────────────────────────────────────────────────────────

  const C = {
    primary:    '#ff9900',
    secondary:  '#232f3e',
    tertiary:   '#007185',
    success:    '#067D62',
    danger:     '#cc0c39',
    darkest:    '#131921',
    textDark:   '#0f1111',
    textMuted:  '#565959',
    border:     '#e3e6e6',
    textDimmed: '#9CA3AF',
    darkPaper:  '#1a2332',
    white:      '#ffffff',
    yellow:     '#ffd814',
  };

  // ── Shared: slide frame ──────────────────────────────────────────────

  function createSlide(name, xOffset, bgColor) {
    const frame = figma.createFrame();
    frame.name = name;
    frame.resize(1920, 1080);
    frame.x = xOffset;
    frame.y = 0;
    frame.fills = [{ type: 'SOLID', color: hexToRgb(bgColor) }];
    frame.clipsContent = true;
    return frame;
  }

  // ── Shared: badge pill ───────────────────────────────────────────────

  async function createBadge(parent, label, x, y, opts = {}) {
    const bgColor = opts.bg || C.primary;
    const bgOpacity = opts.bgOpacity || 0.1;
    const textColor = opts.textColor || C.primary;

    const pill = figma.createRectangle();
    const padH = 24;
    const height = 36;
    pill.cornerRadius = 18;
    pill.fills = [{ type: 'SOLID', color: hexToRgb(bgColor), opacity: bgOpacity }];
    parent.appendChild(pill);

    const t = await createText(parent, label, x + padH, y + 8, {
      weight: 700, size: 13, color: textColor
    });

    const tw = t.width;
    pill.resize(tw + padH * 2, height);
    pill.x = x;
    pill.y = y;
    return pill;
  }

  // ════════════════════════════════════════════════════════════════════
  // SLIDE 6 — MERCADO
  // ════════════════════════════════════════════════════════════════════

  const s6 = createSlide('Slide 6 — Mercado', 10100, C.white);

  await createBadge(s6, 'MERCADO', 120, 80);
  await createText(s6, 'Oportunidad de $12B+ en software\nempresarial para PyMEs LATAM', 120, 140, {
    weight: 700, size: 40, color: C.textDark, width: 1680
  });

  // TAM / SAM / SOM concentric circles
  const circleData = [
    { label: '$12.4B', sub: 'Software empresarial LATAM + España', w: 500, h: 500, cx: 230, cy: 350, op: 0.08, labelSize: 20 },
    { label: '$3.2B',  sub: 'ERP Cloud para PyMEs',                w: 340, h: 340, cx: 310, cy: 430, op: 0.15, labelSize: 20 },
    { label: '$180M',  sub: 'Año 5',                               w: 180, h: 180, cx: 390, cy: 510, op: 0.3,  labelSize: 24 },
  ];

  for (const cd of circleData) {
    const el = figma.createEllipse();
    el.resize(cd.w, cd.h);
    el.x = cd.cx;
    el.y = cd.cy;
    el.fills = [{ type: 'SOLID', color: hexToRgb(C.primary), opacity: cd.op }];
    el.strokes = [{ type: 'SOLID', color: hexToRgb(C.primary) }];
    el.strokeWeight = 1;
    s6.appendChild(el);

    const centerX = cd.cx + cd.w / 2;
    const centerY = cd.cy + cd.h / 2;

    await createText(s6, cd.label, centerX - 60, centerY - 24, {
      weight: 800, size: cd.labelSize, color: C.primary, width: 120, align: 'CENTER'
    });
    await createText(s6, cd.sub, centerX - 100, centerY + 6, {
      weight: 400, size: 14, color: C.textMuted, width: 200, align: 'CENTER'
    });
  }

  // Right markets list
  const markets = [
    { flag: '\u{1F1FB}\u{1F1EA} Venezuela',     detail: '25M+ PyMEs informales, 0% penetración ERP' },
    { flag: '\u{1F1E8}\u{1F1F4} Colombia',       detail: 'Facturación electrónica obligatoria DIAN, 1.6M PyMEs' },
    { flag: '\u{1F1F2}\u{1F1FD} México',         detail: 'SAT compliance obligatorio, 4.9M PyMEs' },
    { flag: '\u{1F1EA}\u{1F1F8} España',         detail: 'Verifactu 2027 obligatorio, 3.2M autónomos' },
    { flag: '\u{1F1FA}\u{1F1F8} USA (Hispanos)', detail: '6.1M negocios hispanos, mercado desatendido' },
  ];

  for (let i = 0; i < markets.length; i++) {
    const yPos = 350 + i * 100;
    await createText(s6, markets[i].flag, 820, yPos, { weight: 600, size: 20, color: C.textDark });
    await createText(s6, markets[i].detail, 820, yPos + 32, { weight: 400, size: 16, color: C.textMuted, width: 900 });
  }

  // ════════════════════════════════════════════════════════════════════
  // SLIDE 7 — MODELO DE NEGOCIO
  // ════════════════════════════════════════════════════════════════════

  const s7 = createSlide('Slide 7 — Modelo de Negocio', 12120, C.white);

  await createBadge(s7, 'MODELO DE NEGOCIO', 120, 80);
  await createText(s7, 'SaaS por suscripción + marketplace de integraciones', 120, 140, {
    weight: 700, size: 40, color: C.textDark, width: 1680
  });

  // Pricing cards
  const plans = [
    {
      name: 'Starter', price: '$29', priceColor: C.textDark, bandColor: '#eaeded',
      x: 200, h: 420, strokeColor: C.border, strokeW: 1,
      features: ['3 módulos', '5 usuarios', '1 sucursal', 'Soporte email'],
      popular: false
    },
    {
      name: 'Business', price: '$79', priceColor: C.primary, bandColor: C.primary,
      x: 720, h: 440, strokeColor: C.primary, strokeW: 2,
      features: ['8 módulos', '25 usuarios', '5 sucursales', 'Soporte prioritario', 'API acceso'],
      popular: true
    },
    {
      name: 'Enterprise', price: '$199', priceColor: C.textDark, bandColor: C.secondary,
      x: 1240, h: 420, strokeColor: C.border, strokeW: 1,
      features: ['Todos los módulos', 'Usuarios ilimitados', 'Multi-país', 'Soporte dedicado', 'SLA 99.9%'],
      popular: false
    },
  ];

  for (const plan of plans) {
    // Card
    const card = figma.createRectangle();
    card.resize(480, plan.h);
    card.x = plan.x;
    card.y = 300;
    card.fills = [{ type: 'SOLID', color: hexToRgb(C.white) }];
    card.strokes = [{ type: 'SOLID', color: hexToRgb(plan.strokeColor) }];
    card.strokeWeight = plan.strokeW;
    card.cornerRadius = 16;
    s7.appendChild(card);

    // Header band
    const band = figma.createRectangle();
    band.resize(480, 8);
    band.x = plan.x;
    band.y = 300;
    band.fills = [{ type: 'SOLID', color: hexToRgb(plan.bandColor) }];
    band.topLeftRadius = 16;
    band.topRightRadius = 16;
    band.bottomLeftRadius = 0;
    band.bottomRightRadius = 0;
    s7.appendChild(band);

    // Popular badge
    if (plan.popular) {
      const badge = figma.createRectangle();
      badge.resize(86, 28);
      badge.x = plan.x + 374;
      badge.y = 300 + 20;
      badge.fills = [{ type: 'SOLID', color: hexToRgb(C.primary) }];
      badge.cornerRadius = 14;
      s7.appendChild(badge);
      await createText(s7, 'POPULAR', plan.x + 374 + 14, 300 + 25, {
        weight: 700, size: 12, color: C.white
      });
    }

    // Plan name
    await createText(s7, plan.name, plan.x + 40, 300 + 40, {
      weight: 700, size: 24, color: C.textDark
    });

    // Price
    await createText(s7, plan.price, plan.x + 40, 300 + 80, {
      weight: 800, size: 48, color: plan.priceColor
    });
    await createText(s7, '/mes', plan.x + 40 + (plan.price.length * 28), 300 + 100, {
      weight: 400, size: 20, color: C.textMuted
    });

    // Features
    for (let fi = 0; fi < plan.features.length; fi++) {
      await createText(s7, '•  ' + plan.features[fi], plan.x + 40, 300 + 180 + fi * 32, {
        weight: 400, size: 16, color: C.textMuted
      });
    }
  }

  // Revenue streams row
  const streams = [
    { label: 'Zentto Store',  accent: C.tertiary },
    { label: 'Zentto Notify', accent: C.primary },
    { label: 'Fiscal Agent',  accent: C.secondary },
    { label: 'Implementación', accent: C.success },
  ];

  for (let si = 0; si < streams.length; si++) {
    const sx = 160 + si * 400;
    const sy = 800;
    const pill = figma.createRectangle();
    pill.resize(320, 44);
    pill.x = sx;
    pill.y = sy;
    pill.cornerRadius = 22;
    pill.fills = [{ type: 'SOLID', color: hexToRgb(streams[si].accent), opacity: 0.1 }];
    s7.appendChild(pill);
    await createText(s7, streams[si].label, sx + 40, sy + 12, {
      weight: 600, size: 14, color: streams[si].accent, width: 240, align: 'CENTER'
    });
  }

  // ════════════════════════════════════════════════════════════════════
  // SLIDE 8 — TRACCIÓN
  // ════════════════════════════════════════════════════════════════════

  const s8 = createSlide('Slide 8 — Tracción', 14140, C.white);

  await createBadge(s8, 'TRACCIÓN', 120, 80);
  await createText(s8, 'De sistema legacy a plataforma cloud en 18 meses', 120, 140, {
    weight: 700, size: 40, color: C.textDark, width: 1680
  });

  // Timeline horizontal line
  const tLine = figma.createRectangle();
  tLine.resize(1600, 3);
  tLine.x = 160;
  tLine.y = 398;
  tLine.fills = [{ type: 'SOLID', color: hexToRgb(C.border) }];
  s8.appendChild(tLine);

  const milestones = [
    { date: '2024 Q1', desc: 'Sistema VB6 legacy\n+15 años operando' },
    { date: '2024 Q3', desc: 'Inicio migración web\nNode.js + Next.js' },
    { date: '2025 Q2', desc: '11 micro-frontends\nen producción' },
    { date: '2025 Q4', desc: 'Dual-DB engine\nSQL Server + PostgreSQL' },
    { date: '2026 Q1', desc: 'Multi-tenant\nCI/CD + Zentto Notify' },
    { date: '2026 Q3', desc: 'Expansión CO/MX\nVerifactu España' },
  ];

  const mxPositions = [240, 520, 800, 1080, 1360, 1640];

  for (let mi = 0; mi < milestones.length; mi++) {
    const mx = mxPositions[mi];

    // Dot
    const dot = figma.createEllipse();
    dot.resize(16, 16);
    dot.x = mx - 8;
    dot.y = 390;
    dot.fills = [{ type: 'SOLID', color: hexToRgb(C.primary) }];
    s8.appendChild(dot);

    // Vertical stem
    const stem = figma.createRectangle();
    stem.resize(2, 40);
    stem.x = mx - 1;
    stem.y = 350;
    stem.fills = [{ type: 'SOLID', color: hexToRgb(C.primary) }];
    s8.appendChild(stem);

    // Date label above
    await createText(s8, milestones[mi].date, mx - 50, 328, {
      weight: 700, size: 14, color: C.primary, width: 100, align: 'CENTER'
    });

    // Description below
    await createText(s8, milestones[mi].desc, mx - 100, 420, {
      weight: 400, size: 14, color: C.textMuted, width: 200, align: 'CENTER'
    });
  }

  // KPI cards
  const kpis = [
    { value: '17',    label: 'Apps en producción', color: C.primary },
    { value: '188+',  label: 'Stored procedures',  color: C.tertiary },
    { value: '5',     label: 'Países soportados',  color: C.success },
    { value: '99.9%', label: 'Uptime producción',   color: C.secondary },
  ];

  for (let ki = 0; ki < kpis.length; ki++) {
    const kx = 80 + ki * 392 + ki * 32;
    const ky = 620;
    const kCard = figma.createRectangle();
    kCard.resize(360, 200);
    kCard.x = kx;
    kCard.y = ky;
    kCard.fills = [{ type: 'SOLID', color: hexToRgb(C.white) }];
    kCard.strokes = [{ type: 'SOLID', color: hexToRgb(C.border) }];
    kCard.strokeWeight = 1;
    kCard.cornerRadius = 12;
    s8.appendChild(kCard);

    await createText(s8, kpis[ki].value, kx + 40, ky + 40, {
      weight: 800, size: 56, color: kpis[ki].color
    });
    await createText(s8, kpis[ki].label, kx + 40, ky + 120, {
      weight: 400, size: 16, color: C.textMuted, width: 280
    });
  }

  // ════════════════════════════════════════════════════════════════════
  // SLIDE 9 — COMPETENCIA
  // ════════════════════════════════════════════════════════════════════

  const s9 = createSlide('Slide 9 — Competencia', 16160, '#f8f8f8');

  await createBadge(s9, 'COMPETENCIA', 120, 80);
  await createText(s9, 'Posicionamiento único en un mercado fragmentado', 120, 140, {
    weight: 700, size: 40, color: C.textDark, width: 1680
  });

  // Table
  const tableX = 120;
  const tableY = 280;
  const tableW = 1680;
  const rowH = 48;
  const headerH = 56;
  const colPositions = [
    { label: 'Feature', x: 40 },
    { label: 'Zentto',  x: 400 },
    { label: 'SAP B1',  x: 620 },
    { label: 'Odoo',    x: 840 },
    { label: 'Alegra',  x: 1060 },
    { label: 'Siigo',   x: 1280 },
  ];

  // Header row
  const headerRect = figma.createRectangle();
  headerRect.resize(tableW, headerH);
  headerRect.x = tableX;
  headerRect.y = tableY;
  headerRect.fills = [{ type: 'SOLID', color: hexToRgb(C.secondary) }];
  headerRect.topLeftRadius = 12;
  headerRect.topRightRadius = 12;
  headerRect.bottomLeftRadius = 0;
  headerRect.bottomRightRadius = 0;
  s9.appendChild(headerRect);

  for (const col of colPositions) {
    const isZentto = col.label === 'Zentto';
    await createText(s9, col.label, tableX + col.x, tableY + 16, {
      weight: 700, size: 16, color: isZentto ? C.primary : C.white
    });
  }

  // G=green, R=red, Y=yellow
  const G = 'green', R = 'red', Y = 'yellow';
  const rows = [
    { feature: 'Precio < $100/mes',          vals: [G, R, G, G, G] },
    { feature: 'Modular (paga lo que usas)',  vals: [G, R, Y, R, R] },
    { feature: 'Multi-país fiscal',           vals: [G, Y, R, Y, Y] },
    { feature: 'Multi-tenant nativo',         vals: [G, R, R, R, R] },
    { feature: 'POS integrado',              vals: [G, Y, G, R, R] },
    { feature: 'Ecommerce nativo',           vals: [G, R, G, R, R] },
    { feature: 'API REST moderna',           vals: [G, R, Y, Y, R] },
    { feature: 'Micro-frontends',            vals: [G, R, R, R, R] },
  ];

  const dotColorMap = { green: C.success, red: C.danger, yellow: C.yellow };

  for (let ri = 0; ri < rows.length; ri++) {
    const ry = tableY + headerH + ri * rowH;
    const isAlt = ri % 2 === 1;

    // Row background
    const rowBg = figma.createRectangle();
    rowBg.resize(tableW, rowH);
    rowBg.x = tableX;
    rowBg.y = ry;
    rowBg.fills = [{ type: 'SOLID', color: hexToRgb(isAlt ? '#f4f4f4' : C.white) }];
    // Last row gets bottom corners
    if (ri === rows.length - 1) {
      rowBg.bottomLeftRadius = 12;
      rowBg.bottomRightRadius = 12;
    }
    s9.appendChild(rowBg);

    // Feature text
    await createText(s9, rows[ri].feature, tableX + 40, ry + 14, {
      weight: 400, size: 15, color: C.textDark
    });

    // Zentto dot (always green)
    const zDot = figma.createEllipse();
    zDot.resize(20, 20);
    zDot.x = tableX + 400 + 16;
    zDot.y = ry + 14;
    zDot.fills = [{ type: 'SOLID', color: hexToRgb(C.success) }];
    s9.appendChild(zDot);

    // Competitor dots
    const compCols = [620, 840, 1060, 1280];
    for (let ci = 0; ci < rows[ri].vals.length; ci++) {
      const cDot = figma.createEllipse();
      cDot.resize(20, 20);
      cDot.x = tableX + compCols[ci] + 16;
      cDot.y = ry + 14;
      cDot.fills = [{ type: 'SOLID', color: hexToRgb(dotColorMap[rows[ri].vals[ci]]) }];
      s9.appendChild(cDot);
    }
  }

  // Quote box
  const quoteX = 360;
  const quoteY = 740;

  const quoteBox = figma.createRectangle();
  quoteBox.resize(1200, 80);
  quoteBox.x = quoteX;
  quoteBox.y = quoteY;
  quoteBox.fills = [{ type: 'SOLID', color: hexToRgb(C.primary), opacity: 0.05 }];
  quoteBox.cornerRadius = 8;
  s9.appendChild(quoteBox);

  const quoteBorder = figma.createRectangle();
  quoteBorder.resize(4, 80);
  quoteBorder.x = quoteX;
  quoteBorder.y = quoteY;
  quoteBorder.fills = [{ type: 'SOLID', color: hexToRgb(C.primary) }];
  s9.appendChild(quoteBorder);

  await figma.loadFontAsync({ family: 'Inter', style: 'Medium Italic' });
  const quoteText = figma.createText();
  quoteText.fontName = { family: 'Inter', style: 'Medium Italic' };
  quoteText.characters = 'Zentto es el único ERP modular cloud-native diseñado desde cero para la fiscalidad y operativa de LATAM';
  quoteText.fontSize = 18;
  quoteText.fills = [{ type: 'SOLID', color: hexToRgb(C.textDark) }];
  quoteText.x = quoteX + 28;
  quoteText.y = quoteY + 24;
  quoteText.resize(1140, quoteText.height);
  quoteText.textAutoResize = 'HEIGHT';
  s9.appendChild(quoteText);

  // ════════════════════════════════════════════════════════════════════
  // SLIDE 10 — TECNOLOGÍA
  // ════════════════════════════════════════════════════════════════════

  const s10 = createSlide('Slide 10 — Tecnología', 18180, C.secondary);

  await createBadge(s10, 'TECNOLOGÍA', 120, 80, {
    bg: C.primary, bgOpacity: 0.15, textColor: C.primary
  });
  await createText(s10, 'Arquitectura de siguiente generación', 120, 140, {
    weight: 700, size: 40, color: C.white, width: 1680
  });

  // 2×2 tech cards
  const techCards = [
    {
      x: 120, y: 280, stroke: C.primary,
      title: 'Database-per-Tenant',
      desc: 'Cada cliente tiene su propia base de datos PostgreSQL. Aislamiento total, compliance GDPR, backups independientes.'
    },
    {
      x: 1000, y: 280, stroke: C.tertiary,
      title: 'Dual Database Engine',
      desc: 'SQL Server + PostgreSQL con la misma API. Migración transparente. 188+ stored procedures en paridad.'
    },
    {
      x: 120, y: 640, stroke: C.success,
      title: 'Micro-frontends',
      desc: '17 apps Next.js independientes. Deploy parcial sin downtime. Cada módulo es autónomo.'
    },
    {
      x: 1000, y: 640, stroke: C.danger,
      title: 'Observabilidad Total',
      desc: 'Elasticsearch + Kafka + APM. Logs estructurados, audit trail, métricas en tiempo real. SDK propio.'
    },
  ];

  for (const tc of techCards) {
    // Card background
    const card = figma.createRectangle();
    card.resize(840, 320);
    card.x = tc.x;
    card.y = tc.y;
    card.fills = [{ type: 'SOLID', color: hexToRgb(C.darkPaper) }];
    card.cornerRadius = 16;
    card.strokes = [{ type: 'SOLID', color: hexToRgb(tc.stroke), opacity: 0.3 }];
    card.strokeWeight = 1;
    s10.appendChild(card);

    // Icon placeholder rect
    const icon = figma.createRectangle();
    icon.resize(48, 48);
    icon.x = tc.x + 32;
    icon.y = tc.y + 32;
    icon.fills = [{ type: 'SOLID', color: hexToRgb(tc.stroke), opacity: 0.15 }];
    icon.cornerRadius = 12;
    s10.appendChild(icon);

    // Title
    await createText(s10, tc.title, tc.x + 32, tc.y + 104, {
      weight: 700, size: 24, color: C.white
    });

    // Description
    await createText(s10, tc.desc, tc.x + 32, tc.y + 148, {
      weight: 400, size: 16, color: C.textDimmed, width: 776
    });
  }

  // ── Done ─────────────────────────────────────────────────────────────
  figma.closePlugin('Slides 6-10 created!');

})();
