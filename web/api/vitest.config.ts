import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    testTimeout: 30_000,
    // Separar tests de schema (solo PG) de smoke (necesitan API corriendo)
    include: ['tests/**/*.test.ts'],
    // No fallar el build si hay errores de conexion en CI sin DB
    passWithNoTests: true,
  },
});
