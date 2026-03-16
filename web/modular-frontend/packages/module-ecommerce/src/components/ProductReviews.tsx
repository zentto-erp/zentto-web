"use client";

import { useState } from "react";
import {
  Box, Typography, Paper, Button, TextField, Divider, Avatar,
  LinearProgress, Alert, CircularProgress, Select, MenuItem,
} from "@mui/material";
import ReviewStars from "./ReviewStars";
import { useProductReviews, useCreateReview } from "../hooks/useStoreProducts";
import { useCartStore } from "../store/useCartStore";

interface Props {
  productCode: string;
}

function RatingBar({ stars, count, total }: { stars: number; count: number; total: number }) {
  const pct = total > 0 ? (count / total) * 100 : 0;
  return (
    <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 0.3 }}>
      <Typography variant="caption" sx={{ color: "#007185", minWidth: 50, cursor: "pointer", "&:hover": { textDecoration: "underline" } }}>
        {stars} estrellas
      </Typography>
      <LinearProgress
        variant="determinate"
        value={pct}
        sx={{
          flexGrow: 1,
          height: 16,
          borderRadius: "4px",
          bgcolor: "#f0f0f0",
          "& .MuiLinearProgress-bar": { bgcolor: "#ffa41c", borderRadius: "4px" },
        }}
      />
      <Typography variant="caption" sx={{ color: "#565959", minWidth: 30, textAlign: "right" }}>
        {pct.toFixed(0)}%
      </Typography>
    </Box>
  );
}

function fmtDate(d: string | Date | null | undefined): string {
  if (!d) return "";
  try { return new Date(d as string).toLocaleDateString("es", { year: "numeric", month: "long", day: "numeric" }); }
  catch { return String(d); }
}

