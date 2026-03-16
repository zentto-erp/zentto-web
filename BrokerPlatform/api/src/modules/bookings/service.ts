import { query, execute } from "../../db/query.js";

function generateBookingCode(): string {
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    let code = "BK-";
    for (let i = 0; i < 8; i++) code += chars[Math.floor(Math.random() * chars.length)];
    return code;
}

export async function listBookings(params: { search?: string; status?: string; provider_id?: string; customer_id?: string; from?: string; to?: string; page?: string; limit?: string }) {
    const page = Math.max(Number(params.page || 1), 1);
    const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
    const offset = (page - 1) * limit;
    const where: string[] = [];
    const p: Record<string, unknown> = {};

    if (params.search) { where.push("(b.booking_code LIKE @search OR c.first_name LIKE @search OR c.last_name LIKE @search)"); p.search = `%${params.search}%`; }
    if (params.status) { where.push("b.status = @status"); p.status = params.status; }
    if (params.provider_id) { where.push("b.provider_id = @provider_id"); p.provider_id = Number(params.provider_id); }
    if (params.customer_id) { where.push("b.customer_id = @customer_id"); p.customer_id = Number(params.customer_id); }
    if (params.from) { where.push("b.check_in >= @from"); p.from = params.from; }
    if (params.to) { where.push("b.check_out <= @to"); p.to = params.to; }

    const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
    const rows = await query<any>(
        `SELECT b.*, c.first_name AS customer_first, c.last_name AS customer_last, c.email AS customer_email,
            pr.name AS property_name, pv.name AS provider_name
     FROM Bookings b
     JOIN Customers c ON c.id = b.customer_id
     JOIN Properties pr ON pr.id = b.property_id
     JOIN Providers pv ON pv.id = b.provider_id
     ${clause} ORDER BY b.created_at DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, p);

    const totalR = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Bookings b JOIN Customers c ON c.id = b.customer_id ${clause}`, p);
    return { page, limit, total: Number(totalR[0]?.total ?? 0), rows };
}

export async function getBooking(id: number) {
    const rows = await query<any>(
        `SELECT b.*, c.first_name AS customer_first, c.last_name AS customer_last, c.email AS customer_email, c.phone AS customer_phone,
            pr.name AS property_name, pr.type AS property_type, pr.address AS property_address,
            pv.name AS provider_name, pv.type AS provider_type
     FROM Bookings b
     JOIN Customers c ON c.id = b.customer_id
     JOIN Properties pr ON pr.id = b.property_id
     JOIN Providers pv ON pv.id = b.provider_id
     WHERE b.id = @id`, { id });
    if (!rows[0]) return null;
    const items = await query<any>("SELECT * FROM BookingItems WHERE booking_id = @id", { id });
    const history = await query<any>("SELECT * FROM BookingStatusHistory WHERE booking_id = @id ORDER BY changed_at DESC", { id });
    const payments = await query<any>("SELECT * FROM Payments WHERE booking_id = @id ORDER BY created_at DESC", { id });
    return { ...rows[0], items, history, payments };
}

export async function createBooking(body: Record<string, unknown>) {
    const code = generateBookingCode();

    // Calculate commission
    const providers = await query<any>("SELECT commission_pct FROM Providers WHERE id = @id", { id: body.provider_id });
    const commPct = providers[0]?.commission_pct || 10;
    const total = Number(body.total_amount || 0);
    const commission = Math.round(total * commPct) / 100;

    const result = await execute(
        `INSERT INTO Bookings (booking_code, customer_id, property_id, provider_id, check_in, check_out, guests, status, total_amount, currency, commission_amount, notes)
     OUTPUT INSERTED.id
     VALUES (@code, @customer_id, @property_id, @provider_id, @check_in, @check_out, @guests, 'pending', @total_amount, @currency, @commission, @notes)`,
        {
            code, customer_id: body.customer_id, property_id: body.property_id,
            provider_id: body.provider_id, check_in: body.check_in, check_out: body.check_out,
            guests: body.guests || 1, total_amount: total, currency: body.currency || 'USD',
            commission, notes: body.notes || null,
        }
    );
    const bookingId = result.recordset[0]?.id;

    // Add status history
    await execute(
        "INSERT INTO BookingStatusHistory (booking_id, from_status, to_status, notes) VALUES (@bid, NULL, 'pending', 'Booking created')",
        { bid: bookingId }
    );

    // Add items
    if (Array.isArray(body.items)) {
        for (const item of body.items as any[]) {
            await execute(
                `INSERT INTO BookingItems (booking_id, description, quantity, unit_price, subtotal) VALUES (@bid, @desc, @qty, @up, @st)`,
                { bid: bookingId, desc: item.description, qty: item.quantity || 1, up: item.unit_price || 0, st: item.subtotal || (item.quantity || 1) * (item.unit_price || 0) }
            );
        }
    }

    return { id: bookingId, booking_code: code };
}

export async function updateBookingStatus(id: number, newStatus: string, changedBy?: number, notes?: string) {
    const current = await query<any>("SELECT status FROM Bookings WHERE id = @id", { id });
    if (!current[0]) throw new Error("booking_not_found");

    const fromStatus = current[0].status;
    await execute("UPDATE Bookings SET status = @status, updated_at = GETUTCDATE() WHERE id = @id", { id, status: newStatus });
    await execute(
        "INSERT INTO BookingStatusHistory (booking_id, from_status, to_status, changed_by, notes) VALUES (@bid, @from, @to, @by, @notes)",
        { bid: id, from: fromStatus, to: newStatus, by: changedBy || null, notes: notes || null }
    );
    return { ok: true, from: fromStatus, to: newStatus };
}

export async function updateBooking(id: number, body: Record<string, unknown>) {
    const sets: string[] = [];
    const p: Record<string, unknown> = { id };
    const fields = ["check_in", "check_out", "guests", "total_amount", "currency", "commission_amount", "notes"];
    for (const f of fields) {
        if (body[f] !== undefined) { sets.push(`${f} = @${f}`); p[f] = body[f]; }
    }
    if (body.status) { sets.push("status = @status"); p.status = body.status; }
    if (sets.length) {
        sets.push("updated_at = GETUTCDATE()");
        await execute(`UPDATE Bookings SET ${sets.join(", ")} WHERE id = @id`, p);
    }
    return { ok: true };
}

export async function deleteBooking(id: number) {
    await execute("DELETE FROM BookingStatusHistory WHERE booking_id = @id", { id });
    await execute("DELETE FROM BookingItems WHERE booking_id = @id", { id });
    await execute("DELETE FROM Payments WHERE booking_id = @id", { id });
    await execute("DELETE FROM Bookings WHERE id = @id", { id });
    return { ok: true };
}
