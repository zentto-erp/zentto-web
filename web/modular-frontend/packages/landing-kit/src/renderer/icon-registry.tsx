/**
 * Registry estático de iconos MUI usados en landings.
 *
 * El schema JSON transporta strings (`iconId: "EventSeatOutlined"`). Server-side
 * resolvemos a un componente real. Si el iconId no existe → `null` (no crashea).
 *
 * Cada vertical importa solo los iconos que usa en su schema. Para agregar
 * nuevos, extender este map o — si son únicos — usar `type: "custom"` con un
 * componente en el registry del host.
 */

import * as React from "react";

// ─── Features (productos / sectores) ─────────────────────────────────────
import EventSeatOutlined from "@mui/icons-material/EventSeatOutlined";
import InsightsOutlined from "@mui/icons-material/InsightsOutlined";
import CloudSyncOutlined from "@mui/icons-material/CloudSyncOutlined";
import VpnKeyOutlined from "@mui/icons-material/VpnKeyOutlined";
import PaymentOutlined from "@mui/icons-material/PaymentOutlined";
import HotelOutlined from "@mui/icons-material/HotelOutlined";
import LocalHospitalOutlined from "@mui/icons-material/LocalHospitalOutlined";
import SchoolOutlined from "@mui/icons-material/SchoolOutlined";
import RestaurantOutlined from "@mui/icons-material/RestaurantOutlined";
import StorefrontOutlined from "@mui/icons-material/StorefrontOutlined";
import ApartmentOutlined from "@mui/icons-material/ApartmentOutlined";
import ConfirmationNumberOutlined from "@mui/icons-material/ConfirmationNumberOutlined";
import DirectionsCarOutlined from "@mui/icons-material/DirectionsCarOutlined";
import LocalShippingOutlined from "@mui/icons-material/LocalShippingOutlined";
import PointOfSaleOutlined from "@mui/icons-material/PointOfSaleOutlined";
import AccountBalanceOutlined from "@mui/icons-material/AccountBalanceOutlined";
import HeadsetMicOutlined from "@mui/icons-material/HeadsetMicOutlined";
import PeopleAltOutlined from "@mui/icons-material/PeopleAltOutlined";

// ─── Trust badges / semánticos ───────────────────────────────────────────
import CheckCircleOutline from "@mui/icons-material/CheckCircleOutline";
import BoltOutlined from "@mui/icons-material/BoltOutlined";
import VerifiedOutlined from "@mui/icons-material/VerifiedOutlined";
import LockOutlined from "@mui/icons-material/LockOutlined";
import SupportOutlined from "@mui/icons-material/SupportOutlined";
import ShieldOutlined from "@mui/icons-material/ShieldOutlined";
import TrendingUpOutlined from "@mui/icons-material/TrendingUpOutlined";
import ScheduleOutlined from "@mui/icons-material/ScheduleOutlined";
import RocketLaunchOutlined from "@mui/icons-material/RocketLaunchOutlined";
import AutoAwesomeOutlined from "@mui/icons-material/AutoAwesomeOutlined";
import CheckOutlined from "@mui/icons-material/CheckOutlined";
import StarOutlined from "@mui/icons-material/StarOutlined";

// ─── Redes sociales ──────────────────────────────────────────────────────
import XIcon from "@mui/icons-material/X";
import LinkedIn from "@mui/icons-material/LinkedIn";
import GitHub from "@mui/icons-material/GitHub";
import Facebook from "@mui/icons-material/Facebook";
import Instagram from "@mui/icons-material/Instagram";
import YouTube from "@mui/icons-material/YouTube";
import WhatsApp from "@mui/icons-material/WhatsApp";
import Telegram from "@mui/icons-material/Telegram";

// ─── UI / flechas ────────────────────────────────────────────────────────
import ArrowForward from "@mui/icons-material/ArrowForward";
import ArrowOutward from "@mui/icons-material/ArrowOutward";
import OpenInNew from "@mui/icons-material/OpenInNew";
import EmailOutlined from "@mui/icons-material/EmailOutlined";
import PhoneOutlined from "@mui/icons-material/PhoneOutlined";
import ChatOutlined from "@mui/icons-material/ChatOutlined";
import SettingsOutlined from "@mui/icons-material/SettingsOutlined";
import DashboardOutlined from "@mui/icons-material/DashboardOutlined";
import WorkOutlineOutlined from "@mui/icons-material/WorkOutline";
import GroupsOutlined from "@mui/icons-material/GroupsOutlined";
import BuildOutlined from "@mui/icons-material/BuildOutlined";
import BarChartOutlined from "@mui/icons-material/BarChartOutlined";
import LanguageOutlined from "@mui/icons-material/LanguageOutlined";
import MenuBookOutlined from "@mui/icons-material/MenuBookOutlined";
import DescriptionOutlined from "@mui/icons-material/DescriptionOutlined";
import PersonOutline from "@mui/icons-material/PersonOutline";
import ShoppingCartOutlined from "@mui/icons-material/ShoppingCartOutlined";
import InventoryOutlined from "@mui/icons-material/InventoryOutlined";

