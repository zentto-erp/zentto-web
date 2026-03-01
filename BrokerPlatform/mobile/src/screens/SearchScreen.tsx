import React, { useState, useEffect } from "react";
import { View, Text, StyleSheet, FlatList, TouchableOpacity, Image, TextInput, ActivityIndicator, Dimensions } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { useSearch } from "../hooks/useApi";
import { useRoute, useNavigation } from "@react-navigation/native";
import type { NativeStackNavigationProp } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation";
import MapView, { Marker, PROVIDER_GOOGLE } from "react-native-maps";

const { width, height } = Dimensions.get("window");

export default function SearchScreen() {
    const route = useRoute<any>();
    const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
    const [q, setQ] = useState(route.params?.q || "");
    const [type, setType] = useState(route.params?.type || "");
    const [bounds, setBounds] = useState<{ min_lat?: string; max_lat?: string; min_lng?: string; max_lng?: string }>({});

    useEffect(() => {
        if (route.params?.q !== undefined) setQ(route.params.q);
        if (route.params?.type !== undefined) setType(route.params.type);
    }, [route.params]);

    const { data, isLoading, refetch } = useSearch({ q, type, limit: "20", ...bounds });

    const onRegionChangeComplete = (region: any) => {
        // Calcular "Bounding Box" de la region actual en React Native Maps
        const min_lat = region.latitude - region.latitudeDelta / 2;
        const max_lat = region.latitude + region.latitudeDelta / 2;
        const min_lng = region.longitude - region.longitudeDelta / 2;
        const max_lng = region.longitude + region.longitudeDelta / 2;

        setBounds({
            min_lat: String(min_lat), max_lat: String(max_lat),
            min_lng: String(min_lng), max_lng: String(max_lng)
        });
    };

    const renderItem = ({ item }: { item: any }) => {
        const image = item.images ? JSON.parse(item.images)[0] : "https://images.unsplash.com/photo-1571896349842-33c89424de2d";
        return (
            <TouchableOpacity style={styles.card} onPress={() => navigation.navigate("PropertyDetail", { id: item.id })}>
                <Image source={{ uri: image }} style={styles.image} />
                <View style={styles.cardInfo}>
                    <Text style={styles.cardTitle} numberOfLines={1}>{item.name}</Text>
                    <Text style={styles.cardSub} numberOfLines={1}>{item.city} • {item.provider_type?.replace("_", " ")}</Text>
                    <Text style={styles.cardPrice}>
                        ${item.base_price || 0}
                        <Text style={styles.cardUnit}> / night</Text>
                    </Text>
                </View>
            </TouchableOpacity>
        );
    };

    return (
        <View style={styles.container}>
            <SafeAreaView edges={["top"]} style={{ backgroundColor: "#0A0E1A" }}>
                <View style={styles.header}>
                    <Ionicons name="search" size={20} color="#6C63FF" />
                    <TextInput
                        style={styles.searchInput}
                        placeholder="Search within map..."
                        placeholderTextColor="#9AA0B4"
                        value={q}
                        onChangeText={setQ}
                        onSubmitEditing={() => refetch()}
                        returnKeyType="search"
                    />
                </View>
            </SafeAreaView>

            <View style={styles.mapContainer}>
                {/* Map View con Geocodificación */}
                <MapView
                    style={styles.map}
                    provider={PROVIDER_GOOGLE}
                    initialRegion={{ latitude: 40.7128, longitude: -74.0060, latitudeDelta: 0.1, longitudeDelta: 0.1 }}
                    onRegionChangeComplete={onRegionChangeComplete}
                    customMapStyle={[{ elementType: 'geometry', stylers: [{ color: '#242f3e' }] }, { elementType: 'labels.text.stroke', stylers: [{ color: '#242f3e' }] }, { elementType: 'labels.text.fill', stylers: [{ color: '#746855' }] }]} // Dark UI
                >
                    {data?.rows?.map((item: any) => (
                        <Marker
                            key={item.id}
                            coordinate={{ latitude: Number(item.latitude), longitude: Number(item.longitude) }}
                            title={item.name}
                            description={`$${item.base_price}`}
                            onCalloutPress={() => navigation.navigate("PropertyDetail", { id: item.id })}
                        >
                            <View style={styles.markerPin}>
                                <Text style={styles.markerText}>${item.base_price || 0}</Text>
                            </View>
                        </Marker>
                    ))}
                </MapView>
            </View>

            {/* Lista Inferior Deslizable */}
            <View style={styles.listContainer}>
                <View style={styles.resultsHeader}>
                    <Text style={styles.resultsText}>{data ? `${data.total} properties in map view` : "Scanning area..."}</Text>
                </View>
                {isLoading && !data ? <ActivityIndicator size="small" color="#6C63FF" style={{ marginTop: 10 }} /> : (
                    <FlatList
                        data={data?.rows || []}
                        keyExtractor={(item) => item.id.toString()}
                        renderItem={renderItem}
                        contentContainerStyle={{ padding: 15 }}
                        horizontal
                        showsHorizontalScrollIndicator={false}
                        snapToInterval={width * 0.85 + 15}
                        decelerationRate="fast"
                    />
                )}
            </View>
        </View>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: "#0A0E1A" },
    header: { flexDirection: "row", alignItems: "center", backgroundColor: "#121829", padding: 12, margin: 15, borderRadius: 12, borderWidth: 1, borderColor: "rgba(255,255,255,0.1)" },
    searchInput: { flex: 1, marginHorizontal: 10, color: "#fff", fontSize: 16 },
    mapContainer: { flex: 1 },
    map: { width: "100%", height: "100%" },
    markerPin: { backgroundColor: "#6C63FF", paddingHorizontal: 12, paddingVertical: 6, borderRadius: 14, borderWidth: 2, borderColor: "#fff" },
    markerText: { color: "#fff", fontWeight: "bold", fontSize: 12 },
    listContainer: { position: "absolute", bottom: 0, left: 0, right: 0, paddingBottom: 20 },
    resultsHeader: { paddingHorizontal: 20, marginBottom: 5 },
    resultsText: { color: "#fff", fontWeight: "bold", textShadowColor: "rgba(0,0,0,0.8)", textShadowRadius: 4 },
    card: { flexDirection: "row", backgroundColor: "rgba(18, 24, 41, 0.95)", borderRadius: 12, overflow: "hidden", marginHorizontal: 7.5, width: width * 0.85, borderWidth: 1, borderColor: "rgba(255,255,255,0.15)", shadowColor: "#000", shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.3, shadowRadius: 5 },
    image: { width: 100, height: 100 },
    cardInfo: { flex: 1, padding: 12, justifyContent: "center" },
    cardTitle: { fontSize: 16, fontWeight: "bold", color: "#fff", marginBottom: 2 },
    cardSub: { fontSize: 12, color: "#9AA0B4", marginBottom: 6 },
    cardPrice: { fontSize: 16, fontWeight: "bold", color: "#FF6584" },
    cardUnit: { fontSize: 12, color: "#9AA0B4", fontWeight: "normal" }
});
