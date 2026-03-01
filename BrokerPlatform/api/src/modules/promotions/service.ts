import { query, execute } from "../../db/query.js";

export async function listPromotions(params: { provider_id?: string; status?: string; page?: string; limit?: string }) {
    const page = Math.max(Number(params.page || 1), 1);
    const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
    const offset = (page - 1) * limit;
    const where: string[] = [];
    const p: Record<string, unknown> = {};
    if (params.provider_id) { where.push("pm.provider_id = @provider_id"); p.provider_id = Number(params.provider_id); }
    if (params.status) { where.push("pm.status = @status"); p.status = params.status; }
    const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
    const rows = await query<any>(
        `SELECT pm.*, pv.name AS provider_name, pr.name AS property_name
     FROM Promotions pm LEFT JOIN Providers pv ON pv.id = pm.provider_id LEFT JOIN Properties pr ON pr.id = pm.property_id
     ${clause} ORDER BY pm.valid_from DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, p);
    const totalR = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Promotions pm ${clause}`, p);
    return { page, limit, total: Number(totalR[0]?.total ?? 0), rows };
}

export async function createPromotion(body: Record<string, unknown>) {
    const result = await execute(
        `INSERT INTO Promotions (provider_id, property_id, name, discount_pct, discount_amount, valid_from, valid_to, promo_code, usage_limit, status)
     OUTPUT INSERTED.id
     VALUES (@provider_id, @property_id, @name, @disc_pct, @disc_amt, @valid_from, @valid_to, @promo_code, @usage_limit, @status)`,
        {
            provider_id: body.provider_id || null, property_id: body.property_id || null,
            name: body.name, disc_pct: body.discount_pct || 0, disc_amt: body.discount_amount || 0,
            valid_from: body.valid_from, valid_to: body.valid_to, promo_code: body.promo_code || null,
            usage_limit: body.usage_limit || 0, status: body.status || 'active',
        }
    );
    return { id: result.recordset[0]?.id };
}

export async function updatePromotion(id: number, body: Record<string, unknown>) {
    const sets: string[] = [];
    const p: Record<string, unknown> = { id };
    const fields = ["provider_id", "property_id", "name", "discount_pct", "discount_amount", "valid_from", "valid_to", "promo_code", "usage_limit", "status"];
    for (const f of fields) { if (body[f] !== undefined) { sets.push(`${f} = @${f}`); p[f] = body[f]; } }
    if (sets.length) await execute(`UPDATE Promotions SET ${sets.join(", ")} WHERE id = @id`, p);
    return { ok: true };
}

export async function deletePromotion(id: number) {
    await execute("DELETE FROM Promotions WHERE id = @id", { id });
    return { ok: true };
}

export async function validatePromoCode(code: string) {
    const rows = await query<any>(
        `SELECT * FROM Promotions WHERE promo_code = @code AND status = 'active' AND valid_from <= GETUTCDATE() AND valid_to >= GETUTCDATE() AND (usage_limit = 0 OR times_used < usage_limit)`,
        { code }
    );
    if (!rows[0]) return { valid: false, error: "invalid_or_expired" };
    return { valid: true, promotion: rows[0] };
}
