import { Router } from "express";
import { z } from "zod";
import {
  listProducts,
  getProductByCodeFull,
  listCategories,
  listBrands,
  registerCustomer,
  loginCustomer,
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
    address: z.string().max(250).optional(),
    fiscalId: z.string().max(30).optional(),
  }),
  items: z.array(checkoutItemSchema).min(1).max(200),
  notes: z.string().max(500).optional(),
  addressId: z.number().int().positive().optional(),
  paymentMethodId: z.number().int().positive().optional(),
  paymentMethodType: z.string().max(30).optional(),
});

storeRouter.post("/checkout", async (req, res) => {
  try {
    const parsed = checkoutSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await checkout(parsed.data);
    if (!result.ok) return res.status(400).json(result);
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
    const user = verifyCustomerToken(req.headers.authorization);
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
    const user = verifyCustomerToken(req.headers.authorization);
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
    const user = verifyCustomerToken(req.headers.authorization);
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
    const user = verifyCustomerToken(req.headers.authorization);
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
    const user = verifyCustomerToken(req.headers.authorization);
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
    const user = verifyCustomerToken(req.headers.authorization);
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
    const user = verifyCustomerToken(req.headers.authorization);
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
    const user = verifyCustomerToken(req.headers.authorization);
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
    const user = verifyCustomerToken(req.headers.authorization);
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

storeRouter.get("/my/profile", async (req, res) => {
  try {
    const user = verifyCustomerToken(req.headers.authorization);
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
