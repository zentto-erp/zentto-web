#!/usr/bin/env node

/**
 * DatQBox Frontend Agent - MCP Server
 * Agente especializado para desarrollo Next.js + React + MUI
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { readFileSync, readdirSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const FRONTEND_DIR = join(__dirname, '../../frontend/src');

// Definir herramientas del agente
const TOOLS = [
  {
    name: 'create_page',
    description: 'Crea una nueva página en el App Router de Next.js',
    inputSchema: {
      type: 'object',
      properties: {
        path: {
          type: 'string',
          description: 'Ruta de la página (ej: "clientes", "facturas/nueva")',
        },
        isDashboard: {
          type: 'boolean',
          description: 'Si la página debe estar dentro del layout del dashboard',
        },
        title: {
          type: 'string',
          description: 'Título de la página',
        },
      },
      required: ['path', 'title'],
    },
  },
  {
    name: 'create_component',
    description: 'Crea un nuevo componente React',
    inputSchema: {
      type: 'object',
      properties: {
        name: {
          type: 'string',
          description: 'Nombre del componente (PascalCase)',
        },
        type: {
          type: 'string',
          enum: ['common', 'module', 'form', 'table', 'dialog'],
          description: 'Tipo de componente',
        },
        moduleName: {
          type: 'string',
          description: 'Nombre del módulo (si es tipo module)',
        },
      },
      required: ['name', 'type'],
    },
  },
  {
    name: 'create_tanstack_hook',
    description: 'Crea un hook de TanStack Query para consumir la API',
    inputSchema: {
      type: 'object',
      properties: {
        entityName: {
          type: 'string',
          description: 'Nombre de la entidad (ej: "facturas", "clientes")',
        },
        endpoints: {
          type: 'array',
          description: 'Endpoints a implementar',
          items: {
            type: 'object',
            properties: {
              type: { type: 'string', enum: ['list', 'get', 'create', 'update', 'delete', 'custom'] },
              name: { type: 'string' },
              path: { type: 'string' },
            },
          },
        },
      },
      required: ['entityName', 'endpoints'],
    },
  },
  {
    name: 'create_form_component',
    description: 'Crea un formulario con React Hook Form + Zod',
    inputSchema: {
      type: 'object',
      properties: {
        name: {
          type: 'string',
          description: 'Nombre del formulario',
        },
        fields: {
          type: 'array',
          description: 'Campos del formulario',
          items: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              type: { type: 'string', enum: ['text', 'number', 'date', 'select', 'autocomplete', 'checkbox'] },
              label: { type: 'string' },
              required: { type: 'boolean' },
              validation: { type: 'object' },
            },
          },
        },
      },
      required: ['name', 'fields'],
    },
  },
  {
    name: 'create_data_grid',
    description: 'Crea un DataGrid de MUI X para mostrar datos',
    inputSchema: {
      type: 'object',
      properties: {
        entityName: {
          type: 'string',
          description: 'Nombre de la entidad',
        },
        columns: {
          type: 'array',
          description: 'Columnas del grid',
          items: {
            type: 'object',
            properties: {
              field: { type: 'string' },
              headerName: { type: 'string' },
              type: { type: 'string' },
              width: { type: 'number' },
            },
          },
        },
      },
      required: ['entityName', 'columns'],
    },
  },
  {
    name: 'add_route_to_menu',
    description: 'Agrega una nueva ruta al menú de navegación',
    inputSchema: {
      type: 'object',
      properties: {
        title: {
          type: 'string',
          description: 'Título del menú',
        },
        href: {
          type: 'string',
          description: 'Ruta (ej: "/clientes")',
        },
        icon: {
          type: 'string',
          description: 'Nombre del ícono de MUI (ej: "People", "ShoppingCart")',
        },
        requiresAdmin: {
          type: 'boolean',
          description: 'Si requiere permisos de administrador',
        },
      },
      required: ['title', 'href'],
    },
  },
  {
    name: 'list_components',
    description: 'Lista todos los componentes del proyecto',
    inputSchema: {
      type: 'object',
      properties: {
        type: {
          type: 'string',
          enum: ['all', 'common', 'modules'],
          description: 'Tipo de componentes a listar',
        },
      },
    },
  },
  {
    name: 'analyze_component_usage',
    description: 'Analiza dónde se usa un componente específico',
    inputSchema: {
      type: 'object',
      properties: {
        componentName: {
          type: 'string',
          description: 'Nombre del componente',
        },
      },
      required: ['componentName'],
    },
  },
  {
    name: 'create_crud_module',
    description: 'Crea un módulo CRUD completo (página, componentes, hooks)',
    inputSchema: {
      type: 'object',
      properties: {
        entityName: {
          type: 'string',
          description: 'Nombre de la entidad (singular)',
        },
        entityNamePlural: {
          type: 'string',
          description: 'Nombre de la entidad (plural)',
        },
        fields: {
          type: 'array',
          description: 'Campos de la entidad',
          items: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              label: { type: 'string' },
              type: { type: 'string' },
              required: { type: 'boolean' },
            },
          },
        },
      },
      required: ['entityName', 'entityNamePlural', 'fields'],
    },
  },
];

// Crear servidor MCP
const server = new Server(
  {
    name: 'datqbox-frontend-agent',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Handler para listar herramientas
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools: TOOLS };
});

// Handler para ejecutar herramientas
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'create_page': {
        const { path, isDashboard = true, title } = args;
        const basePath = isDashboard ? '(dashboard)' : '';
        const fullPath = join(FRONTEND_DIR, 'app', basePath, path);

        const pageContent = `
'use client';

import { Box, Typography } from '@mui/material';

export default function ${capitalize(path.split('/').pop())}Page() {
  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        ${title}
      </Typography>
      <Typography variant="body1" color="text.secondary">
        Contenido de la página
      </Typography>
    </Box>
  );
}
`.trim();

        return {
          content: [
            {
              type: 'text',
              text: `Página creada en: ${fullPath}/page.tsx\n\n${pageContent}`,
            },
          ],
        };
      }

      case 'create_component': {
        const { name, type, moduleName } = args;
        
        let componentPath = join(FRONTEND_DIR, 'components');
        if (type === 'common') {
          componentPath = join(componentPath, 'common');
        } else if (type === 'module' && moduleName) {
          componentPath = join(componentPath, 'modules', moduleName);
        }

        const componentContent = `
import { FC } from 'react';
import { Box } from '@mui/material';

interface ${name}Props {
  // TODO: Definir props
}

export const ${name}: FC<${name}Props> = (props) => {
  return (
    <Box>
      {/* TODO: Implementar componente ${name} */}
    </Box>
  );
};
`.trim();

        return {
          content: [
            {
              type: 'text',
              text: `Componente creado en: ${componentPath}/${name}.tsx\n\n${componentContent}`,
            },
          ],
        };
      }

      case 'create_tanstack_hook': {
        const { entityName, endpoints } = args;
        
        const imports = `
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';
`.trim();

        const queryKey = `const QUERY_KEY = '${entityName}';`;

        const hooks = endpoints.map(ep => {
          if (ep.type === 'list') {
            return `
