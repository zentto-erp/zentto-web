-- =============================================
-- CONSTANTES CONTRATO COLECTIVO PETROLERO
-- Basado en CCT Petrolero 2019-2021 PDVSA
-- =============================================

INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
-- VACACIONES PETROLERO (Mucho más generoso que LOT)
('VAC_DIAS_BASE', 'PETRO', 'Días Vacaciones Base Petrolero', '34', 'NUMERO', 'DIAS', 'VACACIONES', 'Cláusula 24 CCT Petrolero', '34 días base sector petrolero', 10),
('VAC_DIAS_ADIC_ANIO', 'PETRO', 'Días Vacaciones Adicional Petrolero', '2', 'NUMERO', 'DIAS', 'VACACIONES', 'Cláusula 24 CCT Petrolero', '2 días adicionales por año', 11),
('VAC_DIAS_MAX', 'PETRO', 'Días Vacaciones Máximo Petrolero', '60', 'NUMERO', 'DIAS', 'VACACIONES', 'Cláusula 24 CCT Petrolero', 'Máximo 60 días vacaciones', 12),
('BONO_VAC_DIAS', 'PETRO', 'Días Bono Vacacional Petrolero', '55', 'NUMERO', 'DIAS', 'VACACIONES', 'Cláusula 24 CCT Petrolero', '55 días bono vacacional', 20),
('BONO_VAC_ADIC_ANIO', 'PETRO', 'Días Bono Vacacional Adicional', '2', 'NUMERO', 'DIAS', 'VACACIONES', 'Cláusula 24 CCT Petrolero', '2 días adicionales bono', 21),
('BONO_VAC_POST_DIAS', 'PETRO', 'Bono Post Vacacional Petrolero', '15', 'NUMERO', 'DIAS', 'VACACIONES', 'Cláusula 24 CCT Petrolero', '15 días post vacacional', 25),
('BONO_VAC_AYUDA', 'PETRO', 'Bono Ayuda Vacacional', '119.22', 'NUMERO', 'MONTO', 'VACACIONES', 'Cláusula 24 CCT Petrolero', 'Ayuda adicional vacacional', 26);

-- UTILIDADES PETROLERO
INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('UTIL_DIAS_MIN', 'PETRO', 'Utilidades Mínimo Petrolero', '120', 'NUMERO', 'DIAS', 'UTILIDADES', 'Cláusula 26 CCT Petrolero', '120 días mínimo utilidades', 30),
('UTIL_DIAS_MAX', 'PETRO', 'Utilidades Máximo Petrolero', '180', 'NUMERO', 'DIAS', 'UTILIDADES', 'Cláusula 26 CCT Petrolero', '180 días máximo utilidades', 31),
('UTIL_CALCULO_SEMANAS', 'PETRO', 'Semanas Base Cálculo', '6', 'NUMERO', 'SEMANAS', 'UTILIDADES', 'Cláusula 26 CCT Petrolero', 'Promedio últimas 6 semanas', 32),
('UTIL_TEA', 'PETRO', 'Tarifa Escala Activa TEA', '2700', 'NUMERO', 'MONTO', 'UTILIDADES', 'Cláusula 26 CCT Petrolero', 'Tarifa especial TEA', 33);

-- PRESTACIONES PETROLERO
INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('PREST_DIAS_ANTIGUEDAD', 'PETRO', 'Días Prestaciones Petrolero', '45', 'NUMERO', 'DIAS', 'PRESTACIONES', 'Cláusula 23 CCT Petrolero', '45 días por año petrolero', 40),
('PREST_TOPE_SALARIO', 'PETRO', 'Tope Salario Integral Petrolero', '12', 'NUMERO', 'MESES', 'PRESTACIONES', 'Cláusula 23 CCT Petrolero', '12 meses de salario tope', 41),
('PREST_INTERES_ANUAL', 'PETRO', 'Interés Anual Prestaciones', '0.06', 'NUMERO', 'PORCENTAJE', 'PRESTACIONES', 'Cláusula 23 CCT Petrolero', '6% anual sobre prestaciones', 42),
('PREST_COMPLEMENTO_ANTIG', 'PETRO', 'Complemento Antigüedad', '5', 'NUMERO', 'DIAS', 'PRESTACIONES', 'Cláusula 23 CCT Petrolero', 'Días complemento antigüedad', 43);

