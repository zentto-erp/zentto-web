import React from "react";
import { NavigationContainer } from "@react-navigation/native";
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { Ionicons } from "@expo/vector-icons";

// Screens
import HomeScreen from "../screens/HomeScreen";
import SearchScreen from "../screens/SearchScreen";
import PropertyDetailScreen from "../screens/PropertyDetailScreen";
import ProfileScreen from "../screens/ProfileScreen";

export type RootStackParamList = {
    MainTabs: undefined;
    PropertyDetail: { id: number };
};

export type MainTabParamList = {
    Home: undefined;
    Search: { type?: string; q?: string };
    Profile: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();
const Tab = createBottomTabNavigator<MainTabParamList>();

function MainTabs() {
    return (
        <Tab.Navigator
            screenOptions={({ route }) => ({
                tabBarIcon: ({ color, size }) => {
                    let iconName: keyof typeof Ionicons.glyphMap = "home";
                    if (route.name === "Home") iconName = "home";
                    else if (route.name === "Search") iconName = "search";
                    else if (route.name === "Profile") iconName = "person";
                    return <Ionicons name={iconName} size={size} color={color} />;
                },
                tabBarActiveTintColor: "#6C63FF",
                tabBarInactiveTintColor: "#8e8e93",
                headerShown: false,
                tabBarStyle: {
                    backgroundColor: "#121829",
                    borderTopColor: "rgba(255,255,255,0.06)",
                },
                tabBarLabelStyle: { fontWeight: "600" }
            })}
        >
            <Tab.Screen name="Home" component={HomeScreen} />
            <Tab.Screen name="Search" component={SearchScreen} />
            <Tab.Screen name="Profile" component={ProfileScreen} />
        </Tab.Navigator>
    );
}

export default function RootNavigation() {
    return (
        <NavigationContainer>
            <Stack.Navigator
                screenOptions={{
                    headerStyle: { backgroundColor: "#121829" },
                    headerTintColor: "#fff",
                    headerTitleStyle: { fontWeight: "bold" },
                    contentStyle: { backgroundColor: "#0A0E1A" }
                }}
            >
                <Stack.Screen
                    name="MainTabs"
                    component={MainTabs}
                    options={{ headerShown: false }}
                />
                <Stack.Screen
                    name="PropertyDetail"
                    component={PropertyDetailScreen}
                    options={{ title: "Details" }}
                />
            </Stack.Navigator>
        </NavigationContainer>
    );
}
