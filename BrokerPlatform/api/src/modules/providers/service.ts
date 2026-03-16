import { query, execute } from "../../db/query.js";

export async function listProviders(params: { search?: string; type?: string; status?: string; page?: string; limit?: string }) {
    const page = Math.max(Number(params.page || 1), 1);
    const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
    const offset = (page - 1) * limit;
    const where: string[] = [];
    const p: Record<string, unknown> = {};

    if (params.search) {
        where.push("(p.name LIKE @search OR p.email LIKE @search OR p.tax_id LIKE @search)");
        p.search = `%${params.search}%`;
    }
    if (params.type) { where.push("p.type = @type"); p.type = params.type; }
    if (params.status) { where.push("p.status = @status"); p.status = params.status; }

    const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
    const rows = await query<any>(`SELECT p.*, c.name AS country_name FROM Providers p LEFT JOIN Countries c ON c.code = p.country ${clause} ORDER BY p.id DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, p);
    const totalR = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Providers p ${clause}`, p);
    return { page, limit, total: Number(totalR[0]?.total ?? 0), rows };
}

export async function getProvider(id: number) {
    const rows = await query<any>(`SELECT p.*, c.name AS country_name FROM Providers p LEFT JOIN Countries c ON c.code = p.country WHERE p.id = @id`, { id });
    if (!rows[0]) return null;
    const cats = await query<any>(`SELECT category FROM ProviderCategories WHERE provider_id = @id`, { id });
    return { ...rows[0], categories: cats.map((c: any) => c.category) };
}

export async function createProvider(body: Record<string, unknown>) {
    const result = await execute(
        `INSERT INTO Providers (name, type, tax_id, email, phone, address, city, state, country, logo_url, description, rating, status, commission_pct, contact_person, user_id)
     OUTPUT INSERTED.id
     VALUES (@name, @type, @tax_id, @email, @phone, @address, @city, @state, @country, @logo_url, @description, @rating, @status, @commission_pct, @contact_person, @user_id)`,
        {
            name: body.name, type: body.type || 'hotel', tax_id: body.tax_id || null,
            email: body.email || null, phone: body.phone || null, address: body.address || null,
            city: body.city || null, state: body.state || null, country: body.country || null,
            logo_url: body.logo_url || null, description: body.description || null,
            rating: body.rating || 0, status: body.status || 'active',
            commission_pct: body.commission_pct || 10, contact_person: body.contact_person || null,
            user_id: body.user_id || null,
        }
    );
    const id = result.recordset[0]?.id;
    if (Array.isArray(body.categories)) {
        for (const cat of body.categories as string[]) {
            await execute("INSERT INTO ProviderCategories (provider_id, category) VALUES (@pid, @cat)", { pid: id, cat });
        }
    }
    return { id };
}

export async function updateProvider(id: number, body: Record<string, unknown>) {
    const sets: string[] = [];
    const p: Record<string, unknown> = { id };
    const fields = ["name", "type", "tax_id", "email", "phone", "address", "city", "state", "country", "logo_url", "description", "rating", "status", "commission_pct", "contact_person", "user_id"];
    for (const f of fields) {
        if (body[f] !== undefined) { sets.push(`${f} = @${f}`); p[f] = body[f]; }
    }
    if (sets.length) {
        sets.push("updated_at = GETUTCDATE()");
        await execute(`UPDATE Providers SET ${sets.join(", ")} WHERE id = @id`, p);
    }
    if (Array.isArray(body.categories)) {
        await execute("DELETE FROM ProviderCategories WHERE provider_id = @id", { id });
        for (const cat of body.categories as string[]) {
            await execute("INSERT INTO ProviderCategories (provider_id, category) VALUES (@pid, @cat)", { pid: id, cat });
        }
    }
    return { ok: true };
}

export async function deleteProvider(id: number) {
    await execute("DELETE FROM ProviderCategories WHERE provider_id = @id", { id });
    await execute("DELETE FROM Providers WHERE id = @id", { id });
    return { ok: true };
}
