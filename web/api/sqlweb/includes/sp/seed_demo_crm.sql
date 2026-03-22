/*
 * seed_demo_crm.sql
 * ─────────────────
 * Seed de datos demo para modulo CRM.
 * Idempotente: verifica existencia antes de cada INSERT.
 *
 * Tablas afectadas:
 *   crm.Pipeline, crm.PipelineStage, crm.Lead,
 *   crm.Activity, crm.LeadHistory
 */
USE DatqBoxWeb;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

SET NOCOUNT ON;
GO

PRINT '=== Seed demo: CRM ===';
GO

-- ============================================================================
-- SECCION 1: crm.Pipeline  (1 pipeline)
-- ============================================================================
PRINT '>> 1. Pipeline demo...';

IF NOT EXISTS (SELECT 1 FROM crm.Pipeline WHERE CompanyId = 1 AND PipelineCode = N'CORP')
  INSERT INTO crm.Pipeline (CompanyId, PipelineCode, PipelineName, IsDefault, CreatedByUserId)
  VALUES (1, N'CORP', N'Ventas Corporativas', 1, 1);
GO

-- ============================================================================
-- SECCION 2: crm.PipelineStage  (6 etapas)
-- ============================================================================
PRINT '>> 2. Etapas del pipeline demo...';

DECLARE @PipelineId BIGINT = (SELECT PipelineId FROM crm.Pipeline WHERE CompanyId = 1 AND PipelineCode = N'CORP');

IF @PipelineId IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM crm.PipelineStage WHERE PipelineId = @PipelineId AND StageCode = N'PROSPECT')
    INSERT INTO crm.PipelineStage (PipelineId, StageCode, StageName, StageOrder, Probability, DaysExpected, Color, IsClosed, IsWon, CreatedByUserId)
    VALUES (@PipelineId, N'PROSPECT', N'Prospección', 1, 10.0000, 14, N'#3B82F6', 0, 0, 1);

  IF NOT EXISTS (SELECT 1 FROM crm.PipelineStage WHERE PipelineId = @PipelineId AND StageCode = N'QUALIFY')
    INSERT INTO crm.PipelineStage (PipelineId, StageCode, StageName, StageOrder, Probability, DaysExpected, Color, IsClosed, IsWon, CreatedByUserId)
    VALUES (@PipelineId, N'QUALIFY', N'Calificación', 2, 25.0000, 10, N'#06B6D4', 0, 0, 1);

  IF NOT EXISTS (SELECT 1 FROM crm.PipelineStage WHERE PipelineId = @PipelineId AND StageCode = N'PROPOSAL')
    INSERT INTO crm.PipelineStage (PipelineId, StageCode, StageName, StageOrder, Probability, DaysExpected, Color, IsClosed, IsWon, CreatedByUserId)
    VALUES (@PipelineId, N'PROPOSAL', N'Propuesta', 3, 50.0000, 7, N'#F97316', 0, 0, 1);

  IF NOT EXISTS (SELECT 1 FROM crm.PipelineStage WHERE PipelineId = @PipelineId AND StageCode = N'NEGOTIATION')
    INSERT INTO crm.PipelineStage (PipelineId, StageCode, StageName, StageOrder, Probability, DaysExpected, Color, IsClosed, IsWon, CreatedByUserId)
    VALUES (@PipelineId, N'NEGOTIATION', N'Negociación', 4, 75.0000, 5, N'#8B5CF6', 0, 0, 1);

  IF NOT EXISTS (SELECT 1 FROM crm.PipelineStage WHERE PipelineId = @PipelineId AND StageCode = N'CLOSED_WON')
    INSERT INTO crm.PipelineStage (PipelineId, StageCode, StageName, StageOrder, Probability, DaysExpected, Color, IsClosed, IsWon, CreatedByUserId)
    VALUES (@PipelineId, N'CLOSED_WON', N'Cierre', 5, 100.0000, 0, N'#22C55E', 1, 1, 1);

  IF NOT EXISTS (SELECT 1 FROM crm.PipelineStage WHERE PipelineId = @PipelineId AND StageCode = N'CLOSED_LOST')
    INSERT INTO crm.PipelineStage (PipelineId, StageCode, StageName, StageOrder, Probability, DaysExpected, Color, IsClosed, IsWon, CreatedByUserId)
    VALUES (@PipelineId, N'CLOSED_LOST', N'Perdido', 6, 0.0000, 0, N'#EF4444', 1, 0, 1);
