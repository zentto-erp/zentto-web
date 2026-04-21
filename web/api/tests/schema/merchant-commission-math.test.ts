/**
 * merchant-commission-math.test.ts
 *
 * Tests puros (sin DB) del cálculo de MerchantCommission — replica la
 * lógica del SP usp_store_merchant_commission_generate para verificar que
 * el fix negocio afiliado+merchant funciona correctamente:
 *
 *   - GrossAmount        = l.SubTotal
 *   - CommissionAmount   = round(GrossAmount * rate / 100, 2)
 *   - MerchantEarning    = round(GrossAmount - CommissionAmount, 2)
 *   - AffiliateDeduction = min(AffPerLine, CommissionAmount, AffRemaining), >= 0
 *   - NetZenttoRevenue   = CommissionAmount - AffiliateDeduction, >= 0
 *   - AffPerLine         = round(AffiliateTotal / linesWithMerchant, 2)
 *
 * Escenarios cubiertos:
 *   1. Solo merchant (sin afiliado) — NetZenttoRevenue = CommissionAmount
 *   2. Merchant + afiliado (caso 3 del audit) — descontado de la commission, no del total
 *   3. Orden multi-merchant — prorrateo correcto del afiliado entre líneas
 *   4. Orden sin merchant — 0 commissions generadas
 *   5. Afiliado mayor a la commission retenida — AffiliateDeduction capped, nunca negativo
 */

import { describe, it, expect } from "vitest";

type Line = {
  lineId: number;
  merchantId: number | null;
  productCode: string;
  category?: string | null;
  subtotal: number;
  merchantRate: number | null;
};

type Commission = {
  lineId: number;
  merchantId: number;
  productCode: string;
  category: string | null;
  grossAmount: number;
  commissionRate: number;
  commissionAmount: number;
  merchantEarning: number;
  affiliateDeduction: number;
  netZenttoRevenue: number;
};

type Result = {
  commissions: Commission[];
  commissionsCreated: number;
  totalMerchantEarning: number;
  totalZenttoRevenue: number;
};

/** round a 2 decimales como ROUND(..., 2) del SP. */
function r2(n: number): number {
  return Math.round(n * 100) / 100;
}

/**
 * Réplica en JS puro de la lógica del SP usp_store_merchant_commission_generate.
 * Mantener idéntica al SP para que los tests sirvan como contrato.
 */
function computeMerchantCommissions(
  lines: Line[],
  affiliateCommissionAmount = 0,
  fallbackRate = 12,
): Result {
  const merchantLines = lines.filter((l) => l.merchantId !== null);
  const linesTotal = merchantLines.length;

  if (linesTotal === 0) {
    return { commissions: [], commissionsCreated: 0, totalMerchantEarning: 0, totalZenttoRevenue: 0 };
  }

  const affPerLine = affiliateCommissionAmount > 0 ? r2(affiliateCommissionAmount / linesTotal) : 0;
  let affRemaining = affiliateCommissionAmount;

  const commissions: Commission[] = [];
  let totalMerchantEarning = 0;
  let totalZenttoRevenue = 0;

  for (const l of merchantLines) {
    const rate = l.merchantRate ?? fallbackRate;
    const commission = r2((l.subtotal * rate) / 100);
    const earning = r2(l.subtotal - commission);

    let affDed = Math.min(affPerLine, commission);
    affDed = Math.min(affDed, affRemaining);
    if (affDed < 0) affDed = 0;
    affRemaining = r2(affRemaining - affDed);

    let netZ = r2(commission - affDed);
    if (netZ < 0) netZ = 0;

    commissions.push({
      lineId: l.lineId,
      merchantId: l.merchantId!,
      productCode: l.productCode,
      category: l.category ?? null,
      grossAmount: l.subtotal,
      commissionRate: rate,
      commissionAmount: commission,
      merchantEarning: earning,
      affiliateDeduction: affDed,
      netZenttoRevenue: netZ,
    });

    totalMerchantEarning = r2(totalMerchantEarning + earning);
    totalZenttoRevenue = r2(totalZenttoRevenue + netZ);
  }

  return {
    commissions,
    commissionsCreated: commissions.length,
    totalMerchantEarning,
    totalZenttoRevenue,
  };
}

