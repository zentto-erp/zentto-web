"use client";

import { useEffect, useMemo } from "react";
import { Box, Button, Typography } from "@mui/material";
import { Circle, MapContainer, Marker, Popup, TileLayer, useMap, useMapEvents } from "react-leaflet";
import L from "leaflet";

type LatLng = { lat: number; lng: number };

type MapRow = {
    id: number;
    name: string;
    city?: string | null;
    type?: string | null;
    latitude?: number | string | null;
    longitude?: number | string | null;
    base_price?: number | null;
    currency?: string | null;
};

type GeoapifyMapProps = {
    apiKey: string;
    center: LatLng;
    rows: MapRow[];
    radiusKm: number;
    geoEnabled: boolean;
    activeMarker: MapRow | null;
    onActiveMarker: (row: MapRow | null) => void;
    onCenterChange: (next: LatLng) => void;
    onOpenProperty: (id: number) => void;
};

function normalizeCoord(value: number) {
    return Number(value.toFixed(4));
}

function markerIconUrl(apiKey: string, type?: string | null) {
    const iconByType: Record<string, string> = {
        room: "hotel",
        vehicle: "car",
        boat: "ship",
        flight: "plane",
        train: "train",
    };
    const colorByType: Record<string, string> = {
        room: "%236c63ff",
        vehicle: "%23ff6584",
        boat: "%2300c9a7",
        flight: "%234fc3f7",
        train: "%23ffb547",
    };

    const icon = iconByType[type || ""] || "map-marker";
    const color = colorByType[type || ""] || "%236c63ff";
    return `https://api.geoapify.com/v1/icon/?type=awesome&icon=${icon}&color=${color}&apiKey=${apiKey}`;
}

function buildMarkerIcon(apiKey: string, type?: string | null) {
    return L.icon({
        iconUrl: markerIconUrl(apiKey, type),
        iconSize: [32, 46],
        iconAnchor: [16, 46],
        popupAnchor: [0, -40],
    });
}

function RecenterMap({ center }: { center: LatLng }) {
    const map = useMap();
    useEffect(() => {
        map.panTo([center.lat, center.lng], { animate: true });
    }, [center.lat, center.lng, map]);
    return null;
}

function MapEventBridge({ onCenterChange }: { onCenterChange: (next: LatLng) => void }) {
    useMapEvents({
        moveend: (event) => {
            const mapCenter = event.target.getCenter();
            onCenterChange({
                lat: normalizeCoord(mapCenter.lat),
                lng: normalizeCoord(mapCenter.lng),
            });
        },
    });
    return null;
}

export default function GeoapifyMap({
    apiKey,
    center,
    rows,
    radiusKm,
    geoEnabled,
    activeMarker,
    onActiveMarker,
    onCenterChange,
    onOpenProperty,
}: GeoapifyMapProps) {
    const tileUrl = `https://maps.geoapify.com/v1/tile/osm-carto/{z}/{x}/{y}.png?apiKey=${apiKey}`;
    const attribution =
        '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors | ' +
        '&copy; <a href="https://www.geoapify.com/">Geoapify</a>';

    const icons = useMemo(
        () => ({
            room: buildMarkerIcon(apiKey, "room"),
            vehicle: buildMarkerIcon(apiKey, "vehicle"),
            boat: buildMarkerIcon(apiKey, "boat"),
            flight: buildMarkerIcon(apiKey, "flight"),
            train: buildMarkerIcon(apiKey, "train"),
            default: buildMarkerIcon(apiKey, null),
        }),
        [apiKey]
    );

    return (
        <MapContainer
            center={[center.lat, center.lng]}
            zoom={11}
            style={{ width: "100%", height: "100%" }}
            scrollWheelZoom
        >
            <TileLayer attribution={attribution} url={tileUrl} />
            <MapEventBridge onCenterChange={onCenterChange} />
            <RecenterMap center={center} />

            {geoEnabled && (
                <Circle
                    center={[center.lat, center.lng]}
                    radius={radiusKm * 1000}
                    pathOptions={{ color: "#6c63ff", fillColor: "#6c63ff", fillOpacity: 0.06 }}
                />
            )}

            {rows.map((item) => {
                const lat = Number(item.latitude);
                const lng = Number(item.longitude);
                if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;

                const icon =
                    item.type === "room"
                        ? icons.room
                        : item.type === "vehicle"
                          ? icons.vehicle
                          : item.type === "boat"
                            ? icons.boat
                            : item.type === "flight"
                              ? icons.flight
                              : item.type === "train"
                                ? icons.train
                                : icons.default;

                return (
                    <Marker
                        key={item.id}
                        position={[lat, lng]}
                        icon={icon}
                        eventHandlers={{ click: () => onActiveMarker(item) }}
                    >
                        {activeMarker?.id === item.id && (
                            <Popup>
                                <Box sx={{ minWidth: 190 }}>
                                    <Typography variant="subtitle2" fontWeight={700}>
                                        {item.name}
                                    </Typography>
                                    <Typography variant="body2" color="text.secondary">
                                        {item.city || "Sin ciudad"}
                                    </Typography>
                                    {item.base_price ? (
                                        <Typography variant="body2" sx={{ mt: 0.5 }}>
                                            {item.currency || "USD"} {item.base_price}
                                        </Typography>
                                    ) : null}
                                    <Button
                                        size="small"
                                        variant="contained"
                                        sx={{ mt: 1 }}
                                        onClick={() => onOpenProperty(item.id)}
                                    >
                                        Ver detalle
                                    </Button>
                                </Box>
                            </Popup>
                        )}
                    </Marker>
                );
            })}
        </MapContainer>
    );
}
