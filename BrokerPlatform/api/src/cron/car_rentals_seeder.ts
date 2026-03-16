import "dotenv/config";
import { query, execute } from "../db/query.js";

const TARGET_CITIES = [
    { city: "Madrid", country: "ESP", lat: 40.4168, lng: -3.7038, radius: 25000 },
    { city: "Barcelona", country: "ESP", lat: 41.3874, lng: 2.1686, radius: 25000 },
    { city: "Rome", country: "ITA", lat: 41.9028, lng: 12.4964, radius: 25000 },
    { city: "Milan", country: "ITA", lat: 45.4642, lng: 9.1900, radius: 25000 },
    { city: "Lisbon", country: "PRT", lat: 38.7223, lng: -9.1393, radius: 25000 },
    { city: "Athens", country: "GRC", lat: 37.9838, lng: 23.7275, radius: 25000 },
    { city: "Berlin", country: "DEU", lat: 52.5200, lng: 13.4050, radius: 25000 },
    { city: "Paris", country: "FRA", lat: 48.8566, lng: 2.3522, radius: 25000 },
];

const CAR_RENTAL_GIGANTS = [
    { name: "Hertz", matchPattern: "Hertz", domain: "hertz.com", commission: 15 },
    { name: "Avis", matchPattern: "Avis", domain: "avis.com", commission: 14 },
    { name: "Sixt", matchPattern: "Sixt", domain: "sixt.com", commission: 16 },
    { name: "Enterprise", matchPattern: "Enterprise", domain: "enterprise.com", commission: 15 },
    { name: "Europcar", matchPattern: "Europcar", domain: "europcar.com", commission: 14 },
    { name: "Record Go", matchPattern: "Record ?[Gg]o", domain: "recordrentacar.com", commission: 18 }
];

