import * as cheerio from 'cheerio';
import { callSp } from "../../db/query.js";

// Necesario ya que la web del Banco Central de Venezuela (bcv.org.ve)
// frecuentemente tiene errores en su cadena de certificados SSL (UNABLE_TO_VERIFY_LEAF_SIGNATURE).
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

interface TasasBCV {
    USD: number;
    EUR: number;
    fechaInformativa: string;
}

/**
 * Executes a web request to scrape the Central Bank of Venezuela (BCV) site
 * and extract the latest USD and EUR official rates.
 */
export async function fetchTasasBcvWeb(): Promise<TasasBCV | null> {
    try {
        const response = await fetch('https://www.bcv.org.ve/tasas-informativas-sistema-bancario', {
            // Faking user agent to prevent basic bot blockers
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            },
            // Adding a small timeout to not hang server startup
            signal: AbortSignal.timeout(10000)
        });

        if (!response.ok) {
            console.error('BCV Scraping Failed. Http status: ', response.status);
            return null;
        }

        const html = await response.text();
        const $ = cheerio.load(html);

        // Typical div identifiers in BCV's current layout
        const eurText = $('#euro > div > div > div.col-sm-6.col-xs-6.centrado > strong').text().trim().replace(',', '.');
        const usdText = $('#dolar > div > div > div.col-sm-6.col-xs-6.centrado > strong').text().trim().replace(',', '.');

        // Let's grab the informative date string representing the validity of these rates.
        const dateText = $('.date-display-single').first().text().trim();

        const USD = parseFloat(usdText);
        const EUR = parseFloat(eurText);

        if (isNaN(USD) || isNaN(EUR)) {
            console.error('Tasas parsing returned NaN. Output: ', { usdText, eurText });
            return null;
        }

        return {
            USD,
            EUR,
            fechaInformativa: dateText || new Date().toISOString()
        };
    } catch (err) {
        console.error('Error on fetchTasasBcvWeb:', err);
        return null;
    }
}

/**
 * Persists rates in canonical table cfg.ExchangeRateDaily.
 */
export async function saveTasasToDB(tasas: TasasBCV): Promise<boolean> {
    try {
        await callSp('usp_Cfg_ExchangeRate_Upsert', {
            RateDate: new Date(),
            TasaUSD: tasas.USD,
            TasaEUR: tasas.EUR,
            SourceName: 'BCV_WEB_AUTO'
        });
        return true;
    } catch (e) {
        console.error('Failed to save BCV Tasas to database:', e);
        return false;
    }
}

/**
 * Returns currently known active rates.
 */
export async function getTasasBCV() {
    // 1. Try to fetch from web
    const liveRates = await fetchTasasBcvWeb();

    // 2. Fallbacks
    if (!liveRates) {
        return {
            USD: 45.0, // Hardcoded fallback just for visual mock
            EUR: 48.0,
            fechaInformativa: "Fallback Local",
            origen: "FALLBACK_NOT_FOUND"
        };
    }

    // Attempt to persist the live rates as system parameters implicitly.
    await saveTasasToDB(liveRates);

    return {
        ...liveRates,
        origen: "BCV_WEB_AUTO"
    };
}

/**
 * Triggers manual parsing and saving
 */
export async function triggerSyncTasas() {
    const rates = await fetchTasasBcvWeb();
    if (rates) {
        await saveTasasToDB(rates);
        return { message: "Sync successful", rates };
    }
    throw new Error("Unable to parse rates. Review connection or layout changes");
}
