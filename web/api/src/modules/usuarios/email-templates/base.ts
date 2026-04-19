// Templates de email Zentto — HTML puro, sin dependencias externas
// Cumple: CAN-SPAM Act, GDPR, Ley de Protección de Datos

const BRAND = {
  name: "Zentto",
  legalName: "Zentto ERP, C.A.",
  url: "https://zentto.net",
  appUrl: "https://app.zentto.net",
  color: "#6C63FF",
  colorSecondary: "#FF6584",
  supportEmail: "soporte@zentto.net",
  privacyUrl: "https://zentto.net/privacidad",
  termsUrl: "https://zentto.net/terminos-y-condiciones",
  unsubscribeUrl: "https://app.zentto.net/settings/notifications",
  address: "Zentto ERP — zentto.net",
  year: new Date().getFullYear(),
};

interface LayoutOptions {
  preheader?: string;
  reason?: string;       // Por qué recibe este email
  unsubscribe?: boolean; // Mostrar link de unsub (default: true)
  transactional?: boolean; // Email transaccional (no marketing)
}

function layout(content: string, opts: LayoutOptions = {}) {
  const {
    preheader = "",
    reason = "Recibes este correo porque tienes una cuenta en Zentto.",
    unsubscribe = true,
    transactional = false,
  } = opts;

  const unsubSection = unsubscribe ? `
      <p style="margin-top:16px">
        <a href="${BRAND.unsubscribeUrl}" style="color:#9b9bb0;text-decoration:underline;font-size:11px">Gestionar preferencias de notificación</a>
        ${!transactional ? ` &middot; <a href="${BRAND.unsubscribeUrl}?action=unsubscribe" style="color:#9b9bb0;text-decoration:underline;font-size:11px">Cancelar suscripción</a>` : ""}
      </p>` : "";

  return `<!DOCTYPE html>
<html lang="es" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light dark">
<meta name="supported-color-schemes" content="light dark">
<title>${BRAND.name}</title>
<!--[if mso]><style>table,td{font-family:Arial,sans-serif!important}</style><![endif]-->
<style>
  body{margin:0;padding:0;background:#f4f4f7;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;-webkit-text-size-adjust:100%}
  .container{max-width:580px;margin:0 auto;padding:20px}
  .card{background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.06)}
  .header{background:linear-gradient(135deg,${BRAND.color},${BRAND.colorSecondary});padding:32px 40px;text-align:center}
  .header h1{margin:0;color:#ffffff;font-size:28px;font-weight:800;letter-spacing:-0.5px}
  .header .dot{display:inline-block;width:8px;height:8px;border-radius:50%;background:#ffffff;margin-left:2px;vertical-align:super}
  .body{padding:40px}
  .body h2{margin:0 0 8px;color:#1a1a2e;font-size:22px;font-weight:700}
  .body p{margin:0 0 16px;color:#4a4a68;font-size:15px;line-height:1.65}
  .btn{display:inline-block;background:${BRAND.color};color:#ffffff!important;text-decoration:none;font-weight:700;font-size:15px;padding:14px 32px;border-radius:12px;margin:8px 0 24px}
  .btn:hover{background:#5b54e6}
  .divider{height:1px;background:#e8e8ef;margin:24px 0}
  .info-box{background:#f8f8fc;border:1px solid #e8e8ef;border-radius:12px;padding:20px;margin:16px 0}
  .info-box p{margin:0 0 4px;font-size:13px;color:#6b6b80}
  .info-box strong{color:#1a1a2e}
  .footer{padding:24px 40px;text-align:center;border-top:1px solid #f0f0f5}
  .footer p{margin:0 0 8px;color:#9b9bb0;font-size:11px;line-height:1.5}
  .footer a{color:${BRAND.color};text-decoration:none}
  .legal{font-size:10px;color:#b0b0c8;line-height:1.4;margin-top:16px}
  @media(prefers-color-scheme:dark){
    body{background:#1a1a2e!important}
    .card{background:#0a0a0e!important;box-shadow:0 4px 24px rgba(0,0,0,0.3)!important}
    .body h2{color:#ffffff!important}
    .body p{color:#b0b0c8!important}
    .info-box{background:rgba(108,99,255,0.08)!important;border-color:rgba(108,99,255,0.2)!important}
    .info-box strong{color:#ffffff!important}
    .footer{border-top-color:rgba(255,255,255,0.05)!important}
  }
</style>
</head>
<body>
${preheader ? `<div style="display:none;max-height:0;overflow:hidden;mso-hide:all">${preheader}${"&nbsp;".repeat(80)}</div>` : ""}
<div class="container">
  <div class="card">
    <div class="header">
      <h1>${BRAND.name}<span class="dot"></span></h1>
    </div>
    <div class="body">
      ${content}
    </div>
    <div class="footer">
      <p><a href="${BRAND.url}">zentto.net</a> &middot; <a href="${BRAND.appUrl}">Acceder a la app</a> &middot; <a href="${BRAND.privacyUrl}">Privacidad</a> &middot; <a href="${BRAND.termsUrl}">Términos</a></p>
      <p>ERP SaaS para PYMEs latinoamericanas<br>Facturación &middot; Contabilidad &middot; Inventario &middot; Nómina &middot; POS &middot; Ecommerce</p>
      <p>&copy; ${BRAND.year} ${BRAND.legalName}. Todos los derechos reservados.</p>
      <p><a href="mailto:${BRAND.supportEmail}">${BRAND.supportEmail}</a></p>
      ${unsubSection}
      <div class="legal">
        <p>${reason}</p>
        <p>${BRAND.legalName} &middot; ${BRAND.address}</p>
        ${!transactional ? `<p>Si no deseas recibir más correos de este tipo, puedes <a href="${BRAND.unsubscribeUrl}?action=unsubscribe" style="color:#9b9bb0;text-decoration:underline">cancelar tu suscripción</a> en cualquier momento.</p>` : ""}
      </div>
    </div>
  </div>
</div>
</body>
</html>`;
}

