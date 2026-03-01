import "dotenv/config";
import { query, execute } from "../db/query.js";

const CITIES = [
    { city: "New York", country: "USA", lat: 40.7128, lng: -74.0060, radius: 15000 },
    { city: "London", country: "GBR", lat: 51.5074, lng: -0.1278, radius: 15000 },
    { city: "Paris", country: "FRA", lat: 48.8566, lng: 2.3522, radius: 12000 },
    { city: "Tokyo", country: "JPN", lat: 35.6762, lng: 139.6503, radius: 15000 },
    { city: "Madrid", country: "ESP", lat: 40.4168, lng: -3.7038, radius: 12000 },
    { city: "Miami", country: "USA", lat: 25.7617, lng: -80.1918, radius: 15000 },
    { city: "Rome", country: "ITA", lat: 41.9028, lng: 12.4964, radius: 12000 }
];

const CATEGORIES = [
    {
        type: "vehicle",
        tag: '"amenity"="car_rental"',
        providerName: "Global Auto Rentals",
        image: "https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?w=800&fit=crop",
        descPrefix: "Rent a top quality vehicle at"
    },
    {
        type: "flight",
        tag: '"aeroway"="aerodrome"',
        providerName: "International Airlines Broker",
        image: "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800&fit=crop",
        descPrefix: "Flight departures and boarding from"
    },
    {
        type: "train",
        tag: '"railway"="station"',
        providerName: "World Railway Services",
        image: "https://images.unsplash.com/photo-1474487548417-781cb71495f3?w=800&fit=crop",
        descPrefix: "Railway transport and daily tickets originating from"
    }
];

async function delay(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function fetchNodesFromOSM(lat: number, lng: number, city: string, radius: number, tag: string) {
    console.log(`📡 Consultando OSM para ${tag} en ${city}...`);
    const overpassQuery = `[out:json];node(around:${radius}, ${lat}, ${lng})[${tag}]["name"];out 30;`;

    try {
        const response = await fetch("https://overpass-api.de/api/interpreter", {
            method: "POST",
            body: overpassQuery
        });
        const data = await response.json();

        return data.elements.map((el: any) => {
            const street = el.tags["addr:street"];
            const houseNumber = el.tags["addr:housenumber"];
            const rawAddress = (street && houseNumber) ? `${street} ${houseNumber}` : street;

            return {
                name: el.tags.name,
                lat: el.lat,
                lng: el.lon,
                address: rawAddress || null,
                zipCode: el.tags["addr:postcode"] || null,
                phone: el.tags["phone"] || el.tags["contact:phone"] || null,
                website: el.tags["website"] || el.tags["contact:website"] || null,
            };
        });
    } catch (e) {
        console.error(`❌ Error con la consulta de OSM (${tag}) para ${city}:`, e);
        return [];
    }
}

async function runExtendedSeeder() {
    console.log("🚀 Iniciando integración masiva de VEHÍCULOS, VUELOS Y TRENES...");
    let totalInserted = 0;

    for (const cat of CATEGORIES) {
        console.log(`\n\n========================================`);
        console.log(`🚀 PROCESANDO CATEGORÍA: ${cat.type.toUpperCase()}`);
        console.log(`========================================\n`);

        // 1. Obtener o crear proveedor para esta categoría
        const pCheck = await query<any>("SELECT id FROM Providers WHERE name = @name", { name: cat.providerName });
        let providerId = pCheck[0]?.id;
        if (!providerId) {
            const pResult = await execute(
                `INSERT INTO Providers (name, type, commission_pct, status) OUTPUT INSERTED.id VALUES (@name, @type, 15, 'active')`,
                { name: cat.providerName, type: cat.type }
            );
            providerId = pResult.recordset[0].id;
        }

        for (const location of CITIES) {
            const nodes = await fetchNodesFromOSM(location.lat, location.lng, location.city, location.radius, cat.tag);
            console.log(`📍 ${nodes.length} locaciones de tipo '${cat.type}' detectadas en ${location.city}. Inyectando info...`);

            for (const [idx, node] of nodes.entries()) {
                const existCheck = await query<any>(
                    "SELECT id FROM Properties WHERE name = @name AND city = @city",
                    { name: node.name, city: location.city }
                );

                let propertyId;
                if (existCheck.length > 0) {
                    propertyId = existCheck[0].id;
                    await execute(
                        `UPDATE Properties 
                         SET latitude = @lat, longitude = @lng, address = @addr, zip_code = @zip, phone = @phone, website = @web
                         WHERE id = @id`,
                        {
                            lat: node.lat, lng: node.lng, addr: node.address,
                            zip: node.zipCode, phone: node.phone, web: node.website, id: propertyId
                        }
                    );
                } else {
                    const imagesArr = JSON.stringify([cat.image]);
                    const insertRes = await execute(
                        `INSERT INTO Properties 
                            (provider_id, name, type, description, address, city, country, zip_code, phone, website, latitude, longitude, max_guests, images, status) 
                         OUTPUT INSERTED.id
                         VALUES (@pid, @name, @type, @desc, @addr, @city, @country, @zip, @phone, @web, @lat, @lng, 4, @imgs, 'active')`,
                        {
                            pid: providerId,
                            name: node.name,
                            type: cat.type,
                            desc: `${cat.descPrefix} ${node.name}. Servicio oficial verificado en ${location.city}.`,
                            addr: node.address,
                            city: location.city,
                            country: location.country,
                            zip: node.zipCode,
                            phone: node.phone,
                            web: node.website,
                            lat: node.lat,
                            lng: node.lng,
                            imgs: imagesArr
                        }
                    );
                    propertyId = insertRes.recordset[0].id;
                    totalInserted++;

                    // Tarifas base (Flotan según el tipo de transporte)
                    const realisticPrice = cat.type === 'flight' ? Math.floor(Math.random() * 800) + 150
                        : cat.type === 'vehicle' ? Math.floor(Math.random() * 90) + 35
                            : Math.floor(Math.random() * 100) + 20; // train

                    await execute(
                        `INSERT INTO PropertyRates (property_id, name, price_per_night, currency)
                         VALUES (@id, 'standard', @price, 'USD')`,
                        { id: propertyId, price: realisticPrice }
                    );
                }
            }

            // Wait 1.5 seconds between queries to prevent OSM throttling
            await delay(1500);
        }
    }

    console.log(`\n🎉 ¡COMPLETADO! Inventario extendido rellenado. Se inyectaron/actualizaron ${totalInserted} registros de vehículos, aeropuertos y trenes reales.`);
    process.exit(0);
}

runExtendedSeeder();