END;
GO

-- ============================================================================
-- SECCION 3: crm.Lead  (8 leads)
-- ============================================================================
PRINT '>> 3. Leads demo...';

DECLARE @PipelineId2 BIGINT = (SELECT PipelineId FROM crm.Pipeline WHERE CompanyId = 1 AND PipelineCode = N'CORP');
DECLARE @StageProspect BIGINT = (SELECT StageId FROM crm.PipelineStage WHERE PipelineId = @PipelineId2 AND StageCode = N'PROSPECT');
DECLARE @StageQualify BIGINT = (SELECT StageId FROM crm.PipelineStage WHERE PipelineId = @PipelineId2 AND StageCode = N'QUALIFY');
DECLARE @StageProposal BIGINT = (SELECT StageId FROM crm.PipelineStage WHERE PipelineId = @PipelineId2 AND StageCode = N'PROPOSAL');
DECLARE @StageNegotiation BIGINT = (SELECT StageId FROM crm.PipelineStage WHERE PipelineId = @PipelineId2 AND StageCode = N'NEGOTIATION');
DECLARE @StageClosedWon BIGINT = (SELECT StageId FROM crm.PipelineStage WHERE PipelineId = @PipelineId2 AND StageCode = N'CLOSED_WON');
DECLARE @StageClosedLost BIGINT = (SELECT StageId FROM crm.PipelineStage WHERE PipelineId = @PipelineId2 AND StageCode = N'CLOSED_LOST');

