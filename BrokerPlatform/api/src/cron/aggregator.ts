import cron from "node-cron";
import { env } from "../config/env.js";
import { execute, query } from "../db/query.js";

type InventoryType = "room" | "vehicle" | "boat" | "flight" | "train";
type PlaceProvider = "google" | "here" | "tomtom" | "foursquare" | "geoapify" | "osm";
type InventoryProvider = "booking" | "expedia" | "amadeus" | "simulated";
type TriggerType = "startup" | "scheduled" | "manual";

type CitySeed = {
    city: string;
    country: string;
    lat: number;
    lng: number;
    radius: number;
    airportIata?: string;
};

type InventoryProfile = {
    propertyType: InventoryType;
    providerType: string;
    providerName: string;
    commissionPct: number;
    maxGuests: number;
    searchText: string;
    geoapifyCategories: string;
    osmFilters: string[];
    fallbackNames: string[];
    images: string[];
    priceRange: { min: number; max: number };
    ratingRange: { min: number; max: number };
};

type RawPlace = {
    source: string;
    sourceId: string;
    name: string;
    lat: number;
    lng: number;
    address: string | null;
    city?: string;
    country?: string;
    rating?: number | null;
    payload: Record<string, unknown>;
};

type NormalizedInventory = {
    source: string;
    externalId: string;
    propertyType: InventoryType;
    providerType: string;
    providerName: string;
    name: string;
    description: string;
    address: string | null;
    city: string;
    country: string;
    lat: number;
    lng: number;
    price: number;
    currency: string;
    rating: number;
    image: string | null;
    maxGuests: number;
    payload: Record<string, unknown>;
};

type OverpassElement = {
    id: number | string;
    type: string;
    lat?: number;
    lon?: number;
    center?: { lat?: number; lon?: number };
    tags?: Record<string, string>;
};

const INVENTORY_TYPES: InventoryType[] = ["room", "vehicle", "boat", "flight", "train"];
const PLACE_PROVIDER_ORDER_DEFAULT: PlaceProvider[] = ["geoapify", "foursquare", "tomtom", "here", "google", "osm"];
const INVENTORY_PROVIDER_ORDER_DEFAULT: InventoryProvider[] = ["booking", "amadeus", "simulated"];
const OSM_ENDPOINTS = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
    "https://lz4.overpass-api.de/api/interpreter",
];

const CITY_COORDS: Record<string, CitySeed> = {
    "new york": { city: "New York", country: "USA", lat: 40.7128, lng: -74.006, radius: 22000, airportIata: "JFK" },
    london: { city: "London", country: "GBR", lat: 51.5074, lng: -0.1278, radius: 22000, airportIata: "LHR" },
    paris: { city: "Paris", country: "FRA", lat: 48.8566, lng: 2.3522, radius: 18000, airportIata: "CDG" },
    tokyo: { city: "Tokyo", country: "JPN", lat: 35.6762, lng: 139.6503, radius: 25000, airportIata: "HND" },
    madrid: { city: "Madrid", country: "ESP", lat: 40.4168, lng: -3.7038, radius: 18000, airportIata: "MAD" },
    miami: { city: "Miami", country: "USA", lat: 25.7617, lng: -80.1918, radius: 18000, airportIata: "MIA" },
    barcelona: { city: "Barcelona", country: "ESP", lat: 41.3874, lng: 2.1686, radius: 18000, airportIata: "BCN" },
    rome: { city: "Rome", country: "ITA", lat: 41.9028, lng: 12.4964, radius: 18000, airportIata: "FCO" },
    lisbon: { city: "Lisbon", country: "PRT", lat: 38.7223, lng: -9.1393, radius: 18000, airportIata: "LIS" },
    athens: { city: "Athens", country: "GRC", lat: 37.9838, lng: 23.7275, radius: 18000, airportIata: "ATH" },
    berlin: { city: "Berlin", country: "DEU", lat: 52.52, lng: 13.405, radius: 22000, airportIata: "BER" },
    milan: { city: "Milan", country: "ITA", lat: 45.4642, lng: 9.19, radius: 18000, airportIata: "MXP" },
    bogota: { city: "Bogota", country: "COL", lat: 4.711, lng: -74.0721, radius: 18000, airportIata: "BOG" },
    caracas: { city: "Caracas", country: "VEN", lat: 10.4806, lng: -66.9036, radius: 18000, airportIata: "CCS" },
};

const COUNTRY_ALPHA2_TO3: Record<string, string> = { US: "USA", GB: "GBR", ES: "ESP", FR: "FRA", IT: "ITA", PT: "PRT", DE: "DEU", GR: "GRC", VE: "VEN", CO: "COL", JP: "JPN" };
const COUNTRY_CURRENCY: Record<string, string> = { USA: "USD", GBR: "GBP", ESP: "EUR", FRA: "EUR", ITA: "EUR", PRT: "EUR", DEU: "EUR", GRC: "EUR", JPN: "JPY", VEN: "USD", COL: "USD" };
const CURATED_HUBS: Record<string, Partial<Record<InventoryType, Array<{ name: string; lat: number; lng: number; address: string }>>>> = {
    madrid: {
        flight: [{ name: "Adolfo Suarez Madrid-Barajas Airport", lat: 40.4983, lng: -3.5676, address: "Barajas, Madrid" }],
        train: [{ name: "Madrid Puerta de Atocha", lat: 40.4066, lng: -3.6892, address: "Arganzuela, Madrid" }],
        boat: [{ name: "Madrid Rio Nautical Club", lat: 40.4012, lng: -3.7192, address: "Madrid Rio, Madrid" }],
    },
    barcelona: {
        flight: [{ name: "Josep Tarradellas Barcelona-El Prat Airport", lat: 41.2974, lng: 2.0833, address: "El Prat de Llobregat" }],
        train: [{ name: "Barcelona Sants", lat: 41.379, lng: 2.14, address: "Sants-Montjuic, Barcelona" }],
        boat: [{ name: "Port Vell Marina", lat: 41.3765, lng: 2.1816, address: "Moll de la Fusta, Barcelona" }],
    },
    "new york": {
        flight: [
            { name: "John F. Kennedy International Airport", lat: 40.6413, lng: -73.7781, address: "Queens, New York" },
            { name: "LaGuardia Airport", lat: 40.7769, lng: -73.874, address: "Queens, New York" },
        ],
        train: [{ name: "New York Penn Station", lat: 40.7506, lng: -73.9935, address: "Manhattan, New York" }],
        boat: [{ name: "Brooklyn Bridge Marina", lat: 40.7034, lng: -73.9968, address: "Brooklyn, New York" }],
    },
    london: {
        flight: [{ name: "Heathrow Airport", lat: 51.47, lng: -0.4543, address: "Hounslow, London" }],
        train: [{ name: "St Pancras International", lat: 51.5314, lng: -0.1261, address: "Euston Rd, London" }],
        boat: [{ name: "St Katharine Docks Marina", lat: 51.5079, lng: -0.0726, address: "Tower Hamlets, London" }],
    },
    paris: {
        flight: [{ name: "Paris Charles de Gaulle Airport", lat: 49.0097, lng: 2.5479, address: "Roissy-en-France" }],
        train: [{ name: "Gare du Nord", lat: 48.8809, lng: 2.3553, address: "10th arrondissement, Paris" }],
        boat: [{ name: "Port de l'Arsenal", lat: 48.8492, lng: 2.369, address: "Bastille, Paris" }],
    },
    miami: {
        flight: [{ name: "Miami International Airport", lat: 25.7959, lng: -80.2871, address: "Miami, Florida" }],
        train: [{ name: "MiamiCentral Station", lat: 25.7783, lng: -80.1945, address: "Downtown Miami" }],
        boat: [{ name: "Miami Beach Marina", lat: 25.7695, lng: -80.1398, address: "Miami Beach" }],
    },
};

