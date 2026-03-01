const VALID_AGGREGATOR_INVENTORY_TYPES = new Set(["room", "vehicle", "boat", "flight", "train"]);
const VALID_AGGREGATOR_PLACE_PROVIDERS = new Set(["google", "here", "tomtom", "foursquare", "geoapify", "osm"]);
const VALID_AGGREGATOR_INVENTORY_PROVIDERS = new Set(["booking", "expedia", "amadeus", "simulated"]);

function parseInventoryTypes(raw: string) {
    const values = raw
        .split(",")
        .map((v) => v.trim().toLowerCase())
        .filter(Boolean)
        .filter((v) => VALID_AGGREGATOR_INVENTORY_TYPES.has(v));

    if (values.length === 0) {
        return ["room", "vehicle", "boat", "flight", "train"];
    }
    return Array.from(new Set(values));
}

function parsePlaceProviders(raw: string) {
    const values = raw
        .split(",")
        .map((v) => v.trim().toLowerCase())
        .filter(Boolean)
        .filter((v) => VALID_AGGREGATOR_PLACE_PROVIDERS.has(v));

    if (values.length === 0) {
        return ["geoapify", "foursquare", "tomtom", "here", "google", "osm"];
    }
    return Array.from(new Set(values));
}

function parseInventoryProviders(raw: string) {
    const values = raw
        .split(",")
        .map((v) => v.trim().toLowerCase())
        .filter(Boolean)
        .filter((v) => VALID_AGGREGATOR_INVENTORY_PROVIDERS.has(v));

    if (values.length === 0) {
        return ["booking", "amadeus", "simulated"];
    }
    return Array.from(new Set(values));
}

export const env = {
    port: Number(process.env.PORT || 4100),
    nodeEnv: process.env.NODE_ENV || "development",
    db: {
        server: process.env.DB_SERVER || "(local)\\SQLEXPRESS",
        database: process.env.DB_DATABASE || "BrokerDB",
        user: process.env.DB_USER || "sa",
        password: process.env.DB_PASSWORD || "",
        encrypt: String(process.env.DB_ENCRYPT || "false").toLowerCase() === "true",
        trustServerCertificate: String(process.env.DB_TRUST_CERT || "true").toLowerCase() !== "false",
        poolMin: Number(process.env.DB_POOL_MIN || 0),
        poolMax: Number(process.env.DB_POOL_MAX || 10),
    },
    jwt: {
        secret: process.env.JWT_SECRET || "change_me",
        expires: process.env.JWT_EXPIRES || "12h",
    },
    redisUrl: process.env.REDIS_URL || "",
    aggregator: {
        enabled: String(process.env.AGGREGATOR_CRON_ENABLED || "true").toLowerCase() !== "false",
        schedule: process.env.AGGREGATOR_CRON_SCHEDULE || "0 */6 * * *",
        runOnStartup: String(process.env.AGGREGATOR_RUN_ON_STARTUP || "true").toLowerCase() !== "false",
        startupDelayMs: Math.max(Number(process.env.AGGREGATOR_STARTUP_DELAY_MS || 5000), 0),
        provider: String(process.env.AGGREGATOR_PROVIDER || "auto").toLowerCase(),
        cities: String(
            process.env.AGGREGATOR_CITIES || "New York,London,Paris,Tokyo,Madrid,Miami"
        )
            .split(",")
            .map((c) => c.trim())
            .filter(Boolean),
        inventoryTypes: parseInventoryTypes(
            String(process.env.AGGREGATOR_INVENTORY_TYPES || "room,vehicle,boat,flight,train")
        ),
        placeProviders: parsePlaceProviders(
            String(
                process.env.AGGREGATOR_PLACE_PROVIDERS || "geoapify,foursquare,tomtom,here,google,osm"
            )
        ),
        inventoryProviders: parseInventoryProviders(
            String(process.env.AGGREGATOR_INVENTORY_PROVIDERS || "booking,amadeus,simulated")
        ),
        maxItemsPerCity: Math.min(
            Math.max(Number(process.env.AGGREGATOR_MAX_ITEMS_PER_CITY || 25), 1),
            100
        ),
        osmTimeoutMs: Math.max(Number(process.env.AGGREGATOR_OSM_TIMEOUT_MS || 18000), 1000),
        osmCooldownMs: Math.max(Number(process.env.AGGREGATOR_OSM_COOLDOWN_MS || 900), 0),
        googlePlacesKey: process.env.GOOGLE_PLACES_API_KEY || "",
        hereApiKey: process.env.HERE_API_KEY || "",
        tomtomApiKey: process.env.TOMTOM_API_KEY || "",
        foursquareApiKey: process.env.FOURSQUARE_API_KEY || "",
        geoapifyApiKey: process.env.GEOAPIFY_API_KEY || "",
        amadeusClientId: process.env.AMADEUS_CLIENT_ID || "",
        amadeusClientSecret: process.env.AMADEUS_CLIENT_SECRET || "",
        expediaApiKey: process.env.EXPEDIA_API_KEY || "",
        rapidApi: {
            key: process.env.RAPIDAPI_KEY || "",
            host: process.env.RAPIDAPI_HOST || "",
            endpoint:
                process.env.RAPIDAPI_ENDPOINT ||
                "https://booking-com15.p.rapidapi.com/api/v1/hotels/searchHotels",
            timeoutMs: Math.max(Number(process.env.RAPIDAPI_TIMEOUT_MS || 12000), 1000),
        },
    },
};
