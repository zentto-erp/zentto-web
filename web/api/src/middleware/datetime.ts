import type { Request, Response, NextFunction } from "express";
import type { JwtPayload } from "../auth/jwt.js";
import type { RequestScope } from "../context/request-context.js";

const DATE_ONLY_REGEX = /^\d{4}-\d{2}-\d{2}$/;
const ISO_WITH_TZ_REGEX =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,7})?)?(?:Z|[+-]\d{2}:\d{2})$/i;
const ISO_WITHOUT_TZ_REGEX =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,7})?)?$/i;

const COUNTRY_TIMEZONES: Record<string, string> = {
  VE: "America/Caracas",
  ES: "Europe/Madrid",
};

type ScopedRequest = Request & {
  user?: JwtPayload;
  scope?: RequestScope;
};

function pad2(value: number) {
  return String(value).padStart(2, "0");
}

function normalizeCountryCode(raw: unknown) {
  const value = String(raw ?? "").trim().toUpperCase();
  if (!value) return null;
  return value;
}

function normalizeTimeZone(raw: unknown) {
  const value = String(raw ?? "").trim();
  if (!value) return null;
  try {
    Intl.DateTimeFormat("en-US", { timeZone: value });
    return value;
  } catch {
    return null;
  }
}

function parseDateTimeWithoutTimeZone(value: string) {
  const match =
    /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2})(\.\d{1,7})?)?$/i.exec(
      value.trim()
    );
  if (!match) return null;

  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const hour = Number(match[4]);
  const minute = Number(match[5]);
  const second = Number(match[6] ?? "0");
  const fraction = match[7] ?? "";
  const millisecond = fraction
    ? Number(`${fraction.slice(1)}000`.slice(0, 3))
    : 0;

  if (
    !Number.isFinite(year) ||
    !Number.isFinite(month) ||
    !Number.isFinite(day) ||
    !Number.isFinite(hour) ||
    !Number.isFinite(minute) ||
    !Number.isFinite(second) ||
    !Number.isFinite(millisecond)
  ) {
    return null;
  }

  return { year, month, day, hour, minute, second, millisecond };
}

function getOffsetMs(date: Date, timeZone: string) {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hourCycle: "h23",
  });

  const parts = formatter.formatToParts(date);
  const year = Number(parts.find((p) => p.type === "year")?.value ?? "0");
  const month = Number(parts.find((p) => p.type === "month")?.value ?? "0");
  const day = Number(parts.find((p) => p.type === "day")?.value ?? "0");
  const hour = Number(parts.find((p) => p.type === "hour")?.value ?? "0");
  const minute = Number(parts.find((p) => p.type === "minute")?.value ?? "0");
  const second = Number(parts.find((p) => p.type === "second")?.value ?? "0");

  const asUtc = Date.UTC(year, month - 1, day, hour, minute, second, 0);
  return asUtc - date.getTime();
}

function localDateTimeToUtc(localDateTime: string, timeZone: string) {
  const parsed = parseDateTimeWithoutTimeZone(localDateTime);
  if (!parsed) return null;

  const guessUtc = Date.UTC(
    parsed.year,
    parsed.month - 1,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond
  );

  let offset = getOffsetMs(new Date(guessUtc), timeZone);
  let utcMs = guessUtc - offset;
  const recalculatedOffset = getOffsetMs(new Date(utcMs), timeZone);
  if (recalculatedOffset !== offset) {
    utcMs = guessUtc - recalculatedOffset;
  }

  return new Date(utcMs).toISOString();
}

function extractOffsetString(date: Date, timeZone: string) {
  const tzName = new Intl.DateTimeFormat("en-US", {
    timeZone,
    timeZoneName: "shortOffset",
  })
    .formatToParts(date)
    .find((part) => part.type === "timeZoneName")?.value;

  if (!tzName) return "+00:00";
  if (tzName === "GMT" || tzName === "UTC") return "+00:00";

  const match = /(?:GMT|UTC)([+-])(\d{1,2})(?::?(\d{2}))?/i.exec(tzName);
  if (!match) return "+00:00";

  const sign = match[1];
  const hours = pad2(Number(match[2]));
  const minutes = pad2(Number(match[3] ?? "0"));
  return `${sign}${hours}:${minutes}`;
}

function toLocalIsoString(date: Date, timeZone: string) {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hourCycle: "h23",
  });
  const parts = formatter.formatToParts(date);

  const year = parts.find((p) => p.type === "year")?.value ?? "0000";
  const month = parts.find((p) => p.type === "month")?.value ?? "01";
  const day = parts.find((p) => p.type === "day")?.value ?? "01";
  const hour = parts.find((p) => p.type === "hour")?.value ?? "00";
  const minute = parts.find((p) => p.type === "minute")?.value ?? "00";
  const second = parts.find((p) => p.type === "second")?.value ?? "00";
  const offset = extractOffsetString(date, timeZone);

  return `${year}-${month}-${day}T${hour}:${minute}:${second}${offset}`;
}

