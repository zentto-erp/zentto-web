-- ============================================================
-- DatqBoxWeb PostgreSQL - 17_seed_ecommerce.sql
-- Seed: E-commerce demo data
-- ============================================================

BEGIN;

-- -------------------------------------------------------
-- 1. Nuevas categorias para ecommerce
-- -------------------------------------------------------
INSERT INTO master."Category" ("CompanyId", "CategoryCode", "CategoryName", "Description", "IsActive", "IsDeleted", "CreatedAt", "UpdatedAt") VALUES
  (1, 'ELECTRO', 'Electronica',       'Dispositivos electronicos',     TRUE, FALSE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
  (1, 'HOGAR',   'Hogar y Cocina',    'Articulos para el hogar',       TRUE, FALSE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
  (1, 'DEPORTE', 'Deportes',          'Equipamiento deportivo',        TRUE, FALSE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
  (1, 'ROPA',    'Ropa y Accesorios', 'Moda y accesorios',             TRUE, FALSE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
  (1, 'SALUD',   'Salud y Belleza',   'Productos de salud y belleza',  TRUE, FALSE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
  (1, 'JUGUETE', 'Juguetes',          'Juguetes y juegos',             TRUE, FALSE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 2. Productos ecommerce (30 productos)
-- -------------------------------------------------------

-- Electronica (7 productos)
INSERT INTO master."Product" ("CompanyId","ProductCode","ProductName","CategoryCode","UnitCode","SalesPrice","CostPrice","DefaultTaxCode","DefaultTaxRate","StockQty","IsService","IsActive","IsDeleted","CreatedAt","UpdatedAt") VALUES
  (1,'ELEC-AUD-BT01','Audifonos Bluetooth Pro - Cancelacion de Ruido','ELECTRO','UND',89.99,45.00,'IVA',16,150,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'ELEC-SPKR-01','Parlante Portatil Waterproof 20W','ELECTRO','UND',45.99,22.00,'IVA',16,200,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'ELEC-CHRG-01','Cargador Inalambrico Rapido 15W','ELECTRO','UND',29.99,12.00,'IVA',16,300,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'ELEC-PWR-01','Power Bank 20000mAh USB-C Carga Rapida','ELECTRO','UND',39.99,18.00,'IVA',16,180,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'ELEC-WATCH-01','Smartwatch Fitness Tracker - Monitor Cardiaco','ELECTRO','UND',129.99,55.00,'IVA',16,100,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'ELEC-CAM-01','Camara Web HD 1080p con Microfono','ELECTRO','UND',49.99,20.00,'IVA',16,120,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'ELEC-KBD-01','Teclado Mecanico RGB Gaming','ELECTRO','UND',69.99,30.00,'IVA',16,90,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC')
ON CONFLICT DO NOTHING;

-- Hogar y Cocina (5 productos)
INSERT INTO master."Product" ("CompanyId","ProductCode","ProductName","CategoryCode","UnitCode","SalesPrice","CostPrice","DefaultTaxCode","DefaultTaxRate","StockQty","IsService","IsActive","IsDeleted","CreatedAt","UpdatedAt") VALUES
  (1,'HOG-CAFE-01','Cafetera Programable 12 Tazas con Filtro','HOGAR','UND',59.99,28.00,'IVA',16,80,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'HOG-LIC-01','Licuadora de Alta Potencia 700W','HOGAR','UND',44.99,20.00,'IVA',16,110,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'HOG-SART-01','Set de Sartenes Antiadherentes (3 piezas)','HOGAR','UND',54.99,25.00,'IVA',16,70,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'HOG-LAMP-01','Lampara LED de Escritorio Regulable','HOGAR','UND',34.99,14.00,'IVA',16,140,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'HOG-ALMOH-01','Almohada Memory Foam Cervical','HOGAR','UND',24.99,10.00,'IVA',16,200,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC')
ON CONFLICT DO NOTHING;

-- Deportes (5 productos)
INSERT INTO master."Product" ("CompanyId","ProductCode","ProductName","CategoryCode","UnitCode","SalesPrice","CostPrice","DefaultTaxCode","DefaultTaxRate","StockQty","IsService","IsActive","IsDeleted","CreatedAt","UpdatedAt") VALUES
  (1,'DEP-YOGA-01','Mat de Yoga Antideslizante 6mm','DEPORTE','UND',22.99,9.00,'IVA',16,160,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'DEP-MANC-01','Set de Mancuernas Ajustables 20kg','DEPORTE','UND',79.99,35.00,'IVA',16,60,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'DEP-BOT-01','Botella Termica Deportiva 1L Acero Inoxidable','DEPORTE','UND',19.99,7.00,'IVA',16,250,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'DEP-BAND-01','Set de Bandas Elasticas de Resistencia (5 pcs)','DEPORTE','UND',14.99,5.00,'IVA',16,300,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'DEP-MORR-01','Morral Deportivo Impermeable 40L','DEPORTE','UND',34.99,15.00,'IVA',16,130,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC')
ON CONFLICT DO NOTHING;

-- Ropa y Accesorios (4 productos)
INSERT INTO master."Product" ("CompanyId","ProductCode","ProductName","CategoryCode","UnitCode","SalesPrice","CostPrice","DefaultTaxCode","DefaultTaxRate","StockQty","IsService","IsActive","IsDeleted","CreatedAt","UpdatedAt") VALUES
  (1,'ROP-CAMI-01','Camiseta Deportiva Dry-Fit','ROPA','UND',18.99,7.00,'IVA',16,400,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'ROP-GORRA-01','Gorra Deportiva Ajustable UV Protection','ROPA','UND',15.99,5.50,'IVA',16,350,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'ROP-ZAP-01','Zapatillas Running Ultralight','ROPA','UND',74.99,32.00,'IVA',16,90,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'ROP-LENT-01','Lentes de Sol Polarizados UV400','ROPA','UND',27.99,10.00,'IVA',16,220,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC')
ON CONFLICT DO NOTHING;

-- Salud y Belleza (3 productos)
INSERT INTO master."Product" ("CompanyId","ProductCode","ProductName","CategoryCode","UnitCode","SalesPrice","CostPrice","DefaultTaxCode","DefaultTaxRate","StockQty","IsService","IsActive","IsDeleted","CreatedAt","UpdatedAt") VALUES
  (1,'SAL-PROT-01','Proteina Whey 2lb Sabor Chocolate','SALUD','UND',42.99,20.00,'IVA',16,100,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'SAL-VIT-01','Multivitaminico Completo 90 Capsulas','SALUD','UND',19.99,8.00,'IVA',16,250,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'SAL-CREMA-01','Crema Hidratante Facial SPF 30','SALUD','UND',16.99,6.00,'IVA',16,180,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC')
ON CONFLICT DO NOTHING;

-- Tecnologia / Oficina (3 productos)
INSERT INTO master."Product" ("CompanyId","ProductCode","ProductName","CategoryCode","UnitCode","SalesPrice","CostPrice","DefaultTaxCode","DefaultTaxRate","StockQty","IsService","IsActive","IsDeleted","CreatedAt","UpdatedAt") VALUES
  (1,'TEC-MOUSE-01','Mouse Ergonomico Inalambrico Recargable','TECNOL','UND',32.99,13.00,'IVA',16,170,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'TEC-HUB-01','Hub USB-C 7 en 1 HDMI/USB/SD','TECNOL','UND',38.99,16.00,'IVA',16,140,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'TEC-SOPORT-01','Soporte Laptop Aluminio Ajustable','TECNOL','UND',28.99,11.00,'IVA',16,120,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC')
ON CONFLICT DO NOTHING;

-- Juguetes (2 productos)
INSERT INTO master."Product" ("CompanyId","ProductCode","ProductName","CategoryCode","UnitCode","SalesPrice","CostPrice","DefaultTaxCode","DefaultTaxRate","StockQty","IsService","IsActive","IsDeleted","CreatedAt","UpdatedAt") VALUES
  (1,'JUG-DRON-01','Mini Drone con Camara HD para Principiantes','JUGUETE','UND',59.99,25.00,'IVA',16,75,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC'),
  (1,'JUG-LEGO-01','Set de Construccion 500 Piezas Creativo','JUGUETE','UND',34.99,14.00,'IVA',16,95,FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC')
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 3. Imagenes de productos (MediaAsset + EntityImage)
--    Usa un bloque DO para insertar en cascada
-- -------------------------------------------------------
DO $$
DECLARE
  v_now   TIMESTAMP := NOW() AT TIME ZONE 'UTC';
  v_maId  BIGINT;
  v_prodId BIGINT;
  r       RECORD;
BEGIN
  FOR r IN (
    SELECT * FROM (VALUES
      -- Electronica
      ('ELEC-AUD-BT01','https://picsum.photos/seed/headphones1/600/600','Audifonos Bluetooth Pro',TRUE,1),
      ('ELEC-AUD-BT01','https://picsum.photos/seed/headphones2/600/600','Audifonos vista lateral',FALSE,2),
      ('ELEC-AUD-BT01','https://picsum.photos/seed/headphones3/600/600','Audifonos en estuche',FALSE,3),
      ('ELEC-SPKR-01','https://picsum.photos/seed/speaker1/600/600','Parlante Portatil',TRUE,1),
      ('ELEC-SPKR-01','https://picsum.photos/seed/speaker2/600/600','Parlante vista trasera',FALSE,2),
      ('ELEC-CHRG-01','https://picsum.photos/seed/charger1/600/600','Cargador Inalambrico',TRUE,1),
      ('ELEC-CHRG-01','https://picsum.photos/seed/charger2/600/600','Cargador con telefono',FALSE,2),
      ('ELEC-PWR-01','https://picsum.photos/seed/powerbank1/600/600','Power Bank 20000mAh',TRUE,1),
      ('ELEC-PWR-01','https://picsum.photos/seed/powerbank2/600/600','Power Bank puertos',FALSE,2),
      ('ELEC-WATCH-01','https://picsum.photos/seed/smartwatch1/600/600','Smartwatch Fitness',TRUE,1),
      ('ELEC-WATCH-01','https://picsum.photos/seed/smartwatch2/600/600','Smartwatch en muneca',FALSE,2),
      ('ELEC-WATCH-01','https://picsum.photos/seed/smartwatch3/600/600','Smartwatch funciones',FALSE,3),
      ('ELEC-CAM-01','https://picsum.photos/seed/webcam1/600/600','Camara Web HD',TRUE,1),
      ('ELEC-KBD-01','https://picsum.photos/seed/keyboard1/600/600','Teclado Mecanico RGB',TRUE,1),
      ('ELEC-KBD-01','https://picsum.photos/seed/keyboard2/600/600','Teclado iluminacion',FALSE,2),
      -- Hogar
      ('HOG-CAFE-01','https://picsum.photos/seed/coffeemaker1/600/600','Cafetera Programable',TRUE,1),
      ('HOG-CAFE-01','https://picsum.photos/seed/coffeemaker2/600/600','Cafetera panel',FALSE,2),
      ('HOG-LIC-01','https://picsum.photos/seed/blender1/600/600','Licuadora Alta Potencia',TRUE,1),
      ('HOG-SART-01','https://picsum.photos/seed/pans1/600/600','Set Sartenes',TRUE,1),
      ('HOG-SART-01','https://picsum.photos/seed/pans2/600/600','Sartenes detalle',FALSE,2),
      ('HOG-LAMP-01','https://picsum.photos/seed/desklamp1/600/600','Lampara LED',TRUE,1),
      ('HOG-ALMOH-01','https://picsum.photos/seed/pillow1/600/600','Almohada Memory Foam',TRUE,1),
      -- Deportes
      ('DEP-YOGA-01','https://picsum.photos/seed/yogamat1/600/600','Mat de Yoga',TRUE,1),
      ('DEP-YOGA-01','https://picsum.photos/seed/yogamat2/600/600','Mat de Yoga enrollado',FALSE,2),
      ('DEP-MANC-01','https://picsum.photos/seed/dumbbells1/600/600','Set Mancuernas',TRUE,1),
      ('DEP-MANC-01','https://picsum.photos/seed/dumbbells2/600/600','Mancuernas detalle',FALSE,2),
      ('DEP-BOT-01','https://picsum.photos/seed/bottle1/600/600','Botella Termica',TRUE,1),
      ('DEP-BAND-01','https://picsum.photos/seed/bands1/600/600','Bandas Elasticas',TRUE,1),
      ('DEP-MORR-01','https://picsum.photos/seed/backpack1/600/600','Morral Deportivo',TRUE,1),
      ('DEP-MORR-01','https://picsum.photos/seed/backpack2/600/600','Morral interior',FALSE,2),
      -- Ropa
      ('ROP-CAMI-01','https://picsum.photos/seed/tshirt1/600/600','Camiseta Deportiva',TRUE,1),
      ('ROP-GORRA-01','https://picsum.photos/seed/cap1/600/600','Gorra Deportiva',TRUE,1),
      ('ROP-ZAP-01','https://picsum.photos/seed/shoes1/600/600','Zapatillas Running',TRUE,1),
      ('ROP-ZAP-01','https://picsum.photos/seed/shoes2/600/600','Zapatillas suela',FALSE,2),
      ('ROP-ZAP-01','https://picsum.photos/seed/shoes3/600/600','Zapatillas lateral',FALSE,3),
      ('ROP-LENT-01','https://picsum.photos/seed/sunglasses1/600/600','Lentes Polarizados',TRUE,1),
      -- Salud
      ('SAL-PROT-01','https://picsum.photos/seed/protein1/600/600','Proteina Whey',TRUE,1),
      ('SAL-VIT-01','https://picsum.photos/seed/vitamins1/600/600','Multivitaminico',TRUE,1),
      ('SAL-CREMA-01','https://picsum.photos/seed/cream1/600/600','Crema Hidratante',TRUE,1),
      -- Tecnologia
      ('TEC-MOUSE-01','https://picsum.photos/seed/mouse1/600/600','Mouse Ergonomico',TRUE,1),
      ('TEC-MOUSE-01','https://picsum.photos/seed/mouse2/600/600','Mouse vista lateral',FALSE,2),
      ('TEC-HUB-01','https://picsum.photos/seed/usbhub1/600/600','Hub USB-C',TRUE,1),
      ('TEC-SOPORT-01','https://picsum.photos/seed/stand1/600/600','Soporte Laptop',TRUE,1),
      -- Juguetes
      ('JUG-DRON-01','https://picsum.photos/seed/drone1/600/600','Mini Drone HD',TRUE,1),
      ('JUG-DRON-01','https://picsum.photos/seed/drone2/600/600','Drone en vuelo',FALSE,2),
      ('JUG-LEGO-01','https://picsum.photos/seed/blocks1/600/600','Set Construccion',TRUE,1)
    ) AS t("ProductCode", "ImgUrl", "AltText", "IsPrimary", "SortOrder")
  )
  LOOP
    SELECT "ProductId" INTO v_prodId
      FROM master."Product"
      WHERE "CompanyId" = 1 AND "ProductCode" = r."ProductCode" AND "IsDeleted" = FALSE;

    IF v_prodId IS NOT NULL THEN
      -- Solo insertar si no existe ya esta combinacion URL + producto
      IF NOT EXISTS (
        SELECT 1 FROM cfg."MediaAsset" ma
        INNER JOIN cfg."EntityImage" ei ON ei."MediaAssetId" = ma."MediaAssetId"
        WHERE ma."PublicUrl" = r."ImgUrl"
          AND ei."EntityId"  = v_prodId
          AND ei."EntityType" = 'MASTER_PRODUCT'
      ) THEN
        INSERT INTO cfg."MediaAsset" (
          "CompanyId", "BranchId", "StorageProvider", "StorageKey", "PublicUrl",
          "OriginalFileName", "MimeType", "FileExtension", "FileSizeBytes",
          "AltText", "WidthPx", "HeightPx",
          "IsActive", "IsDeleted", "CreatedAt", "UpdatedAt"
        ) VALUES (
          1, 1, 'external', r."ImgUrl", r."ImgUrl",
          r."ProductCode" || '.jpg', 'image/jpeg', '.jpg', 0,
          r."AltText", 600, 600,
          TRUE, FALSE, v_now, v_now
        )
        RETURNING "MediaAssetId" INTO v_maId;

        INSERT INTO cfg."EntityImage" (
          "CompanyId", "BranchId", "EntityType", "EntityId", "MediaAssetId",
          "RoleCode", "SortOrder", "IsPrimary", "IsActive", "IsDeleted", "CreatedAt", "UpdatedAt"
        ) VALUES (
          1, 1, 'MASTER_PRODUCT', v_prodId, v_maId,
          'PRODUCT_IMAGE', r."SortOrder", r."IsPrimary", TRUE, FALSE, v_now, v_now
        );
      END IF;
    END IF;
  END LOOP;
END $$;

-- -------------------------------------------------------
-- 4. Resenas de productos (~50 resenas variadas)
-- -------------------------------------------------------
INSERT INTO store."ProductReview" ("CompanyId","ProductCode","Rating","Title","Comment","ReviewerName","ReviewerEmail","IsVerified","IsApproved","IsDeleted","CreatedAt") VALUES
  -- ELEC-AUD-BT01 (5 resenas)
  (1,'ELEC-AUD-BT01',5,'Excelente calidad de sonido','Los mejores audifonos que he tenido. La cancelacion de ruido es increible.','Maria G.','maria@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '30 days'),
  (1,'ELEC-AUD-BT01',4,'Muy buenos, bateria dura bastante','La bateria dura todo el dia. El unico detalle es que aprietan un poco al principio.','Carlos R.','carlos@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '25 days'),
  (1,'ELEC-AUD-BT01',5,'Los recomiendo al 100%','Uso estos audifonos para trabajar desde casa y son perfectos. Muy comodos.','Ana P.','ana@test.com',FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '20 days'),
  (1,'ELEC-AUD-BT01',4,'Buen producto','Buena relacion precio-calidad. El sonido es claro y los bajos potentes.','Pedro M.','pedro@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '15 days'),
  (1,'ELEC-AUD-BT01',3,'Estan bien','Cumplen su funcion. Esperaba un poco mas de la cancelacion de ruido.','Laura S.','laura@test.com',FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '10 days'),

  -- ELEC-WATCH-01 (4 resenas)
  (1,'ELEC-WATCH-01',5,'Impresionante para el precio','Monitoreo cardiaco preciso, GPS funciona bien. Muy satisfecho con la compra.','Roberto L.','roberto@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '28 days'),
  (1,'ELEC-WATCH-01',4,'Buen smartwatch','La pantalla se ve muy bien al sol. Las notificaciones funcionan perfectamente.','Sandra K.','sandra@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '22 days'),
  (1,'ELEC-WATCH-01',5,'Lo uso para correr','Excelente tracker de actividad. Lo uso todos los dias para mis carreras.','Diego F.','diego@test.com',FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '18 days'),
  (1,'ELEC-WATCH-01',4,'Muy util','Las funciones de salud son muy completas. Me encanta el monitor de sueno.','Patricia V.','patricia@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '12 days'),

  -- HOG-CAFE-01 (4 resenas)
  (1,'HOG-CAFE-01',5,'El mejor cafe en casa','Hace un cafe delicioso. La funcion de programacion es genial para las mananas.','Fernando A.','fernando@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '35 days'),
  (1,'HOG-CAFE-01',4,'Muy buena cafetera','Facil de usar y limpiar. El cafe sale caliente y con buen sabor.','Lucia M.','lucia@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '27 days'),
  (1,'HOG-CAFE-01',5,'Perfecta','La uso todos los dias. 12 tazas es perfecto para la oficina.','Andres B.','andres@test.com',FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '19 days'),
  (1,'HOG-CAFE-01',3,'Buena pero...','El cafe es bueno pero la jarra es un poco fragil. Cuidado al lavarla.','Marta C.','marta@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '14 days'),

  -- DEP-YOGA-01 (3 resenas)
  (1,'DEP-YOGA-01',5,'Perfecto para yoga','Antideslizante de verdad. Muy comodo para las rodillas.','Valentina R.','valentina@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '32 days'),
  (1,'DEP-YOGA-01',4,'Buen material','Buena calidad, no se deforma. Lo recomiendo para principiantes.','Camila H.','camila@test.com',FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '24 days'),
  (1,'DEP-YOGA-01',5,'Excelente','Lo uso para pilates y yoga. El grosor de 6mm es ideal.','Gabriela T.','gabriela@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '16 days'),

  -- ELEC-PWR-01 (3 resenas)
  (1,'ELEC-PWR-01',5,'Indispensable para viajes','Carga mi telefono 4 veces. La carga rapida funciona genial.','Juan D.','juan@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '29 days'),
  (1,'ELEC-PWR-01',4,'Muy buena capacidad','20000mAh es suficiente para varios dispositivos. Un poco pesado pero vale la pena.','Miguel S.','miguel@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '21 days'),
  (1,'ELEC-PWR-01',5,'Excelente power bank','USB-C de entrada y salida. Carga rapida tanto para cargar como descargar.','Isabel F.','isabel@test.com',FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '13 days'),

  -- ROP-ZAP-01 (4 resenas)
  (1,'ROP-ZAP-01',5,'Las mejores para correr','Super livianas y comodas. Las uso para mis maratones y son increibles.','Alejandro P.','alejandro@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '33 days'),
  (1,'ROP-ZAP-01',4,'Muy comodas','El ajuste es perfecto. La amortiguacion es buena para carreras largas.','Daniela V.','daniela@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '26 days'),
  (1,'ROP-ZAP-01',5,'Excelente calzado','Las uso todos los dias para el gimnasio. Muy livianas y con buen soporte.','Tomas M.','tomas@test.com',FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '17 days'),
  (1,'ROP-ZAP-01',4,'Buena compra','El diseno es bonito y son muy comodas. La suela tiene buen agarre.','Carolina L.','carolina@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '9 days'),

  -- ELEC-KBD-01 (3 resenas)
  (1,'ELEC-KBD-01',5,'Increible para gaming','Los switches son suaves y la iluminacion RGB es espectacular.','Nicolas G.','nicolas@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '31 days'),
  (1,'ELEC-KBD-01',4,'Muy buen teclado','Excelente para programar tambien. Los switches son silenciosos.','Sofia R.','sofia@test.com',FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '23 days'),
  (1,'ELEC-KBD-01',5,'El mejor teclado','La calidad de construccion es premium. Los keycaps se sienten muy bien.','Mateo H.','mateo@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '15 days'),

  -- SAL-PROT-01 (3 resenas)
  (1,'SAL-PROT-01',5,'Sabor increible','El sabor chocolate es delicioso. Se mezcla bien y no deja grumos.','Ricardo T.','ricardo@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '34 days'),
  (1,'SAL-PROT-01',4,'Buena proteina','25g de proteina por scoop. Buena relacion calidad-precio.','Elena K.','elena@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '26 days'),
  (1,'SAL-PROT-01',5,'La mejor del mercado','Llevo 6 meses usandola. Los resultados son notorios.','David A.','david@test.com',FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '18 days'),

  -- DEP-MANC-01 (2 resenas)
  (1,'DEP-MANC-01',5,'Perfectas para casa','El sistema ajustable es muy practico. Reemplazan varios pares de mancuernas.','Andres R.','andres.r@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '30 days'),
  (1,'DEP-MANC-01',4,'Buena inversion','La calidad es buena. El agarre es comodo y los discos estan bien balanceados.','Paula M.','paula@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '22 days'),

  -- ELEC-SPKR-01 (3 resenas)
  (1,'ELEC-SPKR-01',5,'Sonido potente','20W de potencia real. Lo use en la piscina y funciona perfecto.','Jorge L.','jorge@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '28 days'),
  (1,'ELEC-SPKR-01',4,'Buen parlante','Resistente al agua como dice. La bateria dura unas 8 horas.','Natalia S.','natalia@test.com',FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '20 days'),
  (1,'ELEC-SPKR-01',5,'Excelente compra','El bajo es increible para su tamano. Lo llevo a todas partes.','Sebastian V.','sebastian@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '12 days'),

  -- JUG-DRON-01 (3 resenas)
  (1,'JUG-DRON-01',4,'Divertido','Muy facil de volar. La camara tiene buena calidad para el precio.','Luis H.','luis@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '27 days'),
  (1,'JUG-DRON-01',5,'Regalo perfecto','Se lo regale a mi hijo y esta encantado. Muy estable y facil de controlar.','Carmen D.','carmen@test.com',FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '19 days'),
  (1,'JUG-DRON-01',4,'Bueno para empezar','Ideal para principiantes. La bateria dura unos 15 minutos.','Alberto F.','alberto@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '11 days'),

  -- TEC-MOUSE-01 (2 resenas)
  (1,'TEC-MOUSE-01',5,'Adios dolor de muneca','Desde que uso este mouse ergonomico se me quito el dolor de muneca.','Andrea G.','andrea@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '29 days'),
  (1,'TEC-MOUSE-01',4,'Muy comodo','El diseno ergonomico es excelente. La bateria dura semanas.','Cristian B.','cristian@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '21 days'),

  -- HOG-LIC-01 (2 resenas)
  (1,'HOG-LIC-01',5,'Potente','Licua hasta hielo sin problemas. 700W de potencia real.','Rosa P.','rosa@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '26 days'),
  (1,'HOG-LIC-01',4,'Muy buena','Hago smoothies todos los dias. Facil de lavar y usar.','Manuel T.','manuel@test.com',FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '18 days'),

  -- DEP-BAND-01 (2 resenas)
  (1,'DEP-BAND-01',5,'Excelente set','5 niveles de resistencia. Perfectas para entrenar en casa.','Valeria M.','valeria@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '25 days'),
  (1,'DEP-BAND-01',5,'Las uso todos los dias','Muy resistentes y no se deforman. Vienen con bolsa de transporte.','Esteban R.','esteban@test.com',FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '17 days'),

  -- TEC-HUB-01 (2 resenas)
  (1,'TEC-HUB-01',5,'Indispensable','7 puertos en uno. HDMI funciona perfecto a 4K. Lo uso con mi MacBook.','Joaquin L.','joaquin@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '24 days'),
  (1,'TEC-HUB-01',4,'Muy practico','Todos los puertos funcionan bien. El cable es un poco corto.','Mariana F.','mariana@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '16 days'),

  -- ELEC-CHRG-01 (2 resenas)
  (1,'ELEC-CHRG-01',5,'Carga rapida real','15W de carga reales. Mi telefono se carga en 2 horas.','Daniela M.','daniela.m@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '23 days'),
  (1,'ELEC-CHRG-01',4,'Bueno y bonito','Diseno elegante y funcional. Compatible con todos mis dispositivos.','Martin R.','martin@test.com',FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '15 days'),

  -- HOG-SART-01 (2 resenas)
  (1,'HOG-SART-01',5,'Excelentes sartenes','Nada se pega. Muy faciles de limpiar y el mango no se calienta.','Gloria T.','gloria@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '31 days'),
  (1,'HOG-SART-01',4,'Buena calidad','El set de 3 tamanos es perfecto. El antiadherente funciona bien.','Ramon L.','ramon@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '22 days'),

  -- DEP-BOT-01 (2 resenas)
  (1,'DEP-BOT-01',5,'Mantiene la temperatura','Agua fria por 24 horas. Excelente calidad del acero.','Camilo V.','camilo@test.com',TRUE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '20 days'),
  (1,'DEP-BOT-01',4,'Perfecta para el gym','1 litro es suficiente. No gotea y el diseno es muy bonito.','Silvia G.','silvia@test.com',FALSE,TRUE,FALSE,NOW() AT TIME ZONE 'UTC' - INTERVAL '12 days')
ON CONFLICT DO NOTHING;

COMMIT;
