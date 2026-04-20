'use client';
import * as React from 'react';
import Grid from '@mui/material/Grid';
import type { GridProps } from '@mui/material/Grid';

export interface FormGridProps extends Omit<GridProps, 'container'> {
  /** Espaciado entre campos. Default: 3 (24px) */
  spacing?: number;
  children: React.ReactNode;
}

/**
 * Contenedor de formulario — Grid container preconfigurado.
 * Uso:
 *   <FormGrid>
 *     <FormField xs={12} sm={6}><TextField label="Nombre" /></FormField>
 *   </FormGrid>
 */
export function FormGrid({ spacing = 2, children, ...props }: FormGridProps) {
  return (
    <Grid container spacing={spacing} {...props}>
      {children}
    </Grid>
  );
}

export interface FormFieldProps extends Omit<GridProps, 'item'> {
  /** Columnas en mobile (1-12). Default: 12 */
  xs?: number | 'auto';
  /** Columnas en tablet. Default: 6 */
  sm?: number | 'auto';
  /** Columnas en desktop. Default: 4 */
  md?: number | 'auto';
  /** Columnas en wide. Default: 3 */
  lg?: number | 'auto';
  children: React.ReactNode;
}

/**
 * Wrapper de campo de formulario — Grid item preconfigurado.
 *
 * Defaults: `xs=12, sm=6, md=4, lg=3` (4 campos por fila en desktop wide).
 * Para formularios de 1 columna, override explícitamente:
 *   `<FormField xs={12} sm={12} md={12} lg={12}>` (full-width en todos los breakpoints).
 * Para 2 columnas simétricas en desktop: `<FormField xs={12} sm={12} md={6} lg={6}>`.
 * Para 3 columnas admin (precio / stock / SKU): `<FormField xs={12} sm={6} md={4} lg={4}>`.
 *
 * Uso:
 *   <FormField xs={12} sm={6}>
 *     <TextField label="Email" fullWidth />
 *   </FormField>
 */
export function FormField({ xs = 12, sm = 6, md = 4, lg = 3, children, ...props }: FormFieldProps) {
  return (
    <Grid item xs={xs} sm={sm} md={md} lg={lg} {...props}>
      {children}
    </Grid>
  );
}
