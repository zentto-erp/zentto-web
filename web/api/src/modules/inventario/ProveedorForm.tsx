"use client";

import React from "react";
import { useRouter } from "next/navigation";
import { z } from "zod";
import { Box, CircularProgress } from "@mui/material";
import CrudForm from "@/components/common/CrudForm";
import { useCreateProveedor, useUpdateProveedor, useProveedorById } from "@/hooks/useProveedores";
import { CreateProveedorDTO, FormField } from "@/lib/types";

const proveedorSchema = z.object({
  nombre: z.string().min(3, "Mínimo 3 caracteres"),
  rif: z.string().min(1, "Requerido"),
  direccion: z.string().optional(),
  telefono: z.string().optional(),
  email: z.string().email("Email inválido").optional().or(z.literal("")),
});

const formFields: FormField[] = [
  { name: "nombre", label: "Nombre", type: "text", required: true },
  { name: "rif", label: "RIF", type: "text", required: true },
  { name: "direccion", label: "Dirección", type: "textarea" },
  { name: "telefono", label: "Teléfono", type: "tel" },
  { name: "email", label: "Email", type: "email" },
];

export default function ProveedorForm({ codigo }: { codigo?: string }) {
  const router = useRouter();
  const { data: initialData, isLoading: isLoadingData } = useProveedorById(codigo || "");
  const createMutation = useCreateProveedor();
  const updateMutation = useUpdateProveedor(codigo || "");

  const handleSave = async (data: any) => {
    if (codigo) {
      await updateMutation.mutateAsync(data);
    } else {
      await createMutation.mutateAsync(data as CreateProveedorDTO);
    }
    router.push("/proveedores");
  };

  if (codigo && isLoadingData) return <CircularProgress />;

  return (
    <Box>
      <h1>{codigo ? "Editar Proveedor" : "Nuevo Proveedor"}</h1>
      <CrudForm
        fields={formFields}
        schema={proveedorSchema}
        initialValues={initialData || {}}
        onSave={handleSave}
        onCancel={() => router.push("/proveedores")}
        isLoading={createMutation.isPending || updateMutation.isPending}
      />
    </Box>
  );
}