const INVENTORY_PROFILES: Record<InventoryType, InventoryProfile> = {
    room: {
        propertyType: "room", providerType: "hotel", providerName: "External Aggregator Hotels", commissionPct: 14, maxGuests: 2,
        searchText: "hotel", geoapifyCategories: "accommodation.hotel,accommodation.hostel,accommodation.guest_house",
        osmFilters: ['["tourism"="hotel"]', '["tourism"="motel"]', '["tourism"="guest_house"]', '["tourism"="hostel"]'],
        fallbackNames: ["Grand Plaza", "Cityline Boutique", "Urban Stay", "Skyline Suites"],
        images: ["https://images.unsplash.com/photo-1566073771259-6a8506099945", "https://images.unsplash.com/photo-1551882547-ff40c62e54bb", "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267"],
        priceRange: { min: 55, max: 680 }, ratingRange: { min: 3.4, max: 4.9 },
    },
    vehicle: {
        propertyType: "vehicle", providerType: "car_rental", providerName: "External Aggregator Cars", commissionPct: 13, maxGuests: 5,
        searchText: "car rental", geoapifyCategories: "service.vehicle.rental,commercial.car_rental", osmFilters: ['["amenity"="car_rental"]'],
        fallbackNames: ["City Car Hub", "Drive Point", "Auto Direct", "Road Smart"],
        images: ["https://images.unsplash.com/photo-1541899481282-d53bffe3c35d", "https://images.unsplash.com/photo-1494976388531-d1058494cdd8", "https://images.unsplash.com/photo-1503376780353-7e6692767b70"],
        priceRange: { min: 24, max: 180 }, ratingRange: { min: 3.3, max: 4.8 },
    },
    boat: {
        propertyType: "boat", providerType: "marina", providerName: "External Aggregator Boats", commissionPct: 15, maxGuests: 8,
        searchText: "marina", geoapifyCategories: "transportation.ferry,sport.sailing", osmFilters: ['["leisure"="marina"]', '["amenity"="ferry_terminal"]'],
        fallbackNames: ["Harbor Cruises", "Blue Marina", "Ocean Dock", "Coastal Charter"],
        images: ["https://images.unsplash.com/photo-1518391846015-55a9cc003b25", "https://images.unsplash.com/photo-1518837695005-2083093ee35b", "https://images.unsplash.com/photo-1507525428034-b723cf961d3e"],
        priceRange: { min: 45, max: 720 }, ratingRange: { min: 3.4, max: 4.9 },
    },
    flight: {
        propertyType: "flight", providerType: "airline", providerName: "External Aggregator Flights", commissionPct: 10, maxGuests: 1,
        searchText: "airport", geoapifyCategories: "transportation.airport", osmFilters: ['["aeroway"="aerodrome"]', '["aeroway"="terminal"]'],
        fallbackNames: ["Air Link", "Sky Connect", "Global Wings", "Blue Jet"],
        images: ["https://images.unsplash.com/photo-1436491865332-7a61a109cc05", "https://images.unsplash.com/photo-1504198453319-5ce911bafcde", "https://images.unsplash.com/photo-1540339832862-474599807836"],
        priceRange: { min: 65, max: 1200 }, ratingRange: { min: 3.2, max: 4.8 },
    },
    train: {
        propertyType: "train", providerType: "rail", providerName: "External Aggregator Trains", commissionPct: 9, maxGuests: 1,
        searchText: "railway station", geoapifyCategories: "transportation.railway", osmFilters: ['["railway"="station"]', '["railway"="halt"]'],
        fallbackNames: ["Central Rail", "Transit Express", "Main Station", "Intercity Hub"],
        images: ["https://images.unsplash.com/photo-1474487548417-781cb71495f3", "https://images.unsplash.com/photo-1504198458649-3128b932f49b", "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957"],
        priceRange: { min: 12, max: 240 }, ratingRange: { min: 3.1, max: 4.7 },
    },
};

let amadeusTokenCache: { token: string; expiresAt: number } | null = null;
let warnedExpediaMissingAccess = false;