-- JORNADA Y TURNOS PETROLERO
INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('JOR_TURNO_14x14', 'PETRO', 'Turno 14x14', '14', 'NUMERO', 'DIAS', 'JORNADA', 'Cláusula 18 CCT Petrolero', '14 días trabajo, 14 descanso', 80),
('JOR_TURNO_7x7', 'PETRO', 'Turno 7x7', '7', 'NUMERO', 'DIAS', 'JORNADA', 'Cláusula 18 CCT Petrolero', '7 días trabajo, 7 descanso', 81),
('JOR_TURNO_21x21', 'PETRO', 'Turno 21x21', '21', 'NUMERO', 'DIAS', 'JORNADA', 'Cláusula 18 CCT Petrolero', '21 días trabajo, 21 descanso', 82),
('JOR_HORAS_DIARIAS_PETRO', 'PETRO', 'Horas Diarias Petrolero', '12', 'NUMERO', 'HORAS', 'JORNADA', 'Cláusula 18 CCT Petrolero', '12 horas diarias plataforma', 83),
('RECARGO_TURNO_ROTATIVO', 'PETRO', 'Recargo Turno Rotativo %', '0.25', 'NUMERO', 'PORCENTAJE', 'JORNADA', 'Cláusula 18 CCT Petrolero', '25% recargo turno rotativo', 84);

-- BENEFICIOS ADICIONALES PETROLERO
INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('BONO_ALIMENTACION_PETRO', 'PETRO', 'Bono Alimentación Petrolero', 'TEA', 'FORMULA', 'MONTO', 'BENEFICIOS', 'Cláusula 35 CCT Petrolero', 'Tarifa escala activa', 90),
('CESTA_TICKET_DIA', 'PETRO', 'Cesta Ticket Diario', '48.77', 'NUMERO', 'MONTO', 'BENEFICIOS', 'Cláusula 35 CCT Petrolero', 'Valor diario cesta ticket', 91),
('VIVIENDA_INDEMNIZACION', 'PETRO', 'Indemnización Vivienda', '317.33', 'NUMERO', 'MONTO', 'BENEFICIOS', 'Cláusula 27 CCT Petrolero', 'Ayuda vivienda especial', 92),
('HORAS_EXCESO_PETRO', 'PETRO', 'Horas Exceso Petrolero', '600', 'NUMERO', 'HORAS', 'JORNADA', 'Cláusula 20 CCT Petrolero', 'Tope horas extraordinarias', 93);

-- INDEMNIZACIÓN PETROLERO
INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('INDEMN_DIAS_MARINERO', 'PETRO', 'Indemnización Marinero', '45', 'NUMERO', 'DIAS', 'PRESTACIONES', 'Cláusula 29 CCT Petrolero', '45 días marinero/aeronavegante', 50),
('INDEMN_ADIC_EMPLEADO_FIJO', 'PETRO', 'Indemnización Adicional Fijo', '30', 'NUMERO', 'DIAS', 'PRESTACIONES', 'Cláusula 29 CCT Petrolero', '30 días adicional empleado fijo', 51);

PRINT 'Constantes PETROLERO insertadas';
GO

-- =============================================
-- CONSTANTES CONSTRUCCIÓN (CCO)
-- =============================================

INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
-- VACACIONES CONSTRUCCIÓN
('VAC_DIAS_BASE', 'CONST', 'Días Vacaciones Construcción', '15', 'NUMERO', 'DIAS', 'VACACIONES', 'Art. 190 LOTTT + CCO', '15 días base construcción', 10),
('VAC_DIAS_ADIC_ANIO', 'CONST', 'Días Vacaciones Adicional', '1', 'NUMERO', 'DIAS', 'VACACIONES', 'Art. 190 LOTTT + CCO', '1 día adicional por año', 11),
('BONO_VAC_DIAS', 'CONST', 'Bono Vacacional Construcción', '15', 'NUMERO', 'DIAS', 'VACACIONES', 'Art. 192 LOTTT + CCO', '15 días bono', 20);

