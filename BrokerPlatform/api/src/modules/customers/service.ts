import { query, execute } from "../../db/query.js";

export async function listCustomers(params: { search?: string; status?: string; page?: string; limit?: string }) {
    const page = Math.max(Number(params.page || 1), 1);
    const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
    const offset = (page - 1) * limit;
    const where: string[] = [];
    const p: Record<string, unknown> = {};

    if (params.search) { where.push("(first_name LIKE @search OR last_name LIKE @search OR email LIKE @search OR document_number LIKE @search)"); p.search = `%${params.search}%`; }
    if (params.status) { where.push("status = @status"); p.status = params.status; }

    const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
    const rows = await query<any>(`SELECT * FROM Customers ${clause} ORDER BY id DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, p);
    const totalR = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Customers ${clause}`, p);
    return { page, limit, total: Number(totalR[0]?.total ?? 0), rows };
}

export async function getCustomer(id: number) {
    const rows = await query<any>("SELECT * FROM Customers WHERE id = @id", { id });
    if (!rows[0]) return null;
    const bookings = await query<any>(
        `SELECT b.id, b.booking_code, b.check_in, b.check_out, b.status, b.total_amount, pr.name AS property_name
     FROM Bookings b JOIN Properties pr ON pr.id = b.property_id WHERE b.customer_id = @id ORDER BY b.created_at DESC`, { id });
    return { ...rows[0], bookings };
}

export async function createCustomer(body: Record<string, unknown>) {
    const result = await execute(
        `INSERT INTO Customers (user_id, first_name, last_name, email, phone, document_type, document_number, nationality, address, city, country, loyalty_points, status)
     OUTPUT INSERTED.id
     VALUES (@user_id, @first_name, @last_name, @email, @phone, @doc_type, @doc_num, @nationality, @address, @city, @country, @loyalty, @status)`,
        {
            user_id: body.user_id || null, first_name: body.first_name, last_name: body.last_name,
            email: body.email || null, phone: body.phone || null,
            doc_type: body.document_type || null, doc_num: body.document_number || null,
            nationality: body.nationality || null, address: body.address || null,
            city: body.city || null, country: body.country || null,
            loyalty: body.loyalty_points || 0, status: body.status || 'active',
        }
    );
    return { id: result.recordset[0]?.id };
}

export async function updateCustomer(id: number, body: Record<string, unknown>) {
    const sets: string[] = [];
    const p: Record<string, unknown> = { id };
    const fields = ["user_id", "first_name", "last_name", "email", "phone", "document_type", "document_number", "nationality", "address", "city", "country", "loyalty_points", "status"];
    for (const f of fields) {
        if (body[f] !== undefined) { sets.push(`${f} = @${f}`); p[f] = body[f]; }
    }
    if (sets.length) {
        sets.push("updated_at = GETUTCDATE()");
        await execute(`UPDATE Customers SET ${sets.join(", ")} WHERE id = @id`, p);
    }
    return { ok: true };
}

export async function deleteCustomer(id: number) {
    await execute("DELETE FROM Customers WHERE id = @id", { id });
    return { ok: true };
}
