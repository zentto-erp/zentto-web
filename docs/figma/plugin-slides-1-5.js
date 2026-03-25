// Zentto Investor Deck — Slides 1-5
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
    if (opts.strokeDashes) r.dashPattern = opts.strokeDashes;
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

  function makeSlide(index, name) {
    const f = figma.createFrame();
    f.name = name;
    f.resize(1920, 1080);
    f.x = index * 2020;
    f.y = 0;
    f.clipsContent = true;
    return f;
  }

  // Preload all fonts we need
  await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Medium' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Bold' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Extra Bold' });


  // ═══════════════════════════════════════════════════════════
  // SLIDE 1 — COVER
  // ═══════════════════════════════════════════════════════════
  {
    const slide = makeSlide(0, 'Slide 1 — Cover');

    // Gradient background
    slide.fills = [{
      type: 'GRADIENT_LINEAR',
      gradientStops: [
        { color: { ...hexToRgb('#232f3e'), a: 1 }, position: 0 },
        { color: { ...hexToRgb('#131921'), a: 1 }, position: 1 }
      ],
      gradientTransform: [[1, 0, 0], [0, 1, 0]]
    }];

    // Decorative ellipse
    createCircle(slide, 1300, 700, 600, { fill: '#ff9900', opacity: 0.08, name: 'Deco ellipse' });

    // Logo circle
    createCircle(slide, 920, 280, 80, { fill: '#ff9900', name: 'Logo circle' });

    // "Z" in logo
    await createText(slide, 'Z', 942, 294, {
      weight: 800, size: 36, color: '#ffffff', name: 'Logo Z'
    });

    // "Zentto"
    await createText(slide, 'Zentto', 560, 400, {
      weight: 800, size: 72, color: '#ffffff', width: 800, align: 'CENTER', name: 'Title'
    });

    // Tagline
    await createText(slide, 'Plataforma empresarial modular\npara Latinoamérica y España', 460, 500, {
      weight: 400, size: 24, color: '#ff9900', width: 1000, align: 'CENTER', name: 'Tagline'
    });

    // Divider
    createRect(slide, 900, 580, 120, 3, { fill: '#ff9900', name: 'Divider' });

    // Round text
    await createText(slide, 'Ronda de Inversión — 2026', 560, 610, {
      weight: 500, size: 18, color: '#9CA3AF', width: 800, align: 'CENTER', name: 'Round'
    });
  }


  // ═══════════════════════════════════════════════════════════
  // SLIDE 2 — PROBLEMA
  // ═══════════════════════════════════════════════════════════
  {
    const slide = makeSlide(1, 'Slide 2 — Problema');
    slide.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];

    // Badge
    createRect(slide, 120, 80, 160, 36, {
      fill: '#ff9900', fillOpacity: 0.1, cornerRadius: 20, name: 'Badge bg'
    });
    await createText(slide, 'EL PROBLEMA', 124, 88, {
      weight: 700, size: 14, color: '#ff9900', name: 'Badge text'
    });

    // Title
    await createText(slide, 'Las PyMEs de LATAM operan con herramientas fragmentadas', 120, 140, {
      weight: 700, size: 44, color: '#0f1111', width: 900, name: 'Title'
    });

    // 3 problem cards
    const cards = [
      {
        cx: 120, iconColor: '#ff9900',
        title: 'Sistemas desconectados',
        desc: 'Excel, WhatsApp, software local sin integración. Datos duplicados, errores manuales, cero visibilidad.'
      },
      {
        cx: 640, iconColor: '#cc0c39',
        title: 'ERPs caros e inflexibles',
        desc: 'SAP, Oracle, Odoo Enterprise cuestan +$500/mes. Implementación de meses. No adaptados a fiscalidad local.'
      },
      {
        cx: 1160, iconColor: '#007185',
        title: 'Sin cumplimiento fiscal local',
        desc: 'SENIAT (VE), DIAN (CO), SAT (MX), AEAT (ES) — cada país tiene reglas distintas que ningún ERP global cubre bien.'
      }
    ];

    const cardY = 340;
    for (const card of cards) {
      createRect(slide, card.cx, cardY, 480, 300, {
        fill: '#ffffff', stroke: '#e3e6e6', cornerRadius: 12, name: 'Card ' + card.title
      });
      createCircle(slide, card.cx + 24, cardY + 24, 48, {
        fill: card.iconColor, fillOpacity: 0.15, name: 'Icon'
      });
      await createText(slide, card.title, card.cx + 24, cardY + 92, {
        weight: 600, size: 20, color: '#0f1111', name: 'Card title'
      });
      await createText(slide, card.desc, card.cx + 24, cardY + 124, {
        weight: 400, size: 16, color: '#565959', width: 432, name: 'Card desc'
      });
    }

    // Stat bar
    createRect(slide, 0, 860, 1920, 140, { fill: '#232f3e', name: 'Stat bar' });

    const stats = [
      { x: 320, num: '62M+', label: 'PyMEs en LATAM' },
      { x: 960, num: '73%', label: 'usan Excel o papel' },
      { x: 1600, num: '<5%', label: 'tienen un ERP integrado' }
    ];
    for (const s of stats) {
      await createText(slide, s.num, s.x - 60, 880, {
        weight: 800, size: 40, color: '#ff9900', width: 200, align: 'CENTER', name: 'Stat num'
      });
      await createText(slide, s.label, s.x - 60, 930, {
        weight: 400, size: 16, color: '#ffffff', width: 200, align: 'CENTER', name: 'Stat label'
      });
    }
  }


  // ═══════════════════════════════════════════════════════════
  // SLIDE 3 — SOLUCIÓN
  // ═══════════════════════════════════════════════════════════
  {
    const slide = makeSlide(2, 'Slide 3 — Solución');
    slide.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];

    // Badge
    createRect(slide, 120, 80, 160, 36, {
      fill: '#ff9900', fillOpacity: 0.1, cornerRadius: 20, name: 'Badge bg'
    });
    await createText(slide, 'LA SOLUCIÓN', 124, 88, {
      weight: 700, size: 14, color: '#ff9900', name: 'Badge text'
    });

    // Title
    await createText(slide, 'Una plataforma modular que crece con tu empresa', 120, 140, {
      weight: 700, size: 44, color: '#0f1111', width: 900, name: 'Title'
    });

    // 4 value props
    const props = [
      { title: 'Modular', desc: 'Activa solo los módulos que necesitas. Sin pagar por lo que no usas.' },
      { title: 'Multi-país', desc: 'Cumplimiento fiscal integrado: VE, CO, MX, ES, US. Facturación electrónica nativa.' },
      { title: 'Multi-tenant', desc: 'Base de datos aislada por cliente. Seguridad y privacidad total. GDPR ready.' },
      { title: 'Asequible', desc: 'Desde $29/mes para una PyME. Sin costos de implementación. Onboarding en minutos.' }
    ];

    for (let i = 0; i < props.length; i++) {
      const py = 320 + i * 90;

      // Green circle with checkmark
      createCircle(slide, 120, py, 36, { fill: '#067D62', name: 'Check circle' });
      await createText(slide, '✓', 131, py + 5, {
        weight: 700, size: 20, color: '#ffffff', name: 'Check'
      });

      // Title
      await createText(slide, props[i].title, 172, py + 4, {
        weight: 600, size: 22, color: '#0f1111', name: 'Prop title'
      });

      // Desc
      await createText(slide, props[i].desc, 172, py + 34, {
        weight: 400, size: 16, color: '#565959', width: 700, name: 'Prop desc'
      });
    }

    // Dashboard mockup
    const mx = 1080;
    const my = 280;
    createRect(slide, mx, my, 720, 560, {
      fill: '#f7f7f7', stroke: '#e3e6e6', cornerRadius: 16, name: 'Dashboard frame'
    });

    // Header bar
    const headerRect = figma.createRectangle();
    headerRect.x = mx;
    headerRect.y = my;
    headerRect.resize(720, 48);
    headerRect.fills = [{ type: 'SOLID', color: hexToRgb('#ff9900') }];
    headerRect.topLeftRadius = 16;
    headerRect.topRightRadius = 16;
    headerRect.bottomLeftRadius = 0;
    headerRect.bottomRightRadius = 0;
    headerRect.name = 'Dashboard header';
    slide.appendChild(headerRect);

    // Sidebar
    createRect(slide, mx, my + 48, 160, 512, {
      fill: '#232f3e', name: 'Dashboard sidebar'
    });

    // 4 content cards in 2x2
    const contentX = mx + 180;
    const contentY = my + 68;
    const cw = 250;
    const ch = 230;
    const cGap = 20;
    for (let row = 0; row < 2; row++) {
      for (let col = 0; col < 2; col++) {
        createRect(slide, contentX + col * (cw + cGap), contentY + row * (ch + cGap), cw, ch, {
          fill: '#ffffff', stroke: '#e3e6e6', cornerRadius: 8, name: 'Content card'
        });
      }
    }
  }


  // ═══════════════════════════════════════════════════════════
  // SLIDE 4 — PRODUCTO
  // ═══════════════════════════════════════════════════════════
  {
    const slide = makeSlide(3, 'Slide 4 — Producto');
    slide.fills = [{ type: 'SOLID', color: hexToRgb('#f8f8f8') }];

    // Badge
    createRect(slide, 120, 80, 140, 36, {
      fill: '#ff9900', fillOpacity: 0.1, cornerRadius: 20, name: 'Badge bg'
    });
    await createText(slide, 'PRODUCTO', 136, 88, {
      weight: 700, size: 14, color: '#ff9900', name: 'Badge text'
    });

    // Title
    await createText(slide, '11 módulos especializados, una sola plataforma', 120, 140, {
      weight: 700, size: 44, color: '#0f1111', width: 1200, name: 'Title'
    });

    // Module grid
    const modules = [
      // Row 1
      { name: 'Ventas', color: '#ff9900', desc: 'Facturación, cotizaciones, notas de crédito' },
      { name: 'Compras', color: '#007185', desc: 'Órdenes de compra, recepciones, cuentas por pagar' },
      { name: 'Inventario', color: '#ff9900', desc: 'Almacenes, movimientos, trazabilidad por lote' },
      { name: 'Contabilidad', color: '#232f3e', desc: 'Plan de cuentas, asientos, balances' },
      // Row 2
      { name: 'Bancos', color: '#007185', desc: 'Conciliación bancaria, flujo de caja' },
      { name: 'Nómina', color: '#067D62', desc: 'Cálculo de nómina, recibos, prestaciones' },
      { name: 'POS', color: '#ff9900', desc: 'Punto de venta táctil, turnos, arqueos' },
      { name: 'Restaurante', color: '#cc0c39', desc: 'Mesas, comandas, cocina en tiempo real' },
      // Row 3
      { name: 'Ecommerce', color: '#007185', desc: 'Tienda online, catálogo, pasarelas de pago' },
      { name: 'Auditoría', color: '#232f3e', desc: 'Trazabilidad completa, logs, cumplimiento' },
      { name: 'CRM', color: '#067D62', desc: 'Contactos, oportunidades, pipeline de ventas' },
      { name: '+5 más', color: null, desc: 'Flota, Logística, Manufactura, Lab, Shipping', dashed: true }
    ];

    const gridStartY = 280;
    const cardW = 380;
    const cardH = 180;
    const gap = 24;

    for (let i = 0; i < modules.length; i++) {
      const col = i % 4;
      const row = Math.floor(i / 4);
      const cx = 120 + col * (cardW + gap);
      const cy = gridStartY + row * (cardH + gap);
      const mod = modules[i];

      if (mod.dashed) {
        // Dashed border card
        createRect(slide, cx, cy, cardW, cardH, {
          fill: '#ffffff', stroke: '#e3e6e6', cornerRadius: 12,
          strokeDashes: [8, 4], name: 'Card +5'
        });
      } else {
        createRect(slide, cx, cy, cardW, cardH, {
          fill: '#ffffff', stroke: '#e3e6e6', cornerRadius: 12, name: 'Card ' + mod.name
        });
      }

      // Color circle
      if (mod.color) {
        createCircle(slide, cx + 24, cy + 24, 40, {
          fill: mod.color, fillOpacity: 0.2, name: 'Icon ' + mod.name
        });
      } else {
        // For "+5 más", use a muted circle
        createCircle(slide, cx + 24, cy + 24, 40, {
          fill: '#9CA3AF', fillOpacity: 0.15, name: 'Icon +5'
        });
      }

      // Module name
      await createText(slide, mod.name, cx + 76, cy + 30, {
        weight: 600, size: 18, color: '#0f1111', name: 'Mod name'
      });

      // Description
      await createText(slide, mod.desc, cx + 24, cy + 80, {
        weight: 400, size: 13, color: '#565959', width: cardW - 48, name: 'Mod desc'
      });
    }
  }


  // ═══════════════════════════════════════════════════════════
  // SLIDE 5 — ARQUITECTURA
  // ═══════════════════════════════════════════════════════════
  {
    const slide = makeSlide(4, 'Slide 5 — Arquitectura');
    slide.fills = [{ type: 'SOLID', color: hexToRgb('#131921') }];

    // Badge
    createRect(slide, 120, 80, 190, 36, {
      fill: '#ff9900', fillOpacity: 0.15, cornerRadius: 20, name: 'Badge bg'
    });
    await createText(slide, 'ARQUITECTURA', 132, 88, {
      weight: 700, size: 14, color: '#ff9900', name: 'Badge text'
    });

    // Title
    await createText(slide, 'Micro-frontends + API unificada + Dual Database', 120, 140, {
      weight: 700, size: 36, color: '#ffffff', width: 1200, name: 'Title'
    });

    // Top layer — Micro-frontends
    createRect(slide, 360, 260, 1200, 80, {
      fill: '#ff9900', fillOpacity: 0.15, stroke: '#ff9900', cornerRadius: 12, name: 'Layer frontends'
    });
    await createText(slide, '11 Micro-frontends (Next.js)', 360, 286, {
      weight: 600, size: 20, color: '#ff9900', width: 1200, align: 'CENTER', name: 'Layer text'
    });

    // Arrow down
    createRect(slide, 940, 350, 40, 20, {
      fill: '#ff9900', fillOpacity: 0.4, cornerRadius: 4, name: 'Arrow down'
    });

    // Mid layer — API
    createRect(slide, 510, 380, 900, 80, {
      fill: '#007185', fillOpacity: 0.2, stroke: '#007185', cornerRadius: 12, name: 'Layer API'
    });
    await createText(slide, 'API REST — Node.js / Express / TypeScript', 510, 406, {
      weight: 600, size: 18, color: '#007185', width: 900, align: 'CENTER', name: 'API text'
    });

    // Arrow down to DBs
    createRect(slide, 940, 470, 40, 20, {
      fill: '#565959', fillOpacity: 0.4, cornerRadius: 4, name: 'Arrow down 2'
    });

    // Bottom left — SQL Server
    createRect(slide, 470, 520, 380, 70, {
      fill: '#232f3e', stroke: '#565959', cornerRadius: 8, name: 'SQL Server box'
    });
    await createText(slide, 'SQL Server', 470, 542, {
      weight: 600, size: 18, color: '#ffffff', width: 380, align: 'CENTER', name: 'SQL Server text'
    });

    // Bottom right — PostgreSQL
    createRect(slide, 1070, 520, 380, 70, {
      fill: '#232f3e', stroke: '#067D62', cornerRadius: 8, name: 'PostgreSQL box'
    });
    await createText(slide, 'PostgreSQL', 1070, 542, {
      weight: 600, size: 18, color: '#ffffff', width: 380, align: 'CENTER', name: 'PostgreSQL text'
    });

    // Left satellite — Zentto Notify
    createRect(slide, 80, 390, 220, 60, {
      fill: '#232f3e', stroke: '#ff9900', strokeDashes: [6, 4], cornerRadius: 8, name: 'Zentto Notify'
    });
    await createText(slide, 'Zentto Notify', 80, 410, {
      weight: 500, size: 16, color: '#ff9900', width: 220, align: 'CENTER', name: 'Notify text'
    });

    // Right satellite — Fiscal Agent
    createRect(slide, 1620, 390, 220, 60, {
      fill: '#232f3e', stroke: '#007185', strokeDashes: [6, 4], cornerRadius: 8, name: 'Fiscal Agent'
    });
    await createText(slide, 'Fiscal Agent', 1620, 410, {
      weight: 500, size: 16, color: '#007185', width: 220, align: 'CENTER', name: 'Fiscal text'
    });

    // 3 infra pills at y=680
    const pills = ['Docker + CI/CD', 'Hetzner Cloud', 'Cloudflare CDN'];
    const pillW = 180;
    const pillGap = 40;
    const pillTotalW = pills.length * pillW + (pills.length - 1) * pillGap;
    const pillStartX = (1920 - pillTotalW) / 2;

    for (let i = 0; i < pills.length; i++) {
      const px = pillStartX + i * (pillW + pillGap);
      createRect(slide, px, 680, pillW, 40, {
        stroke: '#565959', cornerRadius: 20, name: 'Pill ' + pills[i]
      });
      await createText(slide, pills[i], px, 690, {
        weight: 500, size: 14, color: '#9CA3AF', width: pillW, align: 'CENTER', name: 'Pill text'
      });
    }

    // 4 stat boxes at y=800
    const statData = [
      { num: '188+', label: 'Stored Procedures' },
      { num: '17', label: 'Apps desplegadas' },
      { num: '99.9%', label: 'Uptime' },
      { num: '< 200ms', label: 'API Response' }
    ];
    const statW = 300;
    const statH = 100;
    const statGap = 40;
    const statTotalW = statData.length * statW + (statData.length - 1) * statGap;
    const statStartX = (1920 - statTotalW) / 2;

    for (let i = 0; i < statData.length; i++) {
      const sx = statStartX + i * (statW + statGap);
      createRect(slide, sx, 800, statW, statH, {
        fill: '#1a2332', stroke: '#565959', cornerRadius: 12, name: 'Stat box'
      });
      await createText(slide, statData[i].num, sx, 818, {
        weight: 800, size: 28, color: '#ff9900', width: statW, align: 'CENTER', name: 'Stat num'
      });
      await createText(slide, statData[i].label, sx, 856, {
        weight: 400, size: 14, color: '#9CA3AF', width: statW, align: 'CENTER', name: 'Stat label'
      });
    }
  }

  figma.closePlugin('Done! 5 slides created.');

})();