-- PRESTACIONES CONSTRUCCIÓN
INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('PREST_FACTOR_CONSTRUCCION', 'CONST', 'Factor Prestaciones Construcción', '1.0833', 'NUMERO', 'FACTOR', 'PRESTACIONES', 'CCO Construcción', 'Factor de liquidación sector', 40),
('PREST_DIAS_ANTIGUEDAD', 'CONST', 'Días Prestaciones Construcción', '30', 'NUMERO', 'DIAS', 'PRESTACIONES', 'CCO Construcción', '30 días por año', 41),
('PREST_BONO_FINIQUITO', 'CONST', 'Bono Finiquito Construcción', '15', 'NUMERO', 'DIAS', 'PRESTACIONES', 'CCO Construcción', 'Bono adicional finiquito', 42);

-- JORNADA CONSTRUCCIÓN
INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('JOR_HORAS_DIARIAS_CONST', 'CONST', 'Horas Diarias Construcción', '8', 'NUMERO', 'HORAS', 'JORNADA', 'CCO Construcción', '8 horas laborables', 80),
('JOR_HORAS_TOPE_SEMANA', 'CONST', 'Horas Semana Construcción', '44', 'NUMERO', 'HORAS', 'JORNADA', 'CCO Construcción', '44 horas semanales', 81),
('RECARGO_TRABAJO_CONTINUO', 'CONST', 'Recargo Trabajo Continuo %', '0.25', 'NUMERO', 'PORCENTAJE', 'JORNADA', 'CCO Construcción', '25% trabajo continuo', 82),
('BONO_TRANSPORTE_CONST', 'CONST', 'Bono Transporte Construcción', '0.05', 'NUMERO', 'PORCENTAJE', 'BENEFICIOS', 'CCO Construcción', '5% salario transporte', 90);

-- OBRA ESPECÍFICA
INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('BONO_OBRA_TERMINADA', 'CONST', 'Bono Obra Terminada', '30', 'NUMERO', 'DIAS', 'BENEFICIOS', 'CCO Construcción', '30 días al terminar obra', 95),
('VACACIONES_FRACCION_OBRA', 'CONST', 'Vacaciones Fracción Obra', '1.25', 'NUMERO', 'DIAS', 'VACACIONES', 'CCO Construcción', 'Por mes de obra', 15);

PRINT 'Constantes CONSTRUCCIÓN insertadas';
GO

-- =============================================
-- CONSTANTES POR TIPO DE NÓMINA
-- =============================================

INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, Descripcion, OrdenCalculo) VALUES
-- SEMANAL
('DIAS_PERIODO', 'SEMANAL', 'Días Período Semanal', '7', 'NUMERO', 'DIAS', 'PERIODO', 'Período semanal', 1),
('HORAS_PERIODO', 'SEMANAL', 'Horas Período Semanal', '40', 'NUMERO', 'HORAS', 'PERIODO', '40 horas semanales', 2),
('FACTOR_QUINCENA', 'SEMANAL', 'Factor Semanal a Quincena', '2.142857', 'NUMERO', 'FACTOR', 'PERIODO', 'Factor conversión', 3),
('FACTOR_MES', 'SEMANAL', 'Factor Semanal a Mes', '4.333333', 'NUMERO', 'FACTOR', 'PERIODO', 'Semanas por mes', 4),

-- QUINCENAL
('DIAS_PERIODO', 'QUINCENAL', 'Días Período Quincenal', '15', 'NUMERO', 'DIAS', 'PERIODO', 'Período quincenal', 1),
('HORAS_PERIODO', 'QUINCENAL', 'Horas Período Quincenal', '120', 'NUMERO', 'HORAS', 'PERIODO', '120 horas quincenal', 2),
('FACTOR_SEMANA', 'QUINCENAL', 'Factor Quincena a Semana', '0.466667', 'NUMERO', 'FACTOR', 'PERIODO', 'Factor conversión', 3),
('FACTOR_MES', 'QUINCENAL', 'Factor Quincena a Mes', '2', 'NUMERO', 'FACTOR', 'PERIODO', 'Quincenas por mes', 4),

