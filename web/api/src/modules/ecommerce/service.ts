import { callSp, callSpOut, sql } from "../../db/query.js";
import { signJwt, verifyJwt, type JwtPayload } from "../../auth/jwt.js";
import { sendAuthMail } from "../usuarios/auth-mailer.service.js";
import { welcomeStoreTemplate } from "../usuarios/email-templates/base.js";
import { getActiveScope } from "../_shared/scope.js";
import bcrypt from "bcryptjs";

function scope() {
  const s = getActiveScope();
  return { companyId: s?.companyId ?? 1, branchId: s?.branchId ?? 1 };
}

// Base URL de la API para resolver rutas relativas de imágenes (ej: /media-files/...)
const API_SELF_URL = (process.env.API_SELF_URL || `http://localhost:${process.env.PORT || 4000}`).replace(/\/+$/, "");

/** Convierte URLs relativas de imágenes a absolutas */
function resolveImageUrl(url: string | null | undefined): string | null {
  if (!url) return null;
  // Ya es absoluta
  if (url.startsWith("http://") || url.startsWith("https://")) return url;
  // Relativa → prefijo con la API
  return `${API_SELF_URL}${url.startsWith("/") ? "" : "/"}${url}`;
}

/** Placeholder SVG inline para productos sin imagen */
const PLACEHOLDER_IMAGE = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='400' height='400'%3E%3Crect fill='%23f0f2f2' width='400' height='400'/%3E%3Ctext fill='%23999' x='50%25' y='50%25' text-anchor='middle' dy='.3em' font-size='14'%3ESin imagen%3C/text%3E%3C/svg%3E";

// ─── Tipos ─────────────────────────────────────────────

interface StoreProduct {
  id: number;
  code: string;
  name: string;
  fullDescription: string;
  category: string;
  brand: string;
  price: number;
  stock: number;
  isService: boolean;
  taxRate: number;
  imageUrl: string | null;
}

interface StoreCategory {
  code: string;
  name: string;
  productCount: number;
}

interface StoreBrand {
  code: string;
  name: string;
  productCount: number;
}

interface CustomerLoginRow {
  userId: number;
  email: string;
  displayName: string;
  passwordHash: string;
  isActive: boolean;
  customerCode: string;
  customerName: string;
  phone: string;
  address: string;
  fiscalId: string;
}

// ─── Catálogo ──────────────────────────────────────────

