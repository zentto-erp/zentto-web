"use client";

import { Card, CardContent, Typography, Skeleton } from "@mui/material";
import Grid from "@mui/material/Grid2";
import { formatCurrency } from "@zentto/shared-api";

interface ConciliacionSummaryCardsProps {
  detalle: any;
  isLoading: boolean;
}

export default function ConciliacionSummaryCards({
  detalle,
  isLoading,
}: ConciliacionSummaryCardsProps) {
  const cabecera = detalle?.cabecera;
  const cards = [
    { title: "Pendientes", value: cabecera?.Pendientes ?? 0, color: "#e65100", isCurrency: false },
    { title: "Conciliados", value: cabecera?.Conciliados ?? 0, color: "#2e7d32", isCurrency: false },
    { title: "Saldo sistema", value: cabecera?.Saldo_Final_Sistema ?? 0, color: "#1565c0", isCurrency: true },
    { title: "Diferencia", value: cabecera?.Diferencia ?? 0, color: "#c62828", isCurrency: true },
  ];

  return (
    <Grid container spacing={2} sx={{ mb: 3 }}>
      {cards.map((card, idx) => (
        <Grid size={{ xs: 6, md: 3 }} key={idx}>
          <Card sx={{ borderRadius: 2, borderTop: `3px solid ${card.color}` }}>
            <CardContent sx={{ py: 1.5 }}>
              {isLoading ? (
                <Skeleton width={80} height={36} />
              ) : (
                <Typography variant="h5" fontWeight={700} sx={{ color: card.color }}>
                  {card.isCurrency ? formatCurrency(card.value) : card.value}
                </Typography>
              )}
              <Typography variant="body2" color="text.secondary">
                {card.title}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      ))}
    </Grid>
  );
}
