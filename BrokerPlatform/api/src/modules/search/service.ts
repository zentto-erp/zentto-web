import { query } from "../../db/query.js";

type SearchParams = {
    q?: string;
    type?: string;
    city?: string;
    country?: string;
    check_in?: string;
    check_out?: string;
    guests?: string;
    min_price?: string;
    max_price?: string;
    min_lat?: string;
    max_lat?: string;
    min_lng?: string;
    max_lng?: string;
    lat?: string;
    lng?: string;
    radius_km?: string;
    sort?: string;
    page?: string;
    limit?: string;
};

function toFiniteNumber(value: unknown) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
}

function normalizeRadiusKm(value: unknown) {
    const parsed = toFiniteNumber(value);
    if (parsed === null) return null;
    return Math.min(Math.max(parsed, 1), 500);
}

export async function searchProperties(params: SearchParams) {
    const page = Math.max(Number(params.page || 1), 1);
    const limit = Math.min(Math.max(Number(params.limit || 20), 1), 100);
    const offset = (page - 1) * limit;
    const where: string[] = ["pr.status = 'active'", "pv.status = 'active'"];
    const p: Record<string, unknown> = { offset, limit };

    if (params.q) {
        where.push("(pr.name LIKE @q OR pr.description LIKE @q OR pr.city LIKE @q OR pv.name LIKE @q)");
        p.q = `%${params.q}%`;
    }
    if (params.type) {
        where.push("pr.type = @type");
        p.type = params.type;
    }
    if (params.city) {
        where.push("pr.city LIKE @city");
        p.city = `%${params.city}%`;
    }
    if (params.country) {
        where.push("pr.country = @country");
        p.country = params.country;
    }
    if (params.guests) {
        where.push("pr.max_guests >= @guests");
        p.guests = Number(params.guests);
    }

    const minLat = toFiniteNumber(params.min_lat);
    const maxLat = toFiniteNumber(params.max_lat);
    const minLng = toFiniteNumber(params.min_lng);
    const maxLng = toFiniteNumber(params.max_lng);

    if (minLat !== null) {
        where.push("pr.latitude >= @min_lat");
        p.min_lat = minLat;
    }
    if (maxLat !== null) {
        where.push("pr.latitude <= @max_lat");
        p.max_lat = maxLat;
    }
    if (minLng !== null) {
        where.push("pr.longitude >= @min_lng");
        p.min_lng = minLng;
    }
    if (maxLng !== null) {
        where.push("pr.longitude <= @max_lng");
        p.max_lng = maxLng;
    }

    let priceFilter = "";
    if (params.min_price) {
        priceFilter += " AND rt.price_per_night >= @min_price";
        p.min_price = Number(params.min_price);
    }
    if (params.max_price) {
        priceFilter += " AND rt.price_per_night <= @max_price";
        p.max_price = Number(params.max_price);
    }

    let availabilityFilter = "";
    if (params.check_in && params.check_out) {
        availabilityFilter = `AND NOT EXISTS (
            SELECT 1 FROM Availability av
            WHERE av.property_id = pr.id
              AND av.date BETWEEN @check_in AND @check_out
              AND (av.blocked = 1 OR av.available_units - av.booked_units <= 0)
        )`;
        p.check_in = params.check_in;
        p.check_out = params.check_out;
    }

    const lat = toFiniteNumber(params.lat);
    const lng = toFiniteNumber(params.lng);
    const radiusKm = normalizeRadiusKm(params.radius_km);
    const hasGeoCenter = lat !== null && lng !== null;
    const hasGeoRadius = hasGeoCenter && radiusKm !== null;

    if (hasGeoCenter) {
        p.lat = lat;
        p.lng = lng;
    }
    if (hasGeoRadius) {
        p.radius_km = radiusKm;
    }

    const distanceExpr = hasGeoCenter
        ? `(6371.0 * ACOS(
              COS(RADIANS(@lat)) * COS(RADIANS(pr.latitude)) * COS(RADIANS(pr.longitude) - RADIANS(@lng)) +
              SIN(RADIANS(@lat)) * SIN(RADIANS(pr.latitude))
          ))`
        : "CAST(NULL AS DECIMAL(10,3))";

    if (hasGeoCenter) {
        where.push("pr.latitude IS NOT NULL");
        where.push("pr.longitude IS NOT NULL");
    }

    const sortMap: Record<string, string> = {
        price_asc: "base_price ASC",
        price_desc: "base_price DESC",
        rating: "provider_rating DESC",
        newest: "created_at DESC",
        distance_asc: "distance_km ASC",
        distance_desc: "distance_km DESC",
    };
    const requestedSort = params.sort || "";
    const orderBy =
        (!hasGeoCenter && (requestedSort === "distance_asc" || requestedSort === "distance_desc"))
            ? "provider_rating DESC, id DESC"
            : sortMap[requestedSort] || "provider_rating DESC, id DESC";

    const baseWhere = where.join(" AND ");
    const geoOuterFilter = hasGeoRadius ? "distance_km <= @radius_km" : "1=1";

    const rows = await query<any>(
        `
        WITH base AS (
            SELECT
                pr.*,
                pv.name AS provider_name,
                pv.type AS provider_type,
                pv.rating AS provider_rating,
                rt.price_per_night AS base_price,
                rt.currency,
                ${distanceExpr} AS distance_km,
                (
                    SELECT AVG(CAST(rv.rating AS DECIMAL(3,2)))
                    FROM Reviews rv
                    WHERE rv.property_id = pr.id AND rv.status = 'published'
                ) AS avg_rating,
                (
                    SELECT COUNT(*)
                    FROM Reviews rv
                    WHERE rv.property_id = pr.id AND rv.status = 'published'
                ) AS review_count
            FROM Properties pr
            JOIN Providers pv ON pv.id = pr.provider_id
            LEFT JOIN PropertyRates rt ON rt.property_id = pr.id AND rt.name = 'standard'
            WHERE ${baseWhere} ${priceFilter} ${availabilityFilter}
        )
        SELECT *
        FROM base
        WHERE ${geoOuterFilter}
        ORDER BY ${orderBy}
        OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
        `,
        p
    );

    const totalResult = await query<{ total: number }>(
        `
        WITH base AS (
            SELECT
                pr.id,
                ${distanceExpr} AS distance_km
            FROM Properties pr
            JOIN Providers pv ON pv.id = pr.provider_id
            LEFT JOIN PropertyRates rt ON rt.property_id = pr.id AND rt.name = 'standard'
            WHERE ${baseWhere} ${priceFilter} ${availabilityFilter}
        )
        SELECT COUNT(1) AS total
        FROM base
        WHERE ${geoOuterFilter}
        `,
        p
    );

    const facets = await query<any>(
        `
        SELECT pr.type, COUNT(*) AS count
        FROM Properties pr
        JOIN Providers pv ON pv.id = pr.provider_id
        WHERE pr.status = 'active' AND pv.status = 'active'
        GROUP BY pr.type
        `
    );
    const cities = await query<any>(
        `
        SELECT pr.city, COUNT(*) AS count
        FROM Properties pr
        JOIN Providers pv ON pv.id = pr.provider_id
        WHERE pr.status = 'active' AND pv.status = 'active' AND pr.city IS NOT NULL
        GROUP BY pr.city
        `
    );

    return {
        page,
        limit,
        total: Number(totalResult[0]?.total ?? 0),
        rows,
        facets: { types: facets, cities },
        geo: {
            enabled: hasGeoCenter,
            center: hasGeoCenter ? { lat, lng } : null,
            radiusKm: hasGeoRadius ? radiusKm : null,
        },
    };
}
