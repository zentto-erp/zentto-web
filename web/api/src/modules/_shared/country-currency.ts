import { callSp } from "../../db/query.js";

let _countryCurrencyMap: Record<string, string> | null = null;

export async function getCountryCurrency(countryCode: string): Promise<string> {
  if (!_countryCurrencyMap) {
    try {
      const rows = await callSp<{ CountryCode: string; CurrencyCode: string }>(
        "usp_CFG_Country_List",
        { ActiveOnly: 1 }
      );
      _countryCurrencyMap = {};
      for (const r of rows) {
        _countryCurrencyMap[r.CountryCode] = r.CurrencyCode;
      }
    } catch {
      _countryCurrencyMap = { VE: "VES", ES: "EUR" };
    }
  }
  return _countryCurrencyMap[countryCode] ?? "USD";
}
