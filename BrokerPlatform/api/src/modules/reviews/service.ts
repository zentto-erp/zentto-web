import { query, execute } from "../../db/query.js";

export async function listReviews(params: { property_id?: string; customer_id?: string; status?: string; page?: string; limit?: string }) {
    const page = Math.max(Number(params.page || 1), 1);
    const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
    const offset = (page - 1) * limit;
    const where: string[] = [];
    const p: Record<string, unknown> = {};
    if (params.property_id) { where.push("r.property_id = @property_id"); p.property_id = Number(params.property_id); }
    if (params.customer_id) { where.push("r.customer_id = @customer_id"); p.customer_id = Number(params.customer_id); }
    if (params.status) { where.push("r.status = @status"); p.status = params.status; }
    const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
    const rows = await query<any>(
        `SELECT r.*, c.first_name, c.last_name, pr.name AS property_name
     FROM Reviews r JOIN Customers c ON c.id = r.customer_id JOIN Properties pr ON pr.id = r.property_id
     ${clause} ORDER BY r.created_at DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, p);
    const totalR = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Reviews r ${clause}`, p);
    return { page, limit, total: Number(totalR[0]?.total ?? 0), rows };
}

export async function createReview(body: Record<string, unknown>) {
    const result = await execute(
        `INSERT INTO Reviews (booking_id, customer_id, property_id, rating, title, comment, status)
     OUTPUT INSERTED.id
     VALUES (@booking_id, @customer_id, @property_id, @rating, @title, @comment, 'published')`,
        { booking_id: body.booking_id, customer_id: body.customer_id, property_id: body.property_id, rating: body.rating, title: body.title || null, comment: body.comment || null }
    );
    // Update provider rating
    await execute(
        `UPDATE Providers SET rating = (SELECT AVG(CAST(r.rating AS DECIMAL(3,2))) FROM Reviews r JOIN Properties p ON p.id = r.property_id WHERE p.provider_id = Providers.id AND r.status = 'published')
     WHERE id = (SELECT provider_id FROM Properties WHERE id = @pid)`,
        { pid: body.property_id }
    );
    return { id: result.recordset[0]?.id };
}

export async function replyToReview(id: number, response: string) {
    await execute("UPDATE Reviews SET response = @response WHERE id = @id", { id, response });
    return { ok: true };
}

export async function updateReviewStatus(id: number, status: string) {
    await execute("UPDATE Reviews SET status = @status WHERE id = @id", { id, status });
    return { ok: true };
}

export async function deleteReview(id: number) {
    await execute("DELETE FROM Reviews WHERE id = @id", { id });
    return { ok: true };
}
