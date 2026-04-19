import { Router } from "express";
import { z } from "zod";
import { emitBusinessNotification, syncContact } from "../_shared/notify.js";
import { requireJwt, type AuthenticatedRequest } from "../../middleware/auth.js";
import { sendAuthMail } from "../usuarios/auth-mailer.service.js";
import {
  orderShippedTemplate,
  orderDeliveredTemplate,
} from "../usuarios/email-templates/base.js";
import {
  listProducts,
  getProductByCodeFull,
  listCategories,
  listBrands,
  registerCustomer,
  loginCustomer,
  googleAuthCustomer,
  verifyCustomerToken,
  checkout,
  getOrderByToken,
  getMyOrders,
  getProductReviews,
  createReview,
  listAddresses,
  upsertAddress,
  deleteAddress,
  listPaymentMethods,
  upsertPaymentMethod,
  deletePaymentMethod,
  listStorefrontCountries,
  listStorefrontCurrencies,
  getStorefrontCountry,
  listAdminOrders,
  setOrderStatus,
  getServerCart,
  upsertServerCartItem,
  removeServerCartItem,
  clearServerCart,
  mergeCartToCustomer,
  listWishlist,
  toggleWishlist,
  listRecentlyViewed,
  trackRecentlyViewed,
  getOrderTracking,
  getAdminMetrics,
  getAdminOrderDetail,
  createReturnRequest,
  listReturns,
  getReturnDetail,
  setReturnStatus,
} from "./service.js";

export const storeRouter = Router();

// ─── Catálogo público ──────────────────────────────────

