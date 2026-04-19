"use client";

import { Box, Container } from "@mui/material";
import { ProductCompare } from "@zentto/module-ecommerce";

export default function CompararPage() {
  return (
    <Container maxWidth="xl" sx={{ py: 4 }}>
      <Box sx={{ pb: 12 }}>
        <ProductCompare />
      </Box>
    </Container>
  );
}