export function use${capitalize(entityName)}List(filter?: any) {
  return useQuery({
    queryKey: [QUERY_KEY, filter],
    queryFn: () => api.get('${ep.path}', { params: filter }),
  });
}`;
          } else if (ep.type === 'get') {
            return `
export function use${capitalize(entityName)}(id: number) {
  return useQuery({
    queryKey: [QUERY_KEY, id],
    queryFn: () => api.get(\`${ep.path}/\${id}\`),
    enabled: !!id,
  });
}`;
          } else if (ep.type === 'create') {
            return `
export function useCreate${capitalize(entityName)}() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => api.post('${ep.path}', data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QUERY_KEY] }),
  });
}`;
          } else if (ep.type === 'update') {
            return `
export function useUpdate${capitalize(entityName)}() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: any }) => 
      api.put(\`${ep.path}/\${id}\`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QUERY_KEY] }),
  });
}`;
          } else if (ep.type === 'delete') {
            return `
export function useDelete${capitalize(entityName)}() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => api.delete(\`${ep.path}/\${id}\`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QUERY_KEY] }),
  });
}`;
          }
          return '';
        }).join('\n');

        const fullContent = `${imports}\n\n${queryKey}\n${hooks}`;

        return {
          content: [
            {
              type: 'text',
              text: `Hook creado en: src/hooks/use${capitalize(entityName)}.ts\n\n${fullContent}`,
            },
          ],
        };
      }

      case 'create_form_component': {
        const { name, fields } = args;

        const zodSchema = fields.map(f => {
          let validation = `z.${f.type === 'number' ? 'number()' : 'string()'}`;
          if (f.required) validation += '.min(1, "Campo requerido")';
          return `  ${f.name}: ${validation},`;
        }).join('\n');

        const formFields = fields.map(f => {
          if (f.type === 'text' || f.type === 'number') {
            return `
        <TextField
          {...register('${f.name}')}
          label="${f.label}"
          fullWidth
          error={!!errors.${f.name}}
          helperText={errors.${f.name}?.message}
          type="${f.type === 'number' ? 'number' : 'text'}"
        />`;
          }
          return `        {/* TODO: Campo ${f.name} tipo ${f.type} */}`;
        }).join('\n');

        const formContent = `
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { TextField, Button, Box, Stack } from '@mui/material';

const schema = z.object({
${zodSchema}
});

type FormData = z.infer<typeof schema>;

interface ${name}Props {
  onSubmit: (data: FormData) => void;
  defaultValues?: Partial<FormData>;
}

export function ${name}({ onSubmit, defaultValues }: ${name}Props) {
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues,
  });

  return (
    <Box component="form" onSubmit={handleSubmit(onSubmit)}>
      <Stack spacing={2}>
${formFields}
        <Button type="submit" variant="contained">
          Guardar
        </Button>
      </Stack>
    </Box>
  );
}
`.trim();

        return {
          content: [
            {
              type: 'text',
              text: `Formulario creado:\n\n${formContent}`,
            },
          ],
        };
      }

      case 'create_data_grid': {
        const { entityName, columns } = args;

        const columnsCode = columns.map(col => `
    {
      field: '${col.field}',
      headerName: '${col.headerName}',
      ${col.type ? `type: '${col.type}',` : ''}
      ${col.width ? `width: ${col.width},` : 'flex: 1,'}
    },`).join('');

        const gridContent = `
import { DataGrid, GridColDef } from '@mui/x-data-grid';
import { Box } from '@mui/material';

const columns: GridColDef[] = [${columnsCode}
];

interface ${capitalize(entityName)}GridProps {
  data: any[];
  loading?: boolean;
}

export function ${capitalize(entityName)}Grid({ data, loading }: ${capitalize(entityName)}GridProps) {
  return (
    <Box sx={{ height: 600, width: '100%' }}>
      <DataGrid
        rows={data}
        columns={columns}
        loading={loading}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
      />
    </Box>
  );
}
`.trim();

        return {
          content: [
            {
              type: 'text',
              text: `DataGrid creado:\n\n${gridContent}`,
            },
          ],
        };
      }

      case 'list_components': {
        const { type = 'all' } = args;
        const componentsPath = join(FRONTEND_DIR, 'components');
        
        const listDir = (dir) => {
          try {
            return readdirSync(dir, { withFileTypes: true })
              .filter(dirent => dirent.isFile() && dirent.name.endsWith('.tsx'))
              .map(dirent => dirent.name.replace('.tsx', ''));
          } catch {
            return [];
          }
        };

        const components = {
          common: listDir(join(componentsPath, 'common')),
          modules: {},
        };

        if (type === 'all' || type === 'modules') {
          const modulesPath = join(componentsPath, 'modules');
          try {
            const modules = readdirSync(modulesPath, { withFileTypes: true })
              .filter(dirent => dirent.isDirectory());
            
            modules.forEach(module => {
              components.modules[module.name] = listDir(join(modulesPath, module.name));
            });
          } catch {}
        }

        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(components, null, 2),
            },
          ],
        };
      }

      case 'create_crud_module': {
        const { entityName, entityNamePlural, fields } = args;

        const response = `
# Módulo CRUD: ${capitalize(entityName)}

## 1. Hook (src/hooks/use${capitalize(entityNamePlural)}.ts)
\`\`\`typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';

const QUERY_KEY = '${entityNamePlural}';

export function use${capitalize(entityNamePlural)}List() {
  return useQuery({
    queryKey: [QUERY_KEY],
    queryFn: () => api.get('/v1/${entityNamePlural}'),
  });
}

export function useCreate${capitalize(entityName)}() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => api.post('/v1/${entityNamePlural}', data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QUERY_KEY] }),
  });
}
\`\`\`

## 2. Página (src/app/(dashboard)/${entityNamePlural}/page.tsx)
\`\`\`typescript
'use client';

import { ${capitalize(entityName)}Table } from '@/components/modules/${entityNamePlural}/${capitalize(entityName)}Table';
import { use${capitalize(entityNamePlural)}List } from '@/hooks/use${capitalize(entityNamePlural)}';

export default function ${capitalize(entityNamePlural)}Page() {
  const { data, isLoading } = use${capitalize(entityNamePlural)}List();
  
  return <${capitalize(entityName)}Table data={data} loading={isLoading} />;
}
\`\`\`

## 3. Componente Tabla (src/components/modules/${entityNamePlural}/${capitalize(entityName)}Table.tsx)
\`\`\`typescript
import { DataGrid, GridColDef } from '@mui/x-data-grid';

const columns: GridColDef[] = [
${fields.map(f => `  { field: '${f.name}', headerName: '${f.label}', flex: 1 },`).join('\n')}
];

export function ${capitalize(entityName)}Table({ data, loading }) {
  return <DataGrid rows={data || []} columns={columns} loading={loading} />;
}
\`\`\`

## 4. Agregar al menú (src/lib/menuConfig.ts)
\`\`\`typescript
{
  title: '${capitalize(entityNamePlural)}',
  href: '/${entityNamePlural}',
  icon: ListIcon, // Cambiar por el ícono apropiado
}
\`\`\`
`;

        return {
          content: [{ type: 'text', text: response }],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `Error: ${error.message}\n\nStack: ${error.stack}`,
        },
      ],
      isError: true,
    };
  }
});

function capitalize(str) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

// Iniciar servidor
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('DatQBox Frontend Agent MCP server running on stdio');
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
