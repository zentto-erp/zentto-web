export function formatCurrency(value: number | string | null | undefined): string {
  if (!value) return "Bs. 0,00";
  const num = typeof value === "string" ? parseFloat(value) : value;
  if (isNaN(num)) return "Bs. 0,00";
  return `Bs. ${num.toLocaleString("es-VE", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

export function formatDate(
  date: string | Date | null | undefined,
  options?: { timeZone?: string; locale?: string }
): string {
  if (!date) return "N/A";
  const d = typeof date === "string" ? new Date(date) : date;
  if (isNaN(d.getTime())) return "N/A";
  const opts: Intl.DateTimeFormatOptions = {
    year: "numeric", month: "2-digit", day: "2-digit",
  };
  if (options?.timeZone) opts.timeZone = options.timeZone;
  return d.toLocaleDateString(options?.locale || "es", opts);
}

export function formatDateTime(
  date: string | Date | null | undefined,
  options?: { timeZone?: string; locale?: string }
): string {
  if (!date) return "N/A";
  const d = typeof date === "string" ? new Date(date) : date;
  if (isNaN(d.getTime())) return "N/A";
  const opts: Intl.DateTimeFormatOptions = {
    year: "numeric", month: "2-digit", day: "2-digit",
    hour: "2-digit", minute: "2-digit", hourCycle: "h23",
  };
  if (options?.timeZone) opts.timeZone = options.timeZone;
  return d.toLocaleString(options?.locale || "es", opts);
}

export function toDateOnly(
  date: string | Date | null | undefined,
  timeZone?: string
): string {
  if (!date) return "";
  const d = typeof date === "string" ? new Date(date) : date;
  if (isNaN(d.getTime())) return "";
  const opts: Intl.DateTimeFormatOptions = { year: "numeric", month: "2-digit", day: "2-digit" };
  if (timeZone) opts.timeZone = timeZone;
  return d.toLocaleDateString("en-CA", opts);
}

export function formatName(name: string | null | undefined): string {
  if (!name) return "";
  return name.toLowerCase().split(" ").map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
}

export function formatPercent(value: number | string | null | undefined, decimals = 2): string {
  if (!value) return "0.00%";
  const num = typeof value === "string" ? parseFloat(value) : value;
  if (isNaN(num)) return "0.00%";
  return `${num.toFixed(decimals)}%`;
}

export function truncateText(text: string | null | undefined, length: number = 50): string {
  if (!text) return "";
  return text.length > length ? `${text.substring(0, length)}...` : text;
}

export function getStatusColor(status: string): "success" | "warning" | "error" | "info" | "default" {
  const statusMap: Record<string, "success" | "warning" | "error" | "info" | "default"> = {
    activo: "success", inactivo: "error", pendiente: "warning",
    completado: "success", cancelado: "error", activa: "success", inactiva: "error",
  };
  return statusMap[status.toLowerCase()] || "default";
}