// ─── Medical ────────────────────────────────────────────────────────────
import CalendarMonthOutlined from "@mui/icons-material/CalendarMonthOutlined";
import MedicalServicesOutlined from "@mui/icons-material/MedicalServicesOutlined";
import BiotechOutlined from "@mui/icons-material/BiotechOutlined";
import LocalPharmacyOutlined from "@mui/icons-material/LocalPharmacyOutlined";
import HealthAndSafetyOutlined from "@mui/icons-material/HealthAndSafetyOutlined";
import ReceiptLongOutlined from "@mui/icons-material/ReceiptLongOutlined";

// ─── Education ──────────────────────────────────────────────────────────
import AssignmentOutlined from "@mui/icons-material/AssignmentOutlined";
import ForumOutlined from "@mui/icons-material/ForumOutlined";
import GradingOutlined from "@mui/icons-material/GradingOutlined";

// ─── Rental ─────────────────────────────────────────────────────────────
import BookOnlineOutlined from "@mui/icons-material/BookOnlineOutlined";
import HandshakeOutlined from "@mui/icons-material/HandshakeOutlined";
import MonetizationOnOutlined from "@mui/icons-material/MonetizationOnOutlined";

// ─── Inmobiliario ───────────────────────────────────────────────────────
import HomeWorkOutlined from "@mui/icons-material/HomeWorkOutlined";
import MapOutlined from "@mui/icons-material/MapOutlined";

// ─── Restaurante ────────────────────────────────────────────────────────
import DeliveryDiningOutlined from "@mui/icons-material/DeliveryDiningOutlined";
import RestaurantMenuOutlined from "@mui/icons-material/RestaurantMenuOutlined";
import SoupKitchenOutlined from "@mui/icons-material/SoupKitchenOutlined";
import TableRestaurantOutlined from "@mui/icons-material/TableRestaurantOutlined";

// ─── POS ────────────────────────────────────────────────────────────────
import LoyaltyOutlined from "@mui/icons-material/LoyaltyOutlined";

// MUI `OverridableComponent` requires generic component prop — lo aceptamos
// como `React.ElementType` y hacemos cast en el render.
type IconComponent = React.ElementType;

export const ICON_MAP: Record<string, IconComponent> = {
  // Features / sectores
  EventSeatOutlined,
  InsightsOutlined,
  CloudSyncOutlined,
  VpnKeyOutlined,
  PaymentOutlined,
  HotelOutlined,
  LocalHospitalOutlined,
  SchoolOutlined,
  RestaurantOutlined,
  StorefrontOutlined,
  ApartmentOutlined,
  ConfirmationNumberOutlined,
  DirectionsCarOutlined,
  LocalShippingOutlined,
  PointOfSaleOutlined,
  AccountBalanceOutlined,
  HeadsetMicOutlined,
  PeopleAltOutlined,

  // Trust badges
  CheckCircleOutline,
  BoltOutlined,
  VerifiedOutlined,
  LockOutlined,
  SupportOutlined,
  ShieldOutlined,
  TrendingUpOutlined,
  ScheduleOutlined,
  RocketLaunchOutlined,
  AutoAwesomeOutlined,
  CheckOutlined,
  StarOutlined,

  // Redes sociales (alias canónicos)
  X: XIcon,
  XTwitter: XIcon,
  Twitter: XIcon,
  LinkedIn,
  GitHub,
  Facebook,
  Instagram,
  YouTube,
  WhatsApp,
  Telegram,

  // UI / flechas / utility
  ArrowForward,
  ArrowOutward,
  OpenInNew,
  EmailOutlined,
  PhoneOutlined,
  ChatOutlined,
  SettingsOutlined,
  DashboardOutlined,
  WorkOutlineOutlined,
  GroupsOutlined,
  BuildOutlined,
  BarChartOutlined,
  LanguageOutlined,
  MenuBookOutlined,
  DescriptionOutlined,
  PersonOutline,
  ShoppingCartOutlined,
  InventoryOutlined,

  // Medical
  CalendarMonthOutlined,
  MedicalServicesOutlined,
  BiotechOutlined,
  LocalPharmacyOutlined,
  HealthAndSafetyOutlined,
  ReceiptLongOutlined,

  // Education
  AssignmentOutlined,
  ForumOutlined,
  GradingOutlined,

  // Rental
  BookOnlineOutlined,
  HandshakeOutlined,
  MonetizationOnOutlined,

  // Inmobiliario
  HomeWorkOutlined,
  MapOutlined,

  // Restaurante
  DeliveryDiningOutlined,
  RestaurantMenuOutlined,
  SoupKitchenOutlined,
  TableRestaurantOutlined,

  // POS
  LoyaltyOutlined,
};

/**
 * Resuelve un `iconId` a un nodo React. Nunca lanza — si no existe el icono,
 * retorna `null` y el caller decide qué hacer (e.g. render placeholder o
 * simplemente omitir).
 *
 * @param key iconId string (ej. "EventSeatOutlined"). Case-sensitive.
 * @param fontSize tamaño en px del icono (default 24). Pasado vía `sx`.
 */
export function resolveIcon(
  key: string | undefined | null,
  fontSize: number = 24,
): React.ReactNode {
  if (!key) return null;
  const Icon = ICON_MAP[key] as React.ElementType | undefined;
  if (!Icon) return null;
  return <Icon sx={{ fontSize }} />;
}

/**
 * True si el `iconId` existe en el map. Útil para tests.
 */
export function hasIcon(key: string): boolean {
  return key in ICON_MAP;
}
