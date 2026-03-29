// Figma Plugin — Investor Deck Slides 11-15
// Run via Figma > Plugins > Development > New Plugin > paste & run

(async () => {
  // ── Helpers ──────────────────────────────────────────────
  function hexToRgb(hex) {
    hex = hex.replace('#', '');
    return {
      r: parseInt(hex.substring(0, 2), 16) / 255,
      g: parseInt(hex.substring(2, 4), 16) / 255,
      b: parseInt(hex.substring(4, 6), 16) / 255
    };
  }

  function getFontStyle(w) {
    return { 400: 'Regular', 500: 'Medium', 600: 'Semi Bold', 700: 'Bold', 800: 'Extra Bold' }[w] || 'Regular';
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
    if (opts.width) { t.resize(opts.width, t.height); t.textAutoResize = 'HEIGHT'; }
    if (opts.align) t.textAlignHorizontal = opts.align;
    if (opts.name) t.name = opts.name;
    parent.appendChild(t);
    return t;
  }

  // ── Colors ───────────────────────────────────────────────
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
    darkPaper: '#1a2332'
  };

  // ── Badge helper ─────────────────────────────────────────
  async function createBadge(parent, label, x, y) {
    const badge = figma.createFrame();
    badge.resize(160, 36);
    badge.x = x;
    badge.y = y;
    badge.cornerRadius = 18;
    badge.fills = [{ type: 'SOLID', color: hexToRgb(C.primary), opacity: 0.1 }];
    badge.clipsContent = false;
    badge.name = 'Badge';
    parent.appendChild(badge);
    await createText(badge, label, 0, 8, { size: 14, weight: 700, color: C.primary, width: 160, align: 'CENTER' });
    return badge;
  }

  // ── Preload fonts ────────────────────────────────────────
  const fontsToLoad = ['Regular', 'Medium', 'Semi Bold', 'Bold', 'Extra Bold'];
  for (const style of fontsToLoad) {
    await figma.loadFontAsync({ family: 'Inter', style });
  }

  // ════════════════════════════════════════════════════════════
  // SLIDE 11 — GO-TO-MARKET  (x = 20200)
  // ════════════════════════════════════════════════════════════
  const s11 = figma.createFrame();
  s11.resize(1920, 1080);
  s11.x = 20200;
  s11.y = 0;
  s11.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
  s11.name = 'Slide 11 — Go-to-Market';
  figma.currentPage.appendChild(s11);

  await createBadge(s11, 'ESTRATEGIA', 120, 60);
  await createText(s11, 'Expansión por país con compliance\nfiscal como palanca', 120, 110, { size: 40, weight: 700, color: C.textDark, width: 1680 });

  // Left — 3 expansion phases
  const phases = [
    { color: C.primary, title: 'Fase 1 — 2026', desc: '🇻🇪 Venezuela + 🇨🇴 Colombia — Base operativa + facturación DIAN' },
    { color: C.tertiary, title: 'Fase 2 — 2027', desc: '🇲🇽 México + 🇪🇸 España — SAT compliance + Verifactu obligatorio' },
    { color: C.success, title: 'Fase 3 — 2028', desc: '🇺🇸 USA Hispano + 🇨🇱 Chile + 🇵🇪 Perú — Expansión regional' }
  ];

  for (let i = 0; i < phases.length; i++) {
    const py = 300 + i * 140;
    const ph = phases[i];

    // Background rect
    const bg = figma.createRectangle();
    bg.resize(800, 100);
    bg.x = 120;
    bg.y = py;
    bg.cornerRadius = 8;
    bg.fills = [{ type: 'SOLID', color: hexToRgb(ph.color), opacity: 0.08 }];
    bg.name = `Phase ${i + 1} BG`;
    s11.appendChild(bg);

    // Left border
    const lb = figma.createRectangle();
    lb.resize(4, 100);
    lb.x = 120;
    lb.y = py;
    lb.fills = [{ type: 'SOLID', color: hexToRgb(ph.color) }];
    lb.name = `Phase ${i + 1} Border`;
    s11.appendChild(lb);

    await createText(s11, ph.title, 144, py + 16, { size: 20, weight: 700, color: ph.color });
    await createText(s11, ph.desc, 144, py + 50, { size: 16, weight: 400, color: C.textMuted, width: 740 });
  }

  // Right — 3 channel cards
  const channels = [
    { color: C.primary, title: 'Venta directa digital', desc: 'Self-service + free trial 14 días. Onboarding automatizado.' },
    { color: C.tertiary, title: 'Red de partners contables', desc: 'Contadores y asesores fiscales como canal de distribución. Comisión recurrente.' },
    { color: C.success, title: 'Marketplace Zentto Store', desc: 'Integraciones de terceros que atraen usuarios. Revenue share 20%.' }
  ];

  for (let i = 0; i < channels.length; i++) {
    const cy = 300 + i * 174;
    const ch = channels[i];

    const card = figma.createFrame();
    card.resize(760, 150);
    card.x = 1040;
    card.y = cy;
    card.cornerRadius = 12;
    card.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
    card.strokes = [{ type: 'SOLID', color: hexToRgb(C.border) }];
    card.strokeWeight = 1;
    card.clipsContent = false;
    card.name = `Channel ${i + 1}`;
    s11.appendChild(card);

    const circle = figma.createEllipse();
    circle.resize(48, 48);
    circle.x = 24;
    circle.y = 50;
    circle.fills = [{ type: 'SOLID', color: hexToRgb(ch.color), opacity: 0.1 }];
    card.appendChild(circle);

    await createText(card, ch.title, 88, 40, { size: 20, weight: 600, color: C.textDark });
    await createText(card, ch.desc, 88, 72, { size: 15, weight: 400, color: C.textMuted, width: 640 });
  }

  // Bottom pill
  const pill = figma.createRectangle();
  pill.resize(700, 52);
  pill.x = 610;
  pill.y = 820;
  pill.cornerRadius = 26;
  pill.fills = [{ type: 'SOLID', color: hexToRgb(C.secondary) }];
  pill.name = 'Bottom Pill';
  s11.appendChild(pill);
  await createText(s11, 'Compliance fiscal = barrera de entrada para competidores globales', 610, 834, { size: 16, weight: 600, color: '#FFFFFF', width: 700, align: 'CENTER' });

  // ════════════════════════════════════════════════════════════
  // SLIDE 12 — EQUIPO  (x = 22220)
  // ════════════════════════════════════════════════════════════
  const s12 = figma.createFrame();
  s12.resize(1920, 1080);
  s12.x = 22220;
  s12.y = 0;
  s12.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
  s12.name = 'Slide 12 — Equipo';
  figma.currentPage.appendChild(s12);

  await createBadge(s12, 'EQUIPO', 120, 60);
  await createText(s12, 'Fundadores con +15 años en software empresarial', 120, 110, { size: 40, weight: 700, color: C.textDark, width: 1680 });
  await createText(s12, 'Equipo distribuido con experiencia en ERP legacy, cloud-native y fiscalidad multi-país', 120, 210, { size: 18, weight: 400, color: C.textMuted, width: 1680 });

  // 3 team cards
  const teamCards = [
    { x: 200, initials: 'RG', name: 'Raúl González', role: 'Founder & CEO', roleColor: C.primary, bio: '+15 años desarrollando ERPs. Arquitecto del sistema VB6 legacy con miles de empresas atendidas. Visión de migración a cloud.' },
    { x: 720, initials: '?', name: 'Por contratar', role: 'CTO', roleColor: C.tertiary, bio: 'Buscamos un CTO con experiencia en arquitecturas distribuidas, micro-servicios y equipos de ingeniería en LATAM.' },
    { x: 1240, initials: '?', name: 'Por contratar', role: 'COO / Head of Growth', roleColor: C.success, bio: 'Buscamos un perfil de operaciones y crecimiento con experiencia en SaaS B2B y mercados LATAM.' }
  ];

  for (const tc of teamCards) {
    const card = figma.createFrame();
    card.resize(480, 380);
    card.x = tc.x;
    card.y = 320;
    card.cornerRadius = 16;
    card.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
    card.strokes = [{ type: 'SOLID', color: hexToRgb(C.border) }];
    card.strokeWeight = 1;
    card.clipsContent = false;
    card.name = `Team — ${tc.name}`;
    s12.appendChild(card);

    // Avatar circle
    const avatar = figma.createEllipse();
    avatar.resize(100, 100);
    avatar.x = 190;
    avatar.y = 16;
    avatar.fills = [{ type: 'SOLID', color: hexToRgb('#eaeded') }];
    card.appendChild(avatar);

    await createText(card, tc.initials, 190, 42, { size: 36, weight: 700, color: C.textMuted, width: 100, align: 'CENTER' });
    await createText(card, tc.name, 0, 140, { size: 24, weight: 700, color: C.textDark, width: 480, align: 'CENTER' });
    await createText(card, tc.role, 0, 174, { size: 16, weight: 600, color: tc.roleColor, width: 480, align: 'CENTER' });
    await createText(card, tc.bio, 32, 210, { size: 14, weight: 400, color: C.textMuted, width: 416, align: 'CENTER' });
  }

  // Bottom text
  await createText(s12, 'El funding nos permitirá completar el equipo ejecutivo', 560, 780, { size: 16, weight: 500, color: C.textMuted, width: 800, align: 'CENTER' });

  // ════════════════════════════════════════════════════════════
  // SLIDE 13 — FINANCIEROS  (x = 24240)
  // ════════════════════════════════════════════════════════════
  const s13 = figma.createFrame();
  s13.resize(1920, 1080);
  s13.x = 24240;
  s13.y = 0;
  s13.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
  s13.name = 'Slide 13 — Financieros';
  figma.currentPage.appendChild(s13);

  await createBadge(s13, 'FINANCIEROS', 120, 60);
  await createText(s13, 'Proyección a 5 años', 120, 110, { size: 40, weight: 700, color: C.textDark, width: 1000 });

  // Bar chart baseline
  const baseline = figma.createRectangle();
  baseline.resize(1100, 2);
  baseline.x = 120;
  baseline.y = 740;
  baseline.fills = [{ type: 'SOLID', color: hexToRgb(C.border) }];
  baseline.name = 'Baseline';
  s13.appendChild(baseline);

  const bars = [
    { x: 160, h: 40, label: '$120K', year: 'Año 1' },
    { x: 370, h: 90, label: '$480K', year: 'Año 2' },
    { x: 580, h: 180, label: '$1.8M', year: 'Año 3' },
    { x: 790, h: 310, label: '$5.2M', year: 'Año 4' },
    { x: 1000, h: 440, label: '$14M', year: 'Año 5' }
  ];

  for (const b of bars) {
    const bar = figma.createRectangle();
    bar.resize(140, b.h);
    bar.x = b.x;
    bar.y = 740 - b.h;
    bar.topLeftRadius = 8;
    bar.topRightRadius = 8;
    bar.bottomLeftRadius = 0;
    bar.bottomRightRadius = 0;
    bar.fills = [{ type: 'SOLID', color: hexToRgb(C.primary) }];
    bar.name = `Bar ${b.year}`;
    s13.appendChild(bar);

    await createText(s13, b.label, b.x, 740 - b.h - 30, { size: 20, weight: 800, color: C.primary, width: 140, align: 'CENTER' });
    await createText(s13, b.year, b.x, 752, { size: 14, weight: 600, color: C.textMuted, width: 140, align: 'CENTER' });
  }

  // Unit economics cards
  const metrics = [
    { accent: C.tertiary, label: 'LTV', value: '$2,400', desc: 'Lifetime Value por cliente' },
    { accent: C.secondary, label: 'CAC', value: '$180', desc: 'Costo de adquisición' },
    { accent: C.primary, label: 'LTV/CAC', value: '13.3x', desc: 'Ratio saludable >3x' },
    { accent: C.success, label: 'Churn', value: '3%', desc: 'Mensual estimado' }
  ];

  for (let i = 0; i < metrics.length; i++) {
    const my = 300 + i * 134;
    const m = metrics[i];

    const mbg = figma.createRectangle();
    mbg.resize(460, 110);
    mbg.x = 1340;
    mbg.y = my;
    mbg.cornerRadius = 8;
    mbg.fills = [{ type: 'SOLID', color: hexToRgb(m.accent), opacity: 0.08 }];
    mbg.name = `Metric ${m.label} BG`;
    s13.appendChild(mbg);

    const mlb = figma.createRectangle();
    mlb.resize(4, 110);
    mlb.x = 1340;
    mlb.y = my;
    mlb.fills = [{ type: 'SOLID', color: hexToRgb(m.accent) }];
    mlb.name = `Metric ${m.label} Border`;
    s13.appendChild(mlb);

    await createText(s13, m.label, 1364, my + 12, { size: 14, weight: 700, color: m.accent });
    await createText(s13, m.value, 1364, my + 34, { size: 36, weight: 800, color: C.textDark });
    await createText(s13, m.desc, 1364, my + 78, { size: 14, weight: 400, color: C.textMuted });
  }

  // Footer
  await createText(s13, 'Basado en ACV $79/mes promedio, expansion revenue 15% neto, mercado base Venezuela + Colombia', 120, 840, { size: 14, weight: 400, color: C.textDimmed, width: 1680 });

  // ════════════════════════════════════════════════════════════
  // SLIDE 14 — THE ASK  (x = 26260)
  // ════════════════════════════════════════════════════════════
  const s14 = figma.createFrame();
  s14.resize(1920, 1080);
  s14.x = 26260;
  s14.y = 0;
  s14.fills = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [[0, 1, 0], [0, 0, 1]],
    gradientStops: [
      { position: 0, color: { ...hexToRgb(C.secondary), a: 1 } },
      { position: 1, color: { ...hexToRgb(C.darkest), a: 1 } }
    ]
  }];
  s14.name = 'Slide 14 — The Ask';
  figma.currentPage.appendChild(s14);

  await createBadge(s14, 'LA RONDA', 850, 60);
  await createText(s14, 'Buscamos $500K Pre-Seed', 260, 120, { size: 56, weight: 800, color: '#FFFFFF', width: 1400, align: 'CENTER' });
  await createText(s14, 'Para acelerar expansión a Colombia, México y España', 260, 200, { size: 24, weight: 400, color: C.primary, width: 1400, align: 'CENTER' });

  // Divider
  const div14 = figma.createRectangle();
  div14.resize(80, 3);
  div14.x = 920;
  div14.y = 280;
  div14.fills = [{ type: 'SOLID', color: hexToRgb(C.primary) }];
  s14.appendChild(div14);

  await createText(s14, 'Uso de fondos', 260, 310, { size: 18, weight: 600, color: C.textDimmed, width: 1400, align: 'CENTER' });

  // Fund bars
  const funds = [
    { w: 800, color: C.primary, label: '40% — Producto & Ingeniería' },
    { w: 500, color: C.tertiary, label: '25% — Ventas & Marketing' },
    { w: 400, color: C.success, label: '20% — Compliance fiscal multi-país' },
    { w: 300, color: C.textMuted, label: '15% — Operaciones & infraestructura' }
  ];

  for (let i = 0; i < funds.length; i++) {
    const fy = 360 + i * 72;
    const f = funds[i];

    const fbar = figma.createRectangle();
    fbar.resize(f.w, 56);
    fbar.x = 360;
    fbar.y = fy;
    fbar.cornerRadius = 8;
    fbar.fills = [{ type: 'SOLID', color: hexToRgb(f.color) }];
    fbar.name = `Fund ${f.label}`;
    s14.appendChild(fbar);

    await createText(s14, f.label, 384, fy + 18, { size: 18, weight: 600, color: '#FFFFFF' });
  }

  // 3 milestone cards
  const milestones = [
    { value: '500', color: C.primary, desc: 'clientes pagos\nen 18 meses', valueSize: 48 },
    { value: '3', color: C.tertiary, desc: 'países\noperativos', valueSize: 48 },
    { value: '$1.8M', color: C.success, desc: 'ARR al cierre\nde Año 3', valueSize: 40 }
  ];

  for (let i = 0; i < milestones.length; i++) {
    const mx = 360 + i * 400;
    const ms = milestones[i];

    const mcard = figma.createFrame();
    mcard.resize(360, 160);
    mcard.x = mx;
    mcard.y = 680;
    mcard.cornerRadius = 12;
    mcard.fills = [{ type: 'SOLID', color: hexToRgb(C.darkPaper) }];
    mcard.strokes = [{ type: 'SOLID', color: hexToRgb(C.primary), opacity: 0.2 }];
    mcard.strokeWeight = 1;
    mcard.clipsContent = false;
    mcard.name = `Milestone ${ms.value}`;
    s14.appendChild(mcard);

    await createText(mcard, ms.value, 0, 24, { size: ms.valueSize, weight: 800, color: ms.color, width: 360, align: 'CENTER' });
    await createText(mcard, ms.desc, 0, 84, { size: 16, weight: 400, color: C.textDimmed, width: 360, align: 'CENTER' });
  }

  // Bottom valuation
  await createText(s14, 'Valoración pre-money: $2M | SAFE note | Cierre Q2 2026', 260, 900, { size: 16, weight: 500, color: C.textMuted, width: 1400, align: 'CENTER' });

  // ════════════════════════════════════════════════════════════
  // SLIDE 15 — GRACIAS  (x = 28280)
  // ════════════════════════════════════════════════════════════
  const s15 = figma.createFrame();
  s15.resize(1920, 1080);
  s15.x = 28280;
  s15.y = 0;
  s15.fills = [{ type: 'SOLID', color: hexToRgb(C.darkest) }];
  s15.name = 'Slide 15 — Gracias';
  figma.currentPage.appendChild(s15);

  // Decorative circles
  const deco1 = figma.createEllipse();
  deco1.resize(400, 400);
  deco1.x = -100;
  deco1.y = -100;
  deco1.fills = [{ type: 'SOLID', color: hexToRgb(C.primary) }];
  deco1.opacity = 0.04;
  deco1.name = 'Deco Circle 1';
  s15.appendChild(deco1);

  const deco2 = figma.createEllipse();
  deco2.resize(300, 300);
  deco2.x = 1700;
  deco2.y = 800;
  deco2.fills = [{ type: 'SOLID', color: hexToRgb(C.primary) }];
  deco2.opacity = 0.04;
  deco2.name = 'Deco Circle 2';
  s15.appendChild(deco2);

  // Logo circle
  const logo = figma.createEllipse();
  logo.resize(100, 100);
  logo.x = 910;
  logo.y = 300;
  logo.fills = [{ type: 'SOLID', color: hexToRgb(C.primary) }];
  logo.name = 'Logo Circle';
  s15.appendChild(logo);

  await createText(s15, 'Z', 910, 318, { size: 44, weight: 800, color: '#FFFFFF', width: 100, align: 'CENTER' });

  await createText(s15, 'Gracias', 0, 440, { size: 64, weight: 800, color: '#FFFFFF', width: 1920, align: 'CENTER' });
  await createText(s15, 'Construyamos juntos el ERP de Latinoamérica', 0, 530, { size: 24, weight: 400, color: C.primary, width: 1920, align: 'CENTER' });

  // Divider
  const div15 = figma.createRectangle();
  div15.resize(80, 3);
  div15.x = 920;
  div15.y = 590;
  div15.fills = [{ type: 'SOLID', color: hexToRgb(C.primary) }];
  s15.appendChild(div15);

  // Contact info
  await createText(s15, 'zentto.net', 0, 640, { size: 22, weight: 600, color: '#FFFFFF', width: 1920, align: 'CENTER' });
  await createText(s15, 'info@zentto.net', 0, 676, { size: 18, weight: 400, color: C.textDimmed, width: 1920, align: 'CENTER' });
  await createText(s15, 'github.com/zentto-erp', 0, 708, { size: 16, weight: 400, color: C.textMuted, width: 1920, align: 'CENTER' });

  // Copyright
  await createText(s15, 'Zentto © 2026 — Plataforma empresarial modular', 0, 960, { size: 14, weight: 400, color: C.textMuted, width: 1920, align: 'CENTER' });

  figma.closePlugin('Slides 11-15 created!');
})();
