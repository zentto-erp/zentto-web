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
export function FormGrid({ spacing = 3, children, ...props }: FormGridProps) {
  return (
    <Grid container spacing={spacing} {...props}>
      {children}
    </Grid>
  );
}

export interface FormFieldProps extends Omit<GridProps, 'item'> {
  /** Columnas en mobile (1-12). Default: 12 */
  xs?: number | 'auto';
  /** Columnas en tablet */
  sm?: number | 'auto';
  /** Columnas en desktop */
  md?: number | 'auto';
  /** Columnas en wide */
  lg?: number | 'auto';
  children: React.ReactNode;
}

/**
 * Wrapper de campo de formulario — Grid item preconfigurado.
 * Uso:
 *   <FormField xs={12} sm={6}>
 *     <TextField label="Email" />
 *   </FormField>
 */
export function FormField({ xs = 12, sm, md, lg, children, ...props }: FormFieldProps) {
  return (
    <Grid item xs={xs} sm={sm} md={md} lg={lg} {...props}>
      {children}
    </Grid>
  );
}