function clamp(value: number, min: number, max: number) { return Math.min(Math.max(value, min), max); }
function toFiniteNumber(value: unknown, fallback: number) { const n = Number(value); return Number.isFinite(n) ? n : fallback; }
function parseOptionalNumber(value: unknown) { const n = Number(value); return Number.isFinite(n) ? n : null; }
function hashString(value: string) { let hash = 2166136261; for (let i = 0; i < value.length; i += 1) { hash ^= value.charCodeAt(i); hash += (hash << 1) + (hash << 4) + (hash << 7) + (hash << 8) + (hash << 24); } return hash >>> 0; }
function deterministicInt(seed: string, min: number, max: number) { const range = max - min + 1; if (range <= 0) return min; return min + (hashString(seed) % range); }
function deterministicFloat(seed: string, min: number, max: number, decimals = 2) { const ratio = (hashString(seed) % 100000) / 100000; return Number((min + ratio * (max - min)).toFixed(decimals)); }
function sleep(ms: number) { return new Promise((resolve) => setTimeout(resolve, ms)); }
function normalizeCountry(raw: unknown, fallback: string) { const t = String(raw ?? "").trim().toUpperCase(); if (!t) return fallback; if (t.length === 3) return t; if (t.length === 2) return COUNTRY_ALPHA2_TO3[t] || fallback; return fallback; }
function normalizeCurrency(raw: unknown, fallback: string) { const t = String(raw ?? "").trim().toUpperCase(); return t.length === 3 ? t : fallback; }
function currencyFromCountry(country: string) { return COUNTRY_CURRENCY[country] || "USD"; }
function citySeedFromName(raw: string): CitySeed { const k = raw.trim().toLowerCase(); return CITY_COORDS[k] ?? { city: raw.trim(), country: "USA", lat: 40.7128, lng: -74.006, radius: 18000, airportIata: "JFK" }; }
function parsePlaceProviders(raw: string[]) { const valid = new Set<PlaceProvider>(["google", "here", "tomtom", "foursquare", "geoapify", "osm"]); const parsed = raw.map((v) => v.trim().toLowerCase()).filter((v): v is PlaceProvider => valid.has(v as PlaceProvider)); return parsed.length ? Array.from(new Set(parsed)) : PLACE_PROVIDER_ORDER_DEFAULT; }
function parseInventoryProviders(raw: string[]) { const valid = new Set<InventoryProvider>(["booking", "expedia", "amadeus", "simulated"]); const parsed = raw.map((v) => v.trim().toLowerCase()).filter((v): v is InventoryProvider => valid.has(v as InventoryProvider)); return parsed.length ? Array.from(new Set(parsed)) : INVENTORY_PROVIDER_ORDER_DEFAULT; }
function toInventoryType(raw: string): InventoryType | null { const v = raw.trim().toLowerCase(); return (INVENTORY_TYPES as string[]).includes(v) ? (v as InventoryType) : null; }
function composeAddress(parts: Array<unknown>) { const values = parts.map((v) => String(v || "").trim()).filter(Boolean); return values.length ? values.join(", ") : null; }
function inventoryDescription(profile: InventoryProfile, city: CitySeed) { if (profile.propertyType === "room") return `Accommodation in ${city.city} with dynamic nightly rates.`; if (profile.propertyType === "vehicle") return `Car rental point near ${city.city} with daily pricing.`; if (profile.propertyType === "boat") return `Boat service and marina access in ${city.city}.`; if (profile.propertyType === "flight") return `Flight-related inventory for ${city.city}.`; return `Rail transport node in ${city.city}.`; }
function curatedPlaces(city: CitySeed, profile: InventoryProfile): RawPlace[] {
    const hubs = CURATED_HUBS[city.city.toLowerCase()]?.[profile.propertyType] || [];
    return hubs.map((hub, index) => ({
        source: "osm",
        sourceId: `curated:${profile.propertyType}:${city.city}:${index}`,
        name: hub.name,
        lat: hub.lat,
        lng: hub.lng,
        address: hub.address,
        city: city.city,
        country: city.country,
        payload: { source: "curated_hubs", city: city.city, type: profile.propertyType },
    }));
}
function normalizeFromPlace(place: RawPlace, city: CitySeed, profile: InventoryProfile, index: number): NormalizedInventory {
    const externalId = `${place.source}:${profile.propertyType}:${place.sourceId}`;
    const country = normalizeCountry(place.country, city.country);
    const rating = place.rating !== undefined && place.rating !== null
        ? clamp(Number(place.rating.toFixed(2)), 0, 5)
        : deterministicFloat(`${externalId}:rating`, profile.ratingRange.min, profile.ratingRange.max, 2);

    return {
        source: place.source,
        externalId,
        propertyType: profile.propertyType,
        providerType: profile.providerType,
        providerName: profile.providerName,
        name: place.name,
        description: inventoryDescription(profile, city),
        address: place.address,
        city: place.city || city.city,
        country,
        lat: place.lat,
        lng: place.lng,
        price: deterministicInt(`${externalId}:price`, profile.priceRange.min, profile.priceRange.max),
        currency: currencyFromCountry(country),
        rating,
        image: `${profile.images[index % profile.images.length]}?w=900&fit=crop`,
        maxGuests: profile.maxGuests,
        payload: place.payload,
    };
}

function fallbackInventory(cityName: string, propertyType: InventoryType, maxItems: number): NormalizedInventory[] {
    const city = citySeedFromName(cityName);
    const profile = INVENTORY_PROFILES[propertyType];
    const count = clamp(Math.max(Math.floor(maxItems * 0.7), 8), 8, maxItems);

    return Array.from({ length: count }, (_, idx) => {
        const seed = `sim:${propertyType}:${city.city}:${idx}`;
        const lat = Number((city.lat + deterministicInt(`${seed}:lat`, -450, 450) / 10000).toFixed(7));
        const lng = Number((city.lng + deterministicInt(`${seed}:lng`, -450, 450) / 10000).toFixed(7));
        const country = city.country;
        const externalId = seed;

        return {
            source: "simulated",
            externalId,
            propertyType,
            providerType: profile.providerType,
            providerName: profile.providerName,
            name: `${profile.fallbackNames[idx % profile.fallbackNames.length]} ${city.city}`,
            description: inventoryDescription(profile, city),
            address: null,
            city: city.city,
            country,
            lat,
            lng,
            price: deterministicInt(`${externalId}:price`, profile.priceRange.min, profile.priceRange.max),
            currency: currencyFromCountry(country),
            rating: deterministicFloat(`${externalId}:rating`, profile.ratingRange.min, profile.ratingRange.max, 2),
            image: `${profile.images[idx % profile.images.length]}?w=900&fit=crop`,
            maxGuests: profile.maxGuests,
            payload: { source: "simulated", city: city.city, type: propertyType },
        };
    });
}

