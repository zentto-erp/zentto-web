/*  ═══════════════════════════════════════════════════════════════
    30_ecommerce_product_details_seed.sql
    Datos extendidos: descripciones, highlights, specs, precios de comparación
    para los productos ecommerce existentes (seed 29_*)
    ═══════════════════════════════════════════════════════════════ */
USE [DatqBoxWeb];
GO
SET NOCOUNT ON;
GO

-- ───────────────────────────────────────────────────────
-- 1. Actualizar master.Product con campos extendidos
-- ───────────────────────────────────────────────────────

-- Audífonos Bluetooth Pro
UPDATE [master].Product SET
    ShortDescription = N'Audífonos inalámbricos con cancelación activa de ruido, 30h de batería y conectividad Bluetooth 5.3',
    LongDescription  = N'Experimenta un sonido envolvente con los Audífonos Bluetooth Pro. Equipados con cancelación activa de ruido (ANC) de última generación, estos audífonos bloquean el ruido exterior para que puedas disfrutar de tu música, podcasts o llamadas sin distracciones. Con drivers de 40mm de alta fidelidad, ofrecen graves profundos y agudos cristalinos. La batería de larga duración te brinda hasta 30 horas de reproducción continua, y con solo 10 minutos de carga rápida obtienes 3 horas adicionales. El diseño ergonómico con almohadillas de espuma viscoelástica garantiza comodidad durante todo el día. Compatible con asistentes de voz y controles táctiles intuitivos.',
    BrandCode        = NULL,
    CompareAtPrice   = 119.99,
    WeightKg         = 0.250,
    WidthCm          = 18.00,
    HeightCm         = 20.00,
    DepthCm          = 8.00,
    WarrantyMonths   = 12,
    BarCode          = N'7501234567890',
    Slug             = N'audifonos-bluetooth-pro-cancelacion-ruido'
WHERE ProductCode = 'ELEC-AUD-BT01' AND CompanyId = 1;

-- Parlante Portátil Waterproof
UPDATE [master].Product SET
    ShortDescription = N'Parlante portátil resistente al agua IPX7 con sonido 360° y 12h de batería',
    LongDescription  = N'Lleva tu música a todas partes con el Parlante Portátil Waterproof 20W. Con certificación IPX7 de resistencia al agua, puedes usarlo en la piscina, la playa o bajo la lluvia sin preocupaciones. Su tecnología de sonido 360° llena cualquier espacio con audio potente y claro. Conecta dos parlantes para un efecto estéreo envolvente. La batería recargable ofrece hasta 12 horas de reproducción continua. Incluye micrófono integrado para llamadas manos libres y es compatible con tarjetas microSD.',
    CompareAtPrice   = 59.99,
    WeightKg         = 0.540,
    WidthCm          = 7.50,
    HeightCm         = 18.00,
    DepthCm          = 7.50,
    WarrantyMonths   = 6,
    BarCode          = N'7501234567891',
    Slug             = N'parlante-portatil-waterproof-20w'
WHERE ProductCode = 'ELEC-SPKR-01' AND CompanyId = 1;

-- Cargador Inalámbrico
UPDATE [master].Product SET
    ShortDescription = N'Base de carga inalámbrica Qi compatible con iPhone y Android, carga rápida 15W',
    LongDescription  = N'Olvídate de los cables con el Cargador Inalámbrico Rápido 15W. Compatible con el estándar Qi, funciona con todos los smartphones modernos incluyendo iPhone 15/14/13/12 y Samsung Galaxy S24/S23. Su diseño ultradelgado con superficie antideslizante se adapta perfectamente a tu escritorio o mesita de noche. Incluye indicador LED de estado de carga y protección contra sobrecalentamiento, sobrecarga y cortocircuito. Carga a través de fundas de hasta 5mm de grosor.',
    CompareAtPrice   = NULL,
    WeightKg         = 0.080,
    WidthCm          = 10.00,
    HeightCm         = 1.00,
    DepthCm          = 10.00,
    WarrantyMonths   = 12,
    BarCode          = N'7501234567892',
    Slug             = N'cargador-inalambrico-rapido-15w'
