-- Ejecutar en orden: tablas, seed completo, SP copiar. Base: Sanjose (o la configurada).
:r create_nomina_convencion_conocimiento.sql
:r seed_gananciales_y_deducciones_completo.sql
:r sp_nomina_copiar_conceptos_desde_legal.sql
PRINT 'Nomina legal: tablas, constantes, conceptos y SP listos.';
