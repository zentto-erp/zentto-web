// Zentto POS Screens — Screen 4 (Facturacion) + Screen 5 (Pago)
// Paste into: Figma > Plugins > Development > New Plugin > Run once
// Frames 1440x900 at y=2000, starting x=4620

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
    darkPaper: '#1a2332',
    bgPage: '#eaeded'
  };

  // ─── Preload fonts ─────────────────────────────────────────

  await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Medium' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Bold' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Extra Bold' });

  // ─── Sidebar helper ────────────────────────────────────────

  async function createSidebar(frame, activeIndex) {
    // Sidebar background
    createRect(frame, 0, 0, 72, 900, { fill: C.darkest, name: 'Sidebar' });

    // Logo circle
    createCircle(frame, 16, 16, 40, { fill: C.primary });
    await createText(frame, 'Z', 28, 24, { size: 20, weight: 700, color: '#ffffff' });

    // Nav icons (simple circles as placeholders)
    const navIcons = ['Dashboard', 'Ventas', 'Inventario', 'POS', 'Reportes', 'Config'];
    for (let i = 0; i < navIcons.length; i++) {
      const iy = 100 + i * 56;

      // Active indicator (left border)
      if (i === activeIndex) {
        createRect(frame, 0, iy, 3, 40, { fill: C.primary, name: 'Active indicator' });
      }

      // Icon placeholder circle
      createCircle(frame, 20, iy + 4, 32, {
        fill: i === activeIndex ? C.primary : '#2a3a4e',
        fillOpacity: i === activeIndex ? 0.2 : 1,
        name: navIcons[i]
      });
      await createText(frame, navIcons[i].substring(0, 2).toUpperCase(), 26, iy + 12, {
        size: 11, weight: 600, color: i === activeIndex ? C.primary : '#8899aa'
      });
    }

    // Avatar at bottom
    createCircle(frame, 16, 844, 40, { fill: '#2a3a4e', name: 'Avatar' });
    await createText(frame, 'RG', 26, 854, { size: 13, weight: 600, color: '#8899aa' });
  }

  // ═══════════════════════════════════════════════════════════
  // SCREEN 4 — POS MAIN (FACTURACION)
  // ═══════════════════════════════════════════════════════════
  {
    const frame = figma.createFrame();
    frame.name = 'Screen — POS Facturación';
    frame.resize(1440, 900);
    frame.x = 4620;
    frame.y = 2000;
    frame.clipsContent = true;
    frame.fills = [{ type: 'SOLID', color: hexToRgb('#ffffff') }];

    // ─── Sidebar (collapsed) ───
    await createSidebar(frame, 3); // POS is 4th (index 3)

    // ─── Header bar ───
    createRect(frame, 72, 0, 1368, 56, { fill: '#ffffff', name: 'Header bar' });
    createRect(frame, 72, 55, 1368, 1, { fill: C.border, name: 'Header border' });

    await createText(frame, 'Caja Principal', 92, 18, { size: 16, weight: 700, color: C.textDark });
    await createText(frame, '>', 218, 18, { size: 14, weight: 400, color: C.textMuted });
    await createText(frame, 'Alimentos', 232, 18, { size: 14, weight: 600, color: C.primary });

    // Search input
    createRect(frame, 472, 10, 250, 36, {
      fill: '#f8f8f8', stroke: C.border, cornerRadius: 8, name: 'Search input'
    });
    await createText(frame, 'Buscar producto...', 484, 19, { size: 14, weight: 400, color: C.textDimmed });

    // Fiscal OK chip
    createRect(frame, 1292, 14, 90, 28, {
      fill: C.success, fillOpacity: 0.1, cornerRadius: 14, name: 'Fiscal chip'
    });
    await createText(frame, 'Fiscal OK', 1306, 20, { size: 12, weight: 600, color: C.success });

    // ─── Category tabs ───
    createRect(frame, 72, 56, 1368, 44, { fill: '#f8f8f8', name: 'Category bar' });
    createRect(frame, 72, 99, 1368, 1, { fill: C.border, name: 'Category border' });

    const categories = ['Todos', 'Alimentos', 'Bebidas', 'Postres', 'Combos', 'Otros'];
    let catX = 88;
    for (let i = 0; i < categories.length; i++) {
      const isActive = i === 0;
      const catW = categories[i].length * 9 + 28;
      createRect(frame, catX, 62, catW, 32, {
        fill: isActive ? C.primary : '#ffffff',
        stroke: isActive ? undefined : C.border,
        cornerRadius: 16,
        name: 'Cat ' + categories[i]
      });
      await createText(frame, categories[i], catX + 14, 69, {
        size: 13, weight: isActive ? 600 : 400, color: isActive ? '#ffffff' : C.textMuted
      });
      catX += catW + 8;
    }

    // Pagination arrows
    await createText(frame, '<  >', 1380, 69, { size: 14, weight: 400, color: C.textMuted });

    // ─── Product grid ───
    createRect(frame, 72, 100, 920, 800, { fill: '#ffffff', name: 'Product grid area' });

    const products = [
      { name: 'Hamburguesa Clásica', price: '$8.50', code: 'P001' },
      { name: 'Pizza Margherita', price: '$12.00', code: 'P002' },
      { name: 'Ensalada César', price: '$7.50', code: 'P003' },
      { name: 'Pasta Alfredo', price: '$10.00', code: 'P004' },
      { name: 'Pollo a la Plancha', price: '$9.00', code: 'P005' },
      { name: 'Tacos (3 uds)', price: '$6.50', code: 'P006' },
      { name: 'Sushi Roll', price: '$14.00', code: 'P007' },
      { name: 'Wrap Vegetal', price: '$7.00', code: 'P008' }
    ];

    for (let i = 0; i < products.length; i++) {
      const col = i % 4;
      const row = Math.floor(i / 4);
      const px = 84 + col * 228;
      const py = 112 + row * 168;
      const p = products[i];

      // Card
      createRect(frame, px, py, 220, 160, {
        fill: '#ffffff', stroke: C.border, cornerRadius: 8, name: 'Card ' + p.name
      });

      // Image placeholder
      createRect(frame, px, py, 220, 90, {
        fill: '#f0f0f0', cornerRadius: 8, name: 'Image ' + p.code
      });
      // Fix top-only radius by overlaying bottom portion
      createRect(frame, px, py + 80, 220, 10, { fill: '#f0f0f0' });

      // Product code
      await createText(frame, p.code, px + 85, py + 35, {
        size: 12, weight: 400, color: C.textDimmed, align: 'CENTER'
      });

      // Product name
      await createText(frame, p.name, px + 8, py + 100, {
        size: 13, weight: 600, color: C.textDark, width: 204
      });

      // Price
      await createText(frame, p.price, px + 8, py + 130, {
        size: 16, weight: 700, color: C.primary
      });
    }

    // ─── Cart panel ───
    createRect(frame, 992, 100, 448, 800, { fill: '#ffffff', name: 'Cart panel' });
    createRect(frame, 992, 100, 1, 800, { fill: C.border, name: 'Cart left border' });

    // Pedido Actual title
    await createText(frame, 'Pedido Actual', 1012, 116, { size: 18, weight: 700, color: C.textDark });

    // Cart item 1 (selected - light orange bg)
    createRect(frame, 992, 150, 448, 60, { fill: '#fff8ee', name: 'Cart item 1' });
    await createText(frame, '1 × Hamburguesa Clásica', 1012, 154, { size: 14, weight: 600, color: C.textDark });
    await createText(frame, '$8.50', 1380, 154, { size: 14, weight: 400, color: C.textDark, align: 'RIGHT' });

    // Cart item 2
    createRect(frame, 992, 210, 448, 60, { fill: '#ffffff', name: 'Cart item 2' });
    await createText(frame, '2 × Pizza Margherita', 1012, 214, { size: 14, weight: 600, color: C.textDark });
    await createText(frame, '$24.00', 1380, 214, { size: 14, weight: 400, color: C.textDark, align: 'RIGHT' });

    // Cart item 3
    createRect(frame, 992, 270, 448, 60, { fill: '#f8f8f8', name: 'Cart item 3' });
    await createText(frame, '1 × Ensalada César', 1012, 274, { size: 14, weight: 600, color: C.textDark });
    await createText(frame, '$7.50', 1380, 274, { size: 14, weight: 400, color: C.textDark, align: 'RIGHT' });

    // Separator
    createRect(frame, 1012, 340, 408, 1, { fill: C.border, name: 'Separator' });

    // Totals
    await createText(frame, 'Subtotal', 1012, 360, { size: 14, weight: 400, color: C.textMuted });
    await createText(frame, '$40.00', 1380, 360, { size: 14, weight: 400, color: C.textDark, align: 'RIGHT' });

    await createText(frame, 'IVA (16%)', 1012, 384, { size: 14, weight: 400, color: C.textMuted });
    await createText(frame, '$6.40', 1380, 384, { size: 14, weight: 400, color: C.textDark, align: 'RIGHT' });

    // Separator
    createRect(frame, 1012, 410, 408, 1, { fill: C.border, name: 'Separator 2' });

    // TOTAL
    await createText(frame, 'TOTAL', 1012, 420, { size: 20, weight: 700, color: C.textDark });
    await createText(frame, '$46.40', 1340, 416, { size: 24, weight: 800, color: C.primary, align: 'RIGHT' });

    // Ref line
    await createText(frame, 'Ref: $3,712.00 (Bs. 80.00)', 1012, 455, { size: 12, weight: 400, color: C.textMuted });

    // ─── Numpad ───
    const numpadX = 1012;
    const numpadY = 500;
    const numKeys = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['±', '0', '.']
    ];

    for (let row = 0; row < numKeys.length; row++) {
      for (let col = 0; col < numKeys[row].length; col++) {
        const kx = numpadX + col * 94;
        const ky = numpadY + row * 54;
        createRect(frame, kx, ky, 90, 50, {
          fill: '#f8f8f8', stroke: C.border, cornerRadius: 8, name: 'Key ' + numKeys[row][col]
        });
        await createText(frame, numKeys[row][col], kx + 35, ky + 13, {
          size: 20, weight: 600, color: C.textDark, align: 'CENTER'
        });
      }
    }

    // Right column mode buttons
    const modeButtons = [
      { label: 'Cant', active: true },
      { label: '%Desc', active: false },
      { label: 'Precio', active: false }
    ];
    for (let i = 0; i < modeButtons.length; i++) {
      const mb = modeButtons[i];
      const mbY = numpadY + i * 54;
      const mbX = numpadX + 3 * 94;
      createRect(frame, mbX, mbY, 90, 50, {
        fill: mb.active ? C.primary : '#f8f8f8',
        fillOpacity: mb.active ? 0.15 : 1,
        stroke: mb.active ? undefined : C.border,
        cornerRadius: 8,
        name: 'Mode ' + mb.label
      });
      await createText(frame, mb.label, mbX + 20, mbY + 14, {
        size: 14, weight: 600, color: mb.active ? C.primary : C.textMuted
      });
    }

    // ─── Action buttons row ───
    const actionY = 730;
    const actionButtons = ['Reembolso', 'Nota', 'Código'];
    for (let i = 0; i < actionButtons.length; i++) {
      const ax = 1012 + i * 138;
      createRect(frame, ax, actionY, 130, 44, {
        fill: '#ffffff', stroke: C.border, cornerRadius: 8, name: 'Action ' + actionButtons[i]
      });
      await createText(frame, actionButtons[i], ax + 25, actionY + 13, {
        size: 13, weight: 400, color: C.textMuted, align: 'CENTER'
      });
    }

    // ─── PAY button ───
    createRect(frame, 1012, 790, 408, 50, {
      fill: C.primary, cornerRadius: 24, name: 'Pay button'
    });
    await createText(frame, 'Cobrar $46.40', 1145, 804, {
      size: 18, weight: 700, color: '#ffffff', align: 'CENTER'
    });

    figma.currentPage.appendChild(frame);
  }

  // ═══════════════════════════════════════════════════════════
  // SCREEN 5 — POS PAYMENT MODAL
  // ═══════════════════════════════════════════════════════════
  {
    const frame = figma.createFrame();
    frame.name = 'Screen — POS Pago';
    frame.resize(1440, 900);
    frame.x = 6160;
    frame.y = 2000;
    frame.clipsContent = true;
    frame.fills = [{ type: 'SOLID', color: hexToRgb('#ffffff') }];

    // ─── Dimmed overlay ───
    createRect(frame, 0, 0, 1440, 900, {
      fill: C.darkest, fillOpacity: 0.5, name: 'Overlay dimmed'
    });

    // ─── Payment modal ───
    const modalX = 170;
    const modalY = 50;

    createRect(frame, modalX, modalY, 1100, 800, {
      fill: '#ffffff', cornerRadius: 16, name: 'Payment modal'
    });

    // ═══ Left panel (summary) ═══
    const lpX = modalX;
    const lpY = modalY;

    await createText(frame, 'Resumen de compra', lpX + 30, lpY + 24, {
      size: 20, weight: 700, color: C.textDark
    });

    // Separator
    createRect(frame, lpX + 30, lpY + 60, 390, 1, { fill: C.border, name: 'Summary separator' });

    // Items list
    const items = [
      { label: '1 × Hamburguesa Clásica', price: '$8.50' },
      { label: '2 × Pizza Margherita', price: '$24.00' },
      { label: '1 × Ensalada César', price: '$7.50' }
    ];

    for (let i = 0; i < items.length; i++) {
      const iy = lpY + 70 + i * 36;
      await createText(frame, items[i].label, lpX + 30, iy, {
        size: 14, weight: 400, color: C.textDark
      });
      await createText(frame, items[i].price, lpX + 380, iy, {
        size: 14, weight: 400, color: C.textDark, align: 'RIGHT'
      });
    }

    // Separator
    createRect(frame, lpX + 30, lpY + 200, 390, 1, { fill: C.border, name: 'Items separator' });

    // Totals
    const totals = [
      { label: 'Subtotal Base', value: '$40.00' },
      { label: 'IVA (16%)', value: '$6.40' },
      { label: 'IGTF (3%)', value: '$1.39' }
    ];
    for (let i = 0; i < totals.length; i++) {
      const ty = lpY + 210 + i * 24;
      await createText(frame, totals[i].label, lpX + 30, ty, {
        size: 14, weight: 400, color: C.textMuted
      });
      await createText(frame, totals[i].value, lpX + 380, ty, {
        size: 14, weight: 400, color: C.textDark, align: 'RIGHT'
      });
    }

    // Separator before total
    createRect(frame, lpX + 30, lpY + 285, 390, 1, { fill: C.border, name: 'Total separator' });

    // TOTAL A PAGAR
    await createText(frame, 'TOTAL A PAGAR', lpX + 30, lpY + 295, {
      size: 18, weight: 700, color: C.textDark
    });
    await createText(frame, '$47.79', lpX + 340, lpY + 290, {
      size: 24, weight: 800, color: C.primary, align: 'RIGHT'
    });

    // Ref line
    await createText(frame, 'Ref: $3,823.20 (Bs. 80.00)', lpX + 30, lpY + 330, {
      size: 13, weight: 400, color: C.textMuted
    });

    // Client section
    await createText(frame, 'Cliente:', lpX + 30, lpY + 380, {
      size: 14, weight: 400, color: C.textMuted
    });
    await createText(frame, 'Consumidor Final', lpX + 100, lpY + 380, {
      size: 14, weight: 600, color: C.textDark
    });

    // ═══ Right panel (payment methods) ═══
    const rpX = modalX + 450;
    const rpY = modalY;

    // Right panel background
    createRect(frame, rpX, rpY, 650, 800, {
      fill: '#f8f8f8', cornerRadius: 16, name: 'Right panel'
    });
    // Fix left corners (should be square where it meets left panel)
    createRect(frame, rpX, rpY, 16, 800, { fill: '#f8f8f8' });

    // Left border line
    createRect(frame, rpX, rpY, 1, 800, { fill: C.border, name: 'Right panel border' });

    // Payment method tabs
    const payTabs = [
      { label: 'Efectivo', active: true },
      { label: 'Divisas', active: false },
      { label: 'Punto', active: false },
      { label: 'P. Móvil', active: false },
      { label: 'Transfer.', active: false },
      { label: 'QR', active: false }
    ];
    let tabX = rpX + 20;
    for (let i = 0; i < payTabs.length; i++) {
      const tab = payTabs[i];
      const tabW = tab.label.length * 8 + 24;
      createRect(frame, tabX, rpY + 16, tabW, 32, {
        fill: tab.active ? C.success : '#ffffff',
        stroke: tab.active ? undefined : C.border,
        cornerRadius: 16,
        name: 'Tab ' + tab.label
      });
      await createText(frame, tab.label, tabX + 12, rpY + 24, {
        size: 12, weight: 600, color: tab.active ? '#ffffff' : C.textMuted
      });
      tabX += tabW + 6;
    }

    // Amount input
    await createText(frame, 'Monto', rpX + 20, rpY + 70, {
      size: 14, weight: 400, color: C.textMuted
    });
    createRect(frame, rpX + 20, rpY + 90, 600, 48, {
      fill: '#ffffff', stroke: C.border, cornerRadius: 8, name: 'Amount input'
    });
    await createText(frame, '$', rpX + 32, rpY + 102, {
      size: 16, weight: 400, color: C.textMuted
    });
    await createText(frame, '47.79', rpX + 52, rpY + 102, {
      size: 16, weight: 400, color: C.textDark
    });

    // Agregar Pago button
    createRect(frame, rpX + 20, rpY + 152, 600, 44, {
      fill: C.success, cornerRadius: 8, name: 'Add payment btn'
    });
    await createText(frame, 'Agregar Pago', rpX + 260, rpY + 164, {
      size: 15, weight: 600, color: '#ffffff', align: 'CENTER'
    });

    // Payments list
    await createText(frame, 'Pagos realizados', rpX + 20, rpY + 220, {
      size: 14, weight: 600, color: C.textDark
    });

    // Payment 1 row
    createRect(frame, rpX + 20, rpY + 244, 600, 44, {
      fill: '#ffffff', stroke: C.border, cornerRadius: 8, name: 'Payment 1'
    });
    await createText(frame, 'Efectivo', rpX + 32, rpY + 256, {
      size: 14, weight: 400, color: C.textDark
    });
    await createText(frame, '$47.79', rpX + 540, rpY + 256, {
      size: 14, weight: 600, color: C.textDark, align: 'RIGHT'
    });
    await createText(frame, '×', rpX + 596, rpY + 256, {
      size: 14, weight: 400, color: C.textMuted
    });

    // Summary box
    createRect(frame, rpX + 20, rpY + 320, 600, 100, {
      fill: '#ffffff', stroke: C.border, cornerRadius: 8, name: 'Summary box'
    });
    // Pagado
    await createText(frame, 'Pagado:', rpX + 32, rpY + 336, {
      size: 14, weight: 400, color: C.textMuted
    });
    await createText(frame, '$47.79', rpX + 540, rpY + 336, {
      size: 14, weight: 600, color: C.success, align: 'RIGHT'
    });
    // Restante
    await createText(frame, 'Restante:', rpX + 32, rpY + 360, {
      size: 14, weight: 400, color: C.textMuted
    });
    await createText(frame, '$0.00', rpX + 540, rpY + 360, {
      size: 14, weight: 600, color: C.success, align: 'RIGHT'
    });
    // Cambio
    await createText(frame, 'Cambio:', rpX + 32, rpY + 384, {
      size: 14, weight: 400, color: C.textMuted
    });
    await createText(frame, '$0.00', rpX + 540, rpY + 384, {
      size: 14, weight: 600, color: C.primary, align: 'RIGHT'
    });

    // Facturar e Imprimir button
    createRect(frame, rpX + 20, rpY + 450, 600, 52, {
      fill: C.primary, cornerRadius: 24, name: 'Submit btn'
    });
    await createText(frame, 'Facturar e Imprimir', rpX + 245, rpY + 466, {
      size: 16, weight: 700, color: '#ffffff', align: 'CENTER'
    });

    // Cancel button
    createRect(frame, rpX + 20, rpY + 520, 600, 44, {
      fill: '#ffffff', stroke: C.border, cornerRadius: 8, name: 'Cancel btn'
    });
    await createText(frame, 'Cancelar', rpX + 280, rpY + 532, {
      size: 14, weight: 400, color: C.textMuted, align: 'CENTER'
    });

    figma.currentPage.appendChild(frame);
  }

  figma.closePlugin();

})();