WHERE ProductCode = 'ELEC-CHRG-01' AND CompanyId = 1;

-- Power Bank
UPDATE [master].Product SET
    ShortDescription = N'Batería externa de 20000mAh con USB-C, carga rápida PD 20W y 3 puertos de salida',
    LongDescription  = N'Nunca te quedes sin batería con el Power Bank 20000mAh. Con capacidad para cargar un smartphone hasta 5 veces, es el compañero ideal para viajes largos y jornadas intensas. Soporta carga rápida PD 20W por USB-C y Quick Charge 3.0 por USB-A. Sus 3 puertos de salida permiten cargar múltiples dispositivos simultáneamente. El display LED muestra el nivel de batería restante. Diseño compacto con acabado antihuellas.',
    CompareAtPrice   = 54.99,
    WeightKg         = 0.380,
    WidthCm          = 15.00,
    HeightCm         = 7.00,
    DepthCm          = 2.50,
    WarrantyMonths   = 12,
    BarCode          = N'7501234567893',
    Slug             = N'power-bank-20000mah-usb-c-carga-rapida'
WHERE ProductCode = 'ELEC-PWR-01' AND CompanyId = 1;

-- Smartwatch
UPDATE [master].Product SET
    ShortDescription = N'Reloj inteligente con monitor cardíaco 24/7, GPS integrado y más de 100 modos deportivos',
    LongDescription  = N'Lleva el control de tu salud y rendimiento deportivo con el Smartwatch Fitness Tracker. Monitorea tu ritmo cardíaco las 24 horas, niveles de oxígeno en sangre (SpO2), calidad del sueño y estrés. Con GPS integrado, rastrea tus rutas de carrera, ciclismo y senderismo con precisión. Más de 100 modos deportivos para todo tipo de actividades. Pantalla AMOLED de 1.43" con brillo adaptativo. Resistente al agua 5ATM. Recibe notificaciones de llamadas, mensajes y apps directamente en tu muñeca. Batería de hasta 14 días.',
    CompareAtPrice   = 179.99,
    WeightKg         = 0.045,
    WidthCm          = 4.60,
    HeightCm         = 4.60,
    DepthCm          = 1.20,
    WarrantyMonths   = 12,
    BarCode          = N'7501234567894',
    Slug             = N'smartwatch-fitness-tracker-monitor-cardiaco'
WHERE ProductCode = 'ELEC-WATCH-01' AND CompanyId = 1;

-- Cámara Web
UPDATE [master].Product SET
    ShortDescription = N'Webcam Full HD 1080p a 30fps con micrófono dual y corrección de luz automática',
    LongDescription  = N'Mejora tus videollamadas y streaming con la Cámara Web HD 1080p. Sensor CMOS de alta calidad que captura video nítido a 1920x1080 a 30fps. El micrófono dual con cancelación de ruido asegura que tu voz se escuche clara y natural. La corrección automática de luz se adapta a cualquier condición de iluminación. Compatible con Windows, macOS, Linux y ChromeOS. Funciona con Zoom, Teams, Meet, Skype y todas las plataformas principales. Clip universal que se adapta a monitores y trípodes.',
    CompareAtPrice   = NULL,
    WeightKg         = 0.120,
    WidthCm          = 8.00,
    HeightCm         = 5.00,
    DepthCm          = 5.00,
    WarrantyMonths   = 12,
    BarCode          = N'7501234567895',
    Slug             = N'camara-web-hd-1080p-microfono'
WHERE ProductCode = 'ELEC-CAM-01' AND CompanyId = 1;

