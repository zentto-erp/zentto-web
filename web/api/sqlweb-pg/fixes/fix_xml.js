/**
 * XML helpers for SQL Server 2012 compatibility.
 * Converts JS objects/arrays to XML format parseable by XQuery .nodes()/.value().
 */
function escapeXmlAttr(v) {
    const s = v instanceof Date ? v.toISOString() : String(v);
    return s
        .replace(/&/g, '&amp;')
        .replace(/"/g, '&quot;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
}
/**
 * Converts a single object to `<row Key1="val1" Key2="val2" />`.
 * Null/undefined values are omitted.
 */
export function objectToXml(obj) {
    const attrs = Object.entries(obj)
        .filter(([, v]) => v !== undefined && v !== null)
        .map(([k, v]) => `${k}="${escapeXmlAttr(v)}"`)
        .join(' ');
    return `<row ${attrs}/>`;
}
/**
 * Converts an array of objects to `<root><row .../><row .../></root>`.
 */
export function arrayToXml(arr) {
    return `<root>${arr.map((item) => objectToXml(item)).join('')}</root>`;
}
// ── XML → JSON (para la capa PG) ─────────────────────────────────────────────
function parseXmlAttrs(attrStr) {
    const obj = {};
    const re = /(\w+)="([^"]*)"/g;
    let m;
    while ((m = re.exec(attrStr)) !== null) {
        obj[m[1]] = m[2]
            .replace(/&amp;/g, "&")
            .replace(/&quot;/g, '"')
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">");
    }
    return obj;
}
/**
 * Convierte el XML generado por objectToXml / arrayToXml de vuelta a JSON string.
 *
 *   `<row Key="val"/>` → `'{"Key":"val"}'`
 *   `<root><row A="1"/><row A="2"/></root>` → `'[{"A":"1"},{"A":"2"}]'`
 *   `<rows><row A="1"/><row A="2"/></rows>` → `'[{"A":"1"},{"A":"2"}]'`
 *
 * Usado en query.ts para adaptar parámetros *Xml a *Json en modo PostgreSQL.
 */
export function xmlParamToJson(xml) {
    const str = (xml ?? "").trim();
    // Acepta <root> o <rows> como contenedor de multiples <row ... />
    if (str.startsWith("<root>") || str.startsWith("<rows>")) {
        const rows = [];
        const re = /<row([^>]*?)\/>/g;
        let m;
        while ((m = re.exec(str)) !== null)
            rows.push(parseXmlAttrs(m[1]));
        return JSON.stringify(rows);
    }
    const m = str.match(/^<row([^>]*?)\/>/);
    if (m)
        return JSON.stringify(parseXmlAttrs(m[1]));
    return str; // fallback: devuelve el string original sin modificar
}
