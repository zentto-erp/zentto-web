// app/(dashboard)/proveedores/[codigo]/edit/page.tsx
import { Suspense } from "react";
import ProveedorForm from "@/components/modules/proveedores/ProveedorForm";
import { CircularProgress, Box } from "@mui/material";

export const metadata = {
  title: "Editar Proveedor | DatqBox",
  description: "Editar proveedor",
};

function FormSkeleton() {
  return (
    <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", height: 400 }}>
      <CircularProgress />
    </Box>
  );
}

interface EditProveedorPageProps {
  params: Promise<{
    codigo: string;
  }>;
}

export default async function EditProveedorPage({ params }: EditProveedorPageProps) {
  const resolvedParams = await params;
  return (
    <Suspense fallback={<FormSkeleton />}>
      <ProveedorForm proveedorCodigo={resolvedParams.codigo} />
    </Suspense>
  );
}
