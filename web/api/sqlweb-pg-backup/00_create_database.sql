-- ============================================================
-- DatqBoxWeb PostgreSQL - 00_create_database.sql
-- Crear base de datos y extensiones
-- Ejecutar conectado a 'postgres': psql -U postgres -f 00_create_database.sql
-- ============================================================

-- Crear la base de datos si no existe
SELECT 'CREATE DATABASE datqboxweb ENCODING ''UTF8'' LC_COLLATE ''es_ES.UTF-8'' LC_CTYPE ''es_ES.UTF-8'' TEMPLATE template0'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'datqboxweb')
\gexec

\c datqboxweb

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS pgcrypto;      -- gen_random_uuid(), crypt()
CREATE EXTENSION IF NOT EXISTS unaccent;       -- Busquedas sin acentos
CREATE EXTENSION IF NOT EXISTS pg_trgm;        -- Indices trigram (busqueda fuzzy)

-- Configuracion optima para la aplicacion
ALTER DATABASE datqboxweb SET timezone TO 'UTC';
ALTER DATABASE datqboxweb SET default_text_search_config TO 'pg_catalog.spanish';

DO $$ BEGIN RAISE NOTICE 'DatqBoxWeb database initialized.'; END $$;