-- Teclado Mecánico
UPDATE [master].Product SET
    ShortDescription = N'Teclado mecánico gaming con switches rojos, retroiluminación RGB y reposamuñecas magnético',
    LongDescription  = N'Domina cada partida con el Teclado Mecánico RGB Gaming. Switches mecánicos rojos lineales con respuesta ultrarrápida de 1ms y vida útil de 50 millones de pulsaciones. Retroiluminación RGB personalizable por tecla con más de 16.8 millones de colores y efectos dinámicos. Construcción en aluminio aeronáutico que garantiza durabilidad y estabilidad. Incluye reposamuñecas magnético de espuma viscoelástica para sesiones prolongadas. Anti-ghosting N-Key rollover completo. Compatible con Windows y macOS.',
    CompareAtPrice   = 89.99,
    WeightKg         = 1.100,
    WidthCm          = 44.00,
    HeightCm         = 3.50,
    DepthCm          = 14.00,
    WarrantyMonths   = 24,
    BarCode          = N'7501234567896',
    Slug             = N'teclado-mecanico-rgb-gaming'
WHERE ProductCode = 'ELEC-KBD-01' AND CompanyId = 1;

-- Cafetera
UPDATE [master].Product SET
    ShortDescription = N'Cafetera programable de 12 tazas con filtro permanente y función mantener caliente',
    LongDescription  = N'Disfruta del café perfecto cada mañana con la Cafetera Programable 12 Tazas. Su sistema de preparación optimizado extrae el máximo sabor y aroma de tus granos favoritos. Programador de 24 horas para que tu café esté listo cuando despiertes. Filtro permanente lavable incluido (también compatible con filtros de papel #4). Placa calefactora con función mantener caliente hasta 2 horas. Jarra de vidrio resistente al calor con tapa antigoteo. Sistema de pausa para servir una taza antes de que termine el ciclo.',
    CompareAtPrice   = NULL,
    WeightKg         = 2.300,
    WidthCm          = 23.00,
    HeightCm         = 36.00,
    DepthCm          = 20.00,
    WarrantyMonths   = 12,
    BarCode          = N'7501234567897',
    Slug             = N'cafetera-programable-12-tazas'
WHERE ProductCode = 'HOG-CAFE-01' AND CompanyId = 1;

-- Licuadora
UPDATE [master].Product SET
    ShortDescription = N'Licuadora de alta potencia 700W con vaso de vidrio de 1.5L y 5 velocidades',
    LongDescription  = N'Prepara tus batidos, smoothies y salsas favoritas con la Licuadora de Alta Potencia 700W. Motor profesional de 700W que tritura hielo y frutas congeladas sin esfuerzo. Vaso de vidrio borosilicato de 1.5 litros resistente a impactos térmicos. 5 velocidades + función pulso para control preciso. Cuchillas de acero inoxidable de 6 puntas endurecidas para un licuado uniforme. Base antideslizante con ventosas de seguridad. Tapa con orificio dosificador para agregar ingredientes durante el funcionamiento.',
    CompareAtPrice   = 59.99,
    WeightKg         = 3.200,
    WidthCm          = 20.00,
    HeightCm         = 42.00,
    DepthCm          = 20.00,
    WarrantyMonths   = 12,
    BarCode          = N'7501234567898',
    Slug             = N'licuadora-alta-potencia-700w'
WHERE ProductCode = 'HOG-LIC-01' AND CompanyId = 1;

-- Sartenes
UPDATE [master].Product SET
    ShortDescription = N'Set de 3 sartenes antiadherentes de aluminio forjado (20, 24 y 28 cm) aptas para todas las cocinas',
    LongDescription  = N'Cocina como un profesional con el Set de Sartenes Antiadherentes. Fabricadas en aluminio forjado de alta densidad para una distribución uniforme del calor. Triple capa antiadherente libre de PFOA que permite cocinar con mínimo aceite y facilita la limpieza. Mangos ergonómicos Soft-Touch que permanecen fríos durante la cocción. Aptas para todas las fuentes de calor incluyendo inducción. Incluye 3 tamaños (20cm, 24cm y 28cm) para cubrir todas tus necesidades culinarias.',
    CompareAtPrice   = 74.99,
    WeightKg         = 2.800,
    WarrantyMonths   = 24,
    Slug             = N'set-sartenes-antiadherentes-3-piezas'