async function delay(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function ensureProviders() {
    console.log("🛠️  Creando perfiles corporativos en Base de Datos de Broker...");
    const providerIds: Record<string, number> = {};
    for (const company of CAR_RENTAL_GIGANTS) {
        const pCheck = await query<any>("SELECT id FROM Providers WHERE name = @name", { name: company.name });
        if (pCheck.length > 0) {
            providerIds[company.name] = pCheck[0].id;
        } else {
            const result = await execute(
                `INSERT INTO Providers (name, type, commission_pct, status) OUTPUT INSERTED.id VALUES (@name, 'vehicle', @comm, 'active')`,
                { name: company.name, comm: company.commission }
            );
            providerIds[company.name] = result.recordset[0].id;
            console.log(`✅ Creado Proveedor: ${company.name} | ID: ${result.recordset[0].id}`);
        }
    }
    return providerIds;
}

async function fetchRentalsFromOSM(lat: number, lng: number, city: string, radius: number) {
    console.log(`\n📡 Rastreando ${city} en búsqueda de todas agencias de alquiler (Hertz, Avis, Sixt, Enterprise, etc)...`);

    const regexPattern = CAR_RENTAL_GIGANTS.map(c => c.matchPattern).join("|");
    const overpassQuery = `
    [out:json];
    (
      node(around:${radius}, ${lat}, ${lng})["amenity"="car_rental"]["name"~"${regexPattern}",i];
      way(around:${radius}, ${lat}, ${lng})["amenity"="car_rental"]["name"~"${regexPattern}",i];
    );
    out center;
    `;

    try {
        const response = await fetch("https://overpass-api.de/api/interpreter", {
            method: "POST",
            body: overpassQuery
        });

        if (!response.ok) {
            console.warn(`[!] Servidor OSM rechazó petición para ${city}. Retomando después.`);
            return [];
        }

        const data = await response.json();
        const results = data.elements.map((el: any) => {
            const tags = el.tags || {};
            const street = tags["addr:street"];
            const houseNumber = tags["addr:housenumber"];
            const rawAddress = (street && houseNumber) ? `${street} ${houseNumber}` : street;

            return {
                rawName: tags.name,
                lat: el.lat || (el.center && el.center.lat),
                lng: el.lon || (el.center && el.center.lon),
                address: rawAddress || null,
                zipCode: tags["addr:postcode"] || null,
                phone: tags["phone"] || tags["contact:phone"] || null,
                website: tags["website"] || tags["contact:website"] || null,
            };
        });
        console.log(`📍 -> Encontradas ${results.length} agencias corporativas en la zona de ${city}.`);
        return results;
    } catch (e) {
        console.error(`❌ Falló la consulta a OpenStreetMap para ${city}:`, e);
        return [];
    }
}

function matchCompany(rawName: string) {
    const lName = rawName.toLowerCase();
    for (const comp of CAR_RENTAL_GIGANTS) {
        if (lName.includes(comp.name.toLowerCase())) return comp;
        // Exception for Record RegEx
        if (comp.name === "Record Go" && (lName.includes("record go") || lName.includes("recordrent"))) return comp;
    }
    return CAR_RENTAL_GIGANTS[0]; // fallback to Hertz si el regex falló la coincidencia manual
}

async function ensureCountry(countryCode: string) {
    const tCheck = await query<any>("SELECT code FROM Countries WHERE code = @code", { code: countryCode });
    if (tCheck.length === 0) {
        console.log(`[+] País nuevo detectado: ${countryCode}. Registrando en BD...`);
        await execute(
            `INSERT INTO Countries (code, name, currency, status) VALUES (@c, @n, 'USD', 'active')`,
            { c: countryCode, n: countryCode }
        );
    }
}

async function runGlobalCarRentals() {
    console.log("🚀 MULTINACIONAL CAR RENTAL SEEDER INICIADO...");
    const providerIds = await ensureProviders();
    let totalInserted = 0;

    for (const location of TARGET_CITIES) {
        const agencies = await fetchRentalsFromOSM(location.lat, location.lng, location.city, location.radius);

        for (const branch of agencies) {
            const corporativeBrand = matchCompany(branch.rawName);
            const pId = providerIds[corporativeBrand.name];

            const brandStandardName = `${corporativeBrand.name} ${location.city} Branch`;
            const webTarget = branch.website || `https://www.${corporativeBrand.domain}`;

            const existCheck = await query<any>(
                "SELECT id FROM Properties WHERE name = @name AND provider_id = @pid AND city = @city",
                { name: brandStandardName, pid: pId, city: location.city }
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
                        zip: branch.zipCode, phone: branch.phone, web: webTarget,
                        id: propertyId
                    }
                );
            } else {
                const img = JSON.stringify([`https://source.unsplash.com/featured/?rental,car,${corporativeBrand.name.toLowerCase()}`]);
                const insertRes = await execute(
                    `INSERT INTO Properties 
                        (provider_id, name, type, description, address, city, country, zip_code, phone, website, latitude, longitude, max_guests, images, status) 
                     OUTPUT INSERTED.id
                     VALUES (@pid, @name, 'vehicle', @desc, @addr, @city, @country, @zip, @phone, @web, @lat, @lng, 5, @imgs, 'active')`,
                    {
                        pid: pId,
                        name: brandStandardName,
                        desc: `Sucursal corporativa oficial de ${corporativeBrand.name} Car Rentals. Alquiler de vehículos y furgonetas verificad.`,
                        addr: branch.address,
                        city: location.city,
                        country: location.country,
                        zip: branch.zipCode,
                        phone: branch.phone,
                        web: webTarget,
                        lat: branch.lat,
                        lng: branch.lng,
                        imgs: img
                    }
                );
                propertyId = insertRes.recordset[0].id;
                totalInserted++;

                const realisticPrice = Math.floor(Math.random() * 80) + 30; // 30 - 110 Euros/Dollars a day
                await execute(
                    `INSERT INTO PropertyRates (property_id, name, price_per_night, currency)
                     VALUES (@id, 'standard', @price, 'EUR')`,
                    { id: propertyId, price: realisticPrice }
                );
            }
        }
        // Retrasamos agresivamente la siguiente ciudad para que el sistema global de mapas no se sature.
        await delay(3500);
    }

    console.log(`\n🎉 SEEDER FINALIZADO. Se reinyectaron exitosamente ${totalInserted} centrales mundiales de renta de vehículos.`);
    process.exit(0);
}

runGlobalCarRentals();