function buildOverpassQuery(city: CitySeed, filters: string[], maxRows: number, radius: number) {
    const around = `around:${radius},${city.lat},${city.lng}`;
    const clauses = filters
        .map((filter) => `node(${around})${filter}["name"];way(${around})${filter}["name"];`)
        .join("\n");
    return `[out:json][timeout:25];(${clauses});out center ${maxRows};`;
}

function parseOverpassElements(payload: unknown): OverpassElement[] {
    const asRecord = payload as { elements?: unknown[] };
    if (!Array.isArray(asRecord?.elements)) return [];
    return asRecord.elements as OverpassElement[];
}

function rawPlaceFromOverpass(city: CitySeed, element: OverpassElement): RawPlace | null {
    const tags = element.tags || {};
    const lat = toFiniteNumber(element.lat ?? element.center?.lat, Number.NaN);
    const lng = toFiniteNumber(element.lon ?? element.center?.lon, Number.NaN);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
    const name = String(tags.name || tags.operator || tags.brand || "").trim();
    if (!name) return null;

    return {
        source: "osm",
        sourceId: `${element.type}:${String(element.id)}`,
        name,
        lat,
        lng,
        address: composeAddress([tags["addr:street"], tags["addr:housenumber"], tags["addr:city"]]),
        city: tags["addr:city"] || city.city,
        country: tags["addr:country"] || city.country,
        rating: parseOptionalNumber(tags.stars),
        payload: { source: "osm", osm_id: element.id, osm_type: element.type, tags },
    };
}

async function fetchOsmPlaces(city: CitySeed, profile: InventoryProfile): Promise<RawPlace[]> {
    const nominatimRows = await fetchNominatimPlaces(city, profile);
    if (nominatimRows.length > 0) {
        return nominatimRows;
    }

    const baseRows = clamp(env.aggregator.maxItemsPerCity * 3, 30, 140);
    const attempts = [
        { radius: city.radius, rows: baseRows },
        { radius: Math.max(Math.floor(city.radius * 0.6), 6000), rows: Math.max(Math.floor(baseRows * 0.7), 20) },
    ];

    for (const attempt of attempts) {
        const overpassQuery = buildOverpassQuery(city, profile.osmFilters, attempt.rows, attempt.radius);
        for (const endpoint of OSM_ENDPOINTS) {
            const controller = new AbortController();
            const timeout = setTimeout(() => controller.abort(), env.aggregator.osmTimeoutMs);
            try {
                const response = await fetch(endpoint, {
                    method: "POST",
                    body: overpassQuery,
                    signal: controller.signal,
                    headers: { "Content-Type": "text/plain" },
                });
                if (!response.ok) continue;

                const text = await response.text();
                if (!text || text.includes("rate_limited")) continue;

                let payload: unknown = null;
                try {
                    payload = JSON.parse(text);
                } catch {
                    continue;
                }

                const rows = parseOverpassElements(payload)
                    .map((el) => rawPlaceFromOverpass(city, el))
                    .filter((r): r is RawPlace => Boolean(r));
                if (rows.length > 0) return rows;
            } catch {
                continue;
            } finally {
                clearTimeout(timeout);
            }
        }
    }

    return fetchNominatimPlaces(city, profile);
}

async function fetchNominatimPlaces(city: CitySeed, profile: InventoryProfile): Promise<RawPlace[]> {
    const url = new URL("https://nominatim.openstreetmap.org/search");
    url.searchParams.set("q", `${profile.searchText} in ${city.city}`);
    url.searchParams.set("format", "jsonv2");
    url.searchParams.set("limit", String(env.aggregator.maxItemsPerCity));
    url.searchParams.set("addressdetails", "1");

    try {
        const response = await fetch(url.toString(), {
            headers: {
                "User-Agent": "BrokerPlatformAggregator/1.0",
                Accept: "application/json",
            },
        });
        if (!response.ok) return [];

        const rows = (await response.json()) as Array<Record<string, unknown>>;
        if (!Array.isArray(rows)) return [];

        return rows
            .map((row) => {
                const lat = toFiniteNumber(row.lat, Number.NaN);
                const lng = toFiniteNumber(row.lon, Number.NaN);
                if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;

                const address = row.address as Record<string, unknown> | undefined;
                const displayName = String(row.display_name || "").trim();
                const title = displayName.split(",")[0]?.trim() || String(row.name || "").trim() || `${profile.searchText} ${city.city}`;

                return {
                    source: "osm",
                    sourceId: String(row.place_id || `${title}:${lat}:${lng}`),
                    name: title,
                    lat,
                    lng,
                    address: displayName || null,
                    city: String(address?.city || address?.town || address?.village || city.city),
                    country: String(address?.country_code || city.country),
                    payload: {
                        source: "nominatim",
                        raw: row,
                    },
                } as RawPlace;
            })
            .filter((item): item is RawPlace => Boolean(item));
    } catch {
        return [];
    }
}

