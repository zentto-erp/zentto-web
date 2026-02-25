// Script de datos: Carga inventario desde SQL Server
const sql = require('mssql');

const config = {
    server: 'DELLXEONE31545',
    database: 'sanjose',
    user: 'sa',
    password: '1234',
    options: { encrypt: false, trustServerCertificate: true }
};

async function beforeRender(req, res) {
    const pool = await sql.connect(config);
    const result = await pool.request().query(`
        SELECT TOP 100
            i.CODIGO AS codigo,
            i.DESCRIPCION AS descripcion,
            i.EXISTENCIA AS existencia,
            i.COSTO AS costo,
            i.PRECIO1 AS precio1,
            i.PRECIO2 AS precio2,
            i.Unidad AS unidad,
            ISNULL(c.NOMBRE, 'Sin Categoría') AS categoria
        FROM Inventario i
        LEFT JOIN Categoria c ON c.CODIGO = i.CODIGOCATEGORIA
        WHERE i.EXISTENCIA > 0
        ORDER BY i.DESCRIPCION
    `);
    await pool.close();

    req.data = {
        titulo: 'Inventario Actual',
        fecha: new Date().toLocaleDateString('es-VE'),
        empresa: 'DatqBox',
        rows: result.recordset,
        totalItems: result.recordset.length,
        totalExistencia: result.recordset.reduce((s, r) => s + Number(r.existencia || 0), 0),
        totalValor: result.recordset.reduce((s, r) => s + (Number(r.existencia || 0) * Number(r.costo || 0)), 0)
    };
}
