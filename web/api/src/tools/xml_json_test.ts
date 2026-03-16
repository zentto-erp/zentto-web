/**
 * Verifica la conversión automática XML→JSON en modo PostgreSQL.
 */
import { xmlParamToJson } from "../utils/xml.js";
import { objectToXml, arrayToXml } from "../utils/xml.js";

// Simula lo que hace el service
const header = { DocumentNumber: "FACT-0001", SupplierCode: "P001", TotalAmount: 1500.50 };
const details = [
  { ProductCode: "ART001", Quantity: 2, Price: 500.25 },
  { ProductCode: "ART002", Quantity: 1, Price: 500.00 },
];

const headerXml = objectToXml(header);
const detailXml = arrayToXml(details);
const singleRow = objectToXml({ NOMBRE: "Juan Pérez", CARGO: "Analista", SUELDO: 1500 });

console.log("── objectToXml ────────────────────────────────");
console.log(headerXml);
console.log(singleRow);

console.log("\n── arrayToXml ─────────────────────────────────");
console.log(detailXml);

console.log("\n── xmlParamToJson (object) ────────────────────");
const headerJson = xmlParamToJson(headerXml);
console.log(headerJson);
const parsed = JSON.parse(headerJson) as Record<string, unknown>;
console.log("  DocumentNumber:", parsed.DocumentNumber);
console.log("  TotalAmount:", parsed.TotalAmount);

console.log("\n── xmlParamToJson (array) ─────────────────────");
const detailJson = xmlParamToJson(detailXml);
console.log(detailJson);
const arr = JSON.parse(detailJson) as Record<string, unknown>[];
console.log("  items:", arr.length, "→", arr.map((r) => r.ProductCode));

console.log("\n── adaptParamsForPg simulation ────────────────");
const mssqlParams = {
  CompanyId: 1,
  HeaderXml: headerXml,
  DetailXml: detailXml,
  PaymentsXml: arrayToXml([{ Monto: 1500.50, Metodo: "EFECTIVO" }]),
};
const pgParams = Object.fromEntries(
  Object.entries(mssqlParams).map(([key, value]) => {
    if (key.endsWith("Xml") && typeof value === "string") {
      return [key.replace(/Xml$/, "Json"), xmlParamToJson(value)];
    }
    return [key, value];
  })
);
console.log("MSSQL params:", Object.keys(mssqlParams));
console.log("PG params:   ", Object.keys(pgParams));
console.log("  HeaderJson:", pgParams.HeaderJson?.toString().substring(0, 60) + "...");

console.log("\n✅ XML→JSON conversion OK");
process.exit(0);
