"use client";

import React, { useEffect, useState } from "react";
import { usePathname } from "next/navigation";

const PUBLIC_PATHS = ["/login", "/register", "/forgot-password"];

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    const isPublic = PUBLIC_PATHS.some(p => pathname?.startsWith(p));
    if (isPublic) {
      setChecked(true);
      return;
    }

    // Check auth via sessionStorage
    const user = sessionStorage.getItem("zentto-panel-user");
    if (!user) {
      window.location.href = "/login";
      return;
    }
    setChecked(true);
  }, [pathname]);

  if (!checked) {
    return (
      <html lang="es">
        <body style={{ margin: 0, fontFamily: "Inter, system-ui, sans-serif" }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100vh" }}>
            <div style={{
              width: 36, height: 36, border: "3px solid #e2e8f0", borderTopColor: "#6366f1",
              borderRadius: "50%", animation: "spin 0.7s linear infinite",
            }} />
            <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
          </div>
        </body>
      </html>
    );
  }

  return (
    <html lang="es">
      <body style={{ margin: 0, fontFamily: "Inter, system-ui, sans-serif" }}>
        {children}
      </body>
    </html>
  );
}
