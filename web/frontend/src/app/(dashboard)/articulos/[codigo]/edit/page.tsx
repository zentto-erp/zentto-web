// app/(dashboard)/articulos/[codigo]/edit/page.tsx
import { Suspense } from "react";
import ArticuloForm from "@/components/modules/articulos/ArticuloForm";
import { CircularProgress, Box } from "@mui/material";

export const metadata = {
  title: "Editar Artículo | DatqBox",
  description: "Editar artículo",
};

function FormSkeleton() {
  return (
    <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", height: 400 }}>
      <CircularProgress />
    </Box>
  );
}

interface EditArticuloPageProps {
  params: Promise<{
    codigo: string;
  }>;
}

export default async function EditArticuloPage({ params }: EditArticuloPageProps) {
  const resolvedParams = await params;
  return (
    <Suspense fallback={<FormSkeleton />}>
      <ArticuloForm codigoArticulo={resolvedParams.codigo} />
    </Suspense>
  );
}