describe("MerchantCommission math — usp_store_merchant_commission_generate contract", () => {
  it("1. Solo merchant sin afiliado: NetZenttoRevenue == CommissionAmount", () => {
    const lines: Line[] = [
      { lineId: 1, merchantId: 101, productCode: "MP-1", category: "Electronica", subtotal: 1000, merchantRate: 8 },
    ];
    const r = computeMerchantCommissions(lines, 0);

    expect(r.commissionsCreated).toBe(1);
    const c = r.commissions[0];
    expect(c.grossAmount).toBe(1000);
    expect(c.commissionAmount).toBe(80);
    expect(c.merchantEarning).toBe(920);
    expect(c.affiliateDeduction).toBe(0);
    expect(c.netZenttoRevenue).toBe(80);
    expect(r.totalMerchantEarning).toBe(920);
    expect(r.totalZenttoRevenue).toBe(80);
  });

  it("2. Merchant + afiliado (caso audit: $500 electronica con afiliado 3%)", () => {
    // Caso 3 del audit marketplace-flow-audit.md §9:
    // Venta bruta 500, merchant rate 12%, afiliado 3% (= $15)
    // Post-fix: AffiliateDeduction sale de la commission (60), no del total (500).
    //   commission = 60, merchant_earning = 440, aff_deduction = 15, net_zentto = 45
    const lines: Line[] = [
      { lineId: 1, merchantId: 200, productCode: "MP-TH-1", category: "Electronica", subtotal: 500, merchantRate: 12 },
    ];
    const r = computeMerchantCommissions(lines, 15);

    const c = r.commissions[0];
    expect(c.commissionAmount).toBe(60);
    expect(c.merchantEarning).toBe(440);
    expect(c.affiliateDeduction).toBe(15);
    expect(c.netZenttoRevenue).toBe(45);
    // Invariante clave: net_zentto nunca negativo.
    expect(c.netZenttoRevenue).toBeGreaterThanOrEqual(0);
  });

  it("3. Orden multi-merchant: prorrateo del afiliado por línea", () => {
    // 2 merchants, 3 líneas. Afiliado $30 total → $10 por línea.
    const lines: Line[] = [
      { lineId: 1, merchantId: 10, productCode: "A", subtotal: 200, merchantRate: 10 }, // comm=20 earn=180 affDed=10 net=10
      { lineId: 2, merchantId: 10, productCode: "B", subtotal: 100, merchantRate: 10 }, // comm=10 earn=90  affDed=10 net=0
      { lineId: 3, merchantId: 20, productCode: "C", subtotal: 400, merchantRate: 15 }, // comm=60 earn=340 affDed=10 net=50
    ];
    const r = computeMerchantCommissions(lines, 30);

    expect(r.commissionsCreated).toBe(3);
    expect(r.commissions[0].affiliateDeduction).toBe(10);
    expect(r.commissions[0].netZenttoRevenue).toBe(10);
    expect(r.commissions[1].affiliateDeduction).toBe(10);
    expect(r.commissions[1].netZenttoRevenue).toBe(0);
    expect(r.commissions[2].affiliateDeduction).toBe(10);
    expect(r.commissions[2].netZenttoRevenue).toBe(50);

    // Total descontado = $30 exactos (no se pierde ni duplica nada del afiliado).
    const totalAffDed = r.commissions.reduce((s, c) => s + c.affiliateDeduction, 0);
    expect(totalAffDed).toBe(30);

    // Merchant total earnings
    expect(r.totalMerchantEarning).toBe(610); // 180 + 90 + 340
    expect(r.totalZenttoRevenue).toBe(60);    // 10 + 0 + 50
  });

  it("4. Orden sin merchant: 0 commissions, totales 0", () => {
    const lines: Line[] = [
      { lineId: 1, merchantId: null, productCode: "MASTER-1", subtotal: 500, merchantRate: null },
    ];
    const r = computeMerchantCommissions(lines, 10);
    expect(r.commissionsCreated).toBe(0);
    expect(r.totalMerchantEarning).toBe(0);
    expect(r.totalZenttoRevenue).toBe(0);
    expect(r.commissions.length).toBe(0);
  });

  it("5. Afiliado mayor a la commission: cap a la commission, net nunca negativo", () => {
    // Commission merchant = $20, afiliado reclama $50 por línea.
    // AffiliateDeduction debe quedar capped en 20. NetZenttoRevenue = 0, no -30.
    const lines: Line[] = [
      { lineId: 1, merchantId: 300, productCode: "X", subtotal: 200, merchantRate: 10 }, // commission = 20
    ];
    const r = computeMerchantCommissions(lines, 50);

    const c = r.commissions[0];
    expect(c.commissionAmount).toBe(20);
    expect(c.affiliateDeduction).toBe(20);     // capped al monto de la commission
    expect(c.netZenttoRevenue).toBe(0);        // nunca negativo
    expect(c.merchantEarning).toBe(180);       // intacto — el merchant cobra lo suyo
  });

  it("6. Fallback rate 12% cuando merchant sin CommissionRate definido", () => {
    const lines: Line[] = [
      { lineId: 1, merchantId: 400, productCode: "Y", subtotal: 1000, merchantRate: null },
    ];
    const r = computeMerchantCommissions(lines, 0);
    expect(r.commissions[0].commissionRate).toBe(12);
    expect(r.commissions[0].commissionAmount).toBe(120);
    expect(r.commissions[0].merchantEarning).toBe(880);
  });
});
