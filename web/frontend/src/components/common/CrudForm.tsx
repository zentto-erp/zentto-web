// components/common/CrudForm.tsx
/**
 * FORMULARIO GENÉRICO REUSABLE
 * Se adapta a cualquier entidad (Cliente, Proveedor, Artículo, etc.)
 * 
 * Features:
 * - Validación con React Hook Form
 * - Errores inline
 * - Estados (loading, success, error)
 * - Save/Cancel actions
 */

'use client';

import React, { useEffect } from 'react';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { ZodSchema } from 'zod';
import {
  Box,
  Button,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  FormHelperText,
  CircularProgress,
  Alert,
  Grid,
  Paper,
  Typography,
} from '@mui/material';
import { FormField } from '@/lib/types';

interface CrudFormProps {
  fields: FormField[];
  schema: ZodSchema;
  initialValues?: Record<string, any>;
  onSave: (data: any) => Promise<void>;
  onCancel?: () => void;
  isLoading?: boolean;
  title?: string;
}

export default function CrudForm({
  fields,
  schema,
  initialValues,
  onSave,
  onCancel,
  isLoading,
  title,
}: CrudFormProps) {
  const {
    control,
    handleSubmit,
    formState: { errors, isSubmitting },
    reset,
  } = useForm({
    resolver: zodResolver(schema),
    defaultValues: initialValues || {},
  });

  const [submitError, setSubmitError] = React.useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = React.useState(false);

  useEffect(() => {
    if (initialValues) {
      reset(initialValues);
    }
  }, [initialValues, reset]);

  const onSubmit = async (data: any) => {
    try {
      setSubmitError(null);
      setSubmitSuccess(false);
      await onSave(data);
      setSubmitSuccess(true);
      setTimeout(() => setSubmitSuccess(false), 3000);
    } catch (error) {
      setSubmitError(error instanceof Error ? error.message : 'Error al guardar');
    }
  };

  return (
    <Paper sx={{ p: 3 }}>
      {title && <Typography variant="h5" fontWeight={600} gutterBottom>{title}</Typography>}

      {submitSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          Guardado exitosamente
        </Alert>
      )}

      {submitError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {submitError}
        </Alert>
      )}

      <form onSubmit={handleSubmit(onSubmit)}>
        <Grid container spacing={2}>
          {fields.map((field) => (
            <Grid item xs={12} sm={6} key={field.name}>
              <Controller
                name={field.name}
                control={control}
                render={({ field: fieldProps }) =>
                  field.type === 'select' ? (
                    <FormControl
                      fullWidth
                      error={!!errors[field.name]}
                      required={field.required}
                    >
                      <InputLabel>{field.label}</InputLabel>
                      <Select
                        {...fieldProps}
                        label={field.label}
                      >
                        {field.options?.map((opt) => (
                          <MenuItem
                            key={opt.value}
                            value={opt.value}
                          >
                            {opt.label}
                          </MenuItem>
                        ))}
                      </Select>
                      {errors[field.name] && (
                        <FormHelperText>
                          {String(errors[field.name]?.message)}
                        </FormHelperText>
                      )}
                    </FormControl>
                  ) : field.type === 'textarea' ? (
                    <TextField
                      {...fieldProps}
                      label={field.label}
                      placeholder={field.placeholder}
                      multiline
                      rows={4}
                      fullWidth
                      required={field.required}
                      error={!!errors[field.name]}
                      helperText={
                        errors[field.name]
                          ? String(errors[field.name]?.message)
                          : ''
                      }
                    />
                  ) : (
                    <TextField
                      {...fieldProps}
                      label={field.label}
                      placeholder={field.placeholder}
                      type={field.type}
                      fullWidth
                      required={field.required}
                      error={!!errors[field.name]}
                      helperText={
                        errors[field.name]
                          ? String(errors[field.name]?.message)
                          : ''
                      }
                    />
                  )
                }
              />
            </Grid>
          ))}
        </Grid>

        <Box
          sx={{
            display: 'flex',
            gap: 2,
            mt: 3,
            justifyContent: 'flex-end',
          }}
        >
          {onCancel && (
            <Button
              variant="outlined"
              onClick={onCancel}
              disabled={isSubmitting}
            >
              Cancelar
            </Button>
          )}
          <Button
            variant="contained"
            type="submit"
            disabled={isSubmitting || isLoading}
            startIcon={isSubmitting && <CircularProgress size={20} />}
          >
            {isSubmitting ? 'Guardando...' : 'Guardar'}
          </Button>
        </Box>
      </form>
    </Paper>
  );
}

