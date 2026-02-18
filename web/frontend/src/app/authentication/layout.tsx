export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // El layout principal ya maneja el tema y providers
  // Esta página se renderiza sin layout del dashboard
  return children;
}
