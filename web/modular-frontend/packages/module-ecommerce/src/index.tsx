"use client";

export const MODULE_ID = "ecommerce";
export const MODULE_TITLE = "Comercio Electrónico";

// Store (Zustand)
export { useCartStore } from "./store/useCartStore";
export type { CartItem as CartItemType, CustomerInfo } from "./store/useCartStore";
export { useFavoritesStore } from "./store/useFavoritesStore";
export type { FavoriteItem } from "./store/useFavoritesStore";
export { useRecentlyViewedStore } from "./store/useRecentlyViewedStore";
export type { RecentlyViewedItem } from "./store/useRecentlyViewedStore";
export { useSearchHistoryStore } from "./store/useSearchHistoryStore";

// Hooks
export { useProductList, useProductDetail, useCategoryList, useBrandList, useProductReviews, useCreateReview } from "./hooks/useStoreProducts";
export type { ProductFilters } from "./hooks/useStoreProducts";
export { useCustomerRegister, useCustomerLogin, useCustomerProfile, useCustomerLogout } from "./hooks/useStoreAuth";
export { useCheckout, useOrderByToken, useMyOrders } from "./hooks/useStoreOrders";

// Components
export { default as ProductCard } from "./components/ProductCard";
export { default as ProductGrid } from "./components/ProductGrid";
export { default as ProductDetail } from "./components/ProductDetail";
export { default as CategorySidebar } from "./components/CategorySidebar";
export { default as SearchBar } from "./components/SearchBar";
export { default as CartDrawer } from "./components/CartDrawer";
export { default as CartItem } from "./components/CartItem";
export { default as CheckoutForm } from "./components/CheckoutForm";
export { default as OrderSummary } from "./components/OrderSummary";
export { default as OrderHistory } from "./components/OrderHistory";
export { default as ReviewStars } from "./components/ReviewStars";
export { default as ProductReviews } from "./components/ProductReviews";
export { default as PanelGrid } from "./components/PanelGrid";

// Pages
export { default as StoreLayout } from "./pages/StoreLayout";
export { default as StoreFront } from "./pages/StoreFront";
