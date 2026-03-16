import React from "react";
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Image, TextInput, ActivityIndicator } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { useSearch } from "../hooks/useApi";
import type { NativeStackNavigationProp } from "@react-navigation/native-stack";
import type { BottomTabNavigationProp } from "@react-navigation/bottom-tabs";
import { useNavigation } from "@react-navigation/native";
import { RootStackParamList, MainTabParamList } from "../navigation";

type GridNavProp = NativeStackNavigationProp<RootStackParamList> & BottomTabNavigationProp<MainTabParamList>;

const categories = [
    { type: "room", label: "Hotels", icon: "bed", color: "#6C63FF" },
    { type: "vehicle", label: "Cars", icon: "car", color: "#FF6584" },
    { type: "boat", label: "Boats", icon: "boat", color: "#00C9A7" },
    { type: "flight", label: "Flights", icon: "airplane", color: "#4FC3F7" },
];

export default function HomeScreen() {
    const navigation = useNavigation<GridNavProp>();
    const [searchQuery, setSearchQuery] = React.useState("");

    const { data, isLoading } = useSearch({ limit: "5", sort: "rating" });

    const onSearch = () => {
        navigation.navigate("Search", { q: searchQuery });
    };

    return (
        <SafeAreaView style={styles.container}>
            <ScrollView contentContainerStyle={styles.scroll}>
                {/* Header */}
                <View style={styles.header}>
                    <Ionicons name="compass" size={32} color="#6C63FF" />
                    <Text style={styles.headerTitle}>BrokerPlatform</Text>
                </View>

                {/* Hero */}
                <View style={styles.hero}>
                    <Text style={styles.heroTitle}>Discover Your Next Adventure</Text>
                    <Text style={styles.heroSubtitle}>Best prices, real-time availability.</Text>

                    {/* Custom Search Box */}
                    <View style={styles.searchBox}>
                        <Ionicons name="location" size={20} color="#6C63FF" />
                        <TextInput
                            style={styles.searchInput}
                            placeholder="Where are you going?"
                            placeholderTextColor="#9AA0B4"
                            value={searchQuery}
                            onChangeText={setSearchQuery}
                            onSubmitEditing={onSearch}
                            returnKeyType="search"
                        />
                    </View>
                </View>

                {/* Categories */}
                <View style={styles.categories}>
                    <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                        {categories.map((cat) => (
                            <TouchableOpacity
                                key={cat.type}
                                style={[styles.catCard, { borderColor: cat.color }]}
                                onPress={() => navigation.navigate("Search", { type: cat.type })}
                            >
                                <Ionicons name={cat.icon as any} size={28} color={cat.color} />
                                <Text style={styles.catLabel}>{cat.label}</Text>
                            </TouchableOpacity>
                        ))}
                    </ScrollView>
                </View>

                {/* Featured */}
                <View style={styles.featured}>
                    <Text style={styles.sectionTitle}>Featured Listings</Text>
                    {isLoading ? (
                        <ActivityIndicator size="large" color="#6C63FF" style={{ marginTop: 20 }} />
                    ) : (
                        data?.rows?.map((item: any) => {
                            const image = item.images ? JSON.parse(item.images)[0] : "https://images.unsplash.com/photo-1571896349842-33c89424de2d";
                            return (
                                <TouchableOpacity
                                    key={item.id}
                                    style={styles.propertyCard}
                                    onPress={() => navigation.navigate("PropertyDetail", { id: item.id })}
                                >
                                    <Image source={{ uri: image }} style={styles.propertyImage} />
                                    <View style={styles.propertyContent}>
                                        <View style={styles.propertyRow}>
                                            <Text style={styles.propertyType}>{item.provider_type?.replace("_", " ").toUpperCase()}</Text>
                                            {item.provider_rating > 0 && (
                                                <View style={styles.ratingBox}>
                                                    <Ionicons name="star" size={14} color="#FFB547" />
                                                    <Text style={styles.ratingText}>{item.provider_rating}</Text>
                                                </View>
                                            )}
                                        </View>
                                        <Text style={styles.propertyName} numberOfLines={1}>{item.name}</Text>
                                        <Text style={styles.propertyCity} numberOfLines={1}>
                                            <Ionicons name="location" size={12} /> {item.city}
                                        </Text>
                                        <View style={styles.priceRow}>
                                            <Text style={styles.priceText}>${item.base_price || 0}</Text>
                                            <Text style={styles.priceUnit}>
                                                {item.type === "room" ? "/night" : item.type === "vehicle" ? "/day" : item.type === "flight" ? "/person" : "/unit"}
                                            </Text>
                                        </View>
                                    </View>
                                </TouchableOpacity>
                            );
                        })
                    )}
                </View>
            </ScrollView>
        </SafeAreaView>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: "#0A0E1A" },
    scroll: { paddingBottom: 40 },
    header: { flexDirection: "row", alignItems: "center", padding: 20, gap: 10 },
    headerTitle: { fontSize: 24, fontWeight: "bold", color: "#E8EAED" },
    hero: { paddingHorizontal: 20, paddingTop: 10, paddingBottom: 30 },
    heroTitle: { fontSize: 32, fontWeight: "900", color: "#fff", marginBottom: 10 },
    heroSubtitle: { fontSize: 16, color: "#9AA0B4", marginBottom: 20 },
    searchBox: { flexDirection: "row", alignItems: "center", backgroundColor: "#121829", paddingHorizontal: 15, paddingVertical: 12, borderRadius: 12, borderWidth: 1, borderColor: "rgba(255,255,255,0.1)" },
    searchInput: { flex: 1, marginLeft: 10, color: "#fff", fontSize: 16 },
    categories: { paddingLeft: 20, marginBottom: 30 },
    catCard: { alignItems: "center", justifyContent: "center", backgroundColor: "#121829", borderWidth: 1, borderRadius: 16, padding: 15, marginRight: 15, width: 100 },
    catLabel: { color: "#E8EAED", fontWeight: "600", marginTop: 8 },
    featured: { paddingHorizontal: 20 },
    sectionTitle: { fontSize: 22, fontWeight: "bold", color: "#fff", marginBottom: 15 },
    propertyCard: { backgroundColor: "#121829", borderRadius: 16, overflow: "hidden", marginBottom: 20, borderWidth: 1, borderColor: "rgba(255,255,255,0.06)" },
    propertyImage: { width: "100%", height: 180 },
    propertyContent: { padding: 15 },
    propertyRow: { flexDirection: "row", justifyContent: "space-between", marginBottom: 8 },
    propertyType: { color: "#6C63FF", fontWeight: "bold", fontSize: 12 },
    ratingBox: { flexDirection: "row", alignItems: "center", gap: 4 },
    ratingText: { color: "#FFB547", fontWeight: "bold", fontSize: 12 },
    propertyName: { fontSize: 18, fontWeight: "bold", color: "#fff", marginBottom: 4 },
    propertyCity: { fontSize: 14, color: "#9AA0B4", marginBottom: 12 },
    priceRow: { flexDirection: "row", alignItems: "baseline" },
    priceText: { fontSize: 20, fontWeight: "bold", color: "#FF6584" },
    priceUnit: { fontSize: 12, color: "#9AA0B4", marginLeft: 4 }
});
