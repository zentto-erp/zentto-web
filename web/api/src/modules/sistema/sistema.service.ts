import { callSp } from '../../db/query.js';

export async function getNotificaciones(usuarioId?: string) {
    const rows = await callSp<any>('usp_Sys_Notificacion_List', {
        UsuarioId: usuarioId || null
    });

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

    const safeIds = ids.filter(id => Number.isInteger(id));
    if (safeIds.length === 0) return { ok: true, count: 0 };

    const idsCsv = safeIds.join(',');
    await callSp('usp_Sys_Notificacion_MarkRead', { IdsCsv: idsCsv });

    return { ok: true };
}

export async function getTareas(asignadoA?: string) {
    const rows = await callSp<any>('usp_Sys_Tarea_List', {
        AsignadoA: asignadoA || null
    });

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
    await callSp('usp_Sys_Tarea_Toggle', {
        Id: id,
        Completado: completado,
        Progress: progress
    });
    return { ok: true };
}

export async function getMensajes(destinatarioId: string) {
    const rows = await callSp<any>('usp_Sys_Mensaje_List', {
        DestinatarioId: destinatarioId
    });

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
    await callSp('usp_Sys_Mensaje_MarkRead', { Id: id });
    return { ok: true };
}