function escapeHtml(str: string): string {
  return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

// ─── Templates ─────────────────────────────────────────

export function verifyEmailTemplate(userCode: string, verificationUrl: string) {
  const subject = "Confirma tu cuenta — Zentto";
  const text = `Hola ${userCode}, confirma tu cuenta en Zentto: ${verificationUrl}\n\nSi no solicitaste este registro, ignora este mensaje.\n\n${BRAND.legalName} — ${BRAND.url}`;
  const html = layout(`
    <h2>Confirma tu cuenta</h2>
    <p>Hola <strong>${escapeHtml(userCode)}</strong>,</p>
    <p>Gracias por registrarte en Zentto. Para activar tu cuenta y comenzar tu prueba gratuita de 30 días, confirma tu dirección de correo electrónico:</p>
    <p style="text-align:center">
      <a href="${verificationUrl}" class="btn">Confirmar mi cuenta</a>
    </p>
    <div class="info-box">
      <p>Si el botón no funciona, copia y pega este enlace en tu navegador:</p>
      <p style="word-break:break-all;color:${BRAND.color};font-size:12px">${verificationUrl}</p>
    </div>
    <div class="divider"></div>
    <p style="font-size:13px;color:#9b9bb0">Este enlace expira en 24 horas. Si no solicitaste este registro, puedes ignorar este mensaje de forma segura.</p>
  `, {
    preheader: "Confirma tu cuenta en Zentto para comenzar tu prueba gratuita",
    reason: "Recibes este correo porque alguien usó esta dirección para registrarse en Zentto. Si no fuiste tú, ignóralo.",
    transactional: true,
  });

  return { subject, text, html };
}

export function resetPasswordTemplate(userCode: string, resetUrl: string) {
  const subject = "Restablecer contraseña — Zentto";
  const text = `Hola ${userCode}, restablece tu contraseña en Zentto: ${resetUrl}\n\nSi no lo solicitaste, ignora este correo.\n\n${BRAND.legalName} — ${BRAND.url}`;
  const html = layout(`
    <h2>Restablecer contraseña</h2>
    <p>Hola <strong>${escapeHtml(userCode)}</strong>,</p>
    <p>Recibimos una solicitud para restablecer la contraseña de tu cuenta en Zentto. Haz clic en el siguiente botón para crear una nueva contraseña:</p>
    <p style="text-align:center">
      <a href="${resetUrl}" class="btn">Restablecer contraseña</a>
    </p>
    <div class="info-box">
      <p>Si el botón no funciona, copia y pega este enlace:</p>
      <p style="word-break:break-all;color:${BRAND.color};font-size:12px">${resetUrl}</p>
    </div>
    <div class="divider"></div>
    <p style="font-size:13px;color:#9b9bb0">Este enlace expira en 30 minutos. Si no solicitaste este cambio, ignora este correo — tu contraseña actual seguirá siendo la misma.</p>
  `, {
    preheader: "Solicitud para restablecer tu contraseña en Zentto",
    reason: "Recibes este correo porque se solicitó un restablecimiento de contraseña para tu cuenta en Zentto.",
    transactional: true,
  });

  return { subject, text, html };
}

export function welcomeTemplate(userName: string, loginUrl: string) {
  const subject = "Bienvenido a Zentto — Tu prueba gratuita está activa";
  const text = `Bienvenido a Zentto, ${userName}. Tu prueba gratuita de 30 días está activa. Accede en: ${loginUrl}\n\nPara dejar de recibir emails: ${BRAND.unsubscribeUrl}\n\n${BRAND.legalName} — ${BRAND.url}`;
  const html = layout(`
    <h2>¡Bienvenido a Zentto!</h2>
    <p>Hola <strong>${escapeHtml(userName)}</strong>,</p>
    <p>Tu cuenta está activa y tu <strong>prueba gratuita de 30 días</strong> ha comenzado. Zentto es el ERP diseñado para PYMEs latinoamericanas — todo lo que necesitas en una sola plataforma.</p>

    <div class="info-box">
      <p><strong>Lo que puedes hacer ahora:</strong></p>
      <p style="margin-top:8px">
        &#10003; Facturación electrónica fiscal<br>
        &#10003; Contabilidad con asientos automáticos<br>
        &#10003; Inventario multi-almacén<br>
        &#10003; Punto de venta (POS)<br>
        &#10003; Nómina y RRHH<br>
        &#10003; Ecommerce integrado
      </p>
    </div>

    <p style="text-align:center">
      <a href="${loginUrl}" class="btn">Acceder a Zentto</a>
    </p>

    <div class="divider"></div>
    <p style="font-size:13px;color:#9b9bb0">¿Necesitas ayuda? Responde a este correo o escríbenos a <a href="mailto:soporte@zentto.net" style="color:${BRAND.color}">soporte@zentto.net</a>. Estamos aquí para ayudarte.</p>
  `, {
    preheader: `Bienvenido a Zentto, ${userName}. Tu prueba gratuita de 30 días está activa.`,
    reason: "Recibes este correo porque acabas de crear una cuenta en Zentto.",
    transactional: false,
  });

  return { subject, text, html };
}

export function welcomeStoreTemplate(customerName: string, storeUrl: string) {
  const subject = "Bienvenido a Zentto Store";
  const text = `Bienvenido a Zentto Store, ${customerName}. Explora nuestro catálogo en: ${storeUrl}\n\nPara dejar de recibir emails: ${BRAND.unsubscribeUrl}\n\n${BRAND.legalName} — ${BRAND.url}`;
  const html = layout(`
    <h2>¡Bienvenido a Zentto Store!</h2>
    <p>Hola <strong>${escapeHtml(customerName)}</strong>,</p>
    <p>Tu cuenta en Zentto Store ha sido creada exitosamente. Ya puedes explorar nuestro catálogo, hacer pedidos y guardar tus direcciones de envío.</p>
    <p style="text-align:center">
      <a href="${storeUrl}" class="btn">Ir a la tienda</a>
    </p>
    <div class="divider"></div>
    <p style="font-size:13px;color:#9b9bb0">¿Preguntas sobre tu pedido? Escríbenos a <a href="mailto:soporte@zentto.net" style="color:${BRAND.color}">soporte@zentto.net</a>.</p>
  `, {
    preheader: `Bienvenido a Zentto Store, ${customerName}`,
    reason: "Recibes este correo porque creaste una cuenta en Zentto Store.",
    transactional: false,
  });

  return { subject, text, html };
}

export function passwordChangedTemplate(userCode: string) {
  const subject = "Contraseña actualizada — Zentto";
  const text = `Hola ${userCode}, tu contraseña en Zentto ha sido actualizada exitosamente. Si no fuiste tú, contacta soporte@zentto.net inmediatamente.\n\n${BRAND.legalName} — ${BRAND.url}`;
  const html = layout(`
    <h2>Contraseña actualizada</h2>
    <p>Hola <strong>${escapeHtml(userCode)}</strong>,</p>
    <p>Tu contraseña ha sido actualizada exitosamente. Ya puedes iniciar sesión con tu nueva contraseña.</p>
    <div class="info-box">
      <p><strong>¿No fuiste tú?</strong></p>
      <p>Si no realizaste este cambio, contacta inmediatamente a nuestro equipo de soporte en <a href="mailto:soporte@zentto.net" style="color:${BRAND.color}">soporte@zentto.net</a> para proteger tu cuenta.</p>
    </div>
    <div class="divider"></div>
    <p style="font-size:13px;color:#9b9bb0">
      <strong>Detalles de seguridad:</strong><br>
      Fecha: ${new Date().toISOString().split("T")[0]}<br>
      Si no reconoces esta actividad, cambia tu contraseña inmediatamente.
    </p>
  `, {
    preheader: "Tu contraseña en Zentto ha sido actualizada",
    reason: "Recibes este correo porque se actualizó la contraseña de tu cuenta en Zentto.",
    transactional: true,
    unsubscribe: false,
  });

  return { subject, text, html };
}

export function invoiceTemplate(customerName: string, invoiceNumber: string, amount: string, currency: string, downloadUrl: string) {
  const subject = `Factura ${invoiceNumber} — Zentto`;
  const text = `Hola ${customerName}, tu factura ${invoiceNumber} por ${currency} ${amount} está disponible. Descárgala en: ${downloadUrl}\n\n${BRAND.legalName} — ${BRAND.url}`;
  const html = layout(`
    <h2>Tu factura está lista</h2>
    <p>Hola <strong>${escapeHtml(customerName)}</strong>,</p>
    <p>Se ha generado una nueva factura en tu cuenta:</p>
    <div class="info-box">
      <p><strong>Factura:</strong> ${escapeHtml(invoiceNumber)}</p>
      <p><strong>Monto:</strong> ${escapeHtml(currency)} ${escapeHtml(amount)}</p>
      <p><strong>Fecha:</strong> ${new Date().toLocaleDateString("es-ES", { year: "numeric", month: "long", day: "numeric" })}</p>
    </div>
    <p style="text-align:center">
      <a href="${downloadUrl}" class="btn">Descargar factura</a>
    </p>
    <div class="divider"></div>
    <p style="font-size:13px;color:#9b9bb0">Si tienes preguntas sobre esta factura, escríbenos a <a href="mailto:soporte@zentto.net" style="color:${BRAND.color}">soporte@zentto.net</a>.</p>
  `, {
    preheader: `Factura ${invoiceNumber} por ${currency} ${amount}`,
    reason: "Recibes este correo porque se generó una factura asociada a tu cuenta en Zentto.",
    transactional: true,
  });

  return { subject, text, html };
}

export function trialExpiringTemplate(userName: string, daysLeft: number, upgradeUrl: string) {
  const subject = `Tu prueba gratuita expira en ${daysLeft} día${daysLeft > 1 ? "s" : ""} — Zentto`;
  const text = `Hola ${userName}, tu prueba gratuita de Zentto expira en ${daysLeft} días. Actualiza tu plan en: ${upgradeUrl}\n\nPara dejar de recibir emails: ${BRAND.unsubscribeUrl}\n\n${BRAND.legalName} — ${BRAND.url}`;
  const html = layout(`
    <h2>Tu prueba está por terminar</h2>
    <p>Hola <strong>${escapeHtml(userName)}</strong>,</p>
    <p>Tu prueba gratuita de Zentto expira en <strong>${daysLeft} día${daysLeft > 1 ? "s" : ""}</strong>. Para no perder acceso a tus datos y seguir usando todas las funcionalidades, actualiza tu plan:</p>
    <p style="text-align:center">
      <a href="${upgradeUrl}" class="btn">Elegir un plan</a>
    </p>
    <div class="info-box">
      <p><strong>¿Qué pasa si no actualizo?</strong></p>
      <p>Tu cuenta pasará a modo lectura. No perderás tus datos, pero no podrás crear nuevos documentos hasta que actives un plan.</p>
    </div>
    <div class="divider"></div>
    <p style="font-size:13px;color:#9b9bb0">Planes desde $29/mes. <a href="${BRAND.url}/#pricing" style="color:${BRAND.color}">Ver precios</a></p>
  `, {
    preheader: `Tu prueba gratuita expira en ${daysLeft} días — actualiza tu plan`,
    reason: "Recibes este correo porque tienes una prueba gratuita activa en Zentto.",
    transactional: false,
  });

  return { subject, text, html };
}

// ─── Ecommerce — order lifecycle ─────────────────────────

interface OrderItemSummary { name: string; quantity: number; unitPrice: string; lineTotal: string; }

function renderOrderItems(items: OrderItemSummary[]): string {
  if (!items.length) return "";
  return `
    <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="margin:16px 0;border-collapse:collapse">
      <tbody>
        ${items.map(i => `
          <tr>
            <td style="padding:10px 0;border-bottom:1px solid #ececf3;color:#1a1a2e;font-size:13px">
              ${escapeHtml(i.name)}
              <div style="color:#7a7a90;font-size:12px;margin-top:2px">Cant: ${i.quantity} &middot; ${escapeHtml(i.unitPrice)}</div>
            </td>
            <td style="padding:10px 0;border-bottom:1px solid #ececf3;color:#1a1a2e;font-size:13px;text-align:right;white-space:nowrap">
              ${escapeHtml(i.lineTotal)}
            </td>
          </tr>`).join("")}
      </tbody>
    </table>`;
}

export function orderCreatedTemplate(args: {
  customerName: string;
  orderNumber: string;
  total: string;
  currency: string;
  items: OrderItemSummary[];
  trackingUrl: string;
}) {
  const subject = `Confirmamos tu pedido ${args.orderNumber} — Zentto Store`;
  const text = `Hola ${args.customerName}, recibimos tu pedido ${args.orderNumber} por ${args.currency} ${args.total}. Te avisaremos cuando se confirme el pago.\n\nDetalle: ${args.trackingUrl}\n\n${BRAND.legalName} — ${BRAND.url}`;
  const html = layout(`
    <h2>Pedido recibido</h2>
    <p>Hola <strong>${escapeHtml(args.customerName)}</strong>,</p>
    <p>Recibimos tu pedido y lo estamos procesando. En breve te confirmaremos el pago.</p>
    <div class="info-box">
      <p><strong>Número de pedido:</strong> ${escapeHtml(args.orderNumber)}</p>
      <p><strong>Total:</strong> ${escapeHtml(args.currency)} ${escapeHtml(args.total)}</p>
    </div>
    ${renderOrderItems(args.items)}
    <p style="text-align:center"><a href="${args.trackingUrl}" class="btn">Ver mi pedido</a></p>
  `, {
    preheader: `Pedido ${args.orderNumber} por ${args.currency} ${args.total} recibido`,
    reason: "Recibes este correo porque hiciste un pedido en Zentto Store.",
    transactional: true,
  });
  return { subject, text, html };
}

export function orderPaidTemplate(args: {
  customerName: string;
  orderNumber: string;
  total: string;
  currency: string;
  paymentRef: string;
  trackingUrl: string;
}) {
  const subject = `Pago confirmado — pedido ${args.orderNumber}`;
  const text = `Hola ${args.customerName}, confirmamos el pago de tu pedido ${args.orderNumber} por ${args.currency} ${args.total}. Ref: ${args.paymentRef}.\n\nSeguimiento: ${args.trackingUrl}\n\n${BRAND.legalName} — ${BRAND.url}`;
  const html = layout(`
    <h2>¡Pago confirmado!</h2>
    <p>Hola <strong>${escapeHtml(args.customerName)}</strong>,</p>
    <p>Tu pago fue procesado correctamente. Estamos preparando tu pedido para envío.</p>
    <div class="info-box">
      <p><strong>Pedido:</strong> ${escapeHtml(args.orderNumber)}</p>
      <p><strong>Total:</strong> ${escapeHtml(args.currency)} ${escapeHtml(args.total)}</p>
      <p><strong>Referencia de pago:</strong> ${escapeHtml(args.paymentRef)}</p>
    </div>
    <p style="text-align:center"><a href="${args.trackingUrl}" class="btn">Ver mi pedido</a></p>
  `, {
    preheader: `Pago confirmado — pedido ${args.orderNumber}`,
    reason: "Recibes este correo porque hiciste un pedido en Zentto Store.",
    transactional: true,
  });
  return { subject, text, html };
}

export function orderShippedTemplate(args: {
  customerName: string;
  orderNumber: string;
  carrier?: string;
  trackingNumber?: string;
  trackingUrl: string;
}) {
  const subject = `Tu pedido ${args.orderNumber} fue enviado`;
  const text = `Hola ${args.customerName}, tu pedido ${args.orderNumber} ya está en camino${args.carrier ? ` (${args.carrier}${args.trackingNumber ? ` — guía ${args.trackingNumber}` : ""})` : ""}.\n\nSeguimiento: ${args.trackingUrl}\n\n${BRAND.legalName} — ${BRAND.url}`;
  const html = layout(`
    <h2>Tu pedido está en camino 🚚</h2>
    <p>Hola <strong>${escapeHtml(args.customerName)}</strong>,</p>
    <p>Despachamos tu pedido. Pronto estará contigo.</p>
    <div class="info-box">
      <p><strong>Pedido:</strong> ${escapeHtml(args.orderNumber)}</p>
      ${args.carrier ? `<p><strong>Transportista:</strong> ${escapeHtml(args.carrier)}</p>` : ""}
      ${args.trackingNumber ? `<p><strong>Guía de envío:</strong> ${escapeHtml(args.trackingNumber)}</p>` : ""}
    </div>
    <p style="text-align:center"><a href="${args.trackingUrl}" class="btn">Hacer seguimiento</a></p>
  `, {
    preheader: `Pedido ${args.orderNumber} enviado`,
    reason: "Recibes este correo porque hiciste un pedido en Zentto Store.",
    transactional: true,
  });
  return { subject, text, html };
}

export function orderDeliveredTemplate(args: {
  customerName: string;
  orderNumber: string;
  reviewUrl: string;
}) {
  const subject = `Pedido ${args.orderNumber} entregado`;
  const text = `Hola ${args.customerName}, tu pedido ${args.orderNumber} ha sido entregado. ¡Gracias por confiar en Zentto Store!\n\nDeja tu reseña: ${args.reviewUrl}\n\n${BRAND.legalName} — ${BRAND.url}`;
  const html = layout(`
    <h2>Pedido entregado ✅</h2>
    <p>Hola <strong>${escapeHtml(args.customerName)}</strong>,</p>
    <p>Tu pedido <strong>${escapeHtml(args.orderNumber)}</strong> fue entregado. Esperamos que lo disfrutes.</p>
    <p>¿Te ayudamos a contar tu experiencia? Tu opinión ayuda a otros compradores.</p>
    <p style="text-align:center"><a href="${args.reviewUrl}" class="btn">Dejar reseña</a></p>
  `, {
    preheader: `Pedido ${args.orderNumber} entregado`,
    reason: "Recibes este correo porque hiciste un pedido en Zentto Store.",
    transactional: true,
  });
  return { subject, text, html };
}

export function paymentSuccessTemplate(customerName: string, planName: string, amount: string, nextBillingDate: string) {
  const subject = "Pago confirmado — Zentto";
  const text = `Hola ${customerName}, tu pago de ${amount} para el plan ${planName} ha sido procesado. Próxima facturación: ${nextBillingDate}.\n\n${BRAND.legalName} — ${BRAND.url}`;
  const html = layout(`
    <h2>Pago confirmado</h2>
    <p>Hola <strong>${escapeHtml(customerName)}</strong>,</p>
    <p>Tu pago ha sido procesado exitosamente. Aquí están los detalles:</p>
    <div class="info-box">
      <p><strong>Plan:</strong> ${escapeHtml(planName)}</p>
      <p><strong>Monto:</strong> ${escapeHtml(amount)}</p>
      <p><strong>Próxima facturación:</strong> ${escapeHtml(nextBillingDate)}</p>
    </div>
    <p>Gracias por confiar en Zentto para gestionar tu negocio.</p>
    <p style="text-align:center">
      <a href="${BRAND.appUrl}" class="btn">Ir a Zentto</a>
    </p>
  `, {
    preheader: `Pago de ${amount} confirmado para tu plan ${planName}`,
    reason: "Recibes este correo porque realizaste un pago en Zentto.",
    transactional: true,
  });

  return { subject, text, html };
}