export async function listProducts(params: {
  search?: string;
  category?: string;
  brand?: string;
  priceMin?: number;
  priceMax?: number;
  minRating?: number;
  inStockOnly?: boolean;
  sortBy?: string;
  page?: number;
  limit?: number;
}) {
  const page = Math.max(params.page ?? 1, 1);
  const limit = Math.min(Math.max(params.limit ?? 24, 1), 100);

  const validSorts = ["name", "price_asc", "price_desc", "rating", "newest", "bestseller"];
  const sortBy = validSorts.includes(params.sortBy ?? "") ? params.sortBy! : "name";

  const { rows, output } = await callSpOut<StoreProduct>(
    "usp_Store_Product_List",
    {
      CompanyId: scope().companyId,
      BranchId: scope().branchId,
      Search: params.search?.trim() || null,
      Category: params.category || null,
      Brand: params.brand || null,
      PriceMin: params.priceMin ?? null,
      PriceMax: params.priceMax ?? null,
      MinRating: params.minRating ?? null,
      InStockOnly: params.inStockOnly !== false ? 1 : 0,
      SortBy: sortBy,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  // Resolver URLs de imágenes relativas y agregar placeholder
  const resolvedRows = rows.map((r: any) => ({
    ...r,
    imageUrl: resolveImageUrl(r.imageUrl) || PLACEHOLDER_IMAGE,
  }));

  return {
    page,
    limit,
    total: (output.TotalCount as number) ?? 0,
    rows: resolvedRows,
  };
}

export async function getProductByCode(code: string) {
  const rows = await callSp<any>(
    "usp_Store_Product_GetByCode",
    {
      CompanyId: scope().companyId,
      BranchId: scope().branchId,
      Code: code,
    }
  );

  // SP retorna 2 recordsets: [0] = producto, [1] = imágenes
  // callSp solo retorna el primer recordset, usamos callSpOut para múltiples
  return rows[0] ?? null;
}

export async function getProductByCodeFull(code: string) {
  const params = { CompanyId: scope().companyId, BranchId: scope().branchId, Code: code };

  // Lanzar todas las consultas en paralelo
  const [productRows, images, highlightRows, specRows] = await Promise.all([
    callSp<any>("usp_Store_Product_GetByCode", params),
    callSp<any>("usp_Store_Product_GetImages", params),
    callSp<any>("usp_Store_Product_GetHighlights", { CompanyId: scope().companyId, Code: code }),
    callSp<any>("usp_Store_Product_GetSpecs", { CompanyId: scope().companyId, Code: code }),
  ]);

  const product = productRows[0] ?? null;
  if (!product) return null;

  const highlights = highlightRows.map((h: any) => h.text);
  const specs = specRows.map((s: any) => ({
    group: s.group,
    key: s.key,
    value: s.value,
  }));

  // TODO: variantes e industryAttributes cuando las funciones PG estén listas
  const variants: any[] = [];
  const industryAttributes: any[] = [];

  // Resolver URLs de imágenes relativas a absolutas
  const resolvedImages = images.map((img: any) => ({
    ...img,
    url: resolveImageUrl(img.url) || PLACEHOLDER_IMAGE,
  }));

  // Si no hay imágenes, agregar placeholder
  if (resolvedImages.length === 0) {
    resolvedImages.push({ id: 0, url: PLACEHOLDER_IMAGE, role: "PRIMARY", isPrimary: true, altText: "Sin imagen" });
  }

  return { ...product, images: resolvedImages, highlights, specs, variants, industryAttributes };
}

export async function listCategories() {
  return callSp<StoreCategory>("usp_Store_Category_List", {
    CompanyId: scope().companyId,
  });
}

export async function listBrands() {
  return callSp<StoreBrand>("usp_Store_Brand_List", {
    CompanyId: scope().companyId,
  });
}

// ─── Storefront público (multi-moneda / país) ─────────

export async function listStorefrontCountries() {
  return callSp<{
    countryCode: string;
    countryName: string;
    currencyCode: string;
    currencySymbol: string;
    phonePrefix: string;
    flagEmoji: string;
    sortOrder: number;
  }>("usp_Store_Storefront_Countries_List", {});
}

export async function listStorefrontCurrencies() {
  return callSp<{
    currencyCode: string;
    currencyName: string;
    symbol: string;
    rateToBase: number;
    isBase: boolean;
    rateDate: string;
  }>("usp_Store_Storefront_Currencies_List", { CompanyId: scope().companyId });
}

export async function getStorefrontCountry(code: string) {
  const rows = await callSp<{
    countryCode: string;
    countryName: string;
    currencyCode: string;
    currencySymbol: string;
    referenceCurrency: string;
    defaultExchangeRate: number;
    pricesIncludeTax: boolean;
    specialTaxRate: number;
    specialTaxEnabled: boolean;
    taxAuthorityCode: string;
    fiscalIdName: string;
    timeZoneIana: string;
    phonePrefix: string;
    flagEmoji: string;
    defaultTaxCode: string | null;
    defaultTaxName: string | null;
    defaultTaxRate: number;
  }>("usp_Store_Storefront_Country_Get", { CountryCode: code.toUpperCase() });
  return rows[0] ?? null;
}

// ─── Auth de clientes ──────────────────────────────────

export async function registerCustomer(data: {
  email: string;
  name: string;
  password: string;
  phone?: string;
  address?: string;
  fiscalId?: string;
}) {
  const hash = await bcrypt.hash(data.password, 10);

  const { output } = await callSpOut(
    "usp_Store_Customer_Register",
    {
      CompanyId: scope().companyId,
      Email: data.email.toLowerCase().trim(),
      Name: data.name.trim(),
      PasswordHash: hash,
      Phone: data.phone || null,
      Address: data.address || null,
      FiscalId: data.fiscalId || null,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
    }
  );

  const resultado = output.Resultado as number;
  const mensaje = output.Mensaje as string;

  if (resultado !== 1) {
    return { ok: false, error: mensaje };
  }

  // Email de bienvenida (silencioso, no bloquea el registro)
  const storeUrl = process.env.STORE_URL || "https://app.zentto.net";
  const { subject, text, html } = welcomeStoreTemplate(data.name, storeUrl);
  sendAuthMail({ to: data.email, subject, text, html }).catch(() => {});

  return { ok: true, message: mensaje };
}

export async function loginCustomer(email: string, password: string) {
  const rows = await callSp<CustomerLoginRow>(
    "usp_Store_Customer_Login",
    { CompanyId: scope().companyId, Email: email.toLowerCase().trim() }
  );

  const user = rows[0];
  if (!user) return { ok: false, error: "Credenciales inválidas" };
  if (!user.isActive) return { ok: false, error: "Cuenta desactivada" };

  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) return { ok: false, error: "Credenciales inválidas" };

  const token = signJwt({
    sub: String(user.userId),
    name: user.displayName,
    isAdmin: false,
    modulos: ["ecommerce"],
    companyId: scope().companyId,
    branchId: scope().branchId,
  } as JwtPayload);

  return {
    ok: true,
    token,
    customer: {
      email: user.email,
      name: user.displayName,
      customerCode: user.customerCode,
      phone: user.phone,
      address: user.address,
      fiscalId: user.fiscalId,
    },
  };
}

/**
 * Google OAuth: verifica token de Google y registra/loguea al cliente.
 * Usa el endpoint de Google para verificar el ID token.
 */
export async function googleAuthCustomer(idToken: string) {
  // Verificar token con Google
  const googleRes = await fetch(
    `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`
  );
  if (!googleRes.ok) {
    return { ok: false, error: "Token de Google inválido" };
  }

  const google = (await googleRes.json()) as {
    email: string;
    name: string;
    given_name?: string;
    family_name?: string;
    picture?: string;
    email_verified?: string;
    sub: string;
  };

  if (!google.email) {
    return { ok: false, error: "No se pudo obtener email de Google" };
  }

  const email = google.email.toLowerCase().trim();
  const name = google.name || `${google.given_name || ""} ${google.family_name || ""}`.trim() || email;

  // Buscar si ya existe
  const existing = await callSp<CustomerLoginRow>(
    "usp_Store_Customer_Login",
    { CompanyId: scope().companyId, Email: email }
  );

  if (existing[0]) {
    // Ya existe — login directo (sin verificar password)
    const user = existing[0];
    if (!user.isActive) return { ok: false, error: "Cuenta desactivada" };

    const token = signJwt({
      sub: String(user.userId),
      name: user.displayName,
      isAdmin: false,
      modulos: ["ecommerce"],
      companyId: scope().companyId,
      branchId: scope().branchId,
    } as JwtPayload);

    return {
      ok: true,
      token,
      isNew: false,
      customer: {
        email: user.email,
        name: user.displayName,
        customerCode: user.customerCode,
        phone: user.phone,
        address: user.address,
        fiscalId: user.fiscalId,
      },
    };
  }

  // No existe — registrar con password random (no usará password, siempre Google)
  const randomPwd = crypto.randomUUID();
  const hash = await bcrypt.hash(randomPwd, 10);

  const { output } = await callSpOut(
    "usp_Store_Customer_Register",
    {
      CompanyId: scope().companyId,
      Email: email,
      Name: name,
      PasswordHash: hash,
      Phone: null,
      Address: null,
      FiscalId: null,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
    }
  );

  if ((output.Resultado as number) !== 1) {
    return { ok: false, error: output.Mensaje as string };
  }

  // Buscar el recién creado para obtener userId
  const newRows = await callSp<CustomerLoginRow>(
    "usp_Store_Customer_Login",
    { CompanyId: scope().companyId, Email: email }
  );
  const newUser = newRows[0];
  if (!newUser) return { ok: false, error: "Error al crear cuenta" };

  const token = signJwt({
    sub: String(newUser.userId),
    name: newUser.displayName,
    isAdmin: false,
    modulos: ["ecommerce"],
    companyId: scope().companyId,
    branchId: scope().branchId,
  } as JwtPayload);

  return {
    ok: true,
    token,
    isNew: true,
    customer: {
      email: newUser.email,
      name: newUser.displayName,
      customerCode: newUser.customerCode,
      phone: newUser.phone,
      address: newUser.address,
      fiscalId: newUser.fiscalId,
    },
  };
}

export async function verifyCustomerToken(authHeader?: string) {
  if (!authHeader) return null;
  const [scheme, token] = authHeader.split(" ");
  if (scheme !== "Bearer" || !token) return null;
  try {
    return await verifyJwt(token);
  } catch {
    return null;
  }
}

// ─── Checkout ──────────────────────────────────────────

export async function checkout(data: {
  customer: {
    name: string;
    email: string;
    phone?: string;
    address?: string;
    billingAddress?: string;
    fiscalId?: string;
  };
  items: Array<{
    productCode: string;
    productName: string;
    quantity: number;
    unitPrice: number;
    taxRate: number;
    subtotal: number;
    taxAmount: number;
  }>;
  notes?: string;
  addressId?: number;
  billingAddressId?: number;
  paymentMethodId?: number;
  paymentMethodType?: string;
  currencyCode?: string;
  exchangeRate?: number;
  countryCode?: string;
}) {
  // 1. Buscar o crear cliente
  const { output: custOut } = await callSpOut(
    "usp_Store_Customer_FindOrCreate",
    {
      CompanyId: scope().companyId,
      Email: data.customer.email.toLowerCase().trim(),
      Name: data.customer.name.trim(),
      Phone: data.customer.phone || null,
      Address: data.customer.address || null,
      FiscalId: data.customer.fiscalId || null,
    },
    {
      CustomerCode: sql.NVarChar(24),
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
    }
  );

  const customerCode = custOut.CustomerCode as string;
  if (!customerCode) {
    return { ok: false, error: custOut.Mensaje as string };
  }

  // 2. Crear pedido — XML para SQL Server 2012 (no soporta OPENJSON)
  const escXml = (s: string) => s.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  const itemsXml = "<items>" + data.items.map(i =>
    `<i pc="${escXml(i.productCode)}" pn="${escXml(i.productName)}" qty="${i.quantity}" up="${i.unitPrice}" tr="${i.taxRate}" st="${i.subtotal}" ta="${i.taxAmount}"/>`
  ).join("") + "</items>";

  const { output: orderOut } = await callSpOut(
    "usp_Store_Order_Create",
    {
      CompanyId: scope().companyId,
      BranchId: scope().branchId,
      CustomerCode: customerCode,
      CustomerName: data.customer.name.trim(),
      CustomerEmail: data.customer.email.toLowerCase().trim(),
      FiscalId: data.customer.fiscalId || null,
      Phone: data.customer.phone || null,
      Address: data.customer.address || null,
      Notes: data.notes || null,
      ItemsXml: itemsXml,
      AddressId: data.addressId ?? null,
      PaymentMethodId: data.paymentMethodId ?? null,
      PaymentMethodType: data.paymentMethodType || null,
      BillingAddressId: data.billingAddressId ?? null,
      ShippingAddressText: data.customer.address || null,
      BillingAddressText: data.customer.billingAddress || data.customer.address || null,
      CurrencyCode: data.currencyCode ?? null,
      ExchangeRate: data.exchangeRate ?? null,
    },
    {
      OrderNumber: sql.NVarChar(60),
      OrderToken: sql.NVarChar(100),
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
    }
  );

  const resultado = orderOut.Resultado as number;
  if (resultado !== 1) {
    return { ok: false, error: orderOut.Mensaje as string };
  }

  const orderNumber = orderOut.OrderNumber as string;
  const orderToken = orderOut.OrderToken as string;

  // 3. Iniciar checkout en zentto-payments (cobro real)
  let checkoutUrl: string | null = null;
  let paymentTxnId: string | null = null;
  try {
    const totalAmount = data.items.reduce((s, i) => s + i.subtotal + i.taxAmount, 0);
    const currency = (data.currencyCode ?? "USD").toUpperCase();
    const PAYMENTS_URL = process.env.ZENTTO_PAYMENTS_URL || "https://payments.zentto.net";
    const PAYMENTS_KEY = process.env.ZENTTO_PAYMENTS_API_KEY || "";
    const PUBLIC_API = process.env.PUBLIC_API_URL || "https://api.zentto.net";
    const PUBLIC_FE  = process.env.PUBLIC_FRONTEND_URL || "https://app.zentto.net";

    if (PAYMENTS_KEY && totalAmount > 0) {
      const itemNames = data.items.slice(0, 3).map(i => i.productName).join(", ");
      const itemsCount = data.items.length;
      const summaryName = itemsCount > 3 ? `${itemNames} +${itemsCount - 3} más` : itemNames;

      const res = await fetch(`${PAYMENTS_URL}/v1/checkout`, {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-API-Key": PAYMENTS_KEY },
        body: JSON.stringify({
          provider: process.env.ZENTTO_PAYMENTS_PROVIDER || "paddle",
          companyId: scope().companyId,
          items: [{
            name: `Pedido ${orderNumber} — ${summaryName}`,
            unitAmount: totalAmount,
            quantity: 1,
            currency,
          }],
          customerEmail: data.customer.email.toLowerCase(),
          customerName: data.customer.name,
          callbackUrl: `${PUBLIC_API}/v1/payments/callback`,
          successUrl: `${PUBLIC_FE}/confirmacion/${orderToken}`,
          cancelUrl:  `${PUBLIC_FE}/checkout?cancelled=1`,
          metadata: {
            source: "ecommerce",
            orderToken,
            orderNumber,
            customerCode,
            customerEmail: data.customer.email.toLowerCase(),
            customerName: data.customer.name,
            companyId: String(scope().companyId),
            totalAmount: String(totalAmount),
            currencyCode: currency,
          },
        }),
      });
      const json = await res.json().catch(() => ({} as Record<string, unknown>));
      if (res.ok) {
        checkoutUrl = (json as { checkoutUrl?: string }).checkoutUrl ?? null;
        paymentTxnId = (json as { providerTxnId?: string }).providerTxnId ?? null;
      } else {
        console.error("[ecommerce/checkout] payments microservice error:", json);
      }
    }
  } catch (err) {
    console.error("[ecommerce/checkout] payments fetch error:", err);
  }

  // Tracking timeline: evento ORDER_CREATED (best-effort)
  try {
    const trackTotal = data.items.reduce((s, i) => s + i.subtotal + i.taxAmount, 0);
    const trackCurrency = (data.currencyCode ?? "USD").toUpperCase();
    await callSpOut(
      "usp_Store_Order_Tracking_Add",
      {
        CompanyId: scope().companyId,
        DocumentNumber: orderNumber,
        EventCode: "ORDER_CREATED",
        EventLabel: "Pedido recibido",
        Description: `Cliente: ${data.customer.name} — ${data.items.length} producto(s) — total ${trackCurrency} ${trackTotal.toFixed(2)}`,
        ActorUser: "storefront",
      },
      { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
    );
  } catch (trackErr) {
    console.error("[checkout] tracking event error:", trackErr);
  }

  return {
    ok: true,
    orderNumber,
    orderToken,
    message: orderOut.Mensaje as string,
    checkoutUrl,
    paymentTxnId,
  };
}

// ─── Consulta de pedidos ───────────────────────────────

export async function getOrderByToken(token: string) {
  const headers = await callSp<any>("usp_Store_Order_GetByToken", {
    CompanyId: scope().companyId,
    Token: token,
  });
  const header = headers[0] ?? null;
  if (!header) return null;

  // Obtener líneas usando el número de orden del header
  const lines = header.orderNumber
    ? await callSp<any>("usp_Store_Order_GetByNumber_Lines", { CompanyId: scope().companyId, OrderNumber: header.orderNumber })
    : [];

  return { ...header, lines };
}

export async function getMyOrders(customerCode: string, page = 1, limit = 20) {
  const { rows, output } = await callSpOut<any>(
    "usp_Store_Order_List",
    {
      CompanyId: scope().companyId,
      CustomerCode: customerCode,
      Page: Math.max(page, 1),
      Limit: Math.min(Math.max(limit, 1), 100),
    },
    { TotalCount: sql.Int }
  );

  return {
    page,
    limit,
    total: (output.TotalCount as number) ?? 0,
    rows,
  };
}

// ─── Reseñas ────────────────────────────────────────────

export async function getProductReviews(productCode: string, page = 1, limit = 20) {
  const params = { CompanyId: scope().companyId, ProductCode: productCode };
  const safePage = Math.max(page, 1);
  const safeLimit = Math.min(Math.max(limit, 1), 50);

  const [summaryRows, reviews] = await Promise.all([
    callSp<any>("usp_Store_Review_List_Summary", params),
    callSp<any>("usp_Store_Review_List_Items", { ...params, Page: safePage, Limit: safeLimit }),
  ]);

  const summary = summaryRows[0] ?? { avgRating: 0, totalCount: 0, star1: 0, star2: 0, star3: 0, star4: 0, star5: 0 };
  return { summary, reviews };
}

export async function createReview(data: {
  productCode: string;
  rating: number;
  title?: string;
  comment: string;
  reviewerName?: string;
  reviewerEmail?: string;
}) {
  const { output } = await callSpOut(
    "usp_Store_Review_Create",
    {
      CompanyId: scope().companyId,
      ProductCode: data.productCode,
      Rating: data.rating,
      Title: data.title || null,
      Comment: data.comment,
      ReviewerName: data.reviewerName || "Cliente",
      ReviewerEmail: data.reviewerEmail || null,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
    }
  );

  const resultado = output.Resultado as number;
  if (resultado !== 1) {
    return { ok: false, error: output.Mensaje as string };
  }
  return { ok: true, message: output.Mensaje as string };
}

// ─── Direcciones del cliente ─────────────────────────

export async function listAddresses(customerCode: string) {
  return callSp<any>("usp_Store_Address_List", {
    CompanyId: scope().companyId,
    CustomerCode: customerCode,
  });
}

export async function upsertAddress(customerCode: string, data: {
  addressId?: number;
  label: string;
  recipientName: string;
  phone?: string;
  addressLine: string;
  city?: string;
  state?: string;
  zipCode?: string;
  country?: string;
  instructions?: string;
  isDefault?: boolean;
}) {
  const { output } = await callSpOut(
    "usp_Store_Address_Upsert",
    {
      AddressId: data.addressId ?? null,
      CompanyId: scope().companyId,
      CustomerCode: customerCode,
      Label: data.label,
      RecipientName: data.recipientName,
      Phone: data.phone || null,
      AddressLine: data.addressLine,
      City: data.city || null,
      State: data.state || null,
      ZipCode: data.zipCode || null,
      Country: data.country || "Venezuela",
      Instructions: data.instructions || null,
      IsDefault: data.isDefault ? 1 : 0,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), NewId: sql.Int }
  );

  const resultado = output.Resultado as number;
  if (resultado !== 1) return { ok: false, error: output.Mensaje as string };
  return { ok: true, addressId: output.NewId as number, message: output.Mensaje as string };
}

export async function deleteAddress(customerCode: string, addressId: number) {
  const { output } = await callSpOut(
    "usp_Store_Address_Delete",
    { CompanyId: scope().companyId, AddressId: addressId, CustomerCode: customerCode },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  const resultado = output.Resultado as number;
  if (resultado !== 1) return { ok: false, error: output.Mensaje as string };
  return { ok: true, message: output.Mensaje as string };
}

// ─── Métodos de pago del cliente ─────────────────────

export async function listPaymentMethods(customerCode: string) {
  return callSp<any>("usp_Store_PaymentMethod_List", {
    CompanyId: scope().companyId,
    CustomerCode: customerCode,
  });
}

export async function upsertPaymentMethod(customerCode: string, data: {
  paymentMethodId?: number;
  methodType: string;
  label: string;
  bankName?: string;
  accountPhone?: string;
  accountNumber?: string;
  accountEmail?: string;
  holderName?: string;
  holderFiscalId?: string;
  cardType?: string;
  cardLast4?: string;
  cardExpiry?: string;
  isDefault?: boolean;
}) {
  const { output } = await callSpOut(
    "usp_Store_PaymentMethod_Upsert",
    {
      PaymentMethodId: data.paymentMethodId ?? null,
      CompanyId: scope().companyId,
      CustomerCode: customerCode,
      MethodType: data.methodType,
      Label: data.label,
      BankName: data.bankName || null,
      AccountPhone: data.accountPhone || null,
      AccountNumber: data.accountNumber || null,
      AccountEmail: data.accountEmail || null,
      HolderName: data.holderName || null,
      HolderFiscalId: data.holderFiscalId || null,
      CardType: data.cardType || null,
      CardLast4: data.cardLast4 || null,
      CardExpiry: data.cardExpiry || null,
      IsDefault: data.isDefault ? 1 : 0,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), NewId: sql.Int }
  );

  const resultado = output.Resultado as number;
  if (resultado !== 1) return { ok: false, error: output.Mensaje as string };
  return { ok: true, paymentMethodId: output.NewId as number, message: output.Mensaje as string };
}

export async function deletePaymentMethod(customerCode: string, paymentMethodId: number) {
  const { output } = await callSpOut(
    "usp_Store_PaymentMethod_Delete",
    { CompanyId: scope().companyId, PaymentMethodId: paymentMethodId, CustomerCode: customerCode },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  const resultado = output.Resultado as number;
  if (resultado !== 1) return { ok: false, error: output.Mensaje as string };
  return { ok: true, message: output.Mensaje as string };
}

export async function getOrderByNumber(orderNumber: string) {
  const [headers, lines] = await Promise.all([
    callSp<any>("usp_Store_Order_GetByNumber", { CompanyId: scope().companyId, OrderNumber: orderNumber }),
    callSp<any>("usp_Store_Order_GetByNumber_Lines", { CompanyId: scope().companyId, OrderNumber: orderNumber }),
  ]);

  const header = headers[0] ?? null;
  if (!header) return null;
  return { ...header, lines };
}

// ─── Carrito server-side (sync multi-device) ──────────

export interface ServerCartItem {
  productCode: string;
  productName: string | null;
  imageUrl: string | null;
  quantity: number;
  unitPrice: number;
  taxRate: number;
}

export interface ServerCart {
  cartToken: string;
  customerCode: string | null;
  currencyCode: string | null;
  countryCode: string | null;
  exchangeRate: number;
  updatedAt: string | null;
  items: ServerCartItem[];
}

export async function getServerCart(cartToken: string): Promise<ServerCart | null> {
  const rows = await callSp<any>("usp_Store_Cart_Get", {
    CartToken: cartToken,
    CompanyId: scope().companyId,
  });
  if (!rows.length) return null;
  const head = rows[0];
  const items = rows
    .filter((r: any) => r.productCode != null)
    .map((r: any) => ({
      productCode: r.productCode,
      productName: r.productName,
      imageUrl: r.imageUrl,
      quantity: Number(r.quantity),
      unitPrice: Number(r.unitPrice),
      taxRate: Number(r.taxRate ?? 0),
    }));
  return {
    cartToken: head.cartToken,
    customerCode: head.customerCode,
    currencyCode: head.currencyCode,
    countryCode: head.countryCode,
    exchangeRate: Number(head.exchangeRate ?? 1),
    updatedAt: head.updatedAt,
    items,
  };
}

export async function upsertServerCartItem(args: {
  cartToken: string;
  customerCode?: string;
  productCode: string;
  productName?: string;
  imageUrl?: string;
  quantity: number;
  unitPrice: number;
  taxRate: number;
  currencyCode?: string;
  countryCode?: string;
  exchangeRate?: number;
}) {
  const { output } = await callSpOut(
    "usp_Store_Cart_Upsert_Item",
    {
      CartToken: args.cartToken,
      CompanyId: scope().companyId,
      CustomerCode: args.customerCode ?? null,
      ProductCode: args.productCode,
      ProductName: args.productName ?? null,
      ImageUrl: args.imageUrl ?? null,
      Quantity: args.quantity,
      UnitPrice: args.unitPrice,
      TaxRate: args.taxRate,
      CurrencyCode: args.currencyCode ?? null,
      CountryCode: args.countryCode ?? null,
      ExchangeRate: args.exchangeRate ?? null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), CartId: sql.BigInt }
  );
  return {
    ok: Number(output.Resultado) === 1,
    message: String(output.Mensaje || ""),
    cartId: output.CartId ? Number(output.CartId) : null,
  };
}

export async function removeServerCartItem(cartToken: string, productCode: string) {
  const { output } = await callSpOut(
    "usp_Store_Cart_Remove_Item",
    { CartToken: cartToken, CompanyId: scope().companyId, ProductCode: productCode },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  return { ok: Number(output.Resultado) === 1, message: String(output.Mensaje || "") };
}

export async function clearServerCart(cartToken: string) {
  const { output } = await callSpOut(
    "usp_Store_Cart_Clear",
    { CartToken: cartToken, CompanyId: scope().companyId },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  return { ok: Number(output.Resultado) === 1, message: String(output.Mensaje || "") };
}

export async function mergeCartToCustomer(cartToken: string, customerCode: string) {
  const { output } = await callSpOut(
    "usp_Store_Cart_Merge_To_Customer",
    { CartToken: cartToken, CompanyId: scope().companyId, CustomerCode: customerCode },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), MergedCartToken: sql.NVarChar(64) }
  );
  return {
    ok: Number(output.Resultado) === 1,
    message: String(output.Mensaje || ""),
    mergedCartToken: output.MergedCartToken as string | null,
  };
}

// ─── Admin: gestión de pedidos ────────────────────────

export async function listAdminOrders(params: {
  status?: string;
  from?: string;
  to?: string;
  search?: string;
  page?: number;
  limit?: number;
}) {
  const { rows, output } = await callSpOut<any>(
    "usp_Store_Order_Admin_List",
    {
      CompanyId: scope().companyId,
      Status: params.status || null,
      From: params.from || null,
      To: params.to || null,
      Search: params.search || null,
      Page: Math.max(params.page ?? 1, 1),
      Limit: Math.min(Math.max(params.limit ?? 25, 1), 200),
    },
    { TotalCount: sql.BigInt }
  );
  return {
    page: params.page ?? 1,
    limit: params.limit ?? 25,
    total: Number(output.TotalCount ?? 0),
    rows,
  };
}

export async function setOrderStatus(args: {
  orderNumber: string;
  status: "shipped" | "delivered" | "cancelled";
  carrier?: string;
  trackingNo?: string;
  actorUser?: string;
}) {
  const { output } = await callSpOut(
    "usp_Store_Order_Set_Status",
    {
      CompanyId: scope().companyId,
      OrderNumber: args.orderNumber,
      Status: args.status,
      Carrier: args.carrier ?? null,
      TrackingNo: args.trackingNo ?? null,
      ActorUser: args.actorUser ?? "admin",
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      CustomerName: sql.NVarChar(255),
      CustomerEmail: sql.NVarChar(255),
      OrderToken: sql.NVarChar(100),
      TotalAmount: sql.Decimal(18, 4),
      CurrencyCode: sql.NVarChar(20),
    }
  );
  return {
    ok: Number(output.Resultado) === 1,
    message: String(output.Mensaje || ""),
    customerName: output.CustomerName as string | null,
    customerEmail: output.CustomerEmail as string | null,
    orderToken: output.OrderToken as string | null,
    total: Number(output.TotalAmount ?? 0),
    currency: String(output.CurrencyCode || "USD"),
  };
}

// ─── Wishlist persistida (cliente logueado) ───────────

export async function listWishlist(customerCode: string) {
  return callSp<any>("usp_Store_Wishlist_List", {
    CompanyId: scope().companyId,
    CustomerCode: customerCode,
  });
}

export async function toggleWishlist(customerCode: string, productCode: string) {
  const { output } = await callSpOut(
    "usp_Store_Wishlist_Toggle",
    { CompanyId: scope().companyId, CustomerCode: customerCode, ProductCode: productCode },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), InWishlist: sql.Bit }
  );
  return {
    ok: Number(output.Resultado) === 1,
    inWishlist: Boolean(output.InWishlist),
    message: String(output.Mensaje || ""),
  };
}

