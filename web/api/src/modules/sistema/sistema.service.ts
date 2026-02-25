import { query } from '../../db/query.js';

export async function getNotificaciones(usuarioId?: string) {
    const rows = await query<any>(`
        SELECT TOP 50 
            Id, Tipo, Titulo, Mensaje, Leido, FechaCreacion, RutaNavegacion
        FROM Sys_Notificaciones
        WHERE UsuarioId IS NULL OR UsuarioId = @usuarioId
        ORDER BY FechaCreacion DESC
    `, { usuarioId: usuarioId || null });

    return rows.map((r: any) => ({
        id: r.Id.toString(),
        type: r.Tipo,
        title: r.Titulo,
        message: r.Mensaje,
        read: !!r.Leido,
        time: r.FechaCreacion,
        route: r.RutaNavegacion
    }));
}

export async function markNotificacionesAsRead(ids: number[]) {
    if (!ids || ids.length === 0) return { ok: true, count: 0 };
    const idList = ids.join(',');

    // In SQL Server 2012, we can't reliably pass an array safely without IN or TVP. 
    // Since IDs are ints, doing a safe string replace is okay for a simple IN clause 
    // but better is a parameterized query. If doing simple in, ensure all are ints.
    const safeIds = ids.filter(id => Number.isInteger(id)).join(',');
    if (!safeIds) return { ok: true, count: 0 };

    const result = await query<any>(`
        UPDATE Sys_Notificaciones
        SET Leido = 1
        WHERE Id IN (${safeIds})
    `);

    return { ok: true };
}

export async function getTareas(asignadoA?: string) {
    const rows = await query<any>(`
        SELECT TOP 50 
            Id, Titulo, Descripcion, Progreso, Color, AsignadoA, FechaVencimiento, Completado, FechaCreacion
        FROM Sys_Tareas
        WHERE (AsignadoA IS NULL OR AsignadoA = @asignadoA)
          AND Completado = 0
        ORDER BY FechaCreacion DESC
    `, { asignadoA: asignadoA || null });

    return rows.map((r: any) => ({
        id: r.Id.toString(),
        title: r.Titulo,
        description: r.Descripcion,
        progress: r.Progreso,
        color: r.Color,
        completed: !!r.Completado,
        dueDate: r.FechaVencimiento
    }));
}

export async function toggleTarea(id: number, completado: boolean, progress: number) {
    await query(`
        UPDATE Sys_Tareas
        SET Completado = @completado, Progreso = @progress
        WHERE Id = @id
    `, { id, completado, progress });
    return { ok: true };
}

export async function getMensajes(destinatarioId: string) {
    const rows = await query<any>(`
        SELECT TOP 50
            Id, RemitenteId, RemitenteNombre, Asunto, Cuerpo, Leido, FechaEnvio
        FROM Sys_Mensajes
        WHERE DestinatarioId = @destinatarioId
        ORDER BY FechaEnvio DESC
    `, { destinatarioId });

    return rows.map((r: any) => ({
        id: r.Id.toString(),
        sender: r.RemitenteNombre,
        senderId: r.RemitenteId,
        subject: r.Asunto,
        body: r.Cuerpo,
        unread: !r.Leido,
        time: r.FechaEnvio
    }));
}

export async function markMensajeAsRead(id: number) {
    await query(`
        UPDATE Sys_Mensajes
        SET Leido = 1
        WHERE Id = @id
    `, { id });
    return { ok: true };
}
