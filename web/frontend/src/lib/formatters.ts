// lib/formatters.ts
/** Formatea un número como moneda (Bs.) */
export function formatCurrency(value: number | string | null | undefined): string {
  if (!value) return "Bs. 0,00";
  const num = typeof value === "string" ? parseFloat(value) : value;
  if (isNaN(num)) return "Bs. 0,00";
  return `Bs. ${num.toLocaleString("es-VE", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

/** Formatea una fecha en formato DD/MM/YYYY */
export function formatDate(date: string | Date | null | undefined): string {
  if (!date) return "N/A";
  const d = typeof date === "string" ? new Date(date) : date;
  if (isNaN(d.getTime())) return "N/A";
  return d.toLocaleDateString("es-VE", { year: "numeric", month: "2-digit", day: "2-digit" });
}

/** Formatea un nombre para UI (capitalización apropiada) */
export function formatName(name: string | null | undefined): string {
  if (!name) return "";
  return name
    .toLowerCase()
    .split(" ")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

/** Formatea un porcentaje */
export function formatPercent(value: number | string | null | undefined, decimals = 2): string {
  if (!value) return "0.00%";
  const num = typeof value === "string" ? parseFloat(value) : value;
  if (isNaN(num)) return "0.00%";
  return `${num.toFixed(decimals)}%`;
}

/** Trunca texto con ellipsis */
export function truncateText(text: string | null | undefined, length: number = 50): string {
  if (!text) return "";
  return text.length > length ? `${text.substring(0, length)}...` : text;
}

/** Formatea un estado para badge (color y texto) */
export function getStatusColor(status: string): "success" | "warning" | "error" | "info" | "default" {
  const statusMap: Record<string, "success" | "warning" | "error" | "info" | "default"> = {
    activo: "success",
    inactivo: "error",
    pendiente: "warning",
    completado: "success",
    cancelado: "error",
    activa: "success",
    inactiva: "error",
  };
  return statusMap[status.toLowerCase()] || "default";
}