async function fetchGooglePlaces(city: CitySeed, profile: InventoryProfile): Promise<RawPlace[]> {
    if (!env.aggregator.googlePlacesKey) return [];
    const url = new URL("https://maps.googleapis.com/maps/api/place/textsearch/json");
    url.searchParams.set("query", `${profile.searchText} in ${city.city}`);
    url.searchParams.set("location", `${city.lat},${city.lng}`);
    url.searchParams.set("radius", String(city.radius));
    url.searchParams.set("key", env.aggregator.googlePlacesKey);

    const response = await fetch(url.toString());
    if (!response.ok) return [];
    const payload = (await response.json()) as { results?: Array<Record<string, unknown>> };
    const rows = Array.isArray(payload.results) ? payload.results : [];

    return rows.map((row) => {
        const geometry = row.geometry as { location?: { lat?: number; lng?: number } } | undefined;
        const lat = toFiniteNumber(geometry?.location?.lat, Number.NaN);
        const lng = toFiniteNumber(geometry?.location?.lng, Number.NaN);
        const name = String(row.name || "").trim();
        if (!name || !Number.isFinite(lat) || !Number.isFinite(lng)) return null;
        return { source: "google", sourceId: String(row.place_id || name), name, lat, lng, address: String(row.formatted_address || "") || null, city: city.city, country: city.country, rating: parseOptionalNumber(row.rating), payload: { source: "google", raw: row } } as RawPlace;
    }).filter((r): r is RawPlace => Boolean(r));
}
async function fetchHerePlaces(city: CitySeed, profile: InventoryProfile): Promise<RawPlace[]> {
    if (!env.aggregator.hereApiKey) return [];
    const url = new URL("https://discover.search.hereapi.com/v1/discover");
    url.searchParams.set("at", `${city.lat},${city.lng}`);
    url.searchParams.set("q", profile.searchText);
    url.searchParams.set("limit", String(env.aggregator.maxItemsPerCity));
    url.searchParams.set("apiKey", env.aggregator.hereApiKey);

    const response = await fetch(url.toString());
    if (!response.ok) return [];
    const payload = (await response.json()) as { items?: Array<Record<string, unknown>> };
    const rows = Array.isArray(payload.items) ? payload.items : [];

    return rows.map((row) => {
        const pos = row.position as { lat?: number; lng?: number } | undefined;
        const lat = toFiniteNumber(pos?.lat, Number.NaN);
        const lng = toFiniteNumber(pos?.lng, Number.NaN);
        const name = String(row.title || "").trim();
        if (!name || !Number.isFinite(lat) || !Number.isFinite(lng)) return null;
        const addr = row.address as { label?: string; city?: string; countryCode?: string } | undefined;
        return { source: "here", sourceId: String(row.id || name), name, lat, lng, address: String(addr?.label || "") || null, city: addr?.city || city.city, country: addr?.countryCode || city.country, payload: { source: "here", raw: row } } as RawPlace;
    }).filter((r): r is RawPlace => Boolean(r));
}

async function fetchTomTomPlaces(city: CitySeed, profile: InventoryProfile): Promise<RawPlace[]> {
    if (!env.aggregator.tomtomApiKey) return [];
    const url = new URL(`https://api.tomtom.com/search/2/poiSearch/${encodeURIComponent(profile.searchText)}.json`);
    url.searchParams.set("lat", String(city.lat));
    url.searchParams.set("lon", String(city.lng));
    url.searchParams.set("radius", String(city.radius));
    url.searchParams.set("limit", String(env.aggregator.maxItemsPerCity));
    url.searchParams.set("key", env.aggregator.tomtomApiKey);

    const response = await fetch(url.toString());
    if (!response.ok) return [];
    const payload = (await response.json()) as { results?: Array<Record<string, unknown>> };
    const rows = Array.isArray(payload.results) ? payload.results : [];

    return rows.map((row) => {
        const pos = row.position as { lat?: number; lon?: number } | undefined;
        const lat = toFiniteNumber(pos?.lat, Number.NaN);
        const lng = toFiniteNumber(pos?.lon, Number.NaN);
        const poi = row.poi as { name?: string } | undefined;
        const name = String(poi?.name || "").trim();
        if (!name || !Number.isFinite(lat) || !Number.isFinite(lng)) return null;
        const addr = row.address as { freeformAddress?: string; municipality?: string; countryCode?: string } | undefined;
        return { source: "tomtom", sourceId: String(row.id || name), name, lat, lng, address: String(addr?.freeformAddress || "") || null, city: addr?.municipality || city.city, country: addr?.countryCode || city.country, payload: { source: "tomtom", raw: row } } as RawPlace;
    }).filter((r): r is RawPlace => Boolean(r));
}

async function fetchFoursquarePlaces(city: CitySeed, profile: InventoryProfile): Promise<RawPlace[]> {
    if (!env.aggregator.foursquareApiKey) return [];
    const url = new URL("https://api.foursquare.com/v3/places/search");
    url.searchParams.set("ll", `${city.lat},${city.lng}`);
    url.searchParams.set("radius", String(city.radius));
    url.searchParams.set("query", profile.searchText);
    url.searchParams.set("limit", String(env.aggregator.maxItemsPerCity));

    const response = await fetch(url.toString(), { headers: { Authorization: env.aggregator.foursquareApiKey } });
    if (!response.ok) return [];
    const payload = (await response.json()) as { results?: Array<Record<string, unknown>> };
    const rows = Array.isArray(payload.results) ? payload.results : [];

    return rows.map((row) => {
        const geo = row.geocodes as { main?: { latitude?: number; longitude?: number } } | undefined;
        const lat = toFiniteNumber(geo?.main?.latitude, Number.NaN);
        const lng = toFiniteNumber(geo?.main?.longitude, Number.NaN);
        const name = String(row.name || "").trim();
        if (!name || !Number.isFinite(lat) || !Number.isFinite(lng)) return null;
        const location = row.location as { formatted_address?: string; locality?: string; country?: string } | undefined;
        return { source: "foursquare", sourceId: String(row.fsq_id || name), name, lat, lng, address: String(location?.formatted_address || "") || null, city: location?.locality || city.city, country: location?.country || city.country, payload: { source: "foursquare", raw: row } } as RawPlace;
    }).filter((r): r is RawPlace => Boolean(r));
}

async function fetchGeoapifyPlaces(city: CitySeed, profile: InventoryProfile): Promise<RawPlace[]> {
    if (!env.aggregator.geoapifyApiKey) return [];
    const url = new URL("https://api.geoapify.com/v2/places");
    url.searchParams.set("categories", profile.geoapifyCategories);
    url.searchParams.set("filter", `circle:${city.lng},${city.lat},${city.radius}`);
    url.searchParams.set("limit", String(env.aggregator.maxItemsPerCity));
    url.searchParams.set("apiKey", env.aggregator.geoapifyApiKey);

    const response = await fetch(url.toString());
    if (!response.ok) return [];
    const payload = (await response.json()) as { features?: Array<Record<string, unknown>> };
    const rows = Array.isArray(payload.features) ? payload.features : [];

    return rows.map((row) => {
        const geometry = row.geometry as { coordinates?: [number, number] } | undefined;
        const c = Array.isArray(geometry?.coordinates) ? geometry.coordinates : null;
        const lng = toFiniteNumber(c?.[0], Number.NaN);
        const lat = toFiniteNumber(c?.[1], Number.NaN);
        const props = row.properties as Record<string, unknown> | undefined;
        const name = String(props?.name || "").trim();
        if (!name || !Number.isFinite(lat) || !Number.isFinite(lng)) return null;
        return { source: "geoapify", sourceId: String(props?.place_id || name), name, lat, lng, address: String(props?.formatted || "") || null, city: String(props?.city || city.city), country: String(props?.country_code || city.country), payload: { source: "geoapify", raw: row } } as RawPlace;
    }).filter((r): r is RawPlace => Boolean(r));
}

