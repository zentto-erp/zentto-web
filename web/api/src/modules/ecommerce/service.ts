import { callSp, callSpOut, sql } from "../../db/query.js";
import { signJwt, verifyJwt, type JwtPayload } from "../../auth/jwt.js";
import bcrypt from "bcryptjs";

const DEFAULT_COMPANY = 1;
const DEFAULT_BRANCH = 1;

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
      CompanyId: DEFAULT_COMPANY,
      BranchId: DEFAULT_BRANCH,
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
      CompanyId: DEFAULT_COMPANY,
      BranchId: DEFAULT_BRANCH,
      Code: code,
    }
  );

  // SP retorna 2 recordsets: [0] = producto, [1] = imágenes
  // callSp solo retorna el primer recordset, usamos callSpOut para múltiples
  return rows[0] ?? null;
}

export async function getProductByCodeFull(code: string) {
  const pool = (await import("../../db/mssql.js")).getPool();
  const p = await pool;
  const request = p.request();
  request.input("CompanyId", DEFAULT_COMPANY);
  request.input("BranchId", DEFAULT_BRANCH);
  request.input("Code", code);

  const result = await request.execute("usp_Store_Product_GetByCode");

  const sets = result.recordsets as any[];
  const product = sets[0]?.[0] ?? null;
  const images = sets[1] ?? [];
  const highlights = (sets[2] ?? []).map((h: any) => h.text);
  const specs = (sets[3] ?? []).map((s: any) => ({
    group: s.group,
    key: s.key,
    value: s.value,
  }));

  // Recordset 5: Variantes del producto
  const variantsRaw = sets[4] ?? [];
  // Recordset 6: Opciones de variante por código
  const variantOptionsRaw = sets[5] ?? [];
  // Recordset 7: Atributos de industria
  const industryAttributesRaw = sets[6] ?? [];

  // Agrupar opciones por código de variante
  const optionsByCode: Record<string, any[]> = {};
  for (const opt of variantOptionsRaw) {
    (optionsByCode[opt.code] ??= []).push({
      groupCode: opt.groupCode,
      groupName: opt.groupName,
      displayType: opt.displayType,
      optionCode: opt.optionCode,
      optionLabel: opt.optionLabel,
      colorHex: opt.colorHex,
      imageUrl: opt.optionImageUrl,
    });
  }

  const variants = variantsRaw.map((v: any) => ({
    variantId: v.variantId,
    code: v.code,
    name: v.name,
    sku: v.sku,
    price: v.price,
    priceDelta: v.priceDelta,
    stock: v.stock,
    isDefault: v.isDefault,
    sortOrder: v.sortOrder,
    options: optionsByCode[v.code] ?? [],
  }));

  const industryAttributes = industryAttributesRaw.map((a: any) => ({
    key: a.key,
    label: a.label,
    dataType: a.dataType,
    displayGroup: a.displayGroup,
    value: a.valueText ?? a.valueNumber ?? a.valueDate ?? a.valueBoolean,
    valueText: a.valueText,
    valueNumber: a.valueNumber,
    valueDate: a.valueDate,
    valueBoolean: a.valueBoolean,
  }));

  if (!product) return null;

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
    CompanyId: DEFAULT_COMPANY,
  });
}

export async function listBrands() {
  return callSp<StoreBrand>("usp_Store_Brand_List", {
    CompanyId: DEFAULT_COMPANY,
  });
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
      CompanyId: DEFAULT_COMPANY,
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

  return { ok: true, message: mensaje };
}

export async function loginCustomer(email: string, password: string) {
  const rows = await callSp<CustomerLoginRow>(
    "usp_Store_Customer_Login",
    { Email: email.toLowerCase().trim() }
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
    companyId: DEFAULT_COMPANY,
    branchId: DEFAULT_BRANCH,
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

export function verifyCustomerToken(authHeader?: string) {
  if (!authHeader) return null;
  const [scheme, token] = authHeader.split(" ");
  if (scheme !== "Bearer" || !token) return null;
  try {
    return verifyJwt(token);
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
  paymentMethodId?: number;
  paymentMethodType?: string;
}) {
  // 1. Buscar o crear cliente
  const { output: custOut } = await callSpOut(
    "usp_Store_Customer_FindOrCreate",
    {
      CompanyId: DEFAULT_COMPANY,
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
      CompanyId: DEFAULT_COMPANY,
      BranchId: DEFAULT_BRANCH,
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

  return {
    ok: true,
    orderNumber: orderOut.OrderNumber as string,
    orderToken: orderOut.OrderToken as string,
    message: orderOut.Mensaje as string,
  };
}

// ─── Consulta de pedidos ───────────────────────────────

export async function getOrderByToken(token: string) {
  const pool = (await import("../../db/mssql.js")).getPool();
  const p = await pool;
  const request = p.request();
  request.input("CompanyId", DEFAULT_COMPANY);
  request.input("Token", token);

  const result = await request.execute("usp_Store_Order_GetByToken");

  const sets = result.recordsets as any[];
  const header = sets[0]?.[0] ?? null;
  const lines = sets[1] ?? [];

  if (!header) return null;
  return { ...header, lines };
}

export async function getMyOrders(customerCode: string, page = 1, limit = 20) {
  const { rows, output } = await callSpOut<any>(
    "usp_Store_Order_List",
    {
      CompanyId: DEFAULT_COMPANY,
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
  const pool = (await import("../../db/mssql.js")).getPool();
  const p = await pool;
  const request = p.request();
  request.input("CompanyId", DEFAULT_COMPANY);
  request.input("ProductCode", productCode);
  request.input("Page", Math.max(page, 1));
  request.input("Limit", Math.min(Math.max(limit, 1), 50));

  const result = await request.execute("usp_Store_Review_List");

  const sets = result.recordsets as any[];
  const summary = sets[0]?.[0] ?? { avgRating: 0, totalCount: 0, star1: 0, star2: 0, star3: 0, star4: 0, star5: 0 };
  const reviews = sets[1] ?? [];

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
      CompanyId: DEFAULT_COMPANY,
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
    CompanyId: DEFAULT_COMPANY,
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
      CompanyId: DEFAULT_COMPANY,
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
    { AddressId: addressId, CustomerCode: customerCode },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  const resultado = output.Resultado as number;
  if (resultado !== 1) return { ok: false, error: output.Mensaje as string };
  return { ok: true, message: output.Mensaje as string };
}

// ─── Métodos de pago del cliente ─────────────────────

export async function listPaymentMethods(customerCode: string) {
  return callSp<any>("usp_Store_PaymentMethod_List", {
    CompanyId: DEFAULT_COMPANY,
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
      CompanyId: DEFAULT_COMPANY,
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
    { PaymentMethodId: paymentMethodId, CustomerCode: customerCode },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  const resultado = output.Resultado as number;
  if (resultado !== 1) return { ok: false, error: output.Mensaje as string };
  return { ok: true, message: output.Mensaje as string };
}

export async function getOrderByNumber(orderNumber: string) {
  const pool = (await import("../../db/mssql.js")).getPool();
  const p = await pool;
  const request = p.request();
  request.input("CompanyId", DEFAULT_COMPANY);
  request.input("OrderNumber", orderNumber);

  const result = await request.execute("usp_Store_Order_GetByNumber");

  const sets = result.recordsets as any[];
  const header = sets[0]?.[0] ?? null;
  const lines = sets[1] ?? [];

  if (!header) return null;
  return { ...header, lines };
}
