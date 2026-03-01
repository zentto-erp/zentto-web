import { query, execute } from "../../db/query.js";

export async function listPayments(params: { booking_id?: string; customer_id?: string; status?: string; page?: string; limit?: string }) {
    const page = Math.max(Number(params.page || 1), 1);
    const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
    const offset = (page - 1) * limit;
    const where: string[] = [];
    const p: Record<string, unknown> = {};

    if (params.booking_id) { where.push("p.booking_id = @booking_id"); p.booking_id = Number(params.booking_id); }
    if (params.customer_id) { where.push("p.customer_id = @customer_id"); p.customer_id = Number(params.customer_id); }
    if (params.status) { where.push("p.status = @status"); p.status = params.status; }

    const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
    const rows = await query<any>(
        `SELECT p.*, b.booking_code, c.first_name AS customer_first, c.last_name AS customer_last
     FROM Payments p JOIN Bookings b ON b.id = p.booking_id JOIN Customers c ON c.id = p.customer_id
     ${clause} ORDER BY p.created_at DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, p);
    const totalR = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Payments p ${clause}`, p);
    return { page, limit, total: Number(totalR[0]?.total ?? 0), rows };
}

export async function createPayment(body: Record<string, unknown>) {
    const result = await execute(
        `INSERT INTO Payments (booking_id, customer_id, amount, currency, payment_method, gateway_ref, status, paid_at)
     OUTPUT INSERTED.id
     VALUES (@booking_id, @customer_id, @amount, @currency, @method, @gateway_ref, @status, @paid_at)`,
        {
            booking_id: body.booking_id, customer_id: body.customer_id, amount: body.amount,
            currency: body.currency || 'USD', method: body.payment_method || 'card',
            gateway_ref: body.gateway_ref || null, status: body.status || 'pending',
            paid_at: body.status === 'completed' ? new Date().toISOString() : null,
        }
    );
    return { id: result.recordset[0]?.id };
}

export async function updatePaymentStatus(id: number, status: string) {
    const paidAt = status === 'completed' ? ", paid_at = GETUTCDATE()" : "";
    await execute(`UPDATE Payments SET status = @status ${paidAt} WHERE id = @id`, { id, status });
    return { ok: true };
}

// Invoices
export async function listInvoices(params: { booking_id?: string; status?: string; page?: string; limit?: string }) {
    const page = Math.max(Number(params.page || 1), 1);
    const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
    const offset = (page - 1) * limit;
    const where: string[] = [];
    const p: Record<string, unknown> = {};
    if (params.booking_id) { where.push("i.booking_id = @booking_id"); p.booking_id = Number(params.booking_id); }
    if (params.status) { where.push("i.status = @status"); p.status = params.status; }
    const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
    const rows = await query<any>(
        `SELECT i.*, b.booking_code FROM Invoices i JOIN Bookings b ON b.id = i.booking_id ${clause} ORDER BY i.created_at DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, p);
    const totalR = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Invoices i ${clause}`, p);
    return { page, limit, total: Number(totalR[0]?.total ?? 0), rows };
}

export async function createInvoice(body: Record<string, unknown>) {
    const invNum = `INV-${Date.now().toString(36).toUpperCase()}`;
    const result = await execute(
        `INSERT INTO Invoices (booking_id, invoice_number, subtotal, tax_amount, total, status, issued_at)
     OUTPUT INSERTED.id
     VALUES (@booking_id, @inv_num, @subtotal, @tax, @total, @status, @issued_at)`,
        {
            booking_id: body.booking_id, inv_num: invNum,
            subtotal: body.subtotal || 0, tax: body.tax_amount || 0, total: body.total || 0,
            status: body.status || 'draft', issued_at: body.status === 'issued' ? new Date().toISOString() : null,
        }
    );
    return { id: result.recordset[0]?.id, invoice_number: invNum };
}

// Refunds
export async function createRefund(body: Record<string, unknown>) {
    const result = await execute(
        `INSERT INTO Refunds (payment_id, amount, reason, status)
     OUTPUT INSERTED.id
     VALUES (@payment_id, @amount, @reason, 'pending')`,
        { payment_id: body.payment_id, amount: body.amount, reason: body.reason || null }
    );
    return { id: result.recordset[0]?.id };
}

export async function approveRefund(id: number) {
    await execute("UPDATE Refunds SET status = 'completed', refunded_at = GETUTCDATE() WHERE id = @id", { id });
    const refund = await query<any>("SELECT payment_id, amount FROM Refunds WHERE id = @id", { id });
    if (refund[0]) {
        await execute("UPDATE Payments SET status = 'refunded' WHERE id = @pid", { pid: refund[0].payment_id });
    }
    return { ok: true };
}