async function fetchPlacesFromProvider(provider: PlaceProvider, city: CitySeed, profile: InventoryProfile): Promise<RawPlace[]> {
    if (provider === "google") return fetchGooglePlaces(city, profile);
    if (provider === "here") return fetchHerePlaces(city, profile);
    if (provider === "tomtom") return fetchTomTomPlaces(city, profile);
    if (provider === "foursquare") return fetchFoursquarePlaces(city, profile);
    if (provider === "geoapify") return fetchGeoapifyPlaces(city, profile);
    return fetchOsmPlaces(city, profile);
}

async function fetchPlaces(cityName: string, propertyType: InventoryType): Promise<RawPlace[]> {
    const city = citySeedFromName(cityName);
    const profile = INVENTORY_PROFILES[propertyType];
    const providers = parsePlaceProviders(env.aggregator.placeProviders);
    const dedup = new Map<string, RawPlace>();

    for (const provider of providers) {
        try {
            const rows = await fetchPlacesFromProvider(provider, city, profile);
            for (const row of rows) {
                const key = `${row.source}:${row.sourceId}`;
                if (!dedup.has(key)) dedup.set(key, row);
                if (dedup.size >= env.aggregator.maxItemsPerCity) {
                    return Array.from(dedup.values()).slice(0, env.aggregator.maxItemsPerCity);
                }
            }
        } catch (error) {
            console.warn(`[Aggregator] Places provider ${provider} failed for ${cityName}/${propertyType}.`, error);
        }
        if (env.aggregator.osmCooldownMs > 0) await sleep(Math.floor(env.aggregator.osmCooldownMs / 2));
    }

    if (dedup.size > 0) {
        return Array.from(dedup.values()).slice(0, env.aggregator.maxItemsPerCity);
    }

    const curated = curatedPlaces(city, profile);
    if (curated.length > 0) {
        return curated.slice(0, env.aggregator.maxItemsPerCity);
    }

    return [];
}

async function fetchBookingRoomInventory(cityName: string): Promise<NormalizedInventory[]> {
    const city = citySeedFromName(cityName);
    const profile = INVENTORY_PROFILES.room;
    if (!env.aggregator.rapidApi.key || !env.aggregator.rapidApi.host) return [];

    const url = new URL(env.aggregator.rapidApi.endpoint);
    const checkIn = new Date();
    checkIn.setDate(checkIn.getDate() + 7);
    const checkOut = new Date(checkIn);
    checkOut.setDate(checkOut.getDate() + 2);
    const toIsoDate = (d: Date) => d.toISOString().slice(0, 10);

    if (!url.searchParams.get("query")) url.searchParams.set("query", city.city);
    if (!url.searchParams.get("dest_id")) url.searchParams.set("dest_id", "-1");
    if (!url.searchParams.get("search_type")) url.searchParams.set("search_type", "CITY");
    if (!url.searchParams.get("arrival_date")) url.searchParams.set("arrival_date", toIsoDate(checkIn));
    if (!url.searchParams.get("departure_date")) url.searchParams.set("departure_date", toIsoDate(checkOut));
    if (!url.searchParams.get("adults")) url.searchParams.set("adults", "2");
    if (!url.searchParams.get("room_qty")) url.searchParams.set("room_qty", "1");
    if (!url.searchParams.get("languagecode")) url.searchParams.set("languagecode", "en-us");
    if (!url.searchParams.get("currency_code")) url.searchParams.set("currency_code", "USD");

    const response = await fetch(url.toString(), { headers: { "X-RapidAPI-Key": env.aggregator.rapidApi.key, "X-RapidAPI-Host": env.aggregator.rapidApi.host } });
    if (!response.ok) return [];

    const payload = (await response.json()) as Record<string, unknown>;
    const rows = ((payload?.data as Record<string, unknown> | undefined)?.hotels || (payload?.data as Record<string, unknown> | undefined)?.result || payload?.result || payload?.data || []) as unknown[];
    if (!Array.isArray(rows)) return [];

    return rows.map((raw, idx) => {
        const row = raw as Record<string, unknown>;
        const name = String(row.name || row.hotel_name || row.property_name || row.title || "").trim();
        if (!name) return null;
        const externalId = `booking:room:${String(row.hotel_id || row.id || `${city.city}-${idx}`)}`;
        const country = normalizeCountry(row.country_code || row.country, city.country);
        const price = clamp(Math.round(toFiniteNumber(row.min_total_price || row.price || (row.price_breakdown as Record<string, unknown> | undefined)?.all_inclusive_price, 150)), profile.priceRange.min, profile.priceRange.max);
        return { source: "booking", externalId, propertyType: "room", providerType: profile.providerType, providerName: profile.providerName, name, description: inventoryDescription(profile, city), address: null, city: String(row.city || row.city_name || city.city), country, lat: toFiniteNumber(row.latitude || row.lat, city.lat), lng: toFiniteNumber(row.longitude || row.lng, city.lng), price, currency: normalizeCurrency(row.currencycode || row.currency_code || row.currency, currencyFromCountry(country)), rating: clamp(Number(toFiniteNumber(row.review_score || row.rating, 4.1).toFixed(2)), 0, 5), image: String(row.main_photo_url || row.image_url || "") || null, maxGuests: profile.maxGuests, payload: { source: "booking_rapidapi", raw: row } } as NormalizedInventory;
    }).filter((r): r is NormalizedInventory => Boolean(r)).slice(0, env.aggregator.maxItemsPerCity);
}
async function getAmadeusToken() {
    if (!env.aggregator.amadeusClientId || !env.aggregator.amadeusClientSecret) return null;
    const now = Date.now();
    if (amadeusTokenCache && amadeusTokenCache.expiresAt > now + 60000) return amadeusTokenCache.token;

    const body = new URLSearchParams();
    body.set("grant_type", "client_credentials");
    body.set("client_id", env.aggregator.amadeusClientId);
    body.set("client_secret", env.aggregator.amadeusClientSecret);

    const response = await fetch("https://test.api.amadeus.com/v1/security/oauth2/token", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: body.toString(),
    });
    if (!response.ok) return null;

    const payload = (await response.json()) as { access_token?: string; expires_in?: number };
    if (!payload.access_token) return null;

    amadeusTokenCache = {
        token: payload.access_token,
        expiresAt: now + Math.max((payload.expires_in || 1800) * 1000, 300000),
    };
    return amadeusTokenCache.token;
}

