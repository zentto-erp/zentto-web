'use client';

/**
 * gridLayoutDb.ts
 * IndexedDB wrapper para persistir layouts de ZenttoDataGrid por gridId.
 * DB: zentto-grid-layouts  |  Store: layouts  |  Key: gridId (string)
 *
 * FIX: La version anterior tenia un singleton _db que podria quedar stale
 * si el usuario navegaba entre paginas (SPA) y la conexion se cerraba.
 * Ahora siempre re-validamos la conexion antes de usarla.
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
  // Validate cached connection is still usable
  if (_db) {
    try {
      // Test if the connection is still valid by attempting a transaction
      _db.transaction(STORE_NAME, 'readonly');
      return Promise.resolve(_db);
    } catch {
      // Connection stale — re-open
      _db = null;
    }
  }

  return new Promise((resolve, reject) => {
    try {
      const req = indexedDB.open(DB_NAME, DB_VERSION);
      req.onupgradeneeded = (e) => {
        const db = (e.target as IDBOpenDBRequest).result;
        if (!db.objectStoreNames.contains(STORE_NAME)) {
          db.createObjectStore(STORE_NAME);
        }
      };
      req.onsuccess = () => {
        _db = req.result;
        // If the connection is closed externally, invalidate the cache
        _db.onclose = () => { _db = null; };
        _db.onversionchange = () => {
          _db?.close();
          _db = null;
        };
        resolve(_db);
      };
      req.onerror = () => reject(req.error);
    } catch (e) {
      // IndexedDB not available (SSR, incognito with restrictions, etc.)
      reject(e);
    }
  });
}

export async function getLayout(gridId: string): Promise<GridLayoutState | null> {
  if (!gridId) return null;
  try {
    const db = await openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readonly');
      const store = tx.objectStore(STORE_NAME);
      const req = store.get(gridId);
      req.onsuccess = () => {
        const result = req.result as GridLayoutState | undefined;
        // Validate the shape of the stored data
        if (result && typeof result === 'object' && 'density' in result) {
          resolve(result);
        } else {
          resolve(null);
        }
      };
      req.onerror = () => reject(req.error);
      tx.onerror = () => reject(tx.error);
    });
  } catch {
    return null;
  }
}

export async function saveLayout(gridId: string, state: GridLayoutState): Promise<void> {
  if (!gridId) return;
  try {
    const db = await openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readwrite');
      const store = tx.objectStore(STORE_NAME);
      const req = store.put(state, gridId);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
    });
  } catch {
    // Silencioso en SSR/entornos sin IndexedDB
  }
}

export async function clearLayout(gridId: string): Promise<void> {
  if (!gridId) return;
  try {
    const db = await openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readwrite');
      const store = tx.objectStore(STORE_NAME);
      const req = store.delete(gridId);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
    });
  } catch {
    // Silencioso
  }
}
