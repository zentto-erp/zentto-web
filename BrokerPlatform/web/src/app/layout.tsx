import type { Metadata } from "next";
import "leaflet/dist/leaflet.css";
import "@fontsource/inter/300.css";
import "@fontsource/inter/400.css";
import "@fontsource/inter/500.css";
import "@fontsource/inter/600.css";
import "@fontsource/inter/700.css";
import "./globals.css";
import { Providers } from "@/lib/providers";

export const metadata: Metadata = {
  title: "BrokerPlatform – Hotels, Cars, Boats & More",
  description:
    "Find and book the best hotels, car rentals, boats, flights, lodges and tours. Your one-stop travel broker platform.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body style={{ margin: 0 }}>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
