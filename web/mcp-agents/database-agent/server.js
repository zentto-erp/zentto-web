#!/usr/bin/env node

/**
 * DatQBox Database Agent - MCP Server
 * Agente especializado para operaciones de base de datos SQL Server
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import sql from 'mssql';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Cargar configuración desde .env del API
const envPath = join(__dirname, '../../api/.env');
dotenv.config({ path: envPath });

const DB_CONFIG = {
  server: process.env.DB_SERVER || 'localhost',
  database: process.env.DB_DATABASE || 'sanjose',
  user: process.env.DB_USER || 'sa',
  password: process.env.DB_PASSWORD || '',
  options: {
    encrypt: process.env.DB_ENCRYPT === 'true',
    trustServerCertificate: process.env.DB_TRUST_CERT === 'true',
    enableArithAbort: true,
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000,
  },
};

let pool = null;

async function getPool() {
  if (!pool) {
    pool = await sql.connect(DB_CONFIG);
  }
  return pool;
}

// Definir herramientas del agente
const TOOLS = [
  {
    name: 'execute_sql_query',
    description: 'Ejecuta una consulta SQL SELECT y retorna los resultados. Ideal para análisis y consultas.',
    inputSchema: {
      type: 'object',
      properties: {
        query: {
          type: 'string',
          description: 'La consulta SQL SELECT a ejecutar',
        },
        parameters: {
          type: 'object',
          description: 'Parámetros opcionales para la consulta (ej: { id: 1, nombre: "test" })',
        },
      },
      required: ['query'],
    },
  },
  {
    name: 'execute_sql_script',
    description: 'Ejecuta un script SQL completo (CREATE, INSERT, UPDATE, DELETE, ALTER, etc.). Útil para migraciones.',
    inputSchema: {
      type: 'object',
      properties: {
        script: {
          type: 'string',
          description: 'El script SQL a ejecutar',
        },
        transaction: {
          type: 'boolean',
          description: 'Si debe ejecutarse en una transacción (default: true)',
        },
      },
      required: ['script'],
    },
  },
  {
    name: 'run_sql_file',
    description: 'Ejecuta un archivo SQL desde la carpeta api/sql. Útil para stored procedures y migraciones.',
    inputSchema: {
      type: 'object',
      properties: {
        filename: {
          type: 'string',
          description: 'Nombre del archivo SQL en api/sql/ (ej: "sp_crud_clientes.sql")',
        },
      },
      required: ['filename'],
    },
  },
  {
    name: 'get_table_schema',
    description: 'Obtiene el esquema completo de una tabla (columnas, tipos, constraints, índices)',
    inputSchema: {
      type: 'object',
      properties: {
        tableName: {
          type: 'string',
          description: 'Nombre de la tabla',
        },
      },
      required: ['tableName'],
    },
  },
  {
    name: 'list_tables',
    description: 'Lista todas las tablas de la base de datos',
    inputSchema: {
      type: 'object',
      properties: {
        pattern: {
          type: 'string',
          description: 'Patrón opcional para filtrar tablas (ej: "Cliente%")',
        },
      },
    },
  },
  {
    name: 'get_foreign_keys',
    description: 'Obtiene todas las foreign keys de una tabla',
    inputSchema: {
      type: 'object',
      properties: {
        tableName: {
          type: 'string',
          description: 'Nombre de la tabla',
        },
      },
      required: ['tableName'],
    },
  },
  {
    name: 'analyze_query_plan',
    description: 'Analiza el plan de ejecución de una consulta para optimización',
    inputSchema: {
      type: 'object',
      properties: {
        query: {
          type: 'string',
          description: 'La consulta SQL a analizar',
        },
      },
      required: ['query'],
    },
  },
  {
    name: 'backup_table',
    description: 'Crea una copia de respaldo de una tabla',
    inputSchema: {
      type: 'object',
      properties: {
        tableName: {
          type: 'string',
          description: 'Nombre de la tabla a respaldar',
        },
        backupName: {
          type: 'string',
          description: 'Nombre opcional para la tabla de respaldo (default: [tabla]_backup_[timestamp])',
        },
      },
      required: ['tableName'],
    },
  },
];

// Crear servidor MCP
const server = new Server(
  {
    name: 'datqbox-database-agent',
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
    const pool = await getPool();

    switch (name) {
      case 'execute_sql_query': {
        const { query, parameters } = args;
        const result = await pool.request();
        
        // Agregar parámetros si existen
        if (parameters) {
          Object.entries(parameters).forEach(([key, value]) => {
            result.input(key, value);
          });
        }
        
        const data = await result.query(query);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(data.recordset, null, 2),
            },
          ],
        };
      }

      case 'execute_sql_script': {
        const { script, transaction = true } = args;
        
        if (transaction) {
          const txn = new sql.Transaction(pool);
          await txn.begin();
          try {
            await txn.request().batch(script);
            await txn.commit();
            return {
              content: [{ type: 'text', text: 'Script ejecutado exitosamente (con transacción)' }],
            };
          } catch (error) {
            await txn.rollback();
            throw error;
          }
        } else {
          await pool.request().batch(script);
          return {
            content: [{ type: 'text', text: 'Script ejecutado exitosamente' }],
          };
        }
      }

      case 'run_sql_file': {
        const { filename } = args;
        const sqlPath = join(__dirname, '../../api/sql', filename);
        const script = readFileSync(sqlPath, 'utf-8');
        
        const txn = new sql.Transaction(pool);
        await txn.begin();
        try {
          await txn.request().batch(script);
          await txn.commit();
          return {
            content: [{ type: 'text', text: `Archivo ${filename} ejecutado exitosamente` }],
          };
        } catch (error) {
          await txn.rollback();
          throw error;
        }
      }

      case 'get_table_schema': {
        const { tableName } = args;
        const result = await pool.request()
          .input('tableName', sql.NVarChar, tableName)
          .query(`
            SELECT 
              c.COLUMN_NAME,
              c.DATA_TYPE,
              c.CHARACTER_MAXIMUM_LENGTH,
              c.IS_NULLABLE,
              c.COLUMN_DEFAULT,
              CASE WHEN pk.COLUMN_NAME IS NOT NULL THEN 'YES' ELSE 'NO' END as IS_PRIMARY_KEY
            FROM INFORMATION_SCHEMA.COLUMNS c
            LEFT JOIN (
              SELECT ku.TABLE_CATALOG, ku.TABLE_SCHEMA, ku.TABLE_NAME, ku.COLUMN_NAME
              FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
              INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS ku
                ON tc.CONSTRAINT_TYPE = 'PRIMARY KEY' 
                AND tc.CONSTRAINT_NAME = ku.CONSTRAINT_NAME
            ) pk 
            ON c.TABLE_CATALOG = pk.TABLE_CATALOG
              AND c.TABLE_SCHEMA = pk.TABLE_SCHEMA
              AND c.TABLE_NAME = pk.TABLE_NAME
              AND c.COLUMN_NAME = pk.COLUMN_NAME
            WHERE c.TABLE_NAME = @tableName
            ORDER BY c.ORDINAL_POSITION
          `);

        return {
          content: [{ type: 'text', text: JSON.stringify(result.recordset, null, 2) }],
        };
      }

      case 'list_tables': {
        const { pattern } = args;
        let query = `
          SELECT TABLE_NAME, TABLE_TYPE
          FROM INFORMATION_SCHEMA.TABLES
          WHERE TABLE_TYPE = 'BASE TABLE'
        `;
        
        if (pattern) {
          query += ` AND TABLE_NAME LIKE '${pattern}'`;
        }
        
        query += ' ORDER BY TABLE_NAME';
        
        const result = await pool.request().query(query);
        return {
          content: [{ type: 'text', text: JSON.stringify(result.recordset, null, 2) }],
        };
      }

      case 'get_foreign_keys': {
        const { tableName } = args;
        const result = await pool.request()
          .input('tableName', sql.NVarChar, tableName)
          .query(`
            SELECT 
              fk.name AS FK_NAME,
              tp.name AS PARENT_TABLE,
              cp.name AS PARENT_COLUMN,
              tr.name AS REFERENCED_TABLE,
              cr.name AS REFERENCED_COLUMN
            FROM sys.foreign_keys AS fk
            INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
            INNER JOIN sys.tables AS tp ON fkc.parent_object_id = tp.object_id
            INNER JOIN sys.columns AS cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
            INNER JOIN sys.tables AS tr ON fkc.referenced_object_id = tr.object_id
            INNER JOIN sys.columns AS cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
            WHERE tp.name = @tableName
          `);

        return {
          content: [{ type: 'text', text: JSON.stringify(result.recordset, null, 2) }],
        };
      }

      case 'analyze_query_plan': {
        const { query } = args;
        await pool.request().query('SET SHOWPLAN_TEXT ON');
        const result = await pool.request().query(query);
        await pool.request().query('SET SHOWPLAN_TEXT OFF');
        
        return {
          content: [{ type: 'text', text: JSON.stringify(result.recordset, null, 2) }],
        };
      }

      case 'backup_table': {
        const { tableName, backupName } = args;
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const finalBackupName = backupName || `${tableName}_backup_${timestamp}`;
        
        await pool.request().query(`
          SELECT * INTO ${finalBackupName} FROM ${tableName}
        `);
        
        const count = await pool.request().query(`SELECT COUNT(*) as count FROM ${finalBackupName}`);
        
        return {
          content: [{
            type: 'text',
            text: `Tabla ${tableName} respaldada como ${finalBackupName}. Registros: ${count.recordset[0].count}`,
          }],
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

// Iniciar servidor
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('DatQBox Database Agent MCP server running on stdio');
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