-- MENSUAL
('DIAS_PERIODO', 'MENSUAL', 'Días Período Mensual', '30', 'NUMERO', 'DIAS', 'PERIODO', 'Período mensual', 1),
('HORAS_PERIODO', 'MENSUAL', 'Horas Período Mensual', '240', 'NUMERO', 'HORAS', 'PERIODO', '240 horas mensuales', 2),
('FACTOR_SEMANA', 'MENSUAL', 'Factor Mes a Semana', '4.333333', 'NUMERO', 'FACTOR', 'PERIODO', 'Semanas en mes', 3),
('FACTOR_QUINCENA', 'MENSUAL', 'Factor Mes a Quincena', '2', 'NUMERO', 'FACTOR', 'PERIODO', 'Quincenas en mes', 4),
('DIAS_UTIL_ANO', 'MENSUAL', 'Días Útil Año', '360', 'NUMERO', 'DIAS', 'PERIODO', 'Base 360 días año', 5);

PRINT 'Constantes por tipo de nómina insertadas';
GO

-- =============================================
-- INSERTAR CONCEPTOS POR RÉGIMEN
-- =============================================

-- CONCEPTOS LOT (Régimen General)
INSERT INTO ConceptosNominaRegimen (CoConcepto, Regimen, CoNomina, NbConcepto, Formula, Sobre, Tipo, Clase, Categoria, Bonificable, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('SUE_BASE', 'LOT', 'MENSUAL', 'Sueldo Base', 'SUELDO', NULL, 'ASIGNACION', 'FIJO', 'SALARIO_BASE', 1, 'Art. 104 LOTTT', 'Salario base mensual', 10),
('BON_ALIM', 'LOT', 'MENSUAL', 'Bono Alimentación', 'BONO_ALIMENTACION_DIA * DIAS_PERIODO', NULL, 'ASIGNACION', 'FORMULA', 'BENEFICIOS', 1, 'Art. 105 LOTTT', 'Bono de alimentación', 20),
('H_EXT_D', 'LOT', 'MENSUAL', 'Horas Extras Diurnas', 'HORAS_EXTRAS_DIURNAS * (SALARIO_HORA * (1 + RECARGO_EXTRAS_DIURNAS))', NULL, 'ASIGNACION', 'VARIABLE', 'HORAS_EXTRAS', 1, 'Art. 118 LOTTT', 'Horas extras diurnas', 30),
('H_EXT_N', 'LOT', 'MENSUAL', 'Horas Extras Nocturnas', 'HORAS_EXTRAS_NOCTURNAS * (SALARIO_HORA * (1 + RECARGO_EXTRAS_NOCTURNAS))', NULL, 'ASIGNACION', 'VARIABLE', 'HORAS_EXTRAS', 1, 'Art. 118 LOTTT', 'Horas extras nocturnas', 31),
('REC_NOC', 'LOT', 'MENSUAL', 'Recargo Nocturno', 'HORAS_NOCTURNAS * (SALARIO_HORA * RECARGO_NOCTURNO)', NULL, 'ASIGNACION', 'VARIABLE', 'RECARGOS', 1, 'Art. 118 LOTTT', 'Recargo trabajo nocturno', 40),
('REC_DF', 'LOT', 'MENSUAL', 'Recargo Día Feriado', 'HORAS_FERIADO * (SALARIO_HORA * RECARGO_DF)', NULL, 'ASIGNACION', 'VARIABLE', 'RECARGOS', 1, 'Art. 119 LOTTT', 'Trabajo día feriado', 41);

-- DEDUCCIONES LOT
INSERT INTO ConceptosNominaRegimen (CoConcepto, Regimen, CoNomina, NbConcepto, Formula, Sobre, Tipo, Clase, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('SSO', 'LOT', 'MENSUAL', 'Seguro Social Obligatorio', 'MENOR(SUELDO * SSO_PORC_EMPLEADO, SSO_TOPE_SALARIO * SUELDO_MIN * SSO_PORC_EMPLEADO)', NULL, 'DEDUCCION', 'FORMULA', 'SEGURIDAD_SOCIAL', 0, 'Art. 203 LOTTT', 'Retención SSO 4%', 100),
('FAOV', 'LOT', 'MENSUAL', 'Fondo Vivienda FAOV', 'SUELDO * FAOV_PORC_EMPLEADO', NULL, 'DEDUCCION', 'FORMULA', 'SEGURIDAD_SOCIAL', 0, 'Art. 203 LOTTT', 'Retención FAOV 1%', 101),
('LRPE', 'LOT', 'MENSUAL', 'Paro Forzoso LRPE', 'SUELDO * LRPE_PORC_EMPLEADO', NULL, 'DEDUCCION', 'FORMULA', 'SEGURIDAD_SOCIAL', 0, 'Art. 203 LOTTT', 'Retención LRPE 0.5%', 102),
('INCE', 'LOT', 'MENSUAL', 'INCE', 'SUELDO * INCE_PORC_EMPLEADO', NULL, 'DEDUCCION', 'FORMULA', 'SEGURIDAD_SOCIAL', 0, 'Art. 203 LOTTT', 'Retención INCE 0.5%', 103);

-- CONCEPTOS PETROLERO
INSERT INTO ConceptosNominaRegimen (CoConcepto, Regimen, CoNomina, NbConcepto, Formula, Sobre, Tipo, Clase, Categoria, Bonificable, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('SUE_BASE_PETRO', 'PETRO', 'MENSUAL', 'Sueldo Base Petrolero', 'SUELDO', NULL, 'ASIGNACION', 'FIJO', 'SALARIO_BASE', 1, 'Cláusula 15 CCT', 'Salario base sector petrolero', 10),
('BON_ALIM_PETRO', 'PETRO', 'MENSUAL', 'Bono Alimentación Petrolero', 'CESTA_TICKET_DIA * DIAS_TRABAJADOS', NULL, 'ASIGNACION', 'FORMULA', 'BENEFICIOS', 1, 'Cláusula 35 CCT', 'Cesta ticket petrolero', 20),
('REC_TURNO_ROT', 'PETRO', 'MENSUAL', 'Recargo Turno Rotativo', 'SUELDO * RECARGO_TURNO_ROTATIVO', NULL, 'ASIGNACION', 'FORMULA', 'RECARGOS', 1, 'Cláusula 18 CCT', 'Recargo por turno rotativo', 40),
('H_EXT_PETRO', 'PETRO', 'MENSUAL', 'Horas Exceso Petrolero', '(HORAS_TRABAJADAS - HORAS_NORMALES) * SALARIO_HORA * 1.5', 'HORAS_TRABAJADAS > HORAS_NORMALES', 'ASIGNACION', 'FORMULA', 'HORAS_EXTRAS', 1, 'Cláusula 20 CCT', 'Horas en exceso', 50);

-- CONCEPTOS CONSTRUCCIÓN
INSERT INTO ConceptosNominaRegimen (CoConcepto, Regimen, CoNomina, NbConcepto, Formula, Sobre, Tipo, Clase, Categoria, Bonificable, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('SUE_BASE_CONST', 'CONST', 'SEMANAL', 'Salario Semanal Construcción', 'SUELDO_DIARIO * DIAS_TRABAJADOS', NULL, 'ASIGNACION', 'FORMULA', 'SALARIO_BASE', 1, 'CCO Construcción', 'Salario por días trabajados', 10),
('BON_TRANSP_CONST', 'CONST', 'SEMANAL', 'Bono Transporte', 'SUE_BASE_CONST * BONO_TRANSPORTE_CONST', NULL, 'ASIGNACION', 'FORMULA', 'BENEFICIOS', 1, 'CCO Construcción', '5% transporte', 20),
('REC_TRAB_CONT', 'CONST', 'SEMANAL', 'Recargo Trabajo Continuo', 'SALARIO_HORA * HORAS_TRABAJADAS * RECARGO_TRABAJO_CONTINUO', NULL, 'ASIGNACION', 'FORMULA', 'RECARGOS', 1, 'CCO Construcción', 'Recargo trabajo continuo', 40);

PRINT 'Conceptos por régimen insertados';
GO

PRINT '=============================================';
PRINT 'SISTEMA DE CONSTANTES VENEZOLANO COMPLETADO';
PRINT '=============================================';
GO
