import { query, execute } from "../../db/query.js";

export async function listProperties(params: { search?: string; type?: string; provider_id?: string; city?: string; country?: string; min_price?: string; max_price?: string; guests?: string; page?: string; limit?: string }) {
    const page = Math.max(Number(params.page || 1), 1);
    const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
    const offset = (page - 1) * limit;
    const where: string[] = [];
    const p: Record<string, unknown> = {};

    if (params.search) { where.push("(pr.name LIKE @search OR pr.description LIKE @search OR pr.city LIKE @search)"); p.search = `%${params.search}%`; }
    if (params.type) { where.push("pr.type = @type"); p.type = params.type; }
    if (params.provider_id) { where.push("pr.provider_id = @provider_id"); p.provider_id = Number(params.provider_id); }
    if (params.city) { where.push("pr.city LIKE @city"); p.city = `%${params.city}%`; }
    if (params.country) { where.push("pr.country = @country"); p.country = params.country; }
    if (params.guests) { where.push("pr.max_guests >= @guests"); p.guests = Number(params.guests); }

    const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";

    let priceJoin = "";
    let priceWhere = "";
    if (params.min_price || params.max_price) {
        priceJoin = "LEFT JOIN PropertyRates rt ON rt.property_id = pr.id AND rt.name = 'standard'";
        if (params.min_price) { priceWhere += " AND rt.price_per_night >= @min_price"; p.min_price = Number(params.min_price); }
        if (params.max_price) { priceWhere += " AND rt.price_per_night <= @max_price"; p.max_price = Number(params.max_price); }
    }

    const rows = await query<any>(
        `SELECT pr.*, pv.name AS provider_name, pv.type AS provider_type, pv.rating AS provider_rating,
            (SELECT TOP 1 price_per_night FROM PropertyRates WHERE property_id = pr.id AND name = 'standard') AS base_price
     FROM Properties pr
     JOIN Providers pv ON pv.id = pr.provider_id
     ${priceJoin}
     ${clause} ${priceWhere}
     ORDER BY pr.id DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, p);

    const totalR = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Properties pr ${priceJoin} ${clause} ${priceWhere}`, p);
    return { page, limit, total: Number(totalR[0]?.total ?? 0), rows };
}

export async function getProperty(id: number) {
    const rows = await query<any>(
        `SELECT pr.*, pv.name AS provider_name, pv.type AS provider_type, pv.email AS provider_email, pv.phone AS provider_phone
     FROM Properties pr JOIN Providers pv ON pv.id = pr.provider_id WHERE pr.id = @id`, { id });
    if (!rows[0]) return null;
    const rates = await query<any>("SELECT * FROM PropertyRates WHERE property_id = @id ORDER BY name", { id });
    const amenities = await query<any>(
        `SELECT a.id, a.name, a.icon, a.category FROM PropertyAmenities pa JOIN Amenities a ON a.id = pa.amenity_id WHERE pa.property_id = @id`, { id });
    const reviews = await query<any>(
        `SELECT r.id, r.rating, r.title, r.comment, r.response, r.created_at,
            c.first_name, c.last_name
     FROM Reviews r JOIN Customers c ON c.id = r.customer_id
     WHERE r.property_id = @id AND r.status = 'published' ORDER BY r.created_at DESC`, { id });
    return { ...rows[0], rates, amenities, reviews };
}

export async function createProperty(body: Record<string, unknown>) {
    const result = await execute(
        `INSERT INTO Properties (provider_id, name, type, description, address, city, country, latitude, longitude, max_guests, images, status)
     OUTPUT INSERTED.id
     VALUES (@provider_id, @name, @type, @description, @address, @city, @country, @latitude, @longitude, @max_guests, @images, @status)`,
        {
            provider_id: body.provider_id, name: body.name, type: body.type || 'room',
            description: body.description || null, address: body.address || null,
            city: body.city || null, country: body.country || null,
            latitude: body.latitude || null, longitude: body.longitude || null,
            max_guests: body.max_guests || 2, images: body.images ? JSON.stringify(body.images) : null,
            status: body.status || 'active',
        }
    );
    const id = result.recordset[0]?.id;

    if (Array.isArray(body.rates)) {
        for (const rate of body.rates as any[]) {
            await execute(
                `INSERT INTO PropertyRates (property_id, name, price_per_night, price_per_hour, currency, valid_from, valid_to)
         VALUES (@pid, @name, @ppn, @pph, @currency, @vf, @vt)`,
                { pid: id, name: rate.name || 'standard', ppn: rate.price_per_night || 0, pph: rate.price_per_hour || 0, currency: rate.currency || 'USD', vf: rate.valid_from || null, vt: rate.valid_to || null }
            );
        }
    }

    if (Array.isArray(body.amenity_ids)) {
        for (const aid of body.amenity_ids as number[]) {
            await execute("INSERT INTO PropertyAmenities (property_id, amenity_id) VALUES (@pid, @aid)", { pid: id, aid });
        }
    }

    return { id };
}