function pickDestinationAirport(origin: string) {
    const airports = ["JFK", "LHR", "CDG", "MAD", "MIA", "BCN", "FCO", "LIS", "BER", "HND", "BOG", "CCS"];
    const candidates = airports.filter((code) => code !== origin);
    return candidates[hashString(origin) % candidates.length] || "JFK";
}

async function fetchAmadeusFlights(cityName: string): Promise<NormalizedInventory[]> {
    const city = citySeedFromName(cityName);
    const profile = INVENTORY_PROFILES.flight;
    if (!city.airportIata) return [];

    const token = await getAmadeusToken();
    if (!token) return [];

    const departure = new Date();
    departure.setDate(departure.getDate() + 10);
    const departureDate = departure.toISOString().slice(0, 10);
    const destination = pickDestinationAirport(city.airportIata);

    const url = new URL("https://test.api.amadeus.com/v2/shopping/flight-offers");
    url.searchParams.set("originLocationCode", city.airportIata);
    url.searchParams.set("destinationLocationCode", destination);
    url.searchParams.set("departureDate", departureDate);
    url.searchParams.set("adults", "1");
    url.searchParams.set("max", String(Math.min(env.aggregator.maxItemsPerCity, 25)));
    url.searchParams.set("currencyCode", "USD");

    const response = await fetch(url.toString(), { headers: { Authorization: `Bearer ${token}` } });
    if (!response.ok) return [];

    const payload = (await response.json()) as { data?: Array<Record<string, unknown>> };
    const rows = Array.isArray(payload.data) ? payload.data : [];

    return rows.map((row, idx) => {
        const id = String(row.id || `${city.airportIata}-${destination}-${idx}`);
        const itineraries = row.itineraries as Array<Record<string, unknown>> | undefined;
        const segments = (itineraries?.[0]?.segments as Array<Record<string, unknown>> | undefined) || [];
        const first = segments[0];
        const carrier = String(first?.carrierCode || "AIR");
        const dep = String((first?.departure as Record<string, unknown> | undefined)?.iataCode || city.airportIata);
        const arr = String((first?.arrival as Record<string, unknown> | undefined)?.iataCode || destination);
        const priceRaw = (row.price as Record<string, unknown> | undefined)?.grandTotal;
        const seed = `amadeus:${id}`;

        return {
            source: "amadeus",
            externalId: `amadeus:flight:${id}`,
            propertyType: "flight",
            providerType: profile.providerType,
            providerName: profile.providerName,
            name: `${carrier} ${dep}-${arr}`,
            description: `Flight offer from ${dep} to ${arr}. Price and availability from Amadeus.`,
            address: `${city.airportIata} Airport`,
            city: city.city,
            country: city.country,
            lat: Number((city.lat + deterministicInt(`${seed}:lat`, -250, 250) / 10000).toFixed(7)),
            lng: Number((city.lng + deterministicInt(`${seed}:lng`, -250, 250) / 10000).toFixed(7)),
            price: clamp(Math.round(toFiniteNumber(priceRaw, 280)), profile.priceRange.min, profile.priceRange.max),
            currency: normalizeCurrency((row.price as Record<string, unknown> | undefined)?.currency, "USD"),
            rating: deterministicFloat(`${seed}:rating`, profile.ratingRange.min, profile.ratingRange.max, 2),
            image: `${profile.images[idx % profile.images.length]}?w=900&fit=crop`,
            maxGuests: profile.maxGuests,
            payload: { source: "amadeus", destination, raw: row },
        } as NormalizedInventory;
    }).slice(0, env.aggregator.maxItemsPerCity);
}

async function fetchInventoryForCity(cityName: string, propertyType: InventoryType): Promise<NormalizedInventory[]> {
    const city = citySeedFromName(cityName);
    const profile = INVENTORY_PROFILES[propertyType];

    for (const provider of parseInventoryProviders(env.aggregator.inventoryProviders)) {
        if (provider === "booking" && propertyType === "room") {
            try { const rows = await fetchBookingRoomInventory(cityName); if (rows.length > 0) return rows; } catch {}
            continue;
        }
        if (provider === "amadeus" && propertyType === "flight") {
            try { const rows = await fetchAmadeusFlights(cityName); if (rows.length > 0) return rows; } catch {}
            continue;
        }
        if (provider === "expedia") {
            if (!warnedExpediaMissingAccess) {
                console.warn("[Aggregator] Expedia adapter reservado (requiere acceso partner privado). Se usa fallback.");
                warnedExpediaMissingAccess = true;
            }
            continue;
        }
        if (provider === "simulated") break;
    }

    const places = await fetchPlaces(cityName, propertyType);
    if (places.length > 0) {
        const mapped = places.slice(0, env.aggregator.maxItemsPerCity).map((p, i) => normalizeFromPlace(p, city, profile, i));
        if (mapped.length > 0) return mapped;
    }

    return fallbackInventory(cityName, propertyType, env.aggregator.maxItemsPerCity);
}
class DataAggregatorWorker {
    private running = false;
    private hasExternalRefTableCache: boolean | null = null;
    private providerCache = new Map<InventoryType, number>();

    start() {
        if (!env.aggregator.enabled) return;
        if (!cron.validate(env.aggregator.schedule)) {
            console.error(`[Aggregator] Invalid cron expression ${env.aggregator.schedule}`);
            return;
        }

        const types = env.aggregator.inventoryTypes.map((v) => toInventoryType(v)).filter((v): v is InventoryType => Boolean(v));
        console.log(`[Aggregator] schedule=${env.aggregator.schedule} cities=${env.aggregator.cities.join(",")} types=${types.join(",")} places=${parsePlaceProviders(env.aggregator.placeProviders).join(",")} inv=${parseInventoryProviders(env.aggregator.inventoryProviders).join(",")}`);

        cron.schedule(env.aggregator.schedule, async () => { await this.runSync("scheduled"); });
        if (env.aggregator.runOnStartup) setTimeout(() => { void this.runSync("startup"); }, env.aggregator.startupDelayMs);
    }

