import Database from 'better-sqlite3';
import path from 'path';
import { existsSync, mkdirSync, accessSync, constants } from 'fs';

const DB_DIR = path.join(process.cwd(), 'data');
const DB_PATH = path.join(DB_DIR, 'request-logs.db');

// Asegurar que el directorio existe y tiene permisos de escritura
function ensureDatabaseDirectory() {
  try {
    // Crear directorio si no existe
    if (!existsSync(DB_DIR)) {
      mkdirSync(DB_DIR, { recursive: true });
      // Log solo en desarrollo
      if (process.env.NODE_ENV === 'development') {
        console.log(`[SQLite] Directorio creado: ${DB_DIR}`);
      }
    }
    
    // Verificar permisos de escritura
    try {
      accessSync(DB_DIR, constants.W_OK);
    } catch (error) {
      // Error crítico: siempre registrar (tanto en desarrollo como producción)
      console.log(`[SQLite] ERROR: No hay permisos de escritura en ${DB_DIR}`);
      throw new Error(`No hay permisos de escritura en el directorio de la base de datos: ${DB_DIR}`);
    }
  } catch (error: any) {
    console.log(`[SQLite] ERROR al crear/verificar directorio:`, error);
    throw error;
  }
}

// Inicializar el directorio al cargar el módulo
ensureDatabaseDirectory();

// Crear o abrir la base de datos
let db: Database.Database | null = null;

export function getDatabase(): Database.Database {
  if (!db) {
    db = new Database(DB_PATH);
    db.pragma('journal_mode = WAL'); // Write-Ahead Logging para mejor rendimiento
    initializeDatabase(db);
  }
  return db;
}

function initializeDatabase(database: Database.Database) {
  // Verificar si la tabla existe y si tiene la restricción NOT NULL en request_body
  const tableInfo = database.prepare(`
    SELECT sql FROM sqlite_master 
    WHERE type='table' AND name='request_logs'
  `).get() as { sql: string } | undefined;

  // Crear tabla de logs si no existe
  database.exec(`
    CREATE TABLE IF NOT EXISTS request_logs (
      id TEXT PRIMARY KEY,
      timestamp TEXT NOT NULL,
      user_name TEXT,
      user_email TEXT,
      method TEXT NOT NULL,
      url TEXT NOT NULL,
      endpoint TEXT NOT NULL,
      request_body TEXT,
      request_headers TEXT,
      response_status INTEGER,
      response_status_text TEXT,
      response_body TEXT,
      response_headers TEXT,
      error_message TEXT,
      error_code TEXT,
      error_response_status INTEGER,
      error_response_body TEXT,
      duration_ms INTEGER,
      success INTEGER NOT NULL DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  `);

  // Crear índices si no existen (para tablas nuevas o después de migración)
  database.exec(`
    CREATE INDEX IF NOT EXISTS idx_timestamp ON request_logs(timestamp);
    CREATE INDEX IF NOT EXISTS idx_endpoint ON request_logs(endpoint);
    CREATE INDEX IF NOT EXISTS idx_method ON request_logs(method);
    CREATE INDEX IF NOT EXISTS idx_user_email ON request_logs(user_email);
    CREATE INDEX IF NOT EXISTS idx_success ON request_logs(success);
    CREATE INDEX IF NOT EXISTS idx_created_at ON request_logs(created_at);
    CREATE INDEX IF NOT EXISTS idx_endpoint_method ON request_logs(endpoint, method);
    CREATE INDEX IF NOT EXISTS idx_timestamp_endpoint ON request_logs(timestamp, endpoint);
  `);

  // Crear tabla de bloqueos de proyectos si no existe
  database.exec(`
    CREATE TABLE IF NOT EXISTS project_locks (
      project_id INTEGER PRIMARY KEY,
      user_name TEXT NOT NULL,
      user_email TEXT NOT NULL,
      locked_at TEXT NOT NULL,
      expires_at TEXT NOT NULL
    );

    CREATE INDEX IF NOT EXISTS idx_project_locks_expires_at ON project_locks(expires_at);
  `);
}

// Función para extraer el endpoint de una URL
export function extractEndpoint(url: string): string {
  try {
    const urlObj = new URL(url);
    return urlObj.pathname;
  } catch {
    // Si no es una URL válida, extraer el pathname manualmente
    const match = url.match(/\/[^?]*/);
    return match ? match[0] : url;
  }
}

// Cerrar la base de datos al terminar
if (typeof process !== 'undefined') {
  process.on('exit', () => {
    if (db) {
      db.close();
    }
  });
  
  process.on('SIGINT', () => {
    if (db) {
      db.close();
      process.exit(0);
    }
  });
}
