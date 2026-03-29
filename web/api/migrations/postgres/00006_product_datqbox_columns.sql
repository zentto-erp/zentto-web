-- +goose Up

-- +goose StatementBegin
-- Add DatqBox legacy columns + Descripcion to master.Product

DO $$
BEGIN
  -- Clasificacion
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='Categoria') THEN
    ALTER TABLE master."Product" ADD COLUMN "Categoria" VARCHAR(50);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='Marca') THEN
    ALTER TABLE master."Product" ADD COLUMN "Marca" VARCHAR(50);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='Tipo') THEN
    ALTER TABLE master."Product" ADD COLUMN "Tipo" VARCHAR(50);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='Clase') THEN
    ALTER TABLE master."Product" ADD COLUMN "Clase" VARCHAR(25);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='Linea') THEN
    ALTER TABLE master."Product" ADD COLUMN "Linea" VARCHAR(30);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='Unidad') THEN
    ALTER TABLE master."Product" ADD COLUMN "Unidad" VARCHAR(30);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='Referencia') THEN
    ALTER TABLE master."Product" ADD COLUMN "Referencia" VARCHAR(30);
  END IF;

  -- Precios y stock extendidos
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='VENTA') THEN
    ALTER TABLE master."Product" ADD COLUMN "VENTA" DOUBLE PRECISION DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='MINIMO') THEN
    ALTER TABLE master."Product" ADD COLUMN "MINIMO" DOUBLE PRECISION DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='MAXIMO') THEN
    ALTER TABLE master."Product" ADD COLUMN "MAXIMO" DOUBLE PRECISION DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='PORCENTAJE') THEN
    ALTER TABLE master."Product" ADD COLUMN "PORCENTAJE" DOUBLE PRECISION DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='PRECIO_VENTA1') THEN
    ALTER TABLE master."Product" ADD COLUMN "PRECIO_VENTA1" DOUBLE PRECISION DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='PRECIO_VENTA2') THEN
    ALTER TABLE master."Product" ADD COLUMN "PRECIO_VENTA2" DOUBLE PRECISION DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='PRECIO_VENTA3') THEN
    ALTER TABLE master."Product" ADD COLUMN "PRECIO_VENTA3" DOUBLE PRECISION DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='COSTO_PROMEDIO') THEN
    ALTER TABLE master."Product" ADD COLUMN "COSTO_PROMEDIO" DOUBLE PRECISION DEFAULT 0;
  END IF;

  -- Ubicacion e identificacion
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='UBICACION') THEN
    ALTER TABLE master."Product" ADD COLUMN "UBICACION" VARCHAR(40);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='N_PARTE') THEN
    ALTER TABLE master."Product" ADD COLUMN "N_PARTE" VARCHAR(18);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='Barra') THEN
    ALTER TABLE master."Product" ADD COLUMN "Barra" VARCHAR(50);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='PLU') THEN
    ALTER TABLE master."Product" ADD COLUMN "PLU" INT;
  END IF;

  -- Otros campos DatqBox
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='Co_Usuario') THEN
    ALTER TABLE master."Product" ADD COLUMN "Co_Usuario" VARCHAR(20);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='Garantia') THEN
    ALTER TABLE master."Product" ADD COLUMN "Garantia" VARCHAR(30);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='UbicaFisica') THEN
    ALTER TABLE master."Product" ADD COLUMN "UbicaFisica" VARCHAR(50);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='Alicuota') THEN
    ALTER TABLE master."Product" ADD COLUMN "Alicuota" DOUBLE PRECISION DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='Servicio') THEN
    ALTER TABLE master."Product" ADD COLUMN "Servicio" BOOLEAN DEFAULT FALSE;
  END IF;

  -- Descripcion extendida (nueva, para uso web)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Product' AND column_name='Descripcion') THEN
    ALTER TABLE master."Product" ADD COLUMN "Descripcion" TEXT;
  END IF;
END
$$;

-- +goose StatementEnd

-- +goose Down
-- No drop columns to avoid data loss
