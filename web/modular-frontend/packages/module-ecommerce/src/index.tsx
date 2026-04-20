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
export { useStorefrontCountries, useStorefrontCurrencies, useCountryConfig, useResolveCountry } from "./hooks/useStorefront";
export { useWishlist, useToggleWishlist } from "./hooks/useWishlist";
export { useRecentlyViewed, useTrackRecentlyViewed } from "./hooks/useRecentlyViewed";
export { useOrderTracking } from "./hooks/useOrderTracking";
export type { TrackingEvent } from "./hooks/useOrderTracking";
export {
  useAdminMetrics, useAdminOrderDetail, useAdminReturns,
  useAdminReturnDetail, useAdminSetReturnStatus, useMyOrderDetail,
} from "./hooks/useAdminEcommerce";
export type { AdminMetrics, AdminOrderDetail, ReturnSummary } from "./hooks/useAdminEcommerce";
export { useMyReturns, useMyReturnDetail, useCreateReturn } from "./hooks/useReturns";
export type { MyReturn } from "./hooks/useReturns";
export { useStoreSearch, useProductRecommendations, useCompareProducts } from "./hooks/useStoreSearch";
export type { SearchHit, SearchResponse, RecommendedProduct, CompareProduct } from "./hooks/useStoreSearch";
export { useCompareStore } from "./store/useCompareStore";
export { usePerfAudit, useCacheStats, useInvalidateCache } from "./hooks/usePerfAndCache";
export type { PerfMeasurement, PerfReport, CacheStats } from "./hooks/usePerfAndCache";

// Admin backoffice — productos, imágenes, highlights, specs, categorías, marcas, reviews
export {
  useAdminProducts,
  useAdminProductDetail,
  useUpsertAdminProduct,
  useDeleteAdminProduct,
  usePublishToggleAdminProduct,
} from "./hooks/useAdminProducts";
export type {
  AdminProductRow,
  AdminProductDetail,
  AdminProductUpsertPayload,
  AdminProductListParams,
} from "./hooks/useAdminProducts";
export { useUploadProductImage, useSetProductImages } from "./hooks/useAdminImages";
export type { ProductImageInput, ProductImageUploadResult } from "./hooks/useAdminImages";
export { useSetProductHighlights } from "./hooks/useAdminHighlights";
export type { HighlightInput } from "./hooks/useAdminHighlights";
export { useSetProductSpecs } from "./hooks/useAdminSpecs";
export type { SpecInput } from "./hooks/useAdminSpecs";
export {
  useAdminCategories,
  useUpsertCategory,
  useDeleteCategory,
} from "./hooks/useAdminCategories";
export type { CategoryRow, CategoryUpsertPayload } from "./hooks/useAdminCategories";
export {
  useAdminBrands,
  useUpsertBrand,
  useDeleteBrand,
} from "./hooks/useAdminBrands";
export type { BrandRow, BrandUpsertPayload } from "./hooks/useAdminBrands";
export { useAdminReviewsList, useModerateReview } from "./hooks/useAdminReviews";
export type { AdminReviewRow, AdminReviewListParams } from "./hooks/useAdminReviews";

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
export { default as OrderTimeline } from "./components/OrderTimeline";
export { default as RecentlyViewedRail } from "./components/RecentlyViewedRail";
export { default as CurrencySelector } from "./components/CurrencySelector";
export { default as AdminEcommerceDashboard } from "./components/AdminEcommerceDashboard";
export { default as AdminReturnsList } from "./components/AdminReturnsList";
export { default as MyReturnsList } from "./components/MyReturnsList";
export { default as ReturnRequestForm } from "./components/ReturnRequestForm";
export { default as ProductRecommendations } from "./components/ProductRecommendations";
export { default as ProductCompare } from "./components/ProductCompare";
export { default as CompareBar } from "./components/CompareBar";
export { default as PerfAndCachePanel } from "./components/PerfAndCachePanel";
export { default as AdminProductForm } from "./components/AdminProductForm";

// Grid persistence helpers (para que las apps no tengan que importar subpaths)
export {
  buildEcommerceGridId,
  useEcommerceGridId,
  useEcommerceGridRegistration,
} from "./components/zenttoGridPersistence";

// Pages
export { default as StoreLayout } from "./pages/StoreLayout";
export { default as StoreFront } from "./pages/StoreFront";
