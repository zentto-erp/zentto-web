/**
 * XML helpers for SQL Server 2012 compatibility.
 * Converts JS objects/arrays to XML format parseable by XQuery .nodes()/.value().
 */

function escapeXmlAttr(v: unknown): string {
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
export function objectToXml(obj: Record<string, unknown> | object): string {
  const attrs = Object.entries(obj)
    .filter(([, v]) => v !== undefined && v !== null)
    .map(([k, v]) => `${k}="${escapeXmlAttr(v)}"`)
    .join(' ');
  return `<row ${attrs}/>`;
}

/**
 * Converts an array of objects to `<root><row .../><row .../></root>`.
 */
export function arrayToXml(arr: (Record<string, unknown> | object)[]): string {
  return `<root>${arr.map((item) => objectToXml(item)).join('')}</root>`;
}
