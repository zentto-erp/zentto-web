// components/modules/clientes/ClienteForm.tsx
/**
 * EJEMPLO PRÁCTICO #2 - FORMULARIO DE CLIENTE
 * Template reutilizable para formularios CRUD
 * 
 * Este archivo muestra cómo:
 * 1. Usar el componente genérico CrudForm
 * 2. Definir validación con Zod
 * 3. Adaptar el formulario para CRUD
 * 4. Manejar create/update
 */

'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { z } from 'zod';
import { Box, Paper, CircularProgress, Alert, Typography } from '@mui/material';
import CrudForm from '@/components/common/CrudForm';
import { useCrudGeneric } from '@/hooks/useCrudGeneric';
import { Cliente, CreateClienteDTO, FormField } from '@/lib/types';

// ============================================================================
// VALIDACIÓN CON ZOD
// ============================================================================

const clienteSchema = z.object({
  nombre: z
    .string()
    .min(3, 'El nombre debe tener al menos 3 caracteres')
    .max(100, 'El nombre no puede exceder 100 caracteres'),
  rif: z
    .string()
    .min(1, 'El RIF es requerido')
    .regex(/^[A-Z0-9]{1,20}$/, 'RIF inválido'),
  direccion: z
    .string()
    .min(5, 'La dirección debe tener al menos 5 caracteres')
    .max(255, 'La dirección no puede exceder 255 caracteres'),
  telefono: z
    .string()
    .regex(/^\+?[\d\s\-()]{7,20}$/, 'Teléfono inválido')
    .optional()
    .or(z.literal('')),
  email: z
    .string()
    .email('Email inválido')
    .optional()
    .or(z.literal('')),
});

type ClienteFormData = z.infer<typeof clienteSchema>;

// ============================================================================
// CAMPOS DEL FORMULARIO
// ============================================================================

const formFields: FormField[] = [
  {
    name: 'nombre',
    label: 'Nombre del Cliente',
    type: 'text',
    required: true,
    placeholder: 'Ej: Juan García',
  },
  {
    name: 'rif',
    label: 'RIF',
    type: 'text',
    required: true,
    placeholder: 'Ej: 12345678',
    validation: {
      pattern: /^[A-Z0-9]{1,20}$/,
      message: 'RIF inválido',
    },
  },
  {
    name: 'direccion',
    label: 'Dirección',
    type: 'textarea',
    required: true,
    placeholder: 'Calle, número, ciudad',
  },
  {
    name: 'telefono',
    label: 'Teléfono',
    type: 'tel',
    placeholder: '+58 212 1234567',
  },
  {
    name: 'email',
    label: 'Email',
    type: 'email',
    placeholder: 'cliente@example.com',
  },
];

// ============================================================================
// COMPONENTE PRINCIPAL
// ============================================================================

interface ClienteFormProps {
  isDraft?: boolean;
  clienteCodigo?: string;
}

export default function ClienteForm({
  isDraft = false,
  clienteCodigo,
}: ClienteFormProps) {
  const router = useRouter();
  const crud = useCrudGeneric<Cliente, CreateClienteDTO>('clientes');
  const [initialData, setInitialData] = useState<ClienteFormData | null>(null);
  const [isLoading, setIsLoading] = useState(!!clienteCodigo);
  const [error, setError] = useState<string | null>(null);

  // Fetch cliente si es edición
  useEffect(() => {
    if (!clienteCodigo) {
      setIsLoading(false);
      return;
    }

    const fetchCliente = async () => {
      try {
        const response = await fetch(`/api/v1/clientes/${clienteCodigo}`);
        if (!response.ok) throw new Error('Error al cargar cliente');
        const data = await response.json();
        setInitialData(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Error desconocido');
      } finally {
        setIsLoading(false);
      }
    };

    fetchCliente();
  }, [clienteCodigo]);

  // Mutation hooks
  const createMutation = crud.create();
  const updateMutation = clienteCodigo
    ? crud.update(clienteCodigo)
    : null;

  // Handler para guardar
  const handleSave = async (data: CreateClienteDTO) => {
    try {
      if (clienteCodigo && updateMutation) {
        // Actualizar
        await new Promise((resolve, reject) => {
          updateMutation.mutate(data, {
            onSuccess: resolve,
            onError: reject,
          });
        });
      } else {
        // Crear
        await new Promise((resolve, reject) => {
          createMutation.mutate(data, {
            onSuccess: resolve,
            onError: reject,
          });
        });
      }

      // Redirect
      router.push('/clientes');
    } catch (error) {
      throw error;
    }
  };

  if (isLoading) {
    return (
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          height: 400,
        }}
      >
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ mt: 2 }}>
        {error}
      </Alert>
    );
  }

  return (
    <Box>
      <Typography variant="h5" fontWeight={600} gutterBottom>{clienteCodigo ? 'Editar Cliente' : 'Nuevo Cliente'}</Typography>

      <CrudForm
        fields={formFields}
        schema={clienteSchema}
        initialValues={initialData || {}}
        onSave={handleSave}
        onCancel={() => router.push('/clientes')}
        isLoading={createMutation.isPending || updateMutation?.isPending}
        title={clienteCodigo ? `Editando: ${initialData?.nombre}` : 'Nuevo Cliente'}
      />
    </Box>
  );
}

// ============================================================================
// EXPORT PARA REUTILIZAR EN OTROS MÓDULOS
// ============================================================================

/**
 * TEMPLATE PARA OTROS MÓDULOS
 * 
 * Para crear un formulario para PROVEEDORES, copia esta estructura:
 * 
 * 1. Reemplaza el schema:
 *    const proveedorSchema = z.object({
 *      nombre: z.string().min(3),
 *      razonSocial: z.string(),
 *      // ... más campos
 *    });
 * 
 * 2. Reemplaza los fields:
 *    const formFields: FormField[] = [
 *      { name: 'nombre', label: 'Nombre', ... },
 *      // ... más campos
 *    ];
 * 
 * 3. Reemplaza el hook:
 *    const crud = useCrudGeneric<Proveedor, CreateProveedorDTO>('proveedores');
 * 
 * 4. El resto del código es idéntico
 */

