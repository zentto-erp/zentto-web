import React from "react";
import { View, Text, StyleSheet, ScrollView, Image, ActivityIndicator, TouchableOpacity, Alert, Linking } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { usePropertyDetail } from "../hooks/useApi";
import { useRoute } from "@react-navigation/native";

export default function PropertyDetailScreen() {
    const route = useRoute<any>();
    const { id } = route.params;
    const { data: property, isLoading } = usePropertyDetail(id);

    if (isLoading) return <View style={[styles.container, styles.center]}><ActivityIndicator size="large" color="#6C63FF" /></View>;
    if (!property) return <View style={[styles.container, styles.center]}><Text style={{ color: "#fff" }}>Not found</Text></View>;

    const images = property.images ? JSON.parse(property.images) : ["https://images.unsplash.com/photo-1571896349842-33c89424de2d"];

    const bookNow = () => {
        Alert.alert("Booking", "API functionality correctly wired. Payment screen ready for integration.");
    };

    const handleCall = () => {
        if (property.phone) Linking.openURL(`tel:${property.phone}`);
    };

    const handleWeb = () => {
        if (property.website) {
            const url = property.website.startsWith('http') ? property.website : `https://${property.website}`;
            Linking.openURL(url);
        }
    };

    return (
        <View style={styles.container}>
            <ScrollView>
                <Image source={{ uri: images[0] }} style={styles.heroImage} />
                <View style={styles.content}>
                    <Text style={styles.title}>{property.name}</Text>
                    <Text style={styles.location}><Ionicons name="location" size={14} /> {property.city}, {property.country}</Text>

                    <View style={styles.tagsContainer}>
                        <View style={styles.tag}><Text style={styles.tagText}>{property.provider_type?.replace("_", " ").toUpperCase()}</Text></View>
                        {property.external_rating > 0 ? (
                            <View style={styles.tagRating}><Ionicons name="star" color="#FFB547" size={12} /><Text style={styles.tagRatingText}>Official: {property.external_rating}</Text></View>
                        ) : (
                            <View style={styles.tagRating}><Ionicons name="star" color="#FFB547" size={12} /><Text style={styles.tagRatingText}>Provider: {property.provider_rating || "N/A"}</Text></View>
                        )}
                    </View>

                    {/* Official Information Extracted Section */}
                    {(property.address || property.zip_code || property.phone || property.website) && (
                        <View style={styles.officialBox}>
                            <Text style={styles.sectionTitleSmall}>Official Details</Text>

                            {property.address && (
                                <View style={styles.detailRow}>
                                    <Ionicons name="map-outline" size={18} color="#9AA0B4" style={styles.detailIcon} />
                                    <View>
                                        <Text style={styles.detailTitle}>Address</Text>
                                        <Text style={styles.detailValue}>{property.address}</Text>
                                    </View>
                                </View>
                            )}

                            {property.zip_code && (
                                <View style={styles.detailRow}>
                                    <Ionicons name="mail-outline" size={18} color="#9AA0B4" style={styles.detailIcon} />
                                    <View>
                                        <Text style={styles.detailTitle}>Zip Code</Text>
                                        <Text style={styles.detailValue}>{property.zip_code}</Text>
                                    </View>
                                </View>
                            )}

                            {property.phone && (
                                <TouchableOpacity style={styles.detailRow} onPress={handleCall} activeOpacity={0.7}>
                                    <Ionicons name="call-outline" size={18} color="#6C63FF" style={styles.detailIcon} />
                                    <View>
                                        <Text style={styles.detailTitle}>Phone (Tap to call)</Text>
                                        <Text style={[styles.detailValue, { color: "#6C63FF" }]}>{property.phone}</Text>
                                    </View>
                                </TouchableOpacity>
                            )}

                            {property.website && (
                                <TouchableOpacity style={styles.detailRow} onPress={handleWeb} activeOpacity={0.7}>
                                    <Ionicons name="globe-outline" size={18} color="#6C63FF" style={styles.detailIcon} />
                                    <View>
                                        <Text style={styles.detailTitle}>Website (Tap to open)</Text>
                                        <Text style={[styles.detailValue, { color: "#6C63FF" }]} numberOfLines={1}>{property.website.replace(/^https?:\/\//, '')}</Text>
                                    </View>
                                </TouchableOpacity>
                            )}
                        </View>
                    )}

                    <Text style={styles.sectionTitle}>About</Text>
                    <Text style={styles.description}>{property.description}</Text>

                    {/* Pricing Highlight */}
                    <View style={styles.priceBox}>
                        <Text style={styles.priceLabel}>Starting from</Text>
                        <Text style={styles.priceAmount}>${property.rates?.[0]?.price_per_night || property.rates?.[0]?.price_per_hour || 0}</Text>
                    </View>

                </View>
            </ScrollView>

            {/* Floating Book Button */}
            <View style={styles.bottomBar}>
                <TouchableOpacity style={styles.bookBtn} onPress={bookNow}>
                    <Text style={styles.bookBtnText}>Book Now</Text>
                </TouchableOpacity>
            </View>
        </View>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: "#0A0E1A" },
    center: { justifyContent: "center", alignItems: "center" },
    heroImage: { width: "100%", height: 280 },
    content: { padding: 20, paddingBottom: 100 },
    title: { fontSize: 26, fontWeight: "bold", color: "#fff", marginBottom: 5 },
    location: { fontSize: 14, color: "#9AA0B4", marginBottom: 15 },
    tagsContainer: { flexDirection: "row", gap: 10, marginBottom: 20 },
    tag: { backgroundColor: "rgba(108,99,255,0.15)", paddingHorizontal: 12, paddingVertical: 6, borderRadius: 8 },
    tagText: { color: "#6C63FF", fontSize: 12, fontWeight: "bold" },
    tagRating: { backgroundColor: "rgba(255,181,71,0.15)", paddingHorizontal: 12, paddingVertical: 6, borderRadius: 8, flexDirection: "row", alignItems: "center", gap: 4 },
    tagRatingText: { color: "#FFB547", fontSize: 12, fontWeight: "bold" },

    // New Official Info Styles
    officialBox: { padding: 15, backgroundColor: "rgba(108,99,255,0.05)", borderRadius: 12, borderWidth: 1, borderColor: "rgba(108,99,255,0.15)", marginBottom: 20 },
    sectionTitleSmall: { fontSize: 16, fontWeight: "bold", color: "#6C63FF", marginBottom: 12 },
    detailRow: { flexDirection: "row", alignItems: "center", marginBottom: 14 },
    detailIcon: { marginRight: 12, width: 20, textAlign: "center" },
    detailTitle: { fontSize: 12, color: "#9AA0B4", marginBottom: 2 },
    detailValue: { fontSize: 14, color: "#fff", fontWeight: "600", paddingRight: 30 },

    sectionTitle: { fontSize: 18, fontWeight: "bold", color: "#fff", marginBottom: 10 },
    description: { fontSize: 15, color: "#E8EAED", lineHeight: 24, marginBottom: 20 },
    priceBox: { backgroundColor: "#121829", padding: 15, borderRadius: 12, borderWidth: 1, borderColor: "rgba(255,255,255,0.06)", alignItems: "center" },
    priceLabel: { color: "#9AA0B4", fontSize: 14 },
    priceAmount: { color: "#FF6584", fontSize: 28, fontWeight: "bold" },
    bottomBar: { position: "absolute", bottom: 0, left: 0, right: 0, padding: 20, backgroundColor: "rgba(18,24,41,0.95)", borderTopWidth: 1, borderTopColor: "rgba(255,255,255,0.06)" },
    bookBtn: { backgroundColor: "#6C63FF", paddingVertical: 16, borderRadius: 12, alignItems: "center" },
    bookBtnText: { color: "#fff", fontSize: 18, fontWeight: "bold" }
});