    async runManual() { await this.runSync("manual"); }

    private async ensureProvider(propertyType: InventoryType) {
        const cached = this.providerCache.get(propertyType);
        if (cached) return cached;

        const profile = INVENTORY_PROFILES[propertyType];
        const existing = await query<{ id: number }>("SELECT TOP 1 id FROM Providers WHERE name=@name", { name: profile.providerName });
        if (existing[0]?.id) {
            this.providerCache.set(propertyType, existing[0].id);
            return existing[0].id;
        }

        const created = await execute(
            "INSERT INTO Providers (name,type,commission_pct,status,description) OUTPUT INSERTED.id VALUES (@name,@type,@comm,'active',@description)",
            { name: profile.providerName, type: profile.providerType, comm: profile.commissionPct, description: `Automated ${propertyType} inventory from geo/inventory providers.` }
        );

        const providerId = Number(created.recordset[0]?.id);
        this.providerCache.set(propertyType, providerId);
        return providerId;
    }

    private async hasExternalRefTable() {
        if (this.hasExternalRefTableCache !== null) return this.hasExternalRefTableCache;
        try {
            const rows = await query<{ has_table: number }>(
                "SELECT CASE WHEN OBJECT_ID('dbo.PropertyExternalRefs','U') IS NULL THEN 0 ELSE 1 END AS has_table"
            );
            this.hasExternalRefTableCache = rows[0]?.has_table === 1;
        } catch {
            this.hasExternalRefTableCache = false;
        }
        return this.hasExternalRefTableCache;
    }

    private async findExistingProperty(providerId: number, item: NormalizedInventory) {
        if (await this.hasExternalRefTable()) {
            const refs = await query<{ property_id: number }>(
                "SELECT TOP 1 property_id FROM PropertyExternalRefs WHERE source=@source AND external_id=@external_id",
                { source: item.source, external_id: item.externalId }
            );
            if (refs[0]?.property_id) return refs[0].property_id;
        }

        const rows = await query<{ id: number }>(
            "SELECT TOP 1 id FROM Properties WHERE provider_id=@provider_id AND name=@name AND city=@city AND type=@type",
            { provider_id: providerId, name: item.name, city: item.city, type: item.propertyType }
        );
        return rows[0]?.id ?? null;
    }

    private async upsertProperty(providerId: number, item: NormalizedInventory) {
        const existingId = await this.findExistingProperty(providerId, item);
        let propertyId = existingId;

        if (propertyId) {
            await execute(
                "UPDATE Properties SET type=@type,description=@description,address=@address,country=@country,latitude=@latitude,longitude=@longitude,max_guests=@max_guests,updated_at=GETUTCDATE() WHERE id=@id",
                { id: propertyId, type: item.propertyType, description: item.description, address: item.address, country: item.country, latitude: item.lat, longitude: item.lng, max_guests: item.maxGuests }
            );
        } else {
            const created = await execute(
                "INSERT INTO Properties (provider_id,name,type,description,address,city,country,latitude,longitude,max_guests,images,status) OUTPUT INSERTED.id VALUES (@provider_id,@name,@type,@description,@address,@city,@country,@latitude,@longitude,@max_guests,@images,'active')",
                { provider_id: providerId, name: item.name, type: item.propertyType, description: item.description, address: item.address, city: item.city, country: item.country, latitude: item.lat, longitude: item.lng, max_guests: item.maxGuests, images: JSON.stringify(item.image ? [item.image] : []) }
            );
            propertyId = Number(created.recordset[0]?.id);
        }

        const rate = await query<{ id: number }>(
            "SELECT TOP 1 id FROM PropertyRates WHERE property_id=@property_id AND name='standard'",
            { property_id: propertyId }
        );
        if (rate[0]?.id) {
            await execute("UPDATE PropertyRates SET price_per_night=@price,currency=@currency WHERE id=@id", { id: rate[0].id, price: item.price, currency: item.currency });
        } else {
            await execute("INSERT INTO PropertyRates (property_id,name,price_per_night,currency) VALUES (@property_id,'standard',@price,@currency)", { property_id: propertyId, price: item.price, currency: item.currency });
        }

        if (await this.hasExternalRefTable()) {
            await execute(
                "MERGE PropertyExternalRefs AS target USING (SELECT @source AS source, @external_id AS external_id) AS src ON target.source=src.source AND target.external_id=src.external_id WHEN MATCHED THEN UPDATE SET property_id=@property_id,payload_json=@payload_json,fetched_at=GETUTCDATE(),updated_at=GETUTCDATE() WHEN NOT MATCHED THEN INSERT (property_id,source,external_id,payload_json,fetched_at) VALUES (@property_id,@source,@external_id,@payload_json,GETUTCDATE());",
                { property_id: propertyId, source: item.source, external_id: item.externalId, payload_json: JSON.stringify(item.payload) }
            );
        }
    }

    private async runSync(trigger: TriggerType) {
        if (this.running) return;
        this.running = true;
        const startedAt = Date.now();
        const stats: Record<InventoryType, number> = { room: 0, vehicle: 0, boat: 0, flight: 0, train: 0 };

        try {
            const types = env.aggregator.inventoryTypes.map((v) => toInventoryType(v)).filter((v): v is InventoryType => Boolean(v));
            for (const cityName of env.aggregator.cities) {
                for (const type of types) {
                    const providerId = await this.ensureProvider(type);
                    const rows = await fetchInventoryForCity(cityName, type);
                    for (const row of rows) {
                        await this.upsertProperty(providerId, row);
                        stats[type] += 1;
                    }
                    if (env.aggregator.osmCooldownMs > 0) await sleep(env.aggregator.osmCooldownMs);
                }
            }
            const elapsed = Date.now() - startedAt;
            console.log(`[Aggregator] ${trigger} sync completed room=${stats.room} vehicle=${stats.vehicle} boat=${stats.boat} flight=${stats.flight} train=${stats.train} elapsedMs=${elapsed}`);
        } catch (error) {
            console.error(`[Aggregator] ${trigger} sync failed`, error);
        } finally {
            this.running = false;
        }
    }
}

export const aggregatorWorker = new DataAggregatorWorker();
