/**
 * Registry de generadores fiscales por pais y modelo.
 * Facilita la seleccion del generador correcto desde endpoints genericos.
 */
export { generateModelo303, buildModelo303FromTaxBook } from "./modelo-303.generator.js";
export { generateModelo390 } from "./modelo-390.generator.js";
export { generateModelo111 } from "./modelo-111.generator.js";
export { generateModelo190 } from "./modelo-190.generator.js";
export { generateModelo347 } from "./modelo-347.generator.js";
export { generateFacturaE } from "./facturae.generator.js";
export { generateVerifactuXML, calculateVerifactuHash, generateQRUrl } from "./verifactu-xml.generator.js";

export type { Modelo303Input } from "./modelo-303.generator.js";
export type { Modelo390Input } from "./modelo-390.generator.js";
export type { Modelo111Input } from "./modelo-111.generator.js";
export type { Modelo190Input, Modelo190Perceptor } from "./modelo-190.generator.js";
export type { Modelo347Input, Modelo347Operacion } from "./modelo-347.generator.js";
export type { FacturaEInput, FacturaESeller, FacturaEBuyer, FacturaEItem } from "./facturae.generator.js";
export type { VerifactuRecord, VerifactuOutput } from "./verifactu-xml.generator.js";
