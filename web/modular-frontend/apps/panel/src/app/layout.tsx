import React from "react";
import PanelShell from "./PanelShell";

export const dynamic = "force-dynamic";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es">
      <body style={{ margin: 0, fontFamily: "Inter, system-ui, sans-serif" }}>
        <PanelShell>{children}</PanelShell>
      </body>
    </html>
  );
}
