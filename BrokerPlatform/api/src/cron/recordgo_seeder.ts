import "dotenv/config";
import { query, execute } from "../db/query.js";

const RECORD_GO_HUBS = [
    // España Península
    { city: "Madrid", country: "ESP", lat: 40.4168, lng: -3.7038, radius: 25000 },
    { city: "Barcelona", country: "ESP", lat: 41.3874, lng: 2.1686, radius: 25000 },
    { city: "Palma", country: "ESP", lat: 39.5696, lng: 2.6502, radius: 25000 },
    { city: "Malaga", country: "ESP", lat: 36.7212, lng: -4.4214, radius: 25000 },
    { city: "Alicante", country: "ESP", lat: 38.3452, lng: -0.4810, radius: 25000 },
    { city: "Valencia", country: "ESP", lat: 39.4699, lng: -0.3763, radius: 25000 },
    // España: Canarias
    { city: "Tenerife", country: "ESP", lat: 28.2916, lng: -16.6291, radius: 30000 },
    { city: "Gran Canaria", country: "ESP", lat: 27.9202, lng: -15.3866, radius: 25000 },
    // Portugal
    { city: "Lisbon", country: "PRT", lat: 38.7223, lng: -9.1393, radius: 25000 },
    { city: "Porto", country: "PRT", lat: 41.1579, lng: -8.6291, radius: 25000 },
    { city: "Faro", country: "PRT", lat: 37.0194, lng: -7.9322, radius: 25000 },
    // Italia
    { city: "Rome", country: "ITA", lat: 41.9028, lng: 12.4964, radius: 25000 },
    { city: "Milan", country: "ITA", lat: 45.4642, lng: 9.1900, radius: 25000 },
    { city: "Catania", country: "ITA", lat: 37.5079, lng: 15.0830, radius: 25000 },
    // Grecia
    { city: "Athens", country: "GRC", lat: 37.9838, lng: 23.7275, radius: 25000 },
    { city: "Thessaloniki", country: "GRC", lat: 40.6401, lng: 22.9444, radius: 25000 }
];

async function delay(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function fetchRecordGoFromOSM(lat: number, lng: number, city: string, radius: number) {
    console.log(`📡 Rastrando oficinas de "Record Go" en ${city}...`);
    // Búsqueda específica usando RegEx para variaciones ("Record Go", "Record go", "Record Rent a Car")
    const overpassQuery = `
    [out:json];
    (
      node(around:${radius}, ${lat}, ${lng})["amenity"="car_rental"]["name"~"Record ?[Gg]o|Record Rent",i];
      way(around:${radius}, ${lat}, ${lng})["amenity"="car_rental"]["name"~"Record ?[Gg]o|Record Rent",i];
    );
    out center;
    `;

    try {
        const response = await fetch("https://overpass-api.de/api/interpreter", {
            method: "POST",
            body: overpassQuery
        });

        if (!response.ok) {
            console.warn(`[!] Servidor OSM ocupado para ${city}, reintentando no aplicable hoy.`);
            return [];
        }

        const data = await response.json();

        return data.elements.map((el: any) => {
            const tags = el.tags || {};
            const street = tags["addr:street"];
            const houseNumber = tags["addr:housenumber"];
            const rawAddress = (street && houseNumber) ? `${street} ${houseNumber}` : street;

            // Si es un "way", las coordenadas vienen en "center"
            const finalLat = el.lat || (el.center && el.center.lat);
            const finalLng = el.lon || (el.center && el.center.lon);

            return {
                name: tags.name || "Record Go Auto Rental",
                lat: finalLat,
                lng: finalLng,
                address: rawAddress || null,
                zipCode: tags["addr:postcode"] || null,
                phone: tags["phone"] || tags["contact:phone"] || null,
                website: tags["website"] || tags["contact:website"] || "https://www.recordrentacar.com",
            };
        });
    } catch (e) {
        console.error(`❌ Falló extracción para ${city}:`, e);
        return [];
    }
}

async function runRecordGoSeeder() {
    console.log("🚀 EXPLORANDO RED OFICIAL DE RECORD GO (ESPAÑA)...");

    const pCheck = await query<any>("SELECT id FROM Providers WHERE name = 'Record Go'");
    let providerId = pCheck[0]?.id;
    if (!providerId) {
        const pResult = await execute(
            "INSERT INTO Providers (name, type, commission_pct, status) OUTPUT INSERTED.id VALUES ('Record Go', 'vehicle', 18, 'active')"
        );
        providerId = pResult.recordset[0].id;
        console.log("✅ Proveedor corporativo 'Record Go' creado con ID:", providerId);
    }

    let insertedCount = 0;

    for (const location of RECORD_GO_HUBS) {
        const branches = await fetchRecordGoFromOSM(location.lat, location.lng, location.city, location.radius);

        if (branches.length > 0) {
            console.log(`📍 ¡${branches.length} oficinas de Record Go encontradas en ${location.city}!`);
        }

        for (const branch of branches) {
            const existCheck = await query<any>(
                "SELECT id FROM Properties WHERE name = @name AND city = @city AND provider_id = @pid",
                { name: branch.name, city: location.city, pid: providerId }
            );

            let propertyId;
            if (existCheck.length > 0) {
                propertyId = existCheck[0].id;
                await execute(
                    `UPDATE Properties 
                     SET latitude = @lat, longitude = @lng, address = @addr, zip_code = @zip, phone = @phone, website = @web 
                     WHERE id = @id`,
                    {
                        lat: branch.lat, lng: branch.lng, addr: branch.address,
                        zip: branch.zipCode, phone: branch.phone, web: branch.website,
                        id: propertyId
                    }
                );
            } else {
                const img = JSON.stringify(["https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=800&fit=crop"]); // Car rental placeholder
                const insertRes = await execute(
                    `INSERT INTO Properties 
                        (provider_id, name, type, description, address, city, country, zip_code, phone, website, latitude, longitude, max_guests, images, status) 
                     OUTPUT INSERTED.id
                     VALUES (@pid, @name, 'vehicle', @desc, @addr, @city, @country, @zip, @phone, @web, @lat, @lng, 5, @imgs, 'active')`,
                    {
                        pid: providerId,
                        name: branch.name,
                        desc: `Sucursal oficial de alquiler de vehículos ${branch.name}. Servicio Premium garantizado y flota renovada en los principales aeropuertos y estaciones.`,
                        addr: branch.address,
                        city: location.city,
                        country: location.country,
                        zip: branch.zipCode,
                        phone: branch.phone,
                        web: branch.website,
                        lat: branch.lat,
                        lng: branch.lng,
                        imgs: img
                    }
                );
                propertyId = insertRes.recordset[0].id;
                insertedCount++;

                // Precio aproximado de alquiler diario de Record Go
                const realisticPrice = Math.floor(Math.random() * 40) + 25;
                await execute(
                    `INSERT INTO PropertyRates (property_id, name, price_per_night, currency)
                     VALUES (@id, 'standard', @price, 'EUR')`,
                    { id: propertyId, price: realisticPrice }
                );
            }
        }
        await delay(2000); // Para no molestar a la API
    }

    console.log(`\n🎉 Operación Especial Finalizada. Se inyectaron exitosamente ${insertedCount} oficinas globales de Record Go (España, Portugal, Italia, Grecia y Canarias).`);
    process.exit(0);
}

runRecordGoSeeder();