const productListSchema = z.object({
  search: z.string().optional(),
  category: z.string().optional(),
  brand: z.string().optional(),
  priceMin: z.string().optional(),
  priceMax: z.string().optional(),
  minRating: z.string().optional(),
  inStockOnly: z.string().optional(),
  sortBy: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

storeRouter.get("/products", async (req, res) => {
  try {
    const parsed = productListSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query" });

    const data = await listProducts({
      search: parsed.data.search,
      category: parsed.data.category,
      brand: parsed.data.brand,
      priceMin: parsed.data.priceMin ? Number(parsed.data.priceMin) : undefined,
      priceMax: parsed.data.priceMax ? Number(parsed.data.priceMax) : undefined,
      minRating: parsed.data.minRating ? Number(parsed.data.minRating) : undefined,
      inStockOnly: parsed.data.inStockOnly !== "0" ? true : false,
      sortBy: parsed.data.sortBy,
      page: parsed.data.page ? Number(parsed.data.page) : undefined,
      limit: parsed.data.limit ? Number(parsed.data.limit) : undefined,
    });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.get("/products/:code", async (req, res) => {
  try {
    const product = await getProductByCodeFull(req.params.code);
    if (!product) return res.status(404).json({ error: "not_found" });
    res.json(product);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.get("/categories", async (_req, res) => {
  try {
    res.json(await listCategories());
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.get("/brands", async (_req, res) => {
  try {
    res.json(await listBrands());
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Storefront público (multi-moneda / país) ─────────

storeRouter.get("/storefront/countries", async (_req, res) => {
  try {
    res.json(await listStorefrontCountries());
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.get("/storefront/currencies", async (_req, res) => {
  try {
    res.json(await listStorefrontCurrencies());
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.get("/storefront/country/:code", async (req, res) => {
  try {
    const code = String(req.params.code || "").trim().toUpperCase();
    if (!/^[A-Z]{2}$/.test(code)) return res.status(400).json({ error: "invalid_country_code" });
    const country = await getStorefrontCountry(code);
    if (!country) return res.status(404).json({ error: "country_not_found" });
    res.json(country);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// Resolución por IP (Cloudflare CF-IPCountry header) — si no hay header, devuelve país base.
storeRouter.get("/storefront/resolve", async (req, res) => {
  try {
    const headerCountry = (req.headers["cf-ipcountry"] || req.headers["x-country-code"]) as string | undefined;
    const code = (headerCountry || "").trim().toUpperCase();
    if (code && /^[A-Z]{2}$/.test(code)) {
      const country = await getStorefrontCountry(code);
      if (country) return res.json({ source: "ip", ...country });
    }
    const fallback = await getStorefrontCountry("VE");
    if (!fallback) return res.status(404).json({ error: "no_default_country" });
    res.json({ source: "default", ...fallback });
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Auth de clientes ──────────────────────────────────

const registerSchema = z.object({
  email: z.string().email(),
  name: z.string().min(2).max(200),
  password: z.string().min(6).max(100),
  phone: z.string().max(40).optional(),
  address: z.string().max(250).optional(),
  fiscalId: z.string().max(30).optional(),
});

storeRouter.post("/auth/register", async (req, res) => {
  try {
    const parsed = registerSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await registerCustomer(parsed.data);
    if (!result.ok) return res.status(409).json(result);

    // Notify: welcome email + sync contact (best-effort)
    if (result.ok || (result as any).success) {
      const email = String(req.body.email ?? "").trim();
      if (email) {
        syncContact({ email, name: req.body.name, tags: ["ecommerce"] }).catch(() => {});
        emitBusinessNotification({
          event: "CUSTOMER_REGISTERED",
          to: email,
          subject: "Bienvenido a Zentto Store",
          data: { Nombre: req.body.name ?? "", Email: email },
        }).catch(() => {});
      }
    }

    res.status(201).json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

storeRouter.post("/auth/login", async (req, res) => {
  try {
    const parsed = loginSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body" });

    const result = await loginCustomer(parsed.data.email, parsed.data.password);
    if (!result.ok) return res.status(401).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Google OAuth ──────────────────────────────────────

storeRouter.post("/auth/google", async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken || typeof idToken !== "string") {
      return res.status(400).json({ error: "invalid_body", message: "idToken es requerido" });
    }

    const result = await googleAuthCustomer(idToken);
    if (!result.ok) return res.status(401).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Reseñas ──────────────────────────────────────────

storeRouter.get("/products/:code/reviews", async (req, res) => {
  try {
    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 20;
    const data = await getProductReviews(req.params.code, page, limit);
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const reviewSchema = z.object({
  productCode: z.string().min(1).max(80),
  rating: z.number().int().min(1).max(5),
  title: z.string().max(200).optional(),
  comment: z.string().min(1).max(2000),
  reviewerName: z.string().max(200).optional(),
});

storeRouter.post("/reviews", async (req, res) => {
  try {
    const parsed = reviewSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await createReview(parsed.data);
    if (!result.ok) return res.status(400).json(result);
    res.status(201).json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Checkout ──────────────────────────────────────────

const checkoutItemSchema = z.object({
  productCode: z.string().min(1).max(80),
  productName: z.string().min(1).max(250),
  quantity: z.number().positive(),
  unitPrice: z.number().nonnegative(),
  taxRate: z.number().nonnegative(),
  subtotal: z.number().nonnegative(),
  taxAmount: z.number().nonnegative(),
});

const checkoutSchema = z.object({
  customer: z.object({
    name: z.string().min(2).max(200),
    email: z.string().email(),
    phone: z.string().max(40).optional(),
    address: z.string().max(500).optional(),
    billingAddress: z.string().max(500).optional(),
    fiscalId: z.string().max(30).optional(),
  }),
  items: z.array(checkoutItemSchema).min(1).max(200),
  notes: z.string().max(500).optional(),
  addressId: z.number().int().positive().optional(),
  billingAddressId: z.number().int().positive().optional(),
  paymentMethodId: z.number().int().positive().optional(),
  paymentMethodType: z.string().max(30).optional(),
  currencyCode: z.string().length(3).optional(),
  exchangeRate: z.number().positive().max(1_000_000).optional(),
  countryCode: z.string().length(2).optional(),
});

storeRouter.post("/checkout", async (req, res) => {
  try {
    const parsed = checkoutSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await checkout(parsed.data);
    if (!result.ok) return res.status(400).json(result);

    // Notify: orden creada (best-effort)
    const email = String(parsed.data.customer.email ?? "").trim().toLowerCase();
    const total = parsed.data.items.reduce((s, i) => s + i.subtotal + i.taxAmount, 0);
    const currency = (parsed.data.currencyCode ?? "USD").toUpperCase();
    if (email && result.orderNumber) {
      try {
        const { orderCreatedTemplate } = await import("../usuarios/email-templates/base.js");
        const trackingUrl = `${process.env.PUBLIC_FRONTEND_URL || "https://app.zentto.net"}/confirmacion/${result.orderToken}`;
        const tpl = orderCreatedTemplate({
          customerName: parsed.data.customer.name,
          orderNumber: result.orderNumber,
          total: total.toFixed(2),
          currency,
          trackingUrl,
          items: parsed.data.items.map((i) => ({
            name: i.productName,
            quantity: i.quantity,
            unitPrice: `${currency} ${i.unitPrice.toFixed(2)}`,
            lineTotal: `${currency} ${(i.subtotal + i.taxAmount).toFixed(2)}`,
          })),
        });
        sendAuthMail({ to: email, subject: tpl.subject, text: tpl.text, html: tpl.html }).catch(() => {});
        emitBusinessNotification({
          event: "ORDER_CREATED",
          to: email,
          subject: tpl.subject,
          data: { Orden: result.orderNumber, Total: total.toFixed(2), Moneda: currency, Tracking: trackingUrl },
        }).catch(() => {});
      } catch (notifyErr) {
        console.error("[checkout] notify error:", notifyErr);
      }
    }

    res.status(201).json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Consulta de pedidos ───────────────────────────────

storeRouter.get("/orders/:token", async (req, res) => {
  try {
    const order = await getOrderByToken(req.params.token);
    if (!order) return res.status(404).json({ error: "not_found" });
    res.json(order);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Rutas autenticadas (JWT opcional en handler) ──────

storeRouter.get("/my/orders", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });

    // Obtener customerCode del usuario
    const { callSp } = await import("../../db/query.js");
    const rows = await callSp<{ customerCode: string }>(
      "usp_Store_Customer_Login",
      { Email: user.name ?? user.sub }
    );
    const customerCode = rows[0]?.customerCode;
    if (!customerCode) return res.status(404).json({ error: "customer_not_found" });

    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 20;
    const result = await getMyOrders(customerCode, page, limit);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Direcciones del cliente ─────────────────────────

const addressSchema = z.object({
  label: z.string().min(1).max(50),
  recipientName: z.string().min(2).max(200),
  phone: z.string().max(40).optional(),
  addressLine: z.string().min(5).max(300),
  city: z.string().max(100).optional(),
  state: z.string().max(100).optional(),
  zipCode: z.string().max(20).optional(),
  country: z.string().max(50).optional(),
  instructions: z.string().max(300).optional(),
  isDefault: z.boolean().optional(),
});

storeRouter.get("/my/addresses", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });

    const { callSp } = await import("../../db/query.js");
    const rows = await callSp<{ customerCode: string }>(
      "usp_Store_Customer_Login",
      { Email: user.name ?? user.sub }
    );
    const customerCode = rows[0]?.customerCode;
    if (!customerCode) return res.status(404).json({ error: "customer_not_found" });

    const addresses = await listAddresses(customerCode);
    res.json(addresses);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.post("/my/addresses", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });

    const parsed = addressSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const { callSp } = await import("../../db/query.js");
    const rows = await callSp<{ customerCode: string }>(
      "usp_Store_Customer_Login",
      { Email: user.name ?? user.sub }
    );
    const customerCode = rows[0]?.customerCode;
    if (!customerCode) return res.status(404).json({ error: "customer_not_found" });

    const result = await upsertAddress(customerCode, parsed.data);
    if (!result.ok) return res.status(400).json(result);
    res.status(201).json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.put("/my/addresses/:id", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });

    const parsed = addressSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const { callSp } = await import("../../db/query.js");
    const rows = await callSp<{ customerCode: string }>(
      "usp_Store_Customer_Login",
      { Email: user.name ?? user.sub }
    );
    const customerCode = rows[0]?.customerCode;
    if (!customerCode) return res.status(404).json({ error: "customer_not_found" });

    const result = await upsertAddress(customerCode, {
      ...parsed.data,
      addressId: Number(req.params.id),
    });
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.delete("/my/addresses/:id", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });

    const { callSp } = await import("../../db/query.js");
    const rows = await callSp<{ customerCode: string }>(
      "usp_Store_Customer_Login",
      { Email: user.name ?? user.sub }
    );
    const customerCode = rows[0]?.customerCode;
    if (!customerCode) return res.status(404).json({ error: "customer_not_found" });

    const result = await deleteAddress(customerCode, Number(req.params.id));
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Métodos de pago del cliente ─────────────────────

const paymentMethodSchema = z.object({
  methodType: z.enum(["PAGO_MOVIL", "TRANSFERENCIA", "ZELLE", "EFECTIVO", "TARJETA"]),
  label: z.string().min(1).max(50),
  bankName: z.string().max(100).optional(),
  accountPhone: z.string().max(40).optional(),
  accountNumber: z.string().max(40).optional(),
  accountEmail: z.string().email().optional(),
  holderName: z.string().max(200).optional(),
  holderFiscalId: z.string().max(30).optional(),
  cardType: z.enum(["VISA", "MASTERCARD", "AMEX"]).optional(),
  cardLast4: z.string().length(4).optional(),
  cardExpiry: z.string().max(7).optional(),
  isDefault: z.boolean().optional(),
});

storeRouter.get("/my/payment-methods", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });

    const { callSp } = await import("../../db/query.js");
    const rows = await callSp<{ customerCode: string }>(
      "usp_Store_Customer_Login",
      { Email: user.name ?? user.sub }
    );
    const customerCode = rows[0]?.customerCode;
    if (!customerCode) return res.status(404).json({ error: "customer_not_found" });

    const methods = await listPaymentMethods(customerCode);
    res.json(methods);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.post("/my/payment-methods", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });

    const parsed = paymentMethodSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const { callSp } = await import("../../db/query.js");
    const rows = await callSp<{ customerCode: string }>(
      "usp_Store_Customer_Login",
      { Email: user.name ?? user.sub }
    );
    const customerCode = rows[0]?.customerCode;
    if (!customerCode) return res.status(404).json({ error: "customer_not_found" });

    const result = await upsertPaymentMethod(customerCode, parsed.data);
    if (!result.ok) return res.status(400).json(result);
    res.status(201).json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.put("/my/payment-methods/:id", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });

    const parsed = paymentMethodSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const { callSp } = await import("../../db/query.js");
    const rows = await callSp<{ customerCode: string }>(
      "usp_Store_Customer_Login",
      { Email: user.name ?? user.sub }
    );
    const customerCode = rows[0]?.customerCode;
    if (!customerCode) return res.status(404).json({ error: "customer_not_found" });

    const result = await upsertPaymentMethod(customerCode, {
      ...parsed.data,
      paymentMethodId: Number(req.params.id),
    });
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.delete("/my/payment-methods/:id", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });

    const { callSp } = await import("../../db/query.js");
    const rows = await callSp<{ customerCode: string }>(
      "usp_Store_Customer_Login",
      { Email: user.name ?? user.sub }
    );
    const customerCode = rows[0]?.customerCode;
    if (!customerCode) return res.status(404).json({ error: "customer_not_found" });

    const result = await deletePaymentMethod(customerCode, Number(req.params.id));
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Carrito server-side (sync multi-device) ──────────

const cartItemSchema = z.object({
  cartToken: z.string().min(8).max(64),
  productCode: z.string().min(1).max(60),
  productName: z.string().max(250).optional(),
  imageUrl: z.string().url().max(500).optional(),
  quantity: z.number().nonnegative().max(10000),
  unitPrice: z.number().nonnegative(),
  taxRate: z.number().nonnegative().max(1).default(0),
  currencyCode: z.string().length(3).optional(),
  countryCode: z.string().length(2).optional(),
  exchangeRate: z.number().positive().max(1_000_000).optional(),
  customerCode: z.string().max(24).optional(),
});

storeRouter.get("/cart", async (req, res) => {
  try {
    const token = String(req.query.token || "").trim();
    if (!token) return res.status(400).json({ error: "missing_token" });
    const cart = await getServerCart(token);
    if (!cart) return res.json({ cartToken: token, items: [] });
    res.json(cart);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.post("/cart/items", async (req, res) => {
  try {
    const parsed = cartItemSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });
    const result = await upsertServerCartItem(parsed.data);
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.delete("/cart/items/:productCode", async (req, res) => {
  try {
    const token = String(req.query.token || "").trim();
    if (!token) return res.status(400).json({ error: "missing_token" });
    const result = await removeServerCartItem(token, req.params.productCode);
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.post("/cart/clear", async (req, res) => {
  try {
    const token = String(req.body.cartToken || "").trim();
    if (!token) return res.status(400).json({ error: "missing_token" });
    const result = await clearServerCart(token);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// Merge requiere auth (cliente logueado): JWT con name=email
storeRouter.post("/cart/merge", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });
    const cartToken = String(req.body.cartToken || "").trim();
    if (!cartToken) return res.status(400).json({ error: "missing_token" });

    const { callSp } = await import("../../db/query.js");
    const rows = await callSp<{ customerCode: string }>(
      "usp_Store_Customer_Login",
      { Email: user.name ?? user.sub }
    );
    const customerCode = rows[0]?.customerCode;
    if (!customerCode) return res.status(404).json({ error: "customer_not_found" });

    const result = await mergeCartToCustomer(cartToken, customerCode);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Wishlist (cliente logueado) ──────────────────────

async function getCustomerCodeFromAuth(req: any): Promise<string | null> {
  const user = await verifyCustomerToken(req.headers.authorization);
  if (!user) return null;
  const { callSp } = await import("../../db/query.js");
  const rows = await callSp<{ customerCode: string }>(
    "usp_Store_Customer_Login",
    { Email: user.name ?? user.sub }
  );
  return rows[0]?.customerCode ?? null;
}

storeRouter.get("/wishlist", async (req, res) => {
  try {
    const customerCode = await getCustomerCodeFromAuth(req);
    if (!customerCode) return res.status(401).json({ error: "not_authenticated" });
    res.json(await listWishlist(customerCode));
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.post("/wishlist/toggle", async (req, res) => {
  try {
    const productCode = String(req.body?.productCode || "").trim();
    if (!productCode) return res.status(400).json({ error: "missing_product_code" });
    const customerCode = await getCustomerCodeFromAuth(req);
    if (!customerCode) return res.status(401).json({ error: "not_authenticated" });
    res.json(await toggleWishlist(customerCode, productCode));
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Recently viewed (customer + guest) ────────────────

storeRouter.get("/recently-viewed", async (req, res) => {
  try {
    const sessionToken = (req.query.session as string | undefined) || null;
    const customerCode = await getCustomerCodeFromAuth(req).catch(() => null);
    if (!customerCode && !sessionToken) {
      return res.status(400).json({ error: "missing_session_or_auth" });
    }
    const limit = req.query.limit ? Number(req.query.limit) : 12;
    res.json(await listRecentlyViewed({ customerCode, sessionToken, limit }));
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.post("/recently-viewed", async (req, res) => {
  try {
    const productCode = String(req.body?.productCode || "").trim();
    if (!productCode) return res.status(400).json({ error: "missing_product_code" });
    const sessionToken = String(req.body?.sessionToken || "").trim() || null;
    const customerCode = await getCustomerCodeFromAuth(req).catch(() => null);
    if (!customerCode && !sessionToken) {
      return res.status(400).json({ error: "missing_session_or_auth" });
    }
    res.json(await trackRecentlyViewed({ customerCode, sessionToken, productCode }));
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Order tracking timeline (público vía orderToken) ─

storeRouter.get("/orders/:token/tracking", async (req, res) => {
  try {
    const events = await getOrderTracking({ orderToken: req.params.token });
    res.json(events);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── RMA — devoluciones (cliente) ─────────────────────

const returnCreateSchema = z.object({
  orderNumber: z.string().min(3).max(60),
  reason: z.string().min(1).max(500),
  items: z.array(z.object({
    lineNumber: z.number().int().optional(),
    productCode: z.string().min(1).max(60),
    productName: z.string().max(250).optional(),
    quantity: z.number().positive().optional(),
    unitPrice: z.number().nonnegative().optional(),
    reason: z.string().max(250).optional(),
  })).max(200).optional(),
});

storeRouter.post("/returns", async (req, res) => {
  try {
    const customerCode = await getCustomerCodeFromAuth(req);
    if (!customerCode) return res.status(401).json({ error: "not_authenticated" });
    const parsed = returnCreateSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });
    const result = await createReturnRequest({ customerCode, ...parsed.data });
    if (!result.ok) return res.status(400).json(result);
    res.status(201).json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.get("/my/returns", async (req, res) => {
  try {
    const customerCode = await getCustomerCodeFromAuth(req);
    if (!customerCode) return res.status(401).json({ error: "not_authenticated" });
    const data = await listReturns({
      customerCode,
      status: (req.query.status as string | undefined) || null,
      page: req.query.page ? Number(req.query.page) : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.get("/my/returns/:id", async (req, res) => {
  try {
    const customerCode = await getCustomerCodeFromAuth(req);
    if (!customerCode) return res.status(401).json({ error: "not_authenticated" });
    const detail = await getReturnDetail(Number(req.params.id));
    if (!detail) return res.status(404).json({ error: "not_found" });
    if (detail.customerCode !== customerCode) return res.status(403).json({ error: "forbidden" });
    res.json(detail);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Admin (requireJwt + isAdmin) — gestión de pedidos ──

const setStatusSchema = z.object({
  status: z.enum(["shipped", "delivered", "cancelled"]),
  carrier: z.string().max(120).optional(),
  trackingNo: z.string().max(120).optional(),
});

const returnStatusSchema = z.object({
  status: z.enum(["approved", "rejected", "in_transit", "received", "refunded"]),
  adminNotes: z.string().max(500).optional(),
  refundMethod: z.string().max(30).optional(),
  refundReference: z.string().max(100).optional(),
});

storeRouter.get("/admin/metrics", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
    res.json(await getAdminMetrics({
      from: req.query.from as string | undefined,
      to: req.query.to as string | undefined,
    }));
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.get("/admin/orders/:orderNumber", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
    const detail = await getAdminOrderDetail(req.params.orderNumber);
    if (!detail) return res.status(404).json({ error: "not_found" });
    res.json(detail);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.get("/admin/returns", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
    res.json(await listReturns({
      customerCode: null,
      status: (req.query.status as string | undefined) || null,
      page: req.query.page ? Number(req.query.page) : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    }));
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.get("/admin/returns/:id", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
    const detail = await getReturnDetail(Number(req.params.id));
    if (!detail) return res.status(404).json({ error: "not_found" });
    res.json(detail);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.post("/admin/returns/:id/status", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
    const parsed = returnStatusSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });
    const result = await setReturnStatus({
      returnId: Number(req.params.id),
      status: parsed.data.status,
      adminNotes: parsed.data.adminNotes,
      refundMethod: parsed.data.refundMethod,
      refundReference: parsed.data.refundReference,
      actorUser: user.name || user.sub,
    });
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.get("/admin/orders", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });

    const data = await listAdminOrders({
      status: req.query.status as string | undefined,
      from: req.query.from as string | undefined,
      to: req.query.to as string | undefined,
      search: req.query.search as string | undefined,
      page: req.query.page ? Number(req.query.page) : undefined,
      limit: req.query.limit ? Number(req.query.limit) : undefined,
    });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.post("/admin/orders/:orderNumber/status", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });

    const parsed = setStatusSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await setOrderStatus({
      orderNumber: req.params.orderNumber,
      status: parsed.data.status,
      carrier: parsed.data.carrier,
      trackingNo: parsed.data.trackingNo,
      actorUser: user.name || user.sub,
    });
    if (!result.ok) return res.status(400).json(result);

    // Disparar email + notify según status (best-effort)
    if (result.customerEmail && result.orderToken) {
      const trackingUrl = `${process.env.PUBLIC_FRONTEND_URL || "https://app.zentto.net"}/confirmacion/${result.orderToken}`;
      try {
        if (parsed.data.status === "shipped") {
          const tpl = orderShippedTemplate({
            customerName: result.customerName || "Cliente",
            orderNumber: req.params.orderNumber,
            carrier: parsed.data.carrier,
            trackingNumber: parsed.data.trackingNo,
            trackingUrl,
          });
          sendAuthMail({ to: result.customerEmail, subject: tpl.subject, text: tpl.text, html: tpl.html }).catch(() => {});
          emitBusinessNotification({
            event: "ORDER_SHIPPED",
            to: result.customerEmail,
            subject: tpl.subject,
            data: {
              Orden: req.params.orderNumber,
              Transportista: parsed.data.carrier ?? "",
              Guia: parsed.data.trackingNo ?? "",
              Tracking: trackingUrl,
            },
          }).catch(() => {});
        } else if (parsed.data.status === "delivered") {
          const tpl = orderDeliveredTemplate({
            customerName: result.customerName || "Cliente",
            orderNumber: req.params.orderNumber,
            reviewUrl: trackingUrl + "?review=1",
          });
          sendAuthMail({ to: result.customerEmail, subject: tpl.subject, text: tpl.text, html: tpl.html }).catch(() => {});
          emitBusinessNotification({
            event: "ORDER_DELIVERED",
            to: result.customerEmail,
            subject: tpl.subject,
            data: { Orden: req.params.orderNumber, Resena: trackingUrl + "?review=1" },
          }).catch(() => {});
        }
      } catch (notifyErr) {
        console.error("[admin/orders/status] notify error:", notifyErr);
      }
    }

    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

storeRouter.get("/my/profile", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });

    const { callSp } = await import("../../db/query.js");
    const rows = await callSp<any>(
      "usp_Store_Customer_Login",
      { Email: user.name ?? user.sub }
    );
    const customer = rows[0];
    if (!customer) return res.status(404).json({ error: "customer_not_found" });

    res.json({
      email: customer.email,
      name: customer.displayName,
      customerCode: customer.customerCode,
      phone: customer.phone,
      address: customer.address,
      fiscalId: customer.fiscalId,
    });
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});
