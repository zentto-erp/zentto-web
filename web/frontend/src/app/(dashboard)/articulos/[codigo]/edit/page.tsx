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
  params: {
    codigo: string;
  };
}

export default function EditArticuloPage({ params }: EditArticuloPageProps) {
  return (
    <Suspense fallback={<FormSkeleton />}>
      <ArticuloForm codigoArticulo={params.codigo} />
    </Suspense>
  );
}
