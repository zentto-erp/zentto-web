'use client';

/**
 * gridLayoutDb.ts
 * IndexedDB wrapper para persistir layouts de ZenttoDataGrid por gridId.
 * DB: zentto-grid-layouts  |  Store: layouts  |  Key: gridId (string)
 */

const DB_NAME = 'zentto-grid-layouts';
const STORE_NAME = 'layouts';
const DB_VERSION = 1;

export interface GridLayoutState {
  /** Visibilidad de columnas: { [field]: boolean } */
  columnVisibility: Record<string, boolean>;
  /** Orden de columnas: array de field names en el orden guardado */
  columnOrder: string[];
  /** Anchos de columnas: { [field]: number } */
  columnWidths: Record<string, number>;
  /** Densidad de la tabla */
  density: 'compact' | 'standard' | 'comfortable';
}

let _db: IDBDatabase | null = null;

function openDb(): Promise<IDBDatabase> {
  if (_db) return Promise.resolve(_db);
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, DB_VERSION);
    req.onupgradeneeded = (e) => {
      (e.target as IDBOpenDBRequest).result.createObjectStore(STORE_NAME);
    };
    req.onsuccess = () => {
      _db = req.result;
      resolve(_db);
    };
    req.onerror = () => reject(req.error);
  });
}

export async function getLayout(gridId: string): Promise<GridLayoutState | null> {
  try {
    const db = await openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readonly');
      const req = tx.objectStore(STORE_NAME).get(gridId);
      req.onsuccess = () => resolve((req.result as GridLayoutState) ?? null);
      req.onerror = () => reject(req.error);
    });
  } catch {
    return null;
  }
}

export async function saveLayout(gridId: string, state: GridLayoutState): Promise<void> {
  try {
    const db = await openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readwrite');
      const req = tx.objectStore(STORE_NAME).put(state, gridId);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  } catch {
    // silencioso en SSR/entornos sin IndexedDB
  }
}

export async function clearLayout(gridId: string): Promise<void> {
  try {
    const db = await openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readwrite');
      const req = tx.objectStore(STORE_NAME).delete(gridId);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  } catch {
    // silencioso
  }
}