function shouldConvertStringToUtc(value: string) {
  if (!value) return false;
  if (DATE_ONLY_REGEX.test(value)) return false;
  return ISO_WITH_TZ_REGEX.test(value) || ISO_WITHOUT_TZ_REGEX.test(value);
}

function toUtcValue(value: unknown, timeZone: string): unknown {
  if (value == null) return value;

  if (value instanceof Date) {
    return value.toISOString();
  }

  if (Array.isArray(value)) {
    return value.map((item) => toUtcValue(item, timeZone));
  }

  if (typeof value === "object") {
    const output: Record<string, unknown> = {};
    for (const [key, nested] of Object.entries(value as Record<string, unknown>)) {
      output[key] = toUtcValue(nested, timeZone);
    }
    return output;
  }

  if (typeof value !== "string") return value;

  const trimmed = value.trim();
  if (!shouldConvertStringToUtc(trimmed)) return value;

  if (ISO_WITH_TZ_REGEX.test(trimmed)) {
    const parsed = new Date(trimmed);
    if (Number.isNaN(parsed.getTime())) return value;
    return parsed.toISOString();
  }

  if (ISO_WITHOUT_TZ_REGEX.test(trimmed)) {
    const converted = localDateTimeToUtc(trimmed, timeZone);
    return converted ?? value;
  }

  return value;
}

function toLocalizedValue(value: unknown, timeZone: string): unknown {
  if (value == null) return value;

  if (value instanceof Date) {
    return toLocalIsoString(value, timeZone);
  }

  if (Array.isArray(value)) {
    return value.map((item) => toLocalizedValue(item, timeZone));
  }

  if (typeof value === "object") {
    const output: Record<string, unknown> = {};
    for (const [key, nested] of Object.entries(value as Record<string, unknown>)) {
      output[key] = toLocalizedValue(nested, timeZone);
    }
    return output;
  }

  if (typeof value !== "string") return value;

  const trimmed = value.trim();
  if (DATE_ONLY_REGEX.test(trimmed)) return value;
  if (!ISO_WITH_TZ_REGEX.test(trimmed)) return value;

  const parsed = new Date(trimmed);
  if (Number.isNaN(parsed.getTime())) return value;
  return toLocalIsoString(parsed, timeZone);
}

function resolveCountryCode(req: ScopedRequest) {
  const fromScope = normalizeCountryCode(req.scope?.countryCode);
  if (fromScope) return fromScope;

  const fromUser = normalizeCountryCode(req.user?.countryCode);
  if (fromUser) return fromUser;

  const headerRaw = req.headers["x-country-code"];
  const fromHeader = normalizeCountryCode(
    Array.isArray(headerRaw) ? headerRaw[0] : headerRaw
  );
  if (fromHeader) return fromHeader;

  const fromBody = normalizeCountryCode(
    (req.body as Record<string, unknown> | undefined)?.countryCode
  );
  if (fromBody) return fromBody;

  return null;
}

function resolveTimeZone(req: ScopedRequest) {
  const countryCode = resolveCountryCode(req);
  const fromScope = normalizeTimeZone(req.scope?.timeZone);
  if (fromScope) {
    return { countryCode: countryCode ?? "UTC", timeZone: fromScope };
  }

  const fromUser = normalizeTimeZone(req.user?.timeZone);
  if (fromUser) {
    return { countryCode: countryCode ?? "UTC", timeZone: fromUser };
  }

  const headerRaw = req.headers["x-timezone"];
  const fromHeader = normalizeTimeZone(Array.isArray(headerRaw) ? headerRaw[0] : headerRaw);
  if (fromHeader) {
    return { countryCode: countryCode ?? "UTC", timeZone: fromHeader };
  }

  const timeZone = countryCode ? COUNTRY_TIMEZONES[countryCode] : null;
  return { countryCode: countryCode ?? "UTC", timeZone: timeZone ?? "UTC" };
}

export function normalizeRequestDateTimesToUtc(
  req: Request,
  _res: Response,
  next: NextFunction
) {
  const scopedReq = req as ScopedRequest;
  const { timeZone } = resolveTimeZone(scopedReq);
  if (req.body && typeof req.body === "object") {
    req.body = toUtcValue(req.body, timeZone);
  }
  if (req.query && typeof req.query === "object") {
    (req.query as Record<string, unknown>) = toUtcValue(
      req.query,
      timeZone
    ) as Record<string, unknown>;
  }
  if (req.params && typeof req.params === "object") {
    req.params = toUtcValue(req.params, timeZone) as Record<string, string>;
  }
  next();
}

export function localizeResponseDateTimes(
  req: Request,
  res: Response,
  next: NextFunction
) {
  const scopedReq = req as ScopedRequest;
  const originalJson = res.json.bind(res);

  res.json = ((body: unknown) => {
    const { countryCode, timeZone } = resolveTimeZone(scopedReq);
    res.setHeader("x-datetime-storage", "UTC");
    res.setHeader("x-datetime-country", countryCode);
    res.setHeader("x-datetime-timezone", timeZone);
    return originalJson(toLocalizedValue(body, timeZone));
  }) as Response["json"];

  next();
}
