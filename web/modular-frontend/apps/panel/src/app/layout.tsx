import React from "react";
import AuthGuard from "./AuthGuard";

export const dynamic = "force-dynamic";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es">
      <body style={{ margin: 0, fontFamily: "Inter, system-ui, sans-serif" }}>
        <AuthGuard>{children}</AuthGuard>
      </body>
    </html>
  );
}
