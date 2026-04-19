"use client";

import { Box, Typography, Stack, Skeleton } from "@mui/material";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import PaymentsIcon from "@mui/icons-material/Payments";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import HomeIcon from "@mui/icons-material/Home";
import CancelIcon from "@mui/icons-material/Cancel";
import NotesIcon from "@mui/icons-material/Notes";
import { useOrderTracking, type TrackingEvent } from "../hooks/useOrderTracking";

interface Props {
  orderToken?: string;
}

const ICON_BY_EVENT: Record<TrackingEvent["eventCode"], React.ReactNode> = {
  ORDER_CREATED: <ReceiptLongIcon fontSize="small" />,
  ORDER_PAID: <PaymentsIcon fontSize="small" />,
  ORDER_SHIPPED: <LocalShippingIcon fontSize="small" />,
  ORDER_DELIVERED: <HomeIcon fontSize="small" />,
  ORDER_CANCELLED: <CancelIcon fontSize="small" />,
  NOTE: <NotesIcon fontSize="small" />,
};

const COLOR_BY_EVENT: Record<TrackingEvent["eventCode"], string> = {
  ORDER_CREATED: "#0072c6",
  ORDER_PAID: "#067D62",
  ORDER_SHIPPED: "#ff9900",
  ORDER_DELIVERED: "#067D62",
  ORDER_CANCELLED: "#cc0c39",
  NOTE: "#565959",
};

function formatDate(iso: string) {
  try {
    return new Date(iso).toLocaleString(undefined, {
      day: "2-digit",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return iso;
  }
}

export default function OrderTimeline({ orderToken }: Props) {
  const { data: events = [], isLoading } = useOrderTracking(orderToken);

  if (isLoading) {
    return (
      <Stack spacing={2}>
        {[1, 2, 3].map((i) => (
          <Skeleton key={i} variant="rectangular" height={56} sx={{ borderRadius: 1 }} />
        ))}
      </Stack>
    );
  }

  if (!events.length) {
    return (
      <Typography variant="body2" color="text.secondary">
        Aún no hay actualizaciones de seguimiento. Te avisaremos por email cuando tu pedido cambie de estado.
      </Typography>
    );
  }

  return (
    <Box sx={{ position: "relative", pl: 3 }}>
      {/* Línea vertical */}
      <Box
        sx={{
          position: "absolute",
          left: 12,
          top: 8,
          bottom: 8,
          width: 2,
          bgcolor: "#e3e6e6",
        }}
      />
      <Stack spacing={2.5}>
        {events.map((ev, idx) => {
          const color = COLOR_BY_EVENT[ev.eventCode] ?? "#565959";
          const icon = ICON_BY_EVENT[ev.eventCode] ?? <CheckCircleIcon fontSize="small" />;
          return (
            <Box key={idx} sx={{ position: "relative", pl: 2 }}>
              <Box
                sx={{
                  position: "absolute",
                  left: -22,
                  top: 0,
                  width: 28,
                  height: 28,
                  borderRadius: "50%",
                  bgcolor: color,
                  color: "#fff",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  boxShadow: "0 0 0 3px #fff",
                }}
              >
                {icon}
              </Box>
              <Typography variant="body2" fontWeight="bold" sx={{ color: "#0f1111", lineHeight: 1.2 }}>
                {ev.eventLabel}
              </Typography>
              <Typography variant="caption" color="text.secondary" sx={{ display: "block" }}>
                {formatDate(ev.occurredAt)}
              </Typography>
              {ev.description && (
                <Typography variant="body2" sx={{ color: "#3a3a4a", mt: 0.5, fontSize: 13 }}>
                  {ev.description}
                </Typography>
              )}
            </Box>
          );
        })}
      </Stack>
    </Box>
  );
}
