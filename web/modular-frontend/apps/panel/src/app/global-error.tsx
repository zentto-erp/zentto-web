"use client";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html lang="es">
      <body style={{ margin: 0, fontFamily: "Inter, system-ui, sans-serif" }}>
        <div style={{
          display: "flex", flexDirection: "column", alignItems: "center",
          justifyContent: "center", height: "100vh", gap: 16,
        }}>
          <h2 style={{ color: "#dc2626", margin: 0 }}>Algo salio mal</h2>
          <p style={{ color: "#64748b" }}>{error.message}</p>
          <button
            onClick={reset}
            style={{
              padding: "10px 24px", background: "#6366f1", color: "#fff",
              border: "none", borderRadius: 8, cursor: "pointer", fontSize: 14,
            }}
          >
            Reintentar
          </button>
        </div>
      </body>
    </html>
  );
}
