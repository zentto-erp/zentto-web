-- ============================================================
-- DatqBoxWeb PostgreSQL - 16_seed_nomina.sql
-- Seed: Tabla Empleados legacy + datos de prueba
-- ============================================================

BEGIN;

-- Tabla legacy Empleados (equivalente a dbo.Empleados)
CREATE TABLE IF NOT EXISTS public."Empleados"(
  "CEDULA"        VARCHAR(20)  NOT NULL PRIMARY KEY,
  "GRUPO"         VARCHAR(50),
  "NOMBRE"        VARCHAR(100) NOT NULL,
  "DIRECCION"     VARCHAR(255),
  "TELEFONO"      VARCHAR(60),
  "NACIMIENTO"    TIMESTAMP,
  "CARGO"         VARCHAR(50),
  "NOMINA"        VARCHAR(50),
  "SUELDO"        DOUBLE PRECISION DEFAULT 0,
  "INGRESO"       TIMESTAMP,
  "RETIRO"        TIMESTAMP,
  "STATUS"        VARCHAR(50) DEFAULT 'ACTIVO',
  "COMISION"      DOUBLE PRECISION DEFAULT 0,
  "UTILIDAD"      DOUBLE PRECISION DEFAULT 0,
  "CO_Usuario"    VARCHAR(10),
  "SEXO"          VARCHAR(10),
  "NACIONALIDAD"  VARCHAR(50),
  "Autoriza"      BOOLEAN NOT NULL DEFAULT FALSE,
  "Apodo"         VARCHAR(50)
);

-- Datos seed de empleados
INSERT INTO public."Empleados"
  ("CEDULA", "GRUPO", "NOMBRE", "DIRECCION", "TELEFONO", "NACIMIENTO",
   "CARGO", "NOMINA", "SUELDO", "INGRESO", "STATUS", "SEXO", "NACIONALIDAD", "Autoriza")
VALUES
  ('V-12345678', 'GERENCIA', 'Carlos Alberto Mendoza Rivera',
   'Av. Libertador, Edif. Torres del Sol, Piso 12, Caracas',
   '0412-5551234', '1980-03-15', 'Gerente General', 'MENSUAL',
   8500.00, '2015-01-10', 'ACTIVO', 'M', 'Venezolano', TRUE),

  ('V-23456789', 'GERENCIA', 'Maria Fernanda Gutierrez Lopez',
   'Calle 5, Quinta Los Pinos, La Castellana, Caracas',
   '0414-5552345', '1985-07-22', 'Gerente de Operaciones', 'MENSUAL',
   7200.00, '2016-03-15', 'ACTIVO', 'F', 'Venezolano', TRUE),

  ('V-34567890', 'VENTAS', 'Jose Luis Ramirez Diaz',
   'Av. Principal de Bello Monte, Res. El Parque, Caracas',
   '0424-5553456', '1990-11-08', 'Jefe de Ventas', 'MENSUAL',
   5500.00, '2017-06-01', 'ACTIVO', 'M', 'Venezolano', FALSE),

  ('V-45678901', 'ADMINISTRACION', 'Ana Patricia Herrera Morales',
   'Calle Miranda, Edif. Centro, Piso 3, Barquisimeto',
   '0416-5554567', '1988-04-30', 'Contadora', 'MENSUAL',
   6000.00, '2016-09-20', 'ACTIVO', 'F', 'Venezolano', FALSE),

  ('V-56789012', 'OPERACIONES', 'Pedro Antonio Vargas Torres',
   'Av. Bolivar, Sector Los Olivos, Valencia',
   '0412-5555678', '1992-08-15', 'Supervisor de Almacen', 'QUINCENAL',
   4200.00, '2018-02-12', 'ACTIVO', 'M', 'Venezolano', FALSE),

  ('V-67890123', 'VENTAS', 'Laura Beatriz Castillo Ramos',
   'Urbanizacion El Trigal, Calle 2, Valencia',
   '0414-5556789', '1995-01-20', 'Vendedora', 'QUINCENAL',
   3800.00, '2019-04-01', 'ACTIVO', 'F', 'Venezolano', FALSE),

  ('V-78901234', 'OPERACIONES', 'Miguel Angel Perez Suarez',
   'Barrio La Cruz, Calle Principal, Maracaibo',
   '0424-5557890', '1987-06-12', 'Almacenista', 'QUINCENAL',
   3200.00, '2020-01-15', 'ACTIVO', 'M', 'Venezolano', FALSE),

  ('V-89012345', 'ADMINISTRACION', 'Carmen Elena Rojas Paez',
   'Av. Las Americas, Centro Comercial, Merida',
   '0416-5558901', '1993-09-25', 'Asistente Administrativo', 'MENSUAL',
   3500.00, '2021-07-01', 'ACTIVO', 'F', 'Venezolano', FALSE)
ON CONFLICT ("CEDULA") DO NOTHING;

COMMIT;