// ─── Recently viewed (customer + guest) ───────────────

export async function listRecentlyViewed(args: {
  customerCode?: string | null;
  sessionToken?: string | null;
  limit?: number;
}) {
  return callSp<any>("usp_Store_Recently_Viewed_List", {
    CompanyId: scope().companyId,
    CustomerCode: args.customerCode ?? null,
    SessionToken: args.sessionToken ?? null,
    Limit: args.limit ?? 12,
  });
}

export async function trackRecentlyViewed(args: {
  customerCode?: string | null;
  sessionToken?: string | null;
  productCode: string;
}) {
  const { output } = await callSpOut(
    "usp_Store_Recently_Viewed_Track",
    {
      CompanyId: scope().companyId,
      CustomerCode: args.customerCode ?? null,
      SessionToken: args.sessionToken ?? null,
      ProductCode: args.productCode,
      KeepLast: 50,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  return { ok: Number(output.Resultado) === 1, message: String(output.Mensaje || "") };
}

// ─── Order tracking timeline ──────────────────────────

export interface TrackingEvent {
  documentNumber: string;
  eventCode: string;
  eventLabel: string;
  description: string | null;
  occurredAt: string;
  actorUser: string;
}

export async function getOrderTracking(args: { orderToken?: string; orderNumber?: string }) {
  return callSp<TrackingEvent>("usp_Store_Order_Tracking_Get", {
    CompanyId: scope().companyId,
    OrderToken: args.orderToken ?? null,
    OrderNumber: args.orderNumber ?? null,
  });
}

export async function addOrderTrackingEvent(args: {
  orderNumber: string;
  eventCode: string;
  eventLabel: string;
  description?: string;
  actorUser?: string;
}) {
  const { output } = await callSpOut(
    "usp_Store_Order_Tracking_Add",
    {
      CompanyId: scope().companyId,
      DocumentNumber: args.orderNumber,
      EventCode: args.eventCode,
      EventLabel: args.eventLabel,
      Description: args.description ?? null,
      ActorUser: args.actorUser ?? "system",
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  return { ok: Number(output.Resultado) === 1, message: String(output.Mensaje || "") };
}

// ─── FASE 3: Admin dashboard + RMA ─────────────────────

export async function getAdminMetrics(params: { from?: string; to?: string } = {}) {
  const rows = await callSp<any>("usp_Store_Admin_Metrics", {
    CompanyId: scope().companyId,
    From: params.from || null,
    To: params.to || null,
  });
  return rows[0] ?? {
    totalOrders: 0, pendingOrders: 0, paidOrders: 0, shippedOrders: 0,
    deliveredOrders: 0, cancelledOrders: 0, pendingReturns: 0,
    totalRevenueUsd: 0, avgTicketUsd: 0,
  };
}

export async function getAdminOrderDetail(orderNumber: string) {
  const rows = await callSp<any>("usp_Store_Admin_Order_Detail", {
    CompanyId: scope().companyId,
    OrderNumber: orderNumber,
  });
  if (!rows.length) return null;
  const head = rows[0];
  const lines = new Map<number, any>();
  const payments = new Map<number, any>();
  const events: any[] = [];
  for (const r of rows) {
    if (r.lineNumber != null && !lines.has(r.lineNumber)) {
      lines.set(r.lineNumber, {
        lineNumber: r.lineNumber,
        productCode: r.productCode,
        productName: r.productName,
        quantity: Number(r.quantity),
        unitPrice: Number(r.unitPrice),
        lineTotal: Number(r.lineTotal),
      });
    }
    if (r.paymentId != null && !payments.has(r.paymentId)) {
      payments.set(r.paymentId, {
        paymentId: r.paymentId,
        method: r.paymentMethod,
        reference: r.paymentRef,
        amount: Number(r.paymentAmount),
        date: r.paymentDate,
      });
    }
    if (r.eventCode != null) {
      const key = `${r.eventCode}|${r.eventOccurredAt}`;
      if (!events.some((e) => `${e.eventCode}|${e.occurredAt}` === key)) {
        events.push({
          eventCode: r.eventCode,
          eventLabel: r.eventLabel,
          description: r.eventDescription,
          occurredAt: r.eventOccurredAt,
        });
      }
    }
  }
  return {
    orderNumber: head.orderNumber,
    orderDate: head.orderDate,
    customerCode: head.customerCode,
    customerName: head.customerName,
    fiscalId: head.fiscalId,
    notes: head.notes,
    currencyCode: head.currencyCode,
    exchangeRate: Number(head.exchangeRate ?? 1),
    subtotal: Number(head.subtotal),
    taxAmount: Number(head.taxAmount),
    totalAmount: Number(head.totalAmount),
    isPaid: head.isPaid,
    isVoided: head.isVoided,
    isDelivered: head.isDelivered,
    shipped: Boolean(head.shipped),
    lines: Array.from(lines.values()),
    payments: Array.from(payments.values()),
    events,
  };
}

// ─── RMA (devoluciones) ────────────────────────────────

export async function createReturnRequest(args: {
  customerCode: string;
  orderNumber: string;
  reason: string;
  items?: Array<{
    lineNumber?: number;
    productCode: string;
    productName?: string;
    quantity?: number;
    unitPrice?: number;
    reason?: string;
  }>;
}) {
  const { output } = await callSpOut(
    "usp_Store_Return_Request_Create",
    {
      CompanyId: scope().companyId,
      OrderNumber: args.orderNumber,
      CustomerCode: args.customerCode,
      Reason: args.reason,
      ItemsJson: JSON.stringify(args.items ?? []),
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), ReturnId: sql.BigInt }
  );
  return {
    ok: Number(output.Resultado) === 1,
    message: String(output.Mensaje || ""),
    returnId: output.ReturnId ? Number(output.ReturnId) : null,
  };
}

export async function listReturns(args: {
  customerCode?: string | null;
  status?: string | null;
  page?: number;
  limit?: number;
}) {
  const { rows, output } = await callSpOut<any>(
    "usp_Store_Return_Request_List",
    {
      CompanyId: scope().companyId,
      CustomerCode: args.customerCode ?? null,
      Status: args.status ?? null,
      Page: Math.max(args.page ?? 1, 1),
      Limit: Math.min(Math.max(args.limit ?? 25, 1), 200),
    },
    { TotalCount: sql.BigInt }
  );
  return {
    page: args.page ?? 1,
    limit: args.limit ?? 25,
    total: Number(output.TotalCount ?? 0),
    rows,
  };
}

export async function getReturnDetail(returnId: number) {
  const rows = await callSp<any>("usp_Store_Return_Request_Get", {
    CompanyId: scope().companyId,
    ReturnId: returnId,
  });
  if (!rows.length) return null;
  const h = rows[0];
  const items = rows
    .filter((r: any) => r.productCode != null)
    .map((r: any) => ({
      lineNumber: r.lineNumber,
      productCode: r.productCode,
      productName: r.productName,
      quantity: Number(r.quantity ?? 0),
      unitPrice: Number(r.unitPrice ?? 0),
      reason: r.itemReason,
    }));
  return {
    returnId: Number(h.returnId),
    orderNumber: h.orderNumber,
    customerCode: h.customerCode,
    status: h.status,
    reason: h.reason,
    adminNotes: h.adminNotes,
    refundAmount: Number(h.refundAmount ?? 0),
    refundCurrency: h.refundCurrency,
    refundMethod: h.refundMethod,
    refundReference: h.refundReference,
    requestedAt: h.requestedAt,
    processedAt: h.processedAt,
    items,
  };
}

export async function setReturnStatus(args: {
  returnId: number;
  status: "approved" | "rejected" | "in_transit" | "received" | "refunded";
  adminNotes?: string;
  refundMethod?: string;
  refundReference?: string;
  actorUser?: string;
}) {
  const { output } = await callSpOut(
    "usp_Store_Return_Request_Set_Status",
    {
      CompanyId: scope().companyId,
      ReturnId: args.returnId,
      Status: args.status,
      AdminNotes: args.adminNotes ?? null,
      RefundMethod: args.refundMethod ?? null,
      RefundReference: args.refundReference ?? null,
      ActorUser: args.actorUser ?? "admin",
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      OrderNumber: sql.NVarChar(60),
      CustomerCode: sql.NVarChar(24),
    }
  );
  return {
    ok: Number(output.Resultado) === 1,
    message: String(output.Mensaje || ""),
    orderNumber: output.OrderNumber as string | null,
    customerCode: output.CustomerCode as string | null,
  };
}
