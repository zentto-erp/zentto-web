#!/usr/bin/env node

/**
 * DatQBox API Agent - MCP Server
 * Agente especializado para operaciones del backend Express + TypeScript
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import axios from 'axios';
import { readFileSync, readdirSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Cargar configuración desde .env del API
const envPath = join(__dirname, '../../api/.env');
dotenv.config({ path: envPath });

const API_BASE_URL = `http://localhost:${process.env.PORT || 4000}`;
const API_DIR = join(__dirname, '../../api/src');

// Definir herramientas del agente
const TOOLS = [
  {
    name: 'create_api_module',
    description: 'Crea un nuevo módulo completo de la API (routes.ts, service.ts, types.ts)',
    inputSchema: {
      type: 'object',
      properties: {
        moduleName: {
          type: 'string',
          description: 'Nombre del módulo (ej: "articulos", "ventas")',
        },
        endpoints: {
          type: 'array',
          description: 'Lista de endpoints a crear',
          items: {
            type: 'object',
            properties: {
              method: { type: 'string', enum: ['GET', 'POST', 'PUT', 'DELETE'] },
              path: { type: 'string' },
              description: { type: 'string' },
            },
          },
        },
      },
      required: ['moduleName', 'endpoints'],
    },
  },
  {
    name: 'test_api_endpoint',
    description: 'Prueba un endpoint de la API en desarrollo',
    inputSchema: {
      type: 'object',
      properties: {
        method: {
          type: 'string',
          enum: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
          description: 'Método HTTP',
        },
        path: {
          type: 'string',
          description: 'Ruta del endpoint (ej: "/v1/clientes")',
        },
        data: {
          type: 'object',
          description: 'Datos a enviar (para POST/PUT/PATCH)',
        },
        headers: {
          type: 'object',
          description: 'Headers personalizados',
        },
      },
      required: ['method', 'path'],
    },
  },
  {
    name: 'list_api_modules',
    description: 'Lista todos los módulos disponibles en la API',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
  {
    name: 'get_module_structure',
    description: 'Obtiene la estructura de archivos de un módulo específico',
    inputSchema: {
      type: 'object',
      properties: {
        moduleName: {
          type: 'string',
          description: 'Nombre del módulo',
        },
      },
      required: ['moduleName'],
    },
  },
  {
    name: 'generate_crud_endpoints',
    description: 'Genera endpoints CRUD completos para una entidad',
    inputSchema: {
      type: 'object',
      properties: {
        entityName: {
          type: 'string',
          description: 'Nombre de la entidad (ej: "articulo", "proveedor")',
        },
        tableName: {
          type: 'string',
          description: 'Nombre de la tabla SQL',
        },
        fields: {
          type: 'array',
          description: 'Campos de la entidad',
          items: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              type: { type: 'string' },
              required: { type: 'boolean' },
            },
          },
        },
      },
      required: ['entityName', 'tableName', 'fields'],
    },
  },
  {
    name: 'validate_openapi_contract',
    description: 'Valida que un endpoint cumpla con el contrato OpenAPI',
    inputSchema: {
      type: 'object',
      properties: {
        path: {
          type: 'string',
          description: 'Ruta del endpoint',
        },
        method: {
          type: 'string',
          description: 'Método HTTP',
        },
      },
      required: ['path', 'method'],
    },
  },
  {
    name: 'create_middleware',
    description: 'Crea un nuevo middleware para la API',
    inputSchema: {
      type: 'object',
      properties: {
        name: {
          type: 'string',
          description: 'Nombre del middleware',
        },
        type: {
          type: 'string',
          enum: ['auth', 'validation', 'logging', 'error', 'custom'],
          description: 'Tipo de middleware',
        },
      },
      required: ['name', 'type'],
    },
  },
  {
    name: 'analyze_api_routes',
    description: 'Analiza todas las rutas registradas en la API',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
];

// Crear servidor MCP
const server = new Server(
  {
    name: 'datqbox-api-agent',
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
      case 'test_api_endpoint': {
        const { method, path, data, headers } = args;
        const url = `${API_BASE_URL}${path}`;
        
        const config = {
          method,
          url,
          data,
          headers: headers || {},
        };

        const response = await axios(config);
        
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify({
                status: response.status,
                statusText: response.statusText,
                data: response.data,
                headers: response.headers,
              }, null, 2),
            },
          ],
        };
      }

      case 'list_api_modules': {
        const modulesPath = join(API_DIR, 'modules');
        const modules = readdirSync(modulesPath, { withFileTypes: true })
          .filter(dirent => dirent.isDirectory())
          .map(dirent => dirent.name);

        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify({ modules, count: modules.length }, null, 2),
            },
          ],
        };
      }

      case 'get_module_structure': {
        const { moduleName } = args;
        const modulePath = join(API_DIR, 'modules', moduleName);
        const files = readdirSync(modulePath);

        const structure = {};
        for (const file of files) {
          const content = readFileSync(join(modulePath, file), 'utf-8');
          structure[file] = {
            lines: content.split('\n').length,
            size: content.length,
          };
        }

        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify({ moduleName, files: structure }, null, 2),
            },
          ],
        };
      }

      case 'create_api_module': {
        const { moduleName, endpoints } = args;
        const modulePath = join(API_DIR, 'modules', moduleName);

        // Generar tipos
        const typesContent = `
export interface ${capitalize(moduleName)} {
  id?: number;
  // TODO: Agregar campos específicos
}

export interface ${capitalize(moduleName)}Filter {
  limit?: number;
  offset?: number;
  // TODO: Agregar filtros específicos
}
`.trim();

        // Generar servicio
        const serviceContent = `
import type { ${capitalize(moduleName)}, ${capitalize(moduleName)}Filter } from './types.js';

export class ${capitalize(moduleName)}Service {
  async list(filter: ${capitalize(moduleName)}Filter) {
    // TODO: Implementar lógica
    return [];
  }

  async getById(id: number) {
    // TODO: Implementar lógica
    return null;
  }

  async create(data: ${capitalize(moduleName)}) {
    // TODO: Implementar lógica
    return data;
  }

  async update(id: number, data: Partial<${capitalize(moduleName)}>) {
    // TODO: Implementar lógica
    return data;
  }

  async delete(id: number) {
    // TODO: Implementar lógica
    return true;
  }
}
`.trim();

        // Generar rutas
        const routesContent = `
import { Router } from 'express';
import { ${capitalize(moduleName)}Service } from './service.js';

const router = Router();
const service = new ${capitalize(moduleName)}Service();

${endpoints.map(ep => `
// ${ep.description}
router.${ep.method.toLowerCase()}('${ep.path}', async (req, res, next) => {
  try {
    // TODO: Implementar lógica del endpoint
    res.json({ message: 'TODO: Implementar ${ep.method} ${ep.path}' });
  } catch (error) {
    next(error);
  }
});
`).join('\n')}

export { router as ${moduleName}Router };
`.trim();

        return {
          content: [
            {
              type: 'text',
              text: `Módulo ${moduleName} listo para crear. Archivos generados:\n\n` +
                    `types.ts:\n${typesContent}\n\n` +
                    `service.ts:\n${serviceContent}\n\n` +
                    `routes.ts:\n${routesContent}`,
            },
          ],
        };
      }

      case 'generate_crud_endpoints': {
        const { entityName, tableName, fields } = args;
        
        const fieldTypes = fields.map(f => `  ${f.name}${f.required ? '' : '?'}: ${f.type};`).join('\n');
        
        const crudCode = `
// types.ts
export interface ${capitalize(entityName)} {
${fieldTypes}
}

// service.ts
import sql from 'mssql';

export class ${capitalize(entityName)}Service {
  async list() {
    const pool = await sql.connect();
    const result = await pool.request().query('SELECT * FROM ${tableName}');
    return result.recordset;
  }

  async getById(id: number) {
    const pool = await sql.connect();
    const result = await pool.request()
      .input('id', sql.Int, id)
      .query('SELECT * FROM ${tableName} WHERE id = @id');
    return result.recordset[0];
  }

  async create(data: ${capitalize(entityName)}) {
    const pool = await sql.connect();
    const fields = ${JSON.stringify(fields.map(f => f.name))};
    const values = fields.map(f => '@' + f).join(', ');
    const columns = fields.join(', ');
    
    const request = pool.request();
    ${fields.map(f => `    request.input('${f.name}', data.${f.name});`).join('\n')}
    
    const result = await request.query(
      \`INSERT INTO ${tableName} (\${columns}) VALUES (\${values}); SELECT SCOPE_IDENTITY() as id\`
    );
    return result.recordset[0].id;
  }

  async update(id: number, data: Partial<${capitalize(entityName)}>) {
    const pool = await sql.connect();
    const updates = Object.keys(data).map(k => \`\${k} = @\${k}\`).join(', ');
    
    const request = pool.request().input('id', sql.Int, id);
    Object.entries(data).forEach(([key, val]) => request.input(key, val));
    
    await request.query(\`UPDATE ${tableName} SET \${updates} WHERE id = @id\`);
    return true;
  }

  async delete(id: number) {
    const pool = await sql.connect();
    await pool.request()
      .input('id', sql.Int, id)
      .query('DELETE FROM ${tableName} WHERE id = @id');
    return true;
  }
}
`.trim();

        return {
          content: [{ type: 'text', text: crudCode }],
        };
      }

      case 'analyze_api_routes': {
        const modulesPath = join(API_DIR, 'modules');
        const modules = readdirSync(modulesPath, { withFileTypes: true })
          .filter(dirent => dirent.isDirectory())
          .map(dirent => dirent.name);

        const routes = [];
        for (const module of modules) {
          const routesPath = join(modulesPath, module, 'routes.ts');
          try {
            const content = readFileSync(routesPath, 'utf-8');
            const routeMatches = content.match(/router\.(get|post|put|delete|patch)\(['"]([^'"]+)/g) || [];
            routeMatches.forEach(match => {
              const [, method, path] = match.match(/router\.(\w+)\(['"]([^'"]+)/);
              routes.push({ module, method: method.toUpperCase(), path });
            });
          } catch (e) {
            // Módulo sin routes.ts
          }
        }

        return {
          content: [{ type: 'text', text: JSON.stringify(routes, null, 2) }],
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
  console.error('DatQBox API Agent MCP server running on stdio');
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