WHERE ProductCode = 'HOG-SART-01' AND CompanyId = 1;
GO

-- ───────────────────────────────────────────────────────
-- 2. Highlights (bullets "Acerca de este artículo")
-- ───────────────────────────────────────────────────────

-- Limpiar existentes para idempotencia
DELETE FROM store.ProductHighlight WHERE CompanyId = 1;

-- Audífonos Bluetooth Pro
INSERT INTO store.ProductHighlight (CompanyId, ProductCode, SortOrder, HighlightText) VALUES
(1, 'ELEC-AUD-BT01', 1, N'Cancelación activa de ruido (ANC) que bloquea hasta el 95% del ruido exterior'),
(1, 'ELEC-AUD-BT01', 2, N'Batería de 30 horas de duración — carga rápida de 10 min = 3 horas extra'),
(1, 'ELEC-AUD-BT01', 3, N'Bluetooth 5.3 con alcance de 15 metros y conexión multipunto a 2 dispositivos'),
(1, 'ELEC-AUD-BT01', 4, N'Drivers de 40mm Hi-Fi con graves profundos y agudos cristalinos'),
(1, 'ELEC-AUD-BT01', 5, N'Almohadillas de espuma viscoelástica con diseño over-ear para máxima comodidad');

-- Parlante Portátil
INSERT INTO store.ProductHighlight (CompanyId, ProductCode, SortOrder, HighlightText) VALUES
(1, 'ELEC-SPKR-01', 1, N'Resistente al agua IPX7 — sumergible hasta 1 metro durante 30 minutos'),
(1, 'ELEC-SPKR-01', 2, N'Sonido 360° con potencia de 20W para llenar cualquier espacio'),
(1, 'ELEC-SPKR-01', 3, N'12 horas de reproducción continua con una sola carga'),
(1, 'ELEC-SPKR-01', 4, N'Empareja 2 parlantes para sonido estéreo verdadero'),
(1, 'ELEC-SPKR-01', 5, N'Micrófono integrado para llamadas manos libres');

-- Cargador Inalámbrico
INSERT INTO store.ProductHighlight (CompanyId, ProductCode, SortOrder, HighlightText) VALUES
(1, 'ELEC-CHRG-01', 1, N'Carga rápida de 15W — compatible con Qi estándar para iPhone y Android'),
(1, 'ELEC-CHRG-01', 2, N'Protección inteligente contra sobrecalentamiento, sobrecarga y cortocircuito'),
(1, 'ELEC-CHRG-01', 3, N'Carga a través de fundas de hasta 5mm de grosor'),
(1, 'ELEC-CHRG-01', 4, N'Indicador LED de estado de carga discreto para no molestar de noche');

-- Power Bank
INSERT INTO store.ProductHighlight (CompanyId, ProductCode, SortOrder, HighlightText) VALUES
(1, 'ELEC-PWR-01', 1, N'Capacidad masiva de 20000mAh — carga tu smartphone hasta 5 veces'),
(1, 'ELEC-PWR-01', 2, N'Carga rápida PD 20W (USB-C) y Quick Charge 3.0 (USB-A)'),
(1, 'ELEC-PWR-01', 3, N'3 puertos de salida para cargar múltiples dispositivos a la vez'),
(1, 'ELEC-PWR-01', 4, N'Display LED inteligente que muestra el nivel de batería exacto'),
(1, 'ELEC-PWR-01', 5, N'Seguro para equipaje de mano en aviones (cumple regulaciones de aviación)');

