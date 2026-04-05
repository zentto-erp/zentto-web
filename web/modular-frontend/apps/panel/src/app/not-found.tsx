export default function NotFound() {
  return (
    <div style={{
      display: "flex", flexDirection: "column", alignItems: "center",
      justifyContent: "center", height: "100vh", fontFamily: "Inter, system-ui, sans-serif",
    }}>
      <h1 style={{ fontSize: 64, color: "#e2e8f0", margin: 0 }}>404</h1>
      <p style={{ color: "#64748b" }}>Página no encontrada</p>
      <a href="/" style={{ color: "#6366f1", textDecoration: "none" }}>Volver al inicio</a>
    </div>
  );
}
