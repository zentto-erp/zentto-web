import { query, execute } from "../../db/query.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { env } from "../../config/env.js";

export async function registerUser(body: {
    email: string;
    password: string;
    first_name: string;
    last_name: string;
    phone?: string;
    role?: string;
}) {
    const existing = await query<any>("SELECT id FROM Users WHERE email = @email", { email: body.email });
    if (existing.length > 0) throw new Error("email_already_exists");

    const hash = await bcrypt.hash(body.password, 12);
    const result = await execute(
        `INSERT INTO Users (email, password_hash, first_name, last_name, phone, status)
     OUTPUT INSERTED.id
     VALUES (@email, @hash, @first_name, @last_name, @phone, 'active')`,
        {
            email: body.email,
            hash,
            first_name: body.first_name,
            last_name: body.last_name,
            phone: body.phone || null,
        }
    );
    const userId = result.recordset[0]?.id;

    // Assign role
    const roleName = body.role || "customer";
    const roles = await query<any>("SELECT id FROM Roles WHERE name = @name", { name: roleName });
    if (roles.length > 0) {
        await execute("INSERT INTO UserRoles (user_id, role_id) VALUES (@uid, @rid)", {
            uid: userId,
            rid: roles[0].id,
        });
    }

    return { id: userId, email: body.email };
}

export async function loginUser(email: string, password: string) {
    const users = await query<any>(
        `SELECT u.id, u.email, u.password_hash, u.first_name, u.last_name, u.status
     FROM Users u WHERE u.email = @email`,
        { email }
    );
    if (users.length === 0) throw new Error("invalid_credentials");

    const user = users[0];
    if (user.status !== "active") throw new Error("account_inactive");

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) throw new Error("invalid_credentials");

    const roleRows = await query<any>(
        `SELECT r.name FROM UserRoles ur JOIN Roles r ON r.id = ur.role_id WHERE ur.user_id = @uid`,
        { uid: user.id }
    );
    const roles = roleRows.map((r: any) => r.name);

    const token = jwt.sign(
        { userId: user.id, email: user.email, roles },
        env.jwt.secret,
        { expiresIn: env.jwt.expires as any }
    );

    return {
        token,
        user: {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            roles,
        },
    };
}

export async function getMe(userId: number) {
    const users = await query<any>(
        `SELECT id, email, first_name, last_name, phone, avatar_url, status, created_at
     FROM Users WHERE id = @id`,
        { id: userId }
    );
    if (users.length === 0) return null;

    const roleRows = await query<any>(
        `SELECT r.name FROM UserRoles ur JOIN Roles r ON r.id = ur.role_id WHERE ur.user_id = @uid`,
        { uid: userId }
    );

    return { ...users[0], roles: roleRows.map((r: any) => r.name) };
}