-- Smartwatch
INSERT INTO store.ProductHighlight (CompanyId, ProductCode, SortOrder, HighlightText) VALUES
(1, 'ELEC-WATCH-01', 1, N'Monitor cardíaco 24/7, SpO2 y seguimiento de sueño con análisis detallado'),
(1, 'ELEC-WATCH-01', 2, N'GPS integrado de alta precisión para tracking de rutas sin necesitar el teléfono'),
(1, 'ELEC-WATCH-01', 3, N'Más de 100 modos deportivos incluyendo natación, ciclismo y yoga'),
(1, 'ELEC-WATCH-01', 4, N'Pantalla AMOLED de 1.43" con brillo adaptativo visible bajo el sol'),
(1, 'ELEC-WATCH-01', 5, N'Batería de hasta 14 días de uso normal — resistente al agua 5ATM');

-- Cámara Web
INSERT INTO store.ProductHighlight (CompanyId, ProductCode, SortOrder, HighlightText) VALUES
(1, 'ELEC-CAM-01', 1, N'Video Full HD 1080p a 30fps con autoenfoque rápido'),
(1, 'ELEC-CAM-01', 2, N'Micrófono dual estéreo con cancelación de ruido ambiental'),
(1, 'ELEC-CAM-01', 3, N'Corrección automática de luz para cualquier condición de iluminación'),
(1, 'ELEC-CAM-01', 4, N'Compatible con Zoom, Teams, Meet, Skype y todas las plataformas principales');

-- Teclado Mecánico
INSERT INTO store.ProductHighlight (CompanyId, ProductCode, SortOrder, HighlightText) VALUES
(1, 'ELEC-KBD-01', 1, N'Switches mecánicos rojos lineales con respuesta de 1ms y vida de 50M pulsaciones'),
(1, 'ELEC-KBD-01', 2, N'RGB personalizable por tecla con 16.8 millones de colores'),
(1, 'ELEC-KBD-01', 3, N'Construcción en aluminio aeronáutico — sólido y duradero'),
(1, 'ELEC-KBD-01', 4, N'Reposamuñecas magnético de espuma viscoelástica incluido'),
(1, 'ELEC-KBD-01', 5, N'Anti-ghosting N-Key rollover completo para gaming competitivo');

-- Cafetera
INSERT INTO store.ProductHighlight (CompanyId, ProductCode, SortOrder, HighlightText) VALUES
(1, 'HOG-CAFE-01', 1, N'Capacidad de 12 tazas con programador de 24 horas'),
(1, 'HOG-CAFE-01', 2, N'Filtro permanente lavable incluido — ahorra en filtros de papel'),
(1, 'HOG-CAFE-01', 3, N'Placa calefactora mantiene el café caliente hasta 2 horas'),
(1, 'HOG-CAFE-01', 4, N'Sistema de pausa para servir antes de terminar el ciclo');

-- Licuadora
INSERT INTO store.ProductHighlight (CompanyId, ProductCode, SortOrder, HighlightText) VALUES
(1, 'HOG-LIC-01', 1, N'Motor profesional de 700W que tritura hielo y frutas congeladas'),
(1, 'HOG-LIC-01', 2, N'Vaso de vidrio borosilicato de 1.5L resistente a cambios de temperatura'),
(1, 'HOG-LIC-01', 3, N'5 velocidades + pulso para control preciso del licuado'),
(1, 'HOG-LIC-01', 4, N'Cuchillas de acero inoxidable de 6 puntas para licuado uniforme');

-- Sartenes
INSERT INTO store.ProductHighlight (CompanyId, ProductCode, SortOrder, HighlightText) VALUES
(1, 'HOG-SART-01', 1, N'Triple capa antiadherente libre de PFOA — cocina con mínimo aceite'),
(1, 'HOG-SART-01', 2, N'Aluminio forjado de alta densidad para distribución uniforme del calor'),
(1, 'HOG-SART-01', 3, N'Aptas para todas las cocinas incluyendo inducción'),
(1, 'HOG-SART-01', 4, N'3 tamaños incluidos: 20cm, 24cm y 28cm'),
(1, 'HOG-SART-01', 5, N'Mangos ergonómicos Soft-Touch que permanecen fríos');
GO

