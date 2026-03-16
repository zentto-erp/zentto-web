import React, { useState, useEffect } from "react";
import { View, Text, StyleSheet, TouchableOpacity, TextInput, Alert, ActivityIndicator } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { useLogin } from "../hooks/useApi";

export default function ProfileScreen() {
    const [user, setUser] = useState<any>(null);
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [loadingInitial, setLoadingInitial] = useState(true);

    const login = useLogin();

    useEffect(() => {
        (async () => {
            const storedUser = await AsyncStorage.getItem("broker_user");
            if (storedUser) setUser(JSON.parse(storedUser));
            setLoadingInitial(false);
        })();
    }, []);

    const handleLogin = () => {
        login.mutate({ email, password }, {
            onSuccess: async () => {
                const storedUser = await AsyncStorage.getItem("broker_user");
                if (storedUser) setUser(JSON.parse(storedUser));
            },
            onError: (e) => {
                Alert.alert("Login Failed", e.message || "Invalid credentials");
            }
        });
    };

    const handleLogout = async () => {
        await AsyncStorage.removeItem("broker_token");
        await AsyncStorage.removeItem("broker_user");
        setUser(null);
    };

    if (loadingInitial) return <View style={[styles.container, styles.center]}><ActivityIndicator size="large" color="#6C63FF" /></View>;

    if (user) {
        return (
            <SafeAreaView style={styles.container}>
                <View style={styles.center}>
                    <View style={styles.avatar}>
                        <Ionicons name="person" size={50} color="#6C63FF" />
                    </View>
                    <Text style={styles.name}>{user.first_name} {user.last_name}</Text>
                    <Text style={styles.email}>{user.email}</Text>

                    <TouchableOpacity style={styles.logoutBtn} onPress={handleLogout}>
                        <Text style={styles.logoutText}>Logout</Text>
                    </TouchableOpacity>
                </View>
            </SafeAreaView>
        );
    }

    return (
        <SafeAreaView style={styles.container}>
            <View style={styles.authContainer}>
                <Text style={styles.authTitle}>Login</Text>
                <Text style={styles.authSub}>Access your bookings and account.</Text>

                <TextInput
                    style={styles.input}
                    placeholder="Email"
                    placeholderTextColor="#9AA0B4"
                    autoCapitalize="none"
                    keyboardType="email-address"
                    value={email}
                    onChangeText={setEmail}
                />
                <TextInput
                    style={styles.input}
                    placeholder="Password"
                    placeholderTextColor="#9AA0B4"
                    secureTextEntry
                    value={password}
                    onChangeText={setPassword}
                />

                <TouchableOpacity style={styles.loginBtn} onPress={handleLogin} disabled={login.isPending}>
                    {login.isPending ? <ActivityIndicator color="#fff" /> : <Text style={styles.loginBtnText}>Login</Text>}
                </TouchableOpacity>
            </View>
        </SafeAreaView>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: "#0A0E1A" },
    center: { alignItems: "center", justifyContent: "center", marginTop: 50 },
    avatar: { width: 100, height: 100, borderRadius: 50, backgroundColor: "rgba(108,99,255,0.1)", alignItems: "center", justifyContent: "center", borderWidth: 2, borderColor: "#6C63FF", marginBottom: 20 },
    name: { fontSize: 24, fontWeight: "bold", color: "#fff", marginBottom: 5 },
    email: { fontSize: 16, color: "#9AA0B4", marginBottom: 30 },
    logoutBtn: { paddingVertical: 12, paddingHorizontal: 30, borderRadius: 10, borderWidth: 1, borderColor: "#FF5252" },
    logoutText: { color: "#FF5252", fontSize: 16, fontWeight: "bold" },
    authContainer: { padding: 30, marginTop: 40 },
    authTitle: { fontSize: 32, fontWeight: "bold", color: "#fff", marginBottom: 10 },
    authSub: { fontSize: 16, color: "#9AA0B4", marginBottom: 30 },
    input: { backgroundColor: "#121829", borderRadius: 12, padding: 15, color: "#fff", fontSize: 16, marginBottom: 15, borderWidth: 1, borderColor: "rgba(255,255,255,0.1)" },
    loginBtn: { backgroundColor: "#6C63FF", padding: 16, borderRadius: 12, alignItems: "center", marginTop: 10 },
    loginBtnText: { color: "#fff", fontSize: 16, fontWeight: "bold" }
});
