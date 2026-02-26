-- Ejecutar en orden: tablas y seed legal. Base: Sanjose (o la configurada).
-- Nota 2026-02-25:
--   NO ejecutar el archivo legacy sp_nomina_copiar_conceptos_desde_legal.sql
--   en el flujo canónico, porque la versión legacy depende de ConcNom.
--   El SP canónico vigente se define en:
--   ..\governance\41_rebuild_nomina_canonical.sql
:r create_nomina_convencion_conocimiento.sql
:r seed_gananciales_y_deducciones_completo.sql
PRINT 'Nomina legal: tablas y seed listos (SP canonico en governance/41).';