-- ───────────────────────────────────────────────────────
-- 3. Especificaciones técnicas
-- ───────────────────────────────────────────────────────

DELETE FROM store.ProductSpec WHERE CompanyId = 1;

-- Audífonos Bluetooth Pro
INSERT INTO store.ProductSpec (CompanyId, ProductCode, SpecGroup, SpecKey, SpecValue, SortOrder) VALUES
(1, 'ELEC-AUD-BT01', N'General',    N'Marca',                N'DatqBox Audio', 1),
(1, 'ELEC-AUD-BT01', N'General',    N'Modelo',               N'BT-PRO-ANC', 2),
(1, 'ELEC-AUD-BT01', N'General',    N'Color',                N'Negro mate', 3),
(1, 'ELEC-AUD-BT01', N'Técnico',    N'Tipo de driver',       N'Dinámico 40mm', 1),
(1, 'ELEC-AUD-BT01', N'Técnico',    N'Respuesta de frecuencia', N'20Hz - 20kHz', 2),
(1, 'ELEC-AUD-BT01', N'Técnico',    N'Impedancia',           N'32 Ω', 3),
(1, 'ELEC-AUD-BT01', N'Técnico',    N'Bluetooth',            N'5.3 con aptX HD', 4),
(1, 'ELEC-AUD-BT01', N'Batería',    N'Duración',             N'30 horas (ANC activado)', 1),
(1, 'ELEC-AUD-BT01', N'Batería',    N'Carga rápida',         N'10 min = 3 horas', 2),
(1, 'ELEC-AUD-BT01', N'Batería',    N'Tipo de carga',        N'USB-C', 3),
(1, 'ELEC-AUD-BT01', N'Dimensiones', N'Peso',                N'250 g', 1),
(1, 'ELEC-AUD-BT01', N'Dimensiones', N'Dimensiones plegado',  N'18 × 20 × 8 cm', 2);

-- Parlante Portátil
INSERT INTO store.ProductSpec (CompanyId, ProductCode, SpecGroup, SpecKey, SpecValue, SortOrder) VALUES
(1, 'ELEC-SPKR-01', N'General',    N'Marca',                N'DatqBox Audio', 1),
(1, 'ELEC-SPKR-01', N'General',    N'Color',                N'Negro / Azul', 2),
(1, 'ELEC-SPKR-01', N'Técnico',    N'Potencia',             N'20W RMS', 1),
(1, 'ELEC-SPKR-01', N'Técnico',    N'Resistencia al agua',  N'IPX7', 2),
(1, 'ELEC-SPKR-01', N'Técnico',    N'Bluetooth',            N'5.0', 3),
(1, 'ELEC-SPKR-01', N'Técnico',    N'Alcance Bluetooth',    N'10 metros', 4),
(1, 'ELEC-SPKR-01', N'Batería',    N'Duración',             N'12 horas', 1),
(1, 'ELEC-SPKR-01', N'Batería',    N'Tipo de carga',        N'Micro USB', 2),
(1, 'ELEC-SPKR-01', N'Dimensiones', N'Peso',                N'540 g', 1),
(1, 'ELEC-SPKR-01', N'Dimensiones', N'Dimensiones',          N'7.5 × 18 × 7.5 cm', 2);

