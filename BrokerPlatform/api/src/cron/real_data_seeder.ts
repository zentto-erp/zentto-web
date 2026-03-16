import "dotenv/config";
import { query, execute } from "../db/query.js";

const CITIES = [
    { city: "New York", country: "USA", lat: 40.7128, lng: -74.0060, radius: 10000 },
    { city: "London", country: "GBR", lat: 51.5074, lng: -0.1278, radius: 10000 },
    { city: "Paris", country: "FRA", lat: 48.8566, lng: 2.3522, radius: 8000 },
    { city: "Tokyo", country: "JPN", lat: 35.6762, lng: 139.6503, radius: 15000 },
    { city: "Madrid", country: "ESP", lat: 40.4168, lng: -3.7038, radius: 8000 },
    { city: "Miami", country: "USA", lat: 25.7617, lng: -80.1918, radius: 10000 },
    { city: "Rome", country: "ITA", lat: 41.9028, lng: 12.4964, radius: 8000 }
];

const IMAGES = [
    "https://images.unsplash.com/photo-1566073771259-6a8506099945",
    "https://images.unsplash.com/photo-1551882547-ff40c62e54bb",
    "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267",
    "https://images.unsplash.com/photo-1582719508461-905c673771fd",
    "https://images.unsplash.com/photo-1542314831-c6a4d14dbdea"
];

async function fetchRealHotelsFromOSM(lat: number, lng: number, city: string, radius: number) {
    console.log(`🌐 Buscando Hoteles REALES en Múltiples Ciudades (Radio ${radius}m) para ${city}...`);
    // OpenStreetMap JSON Endpoint. Requiere nombres.
    const overpassQuery = `[out:json];node(around:${radius}, ${lat}, ${lng})["tourism"="hotel"]["name"];out 40;`;

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
                stars: el.tags["stars"] ? parseFloat(el.tags["stars"]) : null,
            };
        });
    } catch (e) {
        console.error(`❌ Error con API de OpenStreetMap para ${city}:`, e);
        return [];
    }
}

async function runRealSeeder() {
    console.log("🚀 Iniciando volcado EXPANSIVO de datos reales en BrokerDB...");

    const pCheck = await query<any>("SELECT id FROM Providers WHERE name = 'OSM Global Network'");
    let providerId = pCheck[0]?.id;
    if (!providerId) {
        const pResult = await execute(
            "INSERT INTO Providers (name, type, commission_pct, status) OUTPUT INSERTED.id VALUES ('OSM Global Network', 'hotel', 12, 'active')"
        );
        providerId = pResult.recordset[0].id;
    }

    let insertedCount = 0;

    for (const location of CITIES) {
        const realHotels = await fetchRealHotelsFromOSM(location.lat, location.lng, location.city, location.radius);
        console.log(`📍 ${realHotels.length} hoteles oficiales detectados en ${location.city}. Inyectando info ampliada...`);

        for (const [idx, hotel] of realHotels.entries()) {
            const existCheck = await query<any>(
                "SELECT id FROM Properties WHERE name = @name AND city = @city",
                { name: hotel.name, city: location.city }
            );

            let propertyId;
            if (existCheck.length > 0) {
                propertyId = existCheck[0].id;
                // Si ya existe actualizamos todos los campos extra que creaste en DB
                await execute(
                    `UPDATE Properties 
                     SET latitude = @lat, longitude = @lng, address = @addr, zip_code = @zip, phone = @phone, website = @web, external_rating = @stars 
                     WHERE id = @id`,
                    {
                        lat: hotel.lat, lng: hotel.lng,
                        addr: hotel.address, zip: hotel.zipCode, phone: hotel.phone, web: hotel.website, stars: hotel.stars,
                        id: propertyId
                    }
                );
            } else {
                // Nuevo Hotel
                const imagesArr = JSON.stringify([IMAGES[idx % IMAGES.length] + "?w=800&fit=crop"]);
                const insertRes = await execute(
                    `INSERT INTO Properties 
                        (provider_id, name, type, description, address, city, country, zip_code, phone, website, external_rating, latitude, longitude, max_guests, images, status) 
                     OUTPUT INSERTED.id
                     VALUES (@pid, @name, 'room', @desc, @addr, @city, @country, @zip, @phone, @web, @stars, @lat, @lng, 2, @imgs, 'active')`,
                    {
                        pid: providerId,
                        name: hotel.name,
                        desc: `Hotel oficial extraído. Ubicación real: ${location.city}, coordenadas (${hotel.lat}, ${hotel.lng}).`,
                        addr: hotel.address,
                        city: location.city,
                        country: location.country,
                        zip: hotel.zipCode,
                        phone: hotel.phone,
                        web: hotel.website,
                        stars: hotel.stars,
                        lat: hotel.lat,
                        lng: hotel.lng,
                        imgs: imagesArr
                    }
                );
                propertyId = insertRes.recordset[0].id;
                insertedCount++;

                const realisticPrice = Math.floor(Math.random() * 410) + 90;
                await execute(
                    `INSERT INTO PropertyRates (property_id, name, price_per_night, currency, min_nights)
                     VALUES (@id, 'standard', @price, 'USD', 1)`,
                    { id: propertyId, price: realisticPrice }
                );
            }
        }
    }

    console.log(`\n🎉 ¡COMPLETADO! Base de datos rellenada masivamente. Se inyectaron/actualizaron ${insertedCount} hoteles.`);
    process.exit(0);
}

runRealSeeder();