IF @PipelineId2 IS NOT NULL
BEGIN
  -- Lead 1: Distribuidora El Sol (Prospeccion, WEB)
  IF NOT EXISTS (SELECT 1 FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-001')
    INSERT INTO crm.Lead (CompanyId, BranchId, PipelineId, StageId, LeadCode, ContactName, CompanyName, Email, Phone, Source, EstimatedValue, CurrencyCode, ExpectedCloseDate, Priority, Status, AssignedToUserId, CreatedByUserId)
    VALUES (1, 1, @PipelineId2, @StageProspect, N'LEAD-001', N'Luis Martínez', N'Distribuidora El Sol C.A.', N'lmartinez@distsol.com.ve', N'+58-212-5558001', N'WEB', 5000.00, N'USD', '2026-05-15', N'MEDIUM', N'OPEN', 1, 1);

  -- Lead 2: Hotel Bella Vista (Calificacion, REFERRAL)
  IF NOT EXISTS (SELECT 1 FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-002')
    INSERT INTO crm.Lead (CompanyId, BranchId, PipelineId, StageId, LeadCode, ContactName, CompanyName, Email, Phone, Source, EstimatedValue, CurrencyCode, ExpectedCloseDate, Priority, Status, AssignedToUserId, CreatedByUserId)
    VALUES (1, 1, @PipelineId2, @StageQualify, N'LEAD-002', N'Carmen Vásquez', N'Hotel Bella Vista', N'gerencia@bellavista.com.ve', N'+58-261-7891234', N'REFERRAL', 12000.00, N'USD', '2026-04-30', N'HIGH', N'OPEN', 1, 1);

  -- Lead 3: Farmacia Santa Ana (Propuesta, COLD_CALL)
  IF NOT EXISTS (SELECT 1 FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-003')
    INSERT INTO crm.Lead (CompanyId, BranchId, PipelineId, StageId, LeadCode, ContactName, CompanyName, Email, Phone, Source, EstimatedValue, CurrencyCode, ExpectedCloseDate, Priority, Status, AssignedToUserId, CreatedByUserId)
    VALUES (1, 1, @PipelineId2, @StageProposal, N'LEAD-003', N'Dr. Ramón Gutiérrez', N'Farmacia Santa Ana', N'compras@farmaciasantaana.ve', N'+58-243-5556789', N'COLD_CALL', 8500.00, N'USD', '2026-04-20', N'MEDIUM', N'OPEN', 1, 1);

  -- Lead 4: Restaurant La Casona (Negociacion, EVENT)
  IF NOT EXISTS (SELECT 1 FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-004')
    INSERT INTO crm.Lead (CompanyId, BranchId, PipelineId, StageId, LeadCode, ContactName, CompanyName, Email, Phone, Source, EstimatedValue, CurrencyCode, ExpectedCloseDate, Priority, Status, AssignedToUserId, CreatedByUserId)
    VALUES (1, 1, @PipelineId2, @StageNegotiation, N'LEAD-004', N'Chef Antonio Blanco', N'Restaurant La Casona', N'gerencia@lacasona.com.ve', N'+58-212-9991234', N'EVENT', 15000.00, N'USD', '2026-04-10', N'HIGH', N'OPEN', 1, 1);

  -- Lead 5: Clinica San Jose (Cierre, REFERRAL, WON)
  IF NOT EXISTS (SELECT 1 FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-005')
    INSERT INTO crm.Lead (CompanyId, BranchId, PipelineId, StageId, LeadCode, ContactName, CompanyName, Email, Phone, Source, EstimatedValue, CurrencyCode, ExpectedCloseDate, Priority, Status, WonAt, AssignedToUserId, CreatedByUserId)
    VALUES (1, 1, @PipelineId2, @StageClosedWon, N'LEAD-005', N'Dra. Isabel Moreno', N'Clínica San José', N'administracion@clinicasanjose.ve', N'+58-251-2345678', N'REFERRAL', 25000.00, N'USD', '2026-03-15', N'URGENT', N'WON', '2026-03-15 16:00:00', 1, 1);

  -- Lead 6: Automotriz del Centro (Perdido, WEB, LOST)
  IF NOT EXISTS (SELECT 1 FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-006')
    INSERT INTO crm.Lead (CompanyId, BranchId, PipelineId, StageId, LeadCode, ContactName, CompanyName, Email, Phone, Source, EstimatedValue, CurrencyCode, Priority, Status, LostReason, LostAt, AssignedToUserId, CreatedByUserId)
    VALUES (1, 1, @PipelineId2, @StageClosedLost, N'LEAD-006', N'Ing. Miguel Ángel Rivas', N'Automotriz del Centro C.A.', N'mrivas@automotrizcentro.ve', N'+58-241-8887654', N'WEB', 7000.00, N'USD', N'LOW', N'LOST', N'Eligieron competidor por menor precio - no se pudo igualar oferta', '2026-03-01 11:30:00', 1, 1);

  -- Lead 7: Supermercado El Triunfo (Prospeccion, SOCIAL)
  IF NOT EXISTS (SELECT 1 FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-007')
    INSERT INTO crm.Lead (CompanyId, BranchId, PipelineId, StageId, LeadCode, ContactName, CompanyName, Email, Phone, Source, EstimatedValue, CurrencyCode, ExpectedCloseDate, Priority, Status, AssignedToUserId, CreatedByUserId)
    VALUES (1, 1, @PipelineId2, @StageProspect, N'LEAD-007', N'Rosa Elena Paredes', N'Supermercado El Triunfo', N'rparedes@eltriunfo.com.ve', N'+58-414-7776655', N'SOCIAL', 3000.00, N'USD', '2026-06-01', N'LOW', N'OPEN', 1, 1);

  -- Lead 8: Ferreteria Los Andes (Calificacion, COLD_CALL)
  IF NOT EXISTS (SELECT 1 FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-008')
    INSERT INTO crm.Lead (CompanyId, BranchId, PipelineId, StageId, LeadCode, ContactName, CompanyName, Email, Phone, Source, EstimatedValue, CurrencyCode, ExpectedCloseDate, Priority, Status, AssignedToUserId, CreatedByUserId)
    VALUES (1, 1, @PipelineId2, @StageQualify, N'LEAD-008', N'Fernando Díaz', N'Ferretería Los Andes', N'fdiaz@ferreandes.ve', N'+58-274-2223344', N'COLD_CALL', 6000.00, N'USD', '2026-05-01', N'MEDIUM', N'OPEN', 1, 1);
END;
GO

-- ============================================================================
-- SECCION 4: crm.Activity  (10 actividades)
-- ============================================================================
PRINT '>> 4. Actividades demo...';

DECLARE @Lead1 BIGINT = (SELECT LeadId FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-001');
DECLARE @Lead2 BIGINT = (SELECT LeadId FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-002');
DECLARE @Lead3 BIGINT = (SELECT LeadId FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-003');
DECLARE @Lead4 BIGINT = (SELECT LeadId FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-004');
DECLARE @Lead5 BIGINT = (SELECT LeadId FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-005');
DECLARE @Lead6 BIGINT = (SELECT LeadId FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-006');
DECLARE @Lead7 BIGINT = (SELECT LeadId FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-007');
DECLARE @Lead8 BIGINT = (SELECT LeadId FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-008');

-- Actividad 1: Llamada inicial a Distribuidora El Sol (completada)
IF @Lead1 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM crm.Activity WHERE CompanyId = 1 AND LeadId = @Lead1 AND Subject = N'Llamada de primer contacto')
  INSERT INTO crm.Activity (CompanyId, LeadId, ActivityType, Subject, Description, DueDate, CompletedAt, IsCompleted, Priority, AssignedToUserId, CreatedByUserId)
  VALUES (1, @Lead1, N'CALL', N'Llamada de primer contacto', N'Contactar a Luis Martínez para presentar nuestro portafolio de soluciones ERP', '2026-03-18 10:00:00', '2026-03-18 10:25:00', 1, N'MEDIUM', 1, 1);

-- Actividad 2: Email de seguimiento a Hotel Bella Vista (completada)
IF @Lead2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM crm.Activity WHERE CompanyId = 1 AND LeadId = @Lead2 AND Subject = N'Envío de propuesta preliminar')
  INSERT INTO crm.Activity (CompanyId, LeadId, ActivityType, Subject, Description, DueDate, CompletedAt, IsCompleted, Priority, AssignedToUserId, CreatedByUserId)
  VALUES (1, @Lead2, N'EMAIL', N'Envío de propuesta preliminar', N'Enviar documento con funcionalidades del módulo hotelero y precios estimados', '2026-03-15 09:00:00', '2026-03-15 09:45:00', 1, N'HIGH', 1, 1);

-- Actividad 3: Reunion con Farmacia Santa Ana (completada)
IF @Lead3 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM crm.Activity WHERE CompanyId = 1 AND LeadId = @Lead3 AND Subject = N'Demo del sistema de inventario')
  INSERT INTO crm.Activity (CompanyId, LeadId, ActivityType, Subject, Description, DueDate, CompletedAt, IsCompleted, Priority, AssignedToUserId, CreatedByUserId)
  VALUES (1, @Lead3, N'MEETING', N'Demo del sistema de inventario', N'Presentar módulo de inventario con control de lotes y vencimientos para farmacia', '2026-03-12 14:00:00', '2026-03-12 15:30:00', 1, N'MEDIUM', 1, 1);

-- Actividad 4: Nota sobre Restaurant La Casona (completada)
IF @Lead4 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM crm.Activity WHERE CompanyId = 1 AND LeadId = @Lead4 AND Subject = N'Negociación de descuento por volumen')
  INSERT INTO crm.Activity (CompanyId, LeadId, ActivityType, Subject, Description, DueDate, CompletedAt, IsCompleted, Priority, AssignedToUserId, CreatedByUserId)
  VALUES (1, @Lead4, N'NOTE', N'Negociación de descuento por volumen', N'El chef Blanco solicita 15% descuento por implementar en sus 3 locales. Gerencia aprueba hasta 12%.', '2026-03-20 00:00:00', '2026-03-20 11:00:00', 1, N'HIGH', 1, 1);

-- Actividad 5: Tarea de seguimiento Clinica San Jose (completada)
IF @Lead5 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM crm.Activity WHERE CompanyId = 1 AND LeadId = @Lead5 AND Subject = N'Preparar contrato de implementación')
  INSERT INTO crm.Activity (CompanyId, LeadId, ActivityType, Subject, Description, DueDate, CompletedAt, IsCompleted, Priority, AssignedToUserId, CreatedByUserId)
  VALUES (1, @Lead5, N'TASK', N'Preparar contrato de implementación', N'Redactar contrato con SLA, cronograma de implementación y condiciones de pago', '2026-03-14 17:00:00', '2026-03-14 16:30:00', 1, N'URGENT', 1, 1);

-- Actividad 6: Email de perdida a Automotriz (completada)
IF @Lead6 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM crm.Activity WHERE CompanyId = 1 AND LeadId = @Lead6 AND Subject = N'Email de agradecimiento y puerta abierta')
  INSERT INTO crm.Activity (CompanyId, LeadId, ActivityType, Subject, Description, DueDate, CompletedAt, IsCompleted, Priority, AssignedToUserId, CreatedByUserId)
  VALUES (1, @Lead6, N'EMAIL', N'Email de agradecimiento y puerta abierta', N'Agradecer la oportunidad y dejar la puerta abierta para futuras necesidades', '2026-03-02 09:00:00', '2026-03-02 09:15:00', 1, N'LOW', 1, 1);

-- Actividad 7: Llamada pendiente a Supermercado El Triunfo
IF @Lead7 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM crm.Activity WHERE CompanyId = 1 AND LeadId = @Lead7 AND Subject = N'Llamada de seguimiento - redes sociales')
  INSERT INTO crm.Activity (CompanyId, LeadId, ActivityType, Subject, Description, DueDate, IsCompleted, Priority, AssignedToUserId, CreatedByUserId)
  VALUES (1, @Lead7, N'CALL', N'Llamada de seguimiento - redes sociales', N'Rosa Elena mostró interés via Instagram. Llamar para agendar reunión presencial.', '2026-03-25 11:00:00', 0, N'MEDIUM', 1, 1);

-- Actividad 8: Reunion pendiente con Ferreteria Los Andes
IF @Lead8 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM crm.Activity WHERE CompanyId = 1 AND LeadId = @Lead8 AND Subject = N'Reunión de levantamiento de requerimientos')
  INSERT INTO crm.Activity (CompanyId, LeadId, ActivityType, Subject, Description, DueDate, IsCompleted, Priority, AssignedToUserId, CreatedByUserId)
  VALUES (1, @Lead8, N'MEETING', N'Reunión de levantamiento de requerimientos', N'Visitar instalaciones en Mérida para evaluar necesidades de POS e inventario', '2026-03-28 09:00:00', 0, N'HIGH', 1, 1);

-- Actividad 9: Tarea pendiente - seguimiento Hotel Bella Vista
IF @Lead2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM crm.Activity WHERE CompanyId = 1 AND LeadId = @Lead2 AND Subject = N'Seguimiento post-propuesta')
  INSERT INTO crm.Activity (CompanyId, LeadId, ActivityType, Subject, Description, DueDate, IsCompleted, Priority, AssignedToUserId, CreatedByUserId)
  VALUES (1, @Lead2, N'FOLLOWUP', N'Seguimiento post-propuesta', N'Llamar a Carmen Vásquez para resolver dudas sobre la propuesta enviada', '2026-03-24 10:00:00', 0, N'HIGH', 1, 1);

-- Actividad 10: Tarea pendiente - preparar propuesta Restaurant La Casona
IF @Lead4 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM crm.Activity WHERE CompanyId = 1 AND LeadId = @Lead4 AND Subject = N'Preparar propuesta final con descuento')
  INSERT INTO crm.Activity (CompanyId, LeadId, ActivityType, Subject, Description, DueDate, IsCompleted, Priority, AssignedToUserId, CreatedByUserId)
  VALUES (1, @Lead4, N'TASK', N'Preparar propuesta final con descuento', N'Preparar propuesta con 12% descuento para 3 locales del restaurant', '2026-03-23 17:00:00', 0, N'URGENT', 1, 1);
GO

-- ============================================================================
-- SECCION 5: crm.LeadHistory  (5 cambios de etapa)
-- ============================================================================
PRINT '>> 5. Historial de leads demo...';

DECLARE @PipelineId3 BIGINT = (SELECT PipelineId FROM crm.Pipeline WHERE CompanyId = 1 AND PipelineCode = N'CORP');
DECLARE @SProspect BIGINT = (SELECT StageId FROM crm.PipelineStage WHERE PipelineId = @PipelineId3 AND StageCode = N'PROSPECT');
DECLARE @SQualify BIGINT = (SELECT StageId FROM crm.PipelineStage WHERE PipelineId = @PipelineId3 AND StageCode = N'QUALIFY');
DECLARE @SProposal BIGINT = (SELECT StageId FROM crm.PipelineStage WHERE PipelineId = @PipelineId3 AND StageCode = N'PROPOSAL');
DECLARE @SNegotiation BIGINT = (SELECT StageId FROM crm.PipelineStage WHERE PipelineId = @PipelineId3 AND StageCode = N'NEGOTIATION');
DECLARE @SClosedWon BIGINT = (SELECT StageId FROM crm.PipelineStage WHERE PipelineId = @PipelineId3 AND StageCode = N'CLOSED_WON');

DECLARE @LH_Lead2 BIGINT = (SELECT LeadId FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-002');
DECLARE @LH_Lead3 BIGINT = (SELECT LeadId FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-003');
DECLARE @LH_Lead4 BIGINT = (SELECT LeadId FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-004');
DECLARE @LH_Lead5 BIGINT = (SELECT LeadId FROM crm.Lead WHERE CompanyId = 1 AND LeadCode = N'LEAD-005');

-- Lead 2: Prospeccion -> Calificacion
IF @LH_Lead2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM crm.LeadHistory WHERE LeadId = @LH_Lead2 AND ChangeType = N'STAGE_CHANGE' AND ToStageId = @SQualify)
  INSERT INTO crm.LeadHistory (LeadId, FromStageId, ToStageId, ChangedByUserId, ChangeType, Notes, CreatedAt)
  VALUES (@LH_Lead2, @SProspect, @SQualify, 1, N'STAGE_CHANGE', N'Cliente interesado tras reunion inicial. Avanza a calificacion.', '2026-03-10 14:00:00');

-- Lead 3: Prospeccion -> Calificacion -> Propuesta
IF @LH_Lead3 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM crm.LeadHistory WHERE LeadId = @LH_Lead3 AND ChangeType = N'STAGE_CHANGE' AND ToStageId = @SQualify)
  INSERT INTO crm.LeadHistory (LeadId, FromStageId, ToStageId, ChangedByUserId, ChangeType, Notes, CreatedAt)
  VALUES (@LH_Lead3, @SProspect, @SQualify, 1, N'STAGE_CHANGE', N'Contacto por llamada en frio. Necesitan control de lotes y vencimientos.', '2026-03-05 10:00:00');

IF @LH_Lead3 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM crm.LeadHistory WHERE LeadId = @LH_Lead3 AND ChangeType = N'STAGE_CHANGE' AND ToStageId = @SProposal)
  INSERT INTO crm.LeadHistory (LeadId, FromStageId, ToStageId, ChangedByUserId, ChangeType, Notes, CreatedAt)
  VALUES (@LH_Lead3, @SQualify, @SProposal, 1, N'STAGE_CHANGE', N'Demo exitosa. Se envia propuesta formal con cronograma.', '2026-03-12 16:00:00');

-- Lead 4: Prospeccion -> ... -> Negociacion
IF @LH_Lead4 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM crm.LeadHistory WHERE LeadId = @LH_Lead4 AND ChangeType = N'STAGE_CHANGE' AND ToStageId = @SNegotiation)
  INSERT INTO crm.LeadHistory (LeadId, FromStageId, ToStageId, ChangedByUserId, ChangeType, Notes, CreatedAt)
  VALUES (@LH_Lead4, @SProposal, @SNegotiation, 1, N'STAGE_CHANGE', N'Aceptan propuesta base. Negociando descuento por 3 locales.', '2026-03-18 15:00:00');

-- Lead 5: Negociacion -> Cierre ganado
IF @LH_Lead5 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM crm.LeadHistory WHERE LeadId = @LH_Lead5 AND ChangeType = N'STAGE_CHANGE' AND ToStageId = @SClosedWon)
  INSERT INTO crm.LeadHistory (LeadId, FromStageId, ToStageId, ChangedByUserId, ChangeType, Notes, CreatedAt)
  VALUES (@LH_Lead5, @SNegotiation, @SClosedWon, 1, N'STAGE_CHANGE', N'Contrato firmado. Implementacion inicia 2026-04-01. Valor: $25,000 USD.', '2026-03-15 16:00:00');
GO

PRINT '=== Seed demo: CRM — COMPLETO ===';
GO
