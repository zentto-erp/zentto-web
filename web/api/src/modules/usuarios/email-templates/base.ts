// Templates de email Zentto — HTML puro, sin dependencias externas

const BRAND = {
  name: "Zentto",
  url: "https://zentto.net",
  appUrl: "https://app.zentto.net",
  color: "#6C63FF",
  colorSecondary: "#FF6584",
  supportEmail: "soporte@zentto.net",
  year: new Date().getFullYear(),
};

function layout(content: string, preheader = "") {
  return `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light dark">
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
  .footer p{margin:0 0 8px;color:#9b9bb0;font-size:12px;line-height:1.5}
  .footer a{color:${BRAND.color};text-decoration:none}
  .social{margin:12px 0}
  .social a{display:inline-block;margin:0 6px;color:#9b9bb0;font-size:12px;text-decoration:none}
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
${preheader ? `<div style="display:none;max-height:0;overflow:hidden">${preheader}</div>` : ""}
<div class="container">
  <div class="card">
    <div class="header">
      <h1>${BRAND.name}<span class="dot"></span></h1>
    </div>
    <div class="body">
      ${content}
    </div>
    <div class="footer">
      <p><a href="${BRAND.url}">zentto.net</a> &middot; <a href="${BRAND.appUrl}">Acceder a la app</a></p>
      <p>ERP SaaS para PYMEs latinoamericanas<br>Facturación &middot; Contabilidad &middot; Inventario &middot; Nómina &middot; POS &middot; Ecommerce</p>
      <p>&copy; ${BRAND.year} ${BRAND.name}. Todos los derechos reservados.</p>
      <p style="margin-top:12px"><a href="mailto:${BRAND.supportEmail}">${BRAND.supportEmail}</a></p>
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
  const text = `Hola ${userCode}, confirma tu cuenta en Zentto: ${verificationUrl}`;
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
    <p style="font-size:13px;color:#9b9bb0">Este enlace expira en 24 horas. Si no solicitaste este registro, puedes ignorar este mensaje.</p>
  `, "Confirma tu cuenta en Zentto para comenzar tu prueba gratuita");

  return { subject, text, html };
}

export function resetPasswordTemplate(userCode: string, resetUrl: string) {
  const subject = "Restablecer contraseña — Zentto";
  const text = `Hola ${userCode}, restablece tu contraseña en Zentto: ${resetUrl}`;
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
  `, "Solicitud para restablecer tu contraseña en Zentto");

  return { subject, text, html };
}

export function welcomeTemplate(userName: string, loginUrl: string) {
  const subject = "Bienvenido a Zentto — Tu prueba gratuita está activa";
  const text = `Bienvenido a Zentto, ${userName}. Tu prueba gratuita de 30 días está activa. Accede en: ${loginUrl}`;
  const html = layout(`
    <h2>¡Bienvenido a Zentto!</h2>
    <p>Hola <strong>${escapeHtml(userName)}</strong>,</p>
    <p>Tu cuenta está activa y tu <strong>prueba gratuita de 30 días</strong> ha comenzado. Zentto es el ERP diseñado para PYMEs latinoamericanas — todo lo que necesitas en una sola plataforma.</p>

    <div class="info-box">
      <p><strong>Lo que puedes hacer ahora:</strong></p>
      <p style="margin-top:8px">
        ✓ Facturación electrónica fiscal<br>
        ✓ Contabilidad con asientos automáticos<br>
        ✓ Inventario multi-almacén<br>
        ✓ Punto de venta (POS)<br>
        ✓ Nómina y RRHH<br>
        ✓ Ecommerce integrado
      </p>
    </div>

    <p style="text-align:center">
      <a href="${loginUrl}" class="btn">Acceder a Zentto</a>
    </p>

    <div class="divider"></div>
    <p style="font-size:13px;color:#9b9bb0">¿Necesitas ayuda? Responde a este correo o escríbenos a <a href="mailto:soporte@zentto.net" style="color:${BRAND.color}">soporte@zentto.net</a>. Estamos aquí para ayudarte.</p>
  `, `Bienvenido a Zentto, ${userName}. Tu prueba gratuita de 30 días está activa.`);

  return { subject, text, html };
}

export function welcomeStoreTemplate(customerName: string, storeUrl: string) {
  const subject = "Bienvenido a Zentto Store";
  const text = `Bienvenido a Zentto Store, ${customerName}. Explora nuestro catálogo en: ${storeUrl}`;
  const html = layout(`
    <h2>¡Bienvenido a Zentto Store!</h2>
    <p>Hola <strong>${escapeHtml(customerName)}</strong>,</p>
    <p>Tu cuenta en Zentto Store ha sido creada exitosamente. Ya puedes explorar nuestro catálogo, hacer pedidos y guardar tus direcciones de envío.</p>
    <p style="text-align:center">
      <a href="${storeUrl}" class="btn">Ir a la tienda</a>
    </p>
    <div class="divider"></div>
    <p style="font-size:13px;color:#9b9bb0">¿Preguntas sobre tu pedido? Escríbenos a <a href="mailto:soporte@zentto.net" style="color:${BRAND.color}">soporte@zentto.net</a>.</p>
  `, `Bienvenido a Zentto Store, ${customerName}`);

  return { subject, text, html };
}

export function passwordChangedTemplate(userCode: string) {
  const subject = "Contraseña actualizada — Zentto";
  const text = `Hola ${userCode}, tu contraseña en Zentto ha sido actualizada exitosamente.`;
  const html = layout(`
    <h2>Contraseña actualizada</h2>
    <p>Hola <strong>${escapeHtml(userCode)}</strong>,</p>
    <p>Tu contraseña ha sido actualizada exitosamente. Ya puedes iniciar sesión con tu nueva contraseña.</p>
    <div class="info-box">
      <p><strong>¿No fuiste tú?</strong></p>
      <p>Si no realizaste este cambio, contacta inmediatamente a nuestro equipo de soporte en <a href="mailto:soporte@zentto.net" style="color:${BRAND.color}">soporte@zentto.net</a>.</p>
    </div>
  `, "Tu contraseña en Zentto ha sido actualizada");

  return { subject, text, html };
}