export default function ProductReviews({ productCode }: Props) {
  const { data: reviewData, isLoading } = useProductReviews(productCode);
  const createReview = useCreateReview();
  const customerToken = useCartStore((s) => s.customerToken);
  const customerInfo = useCartStore((s) => s.customerInfo);

  const [showForm, setShowForm] = useState(false);
  const [rating, setRating] = useState(5);
  const [title, setTitle] = useState("");
  const [comment, setComment] = useState("");
  const [error, setError] = useState("");

  const reviews = reviewData?.reviews ?? [];
  const summary = reviewData?.summary ?? { avgRating: 0, totalCount: 0, star1: 0, star2: 0, star3: 0, star4: 0, star5: 0 };

  const handleSubmit = async () => {
    if (!comment.trim()) { setError("Escribe un comentario"); return; }
    setError("");
    try {
      await createReview.mutateAsync({
        productCode,
        rating,
        title: title.trim() || undefined,
        comment: comment.trim(),
        reviewerName: customerInfo?.name || "Cliente",
      });
      setShowForm(false);
      setTitle("");
      setComment("");
      setRating(5);
    } catch (err: any) {
      setError(err.message || "Error al enviar reseña");
    }
  };

  if (isLoading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
        <CircularProgress sx={{ color: "#ff9900" }} />
      </Box>
    );
  }

  return (
    <Paper elevation={0} sx={{ border: "1px solid #e3e6e6", borderRadius: "8px", p: 3 }}>
      <Typography variant="h6" fontWeight="bold" sx={{ color: "#0f1111", mb: 2 }}>
        Opiniones de clientes
      </Typography>

      <Box sx={{ display: "flex", gap: 4, flexWrap: "wrap", mb: 3 }}>
        {/* Summary */}
        <Box sx={{ minWidth: 200 }}>
          <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 1 }}>
            <ReviewStars rating={summary.avgRating} size="medium" showCount={false} />
            <Typography variant="body1" fontWeight="bold">
              {summary.avgRating?.toFixed(1)} de 5
            </Typography>
          </Box>
          <Typography variant="body2" sx={{ color: "#565959", mb: 1.5 }}>
            {summary.totalCount} calificaciones
          </Typography>

          <RatingBar stars={5} count={summary.star5} total={summary.totalCount} />
          <RatingBar stars={4} count={summary.star4} total={summary.totalCount} />
          <RatingBar stars={3} count={summary.star3} total={summary.totalCount} />
          <RatingBar stars={2} count={summary.star2} total={summary.totalCount} />
          <RatingBar stars={1} count={summary.star1} total={summary.totalCount} />

          <Button
            variant="outlined"
            fullWidth
            onClick={() => setShowForm(!showForm)}
            sx={{
              mt: 2,
              textTransform: "none",
              borderRadius: "20px",
              borderColor: "#d5d9d9",
              color: "#0f1111",
              "&:hover": { bgcolor: "#f7fafa" },
            }}
          >
            Escribir una opinion
          </Button>
        </Box>

        {/* Review Form */}
        {showForm && (
          <Paper elevation={0} sx={{ border: "1px solid #e3e6e6", borderRadius: "8px", p: 2, flex: 1, minWidth: 280 }}>
            <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 1 }}>
              Tu opinion
            </Typography>
            {error && <Alert severity="error" sx={{ mb: 1 }}>{error}</Alert>}
            <Box sx={{ mb: 1 }}>
              <Typography variant="caption">Calificacion:</Typography>
              <Select size="small" value={rating} onChange={(e) => setRating(Number(e.target.value))} sx={{ ml: 1, minWidth: 60 }}>
                {[5, 4, 3, 2, 1].map((v) => (
                  <MenuItem key={v} value={v}>{v} estrella{v > 1 ? "s" : ""}</MenuItem>
                ))}
              </Select>
            </Box>
            <TextField
              label="Titulo (opcional)"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              fullWidth
              size="small"
              sx={{ mb: 1 }}
            />
            <TextField
              label="Tu comentario"
              value={comment}
              onChange={(e) => setComment(e.target.value)}
              fullWidth
              multiline
              rows={3}
              size="small"
              sx={{ mb: 1 }}
            />
            <Button
              variant="contained"
              onClick={handleSubmit}
              disabled={createReview.isPending}
              sx={{
                bgcolor: "#ffd814",
                color: "#0f1111",
                textTransform: "none",
                borderRadius: "20px",
                boxShadow: "none",
                "&:hover": { bgcolor: "#f7ca00", boxShadow: "none" },
              }}
            >
              {createReview.isPending ? "Enviando..." : "Enviar opinion"}
            </Button>
          </Paper>
        )}
      </Box>

      <Divider sx={{ mb: 2 }} />

      {/* Individual Reviews */}
      {reviews.length === 0 ? (
        <Typography variant="body2" color="text.secondary" sx={{ py: 2, textAlign: "center" }}>
          Aun no hay opiniones para este producto. Se el primero en opinar.
        </Typography>
      ) : (
        reviews.map((review: any, i: number) => (
          <Box key={review.id || i} sx={{ mb: 2, pb: 2, borderBottom: i < reviews.length - 1 ? "1px solid #f0f0f0" : "none" }}>
            <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 0.5 }}>
              <Avatar sx={{ width: 28, height: 28, bgcolor: "#232f3e", fontSize: 13 }}>
                {review.reviewerName?.charAt(0) || "C"}
              </Avatar>
              <Typography variant="body2" sx={{ color: "#565959", fontSize: 13 }}>
                {review.reviewerName || "Cliente"}
              </Typography>
            </Box>
            <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 0.3 }}>
              <ReviewStars rating={review.rating} showCount={false} size="small" />
              {review.title && (
                <Typography variant="body2" fontWeight="bold" sx={{ color: "#0f1111" }}>
                  {review.title}
                </Typography>
              )}
            </Box>
            <Typography variant="caption" sx={{ color: "#565959", display: "block", mb: 0.5 }}>
              {fmtDate(review.createdAt)}
            </Typography>
            <Typography variant="body2" sx={{ color: "#0f1111", lineHeight: 1.5 }}>
              {review.comment}
            </Typography>
          </Box>
        ))
      )}
    </Paper>
  );
}