-- Power Bank
INSERT INTO store.ProductSpec (CompanyId, ProductCode, SpecGroup, SpecKey, SpecValue, SortOrder) VALUES
(1, 'ELEC-PWR-01', N'General',    N'Marca',                N'DatqBox Power', 1),
(1, 'ELEC-PWR-01', N'General',    N'Capacidad',            N'20000 mAh / 74 Wh', 2),
(1, 'ELEC-PWR-01', N'Técnico',    N'Entrada',              N'USB-C PD 20W', 1),
(1, 'ELEC-PWR-01', N'Técnico',    N'Salida USB-C',         N'PD 20W', 2),
(1, 'ELEC-PWR-01', N'Técnico',    N'Salida USB-A',         N'QC 3.0 (×2)', 3),
(1, 'ELEC-PWR-01', N'Técnico',    N'Carga simultánea',     N'Hasta 3 dispositivos', 4),
(1, 'ELEC-PWR-01', N'Dimensiones', N'Peso',                N'380 g', 1),
(1, 'ELEC-PWR-01', N'Dimensiones', N'Dimensiones',          N'15 × 7 × 2.5 cm', 2);

-- Smartwatch
INSERT INTO store.ProductSpec (CompanyId, ProductCode, SpecGroup, SpecKey, SpecValue, SortOrder) VALUES
(1, 'ELEC-WATCH-01', N'General',    N'Marca',              N'DatqBox Wearables', 1),
(1, 'ELEC-WATCH-01', N'General',    N'Compatibilidad',     N'Android 6.0+ / iOS 12.0+', 2),
(1, 'ELEC-WATCH-01', N'Pantalla',   N'Tipo',               N'AMOLED', 1),
(1, 'ELEC-WATCH-01', N'Pantalla',   N'Tamaño',             N'1.43 pulgadas', 2),
(1, 'ELEC-WATCH-01', N'Pantalla',   N'Resolución',         N'466 × 466 px', 3),
(1, 'ELEC-WATCH-01', N'Sensores',   N'Cardíaco',           N'PPG óptico 24/7', 1),
(1, 'ELEC-WATCH-01', N'Sensores',   N'SpO2',               N'Oxímetro integrado', 2),
(1, 'ELEC-WATCH-01', N'Sensores',   N'GPS',                N'GPS + GLONASS + Galileo', 3),
(1, 'ELEC-WATCH-01', N'Sensores',   N'Acelerómetro',       N'6 ejes', 4),
(1, 'ELEC-WATCH-01', N'Batería',    N'Duración',           N'Hasta 14 días', 1),
(1, 'ELEC-WATCH-01', N'Batería',    N'Resistencia al agua', N'5 ATM', 2),
(1, 'ELEC-WATCH-01', N'Dimensiones', N'Peso',              N'45 g (sin correa)', 1),
(1, 'ELEC-WATCH-01', N'Dimensiones', N'Dimensiones caja',   N'46 × 46 × 12 mm', 2);

-- Teclado Mecánico
INSERT INTO store.ProductSpec (CompanyId, ProductCode, SpecGroup, SpecKey, SpecValue, SortOrder) VALUES
(1, 'ELEC-KBD-01', N'General',    N'Marca',               N'DatqBox Gaming', 1),
(1, 'ELEC-KBD-01', N'General',    N'Layout',              N'Full Size (104 teclas)', 2),
(1, 'ELEC-KBD-01', N'General',    N'Idioma',              N'Español latinoamericano', 3),
(1, 'ELEC-KBD-01', N'Técnico',    N'Tipo de switch',      N'Mecánico rojo (lineal)', 1),
(1, 'ELEC-KBD-01', N'Técnico',    N'Fuerza de actuación', N'45g ± 10g', 2),
(1, 'ELEC-KBD-01', N'Técnico',    N'Vida útil',           N'50 millones de pulsaciones', 3),
(1, 'ELEC-KBD-01', N'Técnico',    N'Polling rate',        N'1000 Hz (1ms)', 4),
(1, 'ELEC-KBD-01', N'Técnico',    N'Anti-ghosting',       N'N-Key rollover completo', 5),
(1, 'ELEC-KBD-01', N'Conexión',   N'Tipo',                N'USB-C desmontable', 1),
(1, 'ELEC-KBD-01', N'Conexión',   N'Cable',               N'Trenzado 1.8m', 2),
(1, 'ELEC-KBD-01', N'Dimensiones', N'Peso',               N'1.1 kg', 1),
(1, 'ELEC-KBD-01', N'Dimensiones', N'Dimensiones',         N'44 × 14 × 3.5 cm', 2);

