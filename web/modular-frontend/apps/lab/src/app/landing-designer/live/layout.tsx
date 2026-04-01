import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Zentto Landing",
};

export default function LandingLiveLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es">
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </head>
      <body style={{ margin: 0, padding: 0, overflow: "auto" }}>
        {children}
      </body>
    </html>
  );
}