export async function updateProperty(id: number, body: Record<string, unknown>) {
    const sets: string[] = [];
    const p: Record<string, unknown> = { id };
    const fields = ["provider_id", "name", "type", "description", "address", "city", "country", "latitude", "longitude", "max_guests", "status"];
    for (const f of fields) {
        if (body[f] !== undefined) { sets.push(`${f} = @${f}`); p[f] = body[f]; }
    }
    if (body.images !== undefined) { sets.push("images = @images"); p.images = JSON.stringify(body.images); }
    if (sets.length) {
        sets.push("updated_at = GETUTCDATE()");
        await execute(`UPDATE Properties SET ${sets.join(", ")} WHERE id = @id`, p);
    }

    if (Array.isArray(body.rates)) {
        await execute("DELETE FROM PropertyRates WHERE property_id = @id", { id });
        for (const rate of body.rates as any[]) {
            await execute(
                `INSERT INTO PropertyRates (property_id, name, price_per_night, price_per_hour, currency, valid_from, valid_to)
         VALUES (@pid, @name, @ppn, @pph, @currency, @vf, @vt)`,
                { pid: id, name: rate.name || 'standard', ppn: rate.price_per_night || 0, pph: rate.price_per_hour || 0, currency: rate.currency || 'USD', vf: rate.valid_from || null, vt: rate.valid_to || null }
            );
        }
    }

    if (Array.isArray(body.amenity_ids)) {
        await execute("DELETE FROM PropertyAmenities WHERE property_id = @id", { id });
        for (const aid of body.amenity_ids as number[]) {
            await execute("INSERT INTO PropertyAmenities (property_id, amenity_id) VALUES (@pid, @aid)", { pid: id, aid });
        }
    }

    return { ok: true };
}

export async function deleteProperty(id: number) {
    await execute("DELETE FROM PropertyAmenities WHERE property_id = @id", { id });
    await execute("DELETE FROM PropertyRates WHERE property_id = @id", { id });
    await execute("DELETE FROM Properties WHERE id = @id", { id });
    return { ok: true };
}

// ── Availability ──
export async function getAvailability(propertyId: number, from: string, to: string) {
    return query<any>(
        `SELECT * FROM Availability WHERE property_id = @pid AND date BETWEEN @from AND @to ORDER BY date`,
        { pid: propertyId, from, to }
    );
}

export async function setAvailability(propertyId: number, entries: Array<{ date: string; available_units: number; blocked?: boolean; min_stay?: number; max_stay?: number }>) {
    for (const e of entries) {
        const existing = await query<any>("SELECT id FROM Availability WHERE property_id = @pid AND date = @d", { pid: propertyId, d: e.date });
        if (existing.length) {
            await execute(
                `UPDATE Availability SET available_units = @units, blocked = @blocked, min_stay = @min, max_stay = @max WHERE property_id = @pid AND date = @d`,
                { pid: propertyId, d: e.date, units: e.available_units, blocked: e.blocked ? 1 : 0, min: e.min_stay || 1, max: e.max_stay || 30 }
            );
        } else {
            await execute(
                `INSERT INTO Availability (property_id, date, available_units, blocked, min_stay, max_stay) VALUES (@pid, @d, @units, @blocked, @min, @max)`,
                { pid: propertyId, d: e.date, units: e.available_units, blocked: e.blocked ? 1 : 0, min: e.min_stay || 1, max: e.max_stay || 30 }
            );
        }
    }
    return { ok: true };
}