-- Cafetera
INSERT INTO store.ProductSpec (CompanyId, ProductCode, SpecGroup, SpecKey, SpecValue, SortOrder) VALUES
(1, 'HOG-CAFE-01', N'General',    N'Marca',               N'DatqBox Home', 1),
(1, 'HOG-CAFE-01', N'General',    N'Capacidad',           N'12 tazas (1.5 litros)', 2),
(1, 'HOG-CAFE-01', N'Técnico',    N'Potencia',            N'900W', 1),
(1, 'HOG-CAFE-01', N'Técnico',    N'Voltaje',             N'110V / 60Hz', 2),
(1, 'HOG-CAFE-01', N'Técnico',    N'Filtro',              N'Permanente lavable + papel #4', 3),
(1, 'HOG-CAFE-01', N'Técnico',    N'Programador',         N'24 horas', 4),
(1, 'HOG-CAFE-01', N'Dimensiones', N'Peso',               N'2.3 kg', 1),
(1, 'HOG-CAFE-01', N'Dimensiones', N'Dimensiones',         N'23 × 20 × 36 cm', 2);

-- Licuadora
INSERT INTO store.ProductSpec (CompanyId, ProductCode, SpecGroup, SpecKey, SpecValue, SortOrder) VALUES
(1, 'HOG-LIC-01', N'General',    N'Marca',               N'DatqBox Home', 1),
(1, 'HOG-LIC-01', N'General',    N'Capacidad',           N'1.5 litros', 2),
(1, 'HOG-LIC-01', N'Técnico',    N'Potencia',            N'700W', 1),
(1, 'HOG-LIC-01', N'Técnico',    N'Velocidades',         N'5 + Pulso', 2),
(1, 'HOG-LIC-01', N'Técnico',    N'Material vaso',       N'Vidrio borosilicato', 3),
(1, 'HOG-LIC-01', N'Técnico',    N'Cuchillas',           N'Acero inoxidable 6 puntas', 4),
(1, 'HOG-LIC-01', N'Técnico',    N'Voltaje',             N'110V / 60Hz', 5),
(1, 'HOG-LIC-01', N'Dimensiones', N'Peso',               N'3.2 kg', 1),
(1, 'HOG-LIC-01', N'Dimensiones', N'Dimensiones',         N'20 × 20 × 42 cm', 2);

-- Sartenes
INSERT INTO store.ProductSpec (CompanyId, ProductCode, SpecGroup, SpecKey, SpecValue, SortOrder) VALUES
(1, 'HOG-SART-01', N'General',    N'Marca',              N'DatqBox Home', 1),
(1, 'HOG-SART-01', N'General',    N'Piezas incluidas',   N'3 (20cm, 24cm, 28cm)', 2),
(1, 'HOG-SART-01', N'Técnico',    N'Material',           N'Aluminio forjado', 1),
(1, 'HOG-SART-01', N'Técnico',    N'Recubrimiento',      N'Triple antiadherente libre de PFOA', 2),
(1, 'HOG-SART-01', N'Técnico',    N'Compatibilidad',     N'Gas, eléctrica, vitrocerámica, inducción', 3),
(1, 'HOG-SART-01', N'Técnico',    N'Mango',              N'Soft-Touch resistente al calor', 4),
(1, 'HOG-SART-01', N'Técnico',    N'Apto lavavajillas',  N'Sí', 5),
(1, 'HOG-SART-01', N'Dimensiones', N'Peso total',        N'2.8 kg', 1);
GO

PRINT '=== 30_ecommerce_product_details_seed.sql deployed OK ===';
GO
