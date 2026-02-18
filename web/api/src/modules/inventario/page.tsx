"use client";

import { Suspense } from "react";
import ClienteForm from "@/components/modules/clientes/ClienteForm";
import { CircularProgress, Box } from "@mui/material";

export default function EditClientePage({ params }: { params: { codigo: string } }) {
  return (
    <Suspense fallback={<Box sx={{ display: "flex", justifyContent: "center", height: 400 }}><CircularProgress /></Box>}>
      <ClienteForm clienteCodigo={params.codigo} />
    </Suspense>
  );
}