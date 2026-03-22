/*
 * seed_demo_crm.sql (PostgreSQL)
 * ───────────────────────────────
 * Seed de datos demo para modulo CRM.
 * Idempotente: WHERE NOT EXISTS.
 *
 * Tablas afectadas:
 *   crm."Pipeline", crm."PipelineStage", crm."Lead",
 *   crm."Activity", crm."LeadHistory"
 */

DO $$
DECLARE
  v_company_id       INT := 1;
  v_branch_id        INT := 1;
  v_user_id          INT := 1;
  v_pipeline_id      BIGINT;
  v_stage_prospect   BIGINT;
  v_stage_qualify    BIGINT;
  v_stage_proposal   BIGINT;
  v_stage_negotiation BIGINT;
  v_stage_closed_won BIGINT;
  v_stage_closed_lost BIGINT;
  v_lead1 BIGINT;
  v_lead2 BIGINT;
  v_lead3 BIGINT;
  v_lead4 BIGINT;
  v_lead5 BIGINT;
  v_lead6 BIGINT;
  v_lead7 BIGINT;
  v_lead8 BIGINT;
BEGIN
  RAISE NOTICE '=== Seed demo: CRM ===';

  -- ============================================================================
  -- SECCION 1: crm."Pipeline" (1 pipeline)
  -- ============================================================================
  RAISE NOTICE '>> 1. Pipeline demo...';

  INSERT INTO crm."Pipeline" ("CompanyId", "PipelineCode", "PipelineName", "IsDefault", "CreatedByUserId")
  SELECT v_company_id, 'CORP', 'Ventas Corporativas', TRUE, v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM crm."Pipeline" WHERE "CompanyId" = v_company_id AND "PipelineCode" = 'CORP' AND "IsDeleted" = FALSE);

  SELECT "PipelineId" INTO v_pipeline_id FROM crm."Pipeline" WHERE "CompanyId" = v_company_id AND "PipelineCode" = 'CORP' AND "IsDeleted" = FALSE LIMIT 1;

  -- ============================================================================
  -- SECCION 2: crm."PipelineStage" (6 etapas)
  -- ============================================================================
  RAISE NOTICE '>> 2. Etapas del pipeline demo...';

  IF v_pipeline_id IS NOT NULL THEN
    INSERT INTO crm."PipelineStage" ("PipelineId", "StageCode", "StageName", "StageOrder", "Probability", "DaysExpected", "Color", "IsClosed", "IsWon", "CreatedByUserId")
    SELECT v_pipeline_id, 'PROSPECT', 'Prospección', 1, 10.00, 14, '#3B82F6', FALSE, FALSE, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."PipelineStage" WHERE "PipelineId" = v_pipeline_id AND "StageCode" = 'PROSPECT' AND "IsDeleted" = FALSE);

    INSERT INTO crm."PipelineStage" ("PipelineId", "StageCode", "StageName", "StageOrder", "Probability", "DaysExpected", "Color", "IsClosed", "IsWon", "CreatedByUserId")
    SELECT v_pipeline_id, 'QUALIFY', 'Calificación', 2, 25.00, 10, '#06B6D4', FALSE, FALSE, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."PipelineStage" WHERE "PipelineId" = v_pipeline_id AND "StageCode" = 'QUALIFY' AND "IsDeleted" = FALSE);

    INSERT INTO crm."PipelineStage" ("PipelineId", "StageCode", "StageName", "StageOrder", "Probability", "DaysExpected", "Color", "IsClosed", "IsWon", "CreatedByUserId")
    SELECT v_pipeline_id, 'PROPOSAL', 'Propuesta', 3, 50.00, 7, '#F97316', FALSE, FALSE, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."PipelineStage" WHERE "PipelineId" = v_pipeline_id AND "StageCode" = 'PROPOSAL' AND "IsDeleted" = FALSE);

    INSERT INTO crm."PipelineStage" ("PipelineId", "StageCode", "StageName", "StageOrder", "Probability", "DaysExpected", "Color", "IsClosed", "IsWon", "CreatedByUserId")
    SELECT v_pipeline_id, 'NEGOTIATION', 'Negociación', 4, 75.00, 5, '#8B5CF6', FALSE, FALSE, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."PipelineStage" WHERE "PipelineId" = v_pipeline_id AND "StageCode" = 'NEGOTIATION' AND "IsDeleted" = FALSE);

    INSERT INTO crm."PipelineStage" ("PipelineId", "StageCode", "StageName", "StageOrder", "Probability", "DaysExpected", "Color", "IsClosed", "IsWon", "CreatedByUserId")
    SELECT v_pipeline_id, 'CLOSED_WON', 'Cierre', 5, 100.00, 0, '#22C55E', TRUE, TRUE, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."PipelineStage" WHERE "PipelineId" = v_pipeline_id AND "StageCode" = 'CLOSED_WON' AND "IsDeleted" = FALSE);

    INSERT INTO crm."PipelineStage" ("PipelineId", "StageCode", "StageName", "StageOrder", "Probability", "DaysExpected", "Color", "IsClosed", "IsWon", "CreatedByUserId")
    SELECT v_pipeline_id, 'CLOSED_LOST', 'Perdido', 6, 0.00, 0, '#EF4444', TRUE, FALSE, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."PipelineStage" WHERE "PipelineId" = v_pipeline_id AND "StageCode" = 'CLOSED_LOST' AND "IsDeleted" = FALSE);

    -- Obtener IDs de etapas
    SELECT "StageId" INTO v_stage_prospect FROM crm."PipelineStage" WHERE "PipelineId" = v_pipeline_id AND "StageCode" = 'PROSPECT' AND "IsDeleted" = FALSE LIMIT 1;
    SELECT "StageId" INTO v_stage_qualify FROM crm."PipelineStage" WHERE "PipelineId" = v_pipeline_id AND "StageCode" = 'QUALIFY' AND "IsDeleted" = FALSE LIMIT 1;
    SELECT "StageId" INTO v_stage_proposal FROM crm."PipelineStage" WHERE "PipelineId" = v_pipeline_id AND "StageCode" = 'PROPOSAL' AND "IsDeleted" = FALSE LIMIT 1;
    SELECT "StageId" INTO v_stage_negotiation FROM crm."PipelineStage" WHERE "PipelineId" = v_pipeline_id AND "StageCode" = 'NEGOTIATION' AND "IsDeleted" = FALSE LIMIT 1;
    SELECT "StageId" INTO v_stage_closed_won FROM crm."PipelineStage" WHERE "PipelineId" = v_pipeline_id AND "StageCode" = 'CLOSED_WON' AND "IsDeleted" = FALSE LIMIT 1;
    SELECT "StageId" INTO v_stage_closed_lost FROM crm."PipelineStage" WHERE "PipelineId" = v_pipeline_id AND "StageCode" = 'CLOSED_LOST' AND "IsDeleted" = FALSE LIMIT 1;
  END IF;

  -- ============================================================================
  -- SECCION 3: crm."Lead" (8 leads)
  -- ============================================================================
  RAISE NOTICE '>> 3. Leads demo...';

  IF v_pipeline_id IS NOT NULL THEN
    -- Lead 1: Distribuidora El Sol (Prospeccion, WEB)
    INSERT INTO crm."Lead" ("CompanyId", "BranchId", "PipelineId", "StageId", "LeadCode", "ContactName", "CompanyName", "Email", "Phone", "Source", "EstimatedValue", "CurrencyCode", "ExpectedCloseDate", "Priority", "Status", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_branch_id, v_pipeline_id, v_stage_prospect, 'LEAD-001', 'Luis Martínez', 'Distribuidora El Sol C.A.', 'lmartinez@distsol.com.ve', '+58-212-5558001', 'WEB', 5000.00, 'USD', '2026-05-15', 'MEDIUM', 'OPEN', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-001' AND "IsDeleted" = FALSE);

    -- Lead 2: Hotel Bella Vista (Calificacion, REFERRAL)
    INSERT INTO crm."Lead" ("CompanyId", "BranchId", "PipelineId", "StageId", "LeadCode", "ContactName", "CompanyName", "Email", "Phone", "Source", "EstimatedValue", "CurrencyCode", "ExpectedCloseDate", "Priority", "Status", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_branch_id, v_pipeline_id, v_stage_qualify, 'LEAD-002', 'Carmen Vásquez', 'Hotel Bella Vista', 'gerencia@bellavista.com.ve', '+58-261-7891234', 'REFERRAL', 12000.00, 'USD', '2026-04-30', 'HIGH', 'OPEN', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-002' AND "IsDeleted" = FALSE);

    -- Lead 3: Farmacia Santa Ana (Propuesta, COLD_CALL)
    INSERT INTO crm."Lead" ("CompanyId", "BranchId", "PipelineId", "StageId", "LeadCode", "ContactName", "CompanyName", "Email", "Phone", "Source", "EstimatedValue", "CurrencyCode", "ExpectedCloseDate", "Priority", "Status", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_branch_id, v_pipeline_id, v_stage_proposal, 'LEAD-003', 'Dr. Ramón Gutiérrez', 'Farmacia Santa Ana', 'compras@farmaciasantaana.ve', '+58-243-5556789', 'COLD_CALL', 8500.00, 'USD', '2026-04-20', 'MEDIUM', 'OPEN', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-003' AND "IsDeleted" = FALSE);

    -- Lead 4: Restaurant La Casona (Negociacion, EVENT)
    INSERT INTO crm."Lead" ("CompanyId", "BranchId", "PipelineId", "StageId", "LeadCode", "ContactName", "CompanyName", "Email", "Phone", "Source", "EstimatedValue", "CurrencyCode", "ExpectedCloseDate", "Priority", "Status", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_branch_id, v_pipeline_id, v_stage_negotiation, 'LEAD-004', 'Chef Antonio Blanco', 'Restaurant La Casona', 'gerencia@lacasona.com.ve', '+58-212-9991234', 'EVENT', 15000.00, 'USD', '2026-04-10', 'HIGH', 'OPEN', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-004' AND "IsDeleted" = FALSE);

    -- Lead 5: Clinica San Jose (Cierre, REFERRAL, WON)
    INSERT INTO crm."Lead" ("CompanyId", "BranchId", "PipelineId", "StageId", "LeadCode", "ContactName", "CompanyName", "Email", "Phone", "Source", "EstimatedValue", "CurrencyCode", "ExpectedCloseDate", "Priority", "Status", "WonAt", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_branch_id, v_pipeline_id, v_stage_closed_won, 'LEAD-005', 'Dra. Isabel Moreno', 'Clínica San José', 'administracion@clinicasanjose.ve', '+58-251-2345678', 'REFERRAL', 25000.00, 'USD', '2026-03-15', 'URGENT', 'WON', '2026-03-15 16:00:00'::TIMESTAMP, v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-005' AND "IsDeleted" = FALSE);

    -- Lead 6: Automotriz del Centro (Perdido, WEB, LOST)
    INSERT INTO crm."Lead" ("CompanyId", "BranchId", "PipelineId", "StageId", "LeadCode", "ContactName", "CompanyName", "Email", "Phone", "Source", "EstimatedValue", "CurrencyCode", "Priority", "Status", "LostReason", "LostAt", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_branch_id, v_pipeline_id, v_stage_closed_lost, 'LEAD-006', 'Ing. Miguel Ángel Rivas', 'Automotriz del Centro C.A.', 'mrivas@automotrizcentro.ve', '+58-241-8887654', 'WEB', 7000.00, 'USD', 'LOW', 'LOST', 'Eligieron competidor por menor precio - no se pudo igualar oferta', '2026-03-01 11:30:00'::TIMESTAMP, v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-006' AND "IsDeleted" = FALSE);

    -- Lead 7: Supermercado El Triunfo (Prospeccion, SOCIAL)
    INSERT INTO crm."Lead" ("CompanyId", "BranchId", "PipelineId", "StageId", "LeadCode", "ContactName", "CompanyName", "Email", "Phone", "Source", "EstimatedValue", "CurrencyCode", "ExpectedCloseDate", "Priority", "Status", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_branch_id, v_pipeline_id, v_stage_prospect, 'LEAD-007', 'Rosa Elena Paredes', 'Supermercado El Triunfo', 'rparedes@eltriunfo.com.ve', '+58-414-7776655', 'SOCIAL', 3000.00, 'USD', '2026-06-01', 'LOW', 'OPEN', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-007' AND "IsDeleted" = FALSE);

    -- Lead 8: Ferreteria Los Andes (Calificacion, COLD_CALL)
    INSERT INTO crm."Lead" ("CompanyId", "BranchId", "PipelineId", "StageId", "LeadCode", "ContactName", "CompanyName", "Email", "Phone", "Source", "EstimatedValue", "CurrencyCode", "ExpectedCloseDate", "Priority", "Status", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_branch_id, v_pipeline_id, v_stage_qualify, 'LEAD-008', 'Fernando Díaz', 'Ferretería Los Andes', 'fdiaz@ferreandes.ve', '+58-274-2223344', 'COLD_CALL', 6000.00, 'USD', '2026-05-01', 'MEDIUM', 'OPEN', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-008' AND "IsDeleted" = FALSE);
  END IF;

  -- Obtener IDs de leads
  SELECT "LeadId" INTO v_lead1 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-001' AND "IsDeleted" = FALSE LIMIT 1;
  SELECT "LeadId" INTO v_lead2 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-002' AND "IsDeleted" = FALSE LIMIT 1;
  SELECT "LeadId" INTO v_lead3 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-003' AND "IsDeleted" = FALSE LIMIT 1;
  SELECT "LeadId" INTO v_lead4 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-004' AND "IsDeleted" = FALSE LIMIT 1;
  SELECT "LeadId" INTO v_lead5 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-005' AND "IsDeleted" = FALSE LIMIT 1;
  SELECT "LeadId" INTO v_lead6 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-006' AND "IsDeleted" = FALSE LIMIT 1;
  SELECT "LeadId" INTO v_lead7 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-007' AND "IsDeleted" = FALSE LIMIT 1;
  SELECT "LeadId" INTO v_lead8 FROM crm."Lead" WHERE "CompanyId" = v_company_id AND "LeadCode" = 'LEAD-008' AND "IsDeleted" = FALSE LIMIT 1;

  -- ============================================================================
  -- SECCION 4: crm."Activity" (10 actividades)
  -- ============================================================================
  RAISE NOTICE '>> 4. Actividades demo...';

  -- Actividad 1: Llamada inicial a Distribuidora El Sol (completada)
  IF v_lead1 IS NOT NULL THEN
    INSERT INTO crm."Activity" ("CompanyId", "LeadId", "ActivityType", "Subject", "Description", "DueDate", "CompletedAt", "IsCompleted", "Priority", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_lead1, 'CALL', 'Llamada de primer contacto', 'Contactar a Luis Martínez para presentar nuestro portafolio de soluciones ERP', '2026-03-18 10:00:00'::TIMESTAMP, '2026-03-18 10:25:00'::TIMESTAMP, TRUE, 'MEDIUM', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Activity" WHERE "CompanyId" = v_company_id AND "LeadId" = v_lead1 AND "Subject" = 'Llamada de primer contacto');
  END IF;

  -- Actividad 2: Email de seguimiento a Hotel Bella Vista (completada)
  IF v_lead2 IS NOT NULL THEN
    INSERT INTO crm."Activity" ("CompanyId", "LeadId", "ActivityType", "Subject", "Description", "DueDate", "CompletedAt", "IsCompleted", "Priority", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_lead2, 'EMAIL', 'Envío de propuesta preliminar', 'Enviar documento con funcionalidades del módulo hotelero y precios estimados', '2026-03-15 09:00:00'::TIMESTAMP, '2026-03-15 09:45:00'::TIMESTAMP, TRUE, 'HIGH', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Activity" WHERE "CompanyId" = v_company_id AND "LeadId" = v_lead2 AND "Subject" = 'Envío de propuesta preliminar');
  END IF;

  -- Actividad 3: Reunion con Farmacia Santa Ana (completada)
  IF v_lead3 IS NOT NULL THEN
    INSERT INTO crm."Activity" ("CompanyId", "LeadId", "ActivityType", "Subject", "Description", "DueDate", "CompletedAt", "IsCompleted", "Priority", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_lead3, 'MEETING', 'Demo del sistema de inventario', 'Presentar módulo de inventario con control de lotes y vencimientos para farmacia', '2026-03-12 14:00:00'::TIMESTAMP, '2026-03-12 15:30:00'::TIMESTAMP, TRUE, 'MEDIUM', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Activity" WHERE "CompanyId" = v_company_id AND "LeadId" = v_lead3 AND "Subject" = 'Demo del sistema de inventario');
  END IF;

  -- Actividad 4: Nota sobre Restaurant La Casona (completada)
  IF v_lead4 IS NOT NULL THEN
    INSERT INTO crm."Activity" ("CompanyId", "LeadId", "ActivityType", "Subject", "Description", "DueDate", "CompletedAt", "IsCompleted", "Priority", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_lead4, 'NOTE', 'Negociación de descuento por volumen', 'El chef Blanco solicita 15% descuento por implementar en sus 3 locales. Gerencia aprueba hasta 12%.', '2026-03-20 00:00:00'::TIMESTAMP, '2026-03-20 11:00:00'::TIMESTAMP, TRUE, 'HIGH', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Activity" WHERE "CompanyId" = v_company_id AND "LeadId" = v_lead4 AND "Subject" = 'Negociación de descuento por volumen');
  END IF;

  -- Actividad 5: Tarea de seguimiento Clinica San Jose (completada)
  IF v_lead5 IS NOT NULL THEN
    INSERT INTO crm."Activity" ("CompanyId", "LeadId", "ActivityType", "Subject", "Description", "DueDate", "CompletedAt", "IsCompleted", "Priority", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_lead5, 'TASK', 'Preparar contrato de implementación', 'Redactar contrato con SLA, cronograma de implementación y condiciones de pago', '2026-03-14 17:00:00'::TIMESTAMP, '2026-03-14 16:30:00'::TIMESTAMP, TRUE, 'URGENT', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Activity" WHERE "CompanyId" = v_company_id AND "LeadId" = v_lead5 AND "Subject" = 'Preparar contrato de implementación');
  END IF;

  -- Actividad 6: Email de perdida a Automotriz (completada)
  IF v_lead6 IS NOT NULL THEN
    INSERT INTO crm."Activity" ("CompanyId", "LeadId", "ActivityType", "Subject", "Description", "DueDate", "CompletedAt", "IsCompleted", "Priority", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_lead6, 'EMAIL', 'Email de agradecimiento y puerta abierta', 'Agradecer la oportunidad y dejar la puerta abierta para futuras necesidades', '2026-03-02 09:00:00'::TIMESTAMP, '2026-03-02 09:15:00'::TIMESTAMP, TRUE, 'LOW', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Activity" WHERE "CompanyId" = v_company_id AND "LeadId" = v_lead6 AND "Subject" = 'Email de agradecimiento y puerta abierta');
  END IF;

  -- Actividad 7: Llamada pendiente a Supermercado El Triunfo
  IF v_lead7 IS NOT NULL THEN
    INSERT INTO crm."Activity" ("CompanyId", "LeadId", "ActivityType", "Subject", "Description", "DueDate", "IsCompleted", "Priority", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_lead7, 'CALL', 'Llamada de seguimiento - redes sociales', 'Rosa Elena mostró interés via Instagram. Llamar para agendar reunión presencial.', '2026-03-25 11:00:00'::TIMESTAMP, FALSE, 'MEDIUM', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Activity" WHERE "CompanyId" = v_company_id AND "LeadId" = v_lead7 AND "Subject" = 'Llamada de seguimiento - redes sociales');
  END IF;

  -- Actividad 8: Reunion pendiente con Ferreteria Los Andes
  IF v_lead8 IS NOT NULL THEN
    INSERT INTO crm."Activity" ("CompanyId", "LeadId", "ActivityType", "Subject", "Description", "DueDate", "IsCompleted", "Priority", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_lead8, 'MEETING', 'Reunión de levantamiento de requerimientos', 'Visitar instalaciones en Mérida para evaluar necesidades de POS e inventario', '2026-03-28 09:00:00'::TIMESTAMP, FALSE, 'HIGH', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Activity" WHERE "CompanyId" = v_company_id AND "LeadId" = v_lead8 AND "Subject" = 'Reunión de levantamiento de requerimientos');
  END IF;

  -- Actividad 9: Tarea pendiente - seguimiento Hotel Bella Vista
  IF v_lead2 IS NOT NULL THEN
    INSERT INTO crm."Activity" ("CompanyId", "LeadId", "ActivityType", "Subject", "Description", "DueDate", "IsCompleted", "Priority", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_lead2, 'FOLLOWUP', 'Seguimiento post-propuesta', 'Llamar a Carmen Vásquez para resolver dudas sobre la propuesta enviada', '2026-03-24 10:00:00'::TIMESTAMP, FALSE, 'HIGH', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Activity" WHERE "CompanyId" = v_company_id AND "LeadId" = v_lead2 AND "Subject" = 'Seguimiento post-propuesta');
  END IF;

  -- Actividad 10: Tarea pendiente - preparar propuesta Restaurant La Casona
  IF v_lead4 IS NOT NULL THEN
    INSERT INTO crm."Activity" ("CompanyId", "LeadId", "ActivityType", "Subject", "Description", "DueDate", "IsCompleted", "Priority", "AssignedToUserId", "CreatedByUserId")
    SELECT v_company_id, v_lead4, 'TASK', 'Preparar propuesta final con descuento', 'Preparar propuesta con 12% descuento para 3 locales del restaurant', '2026-03-23 17:00:00'::TIMESTAMP, FALSE, 'URGENT', v_user_id, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM crm."Activity" WHERE "CompanyId" = v_company_id AND "LeadId" = v_lead4 AND "Subject" = 'Preparar propuesta final con descuento');
  END IF;

  -- ============================================================================
  -- SECCION 5: crm."LeadHistory" (5 cambios de etapa)
  -- ============================================================================
  RAISE NOTICE '>> 5. Historial de leads demo...';

  -- Lead 2: Prospeccion -> Calificacion
  IF v_lead2 IS NOT NULL THEN
    INSERT INTO crm."LeadHistory" ("LeadId", "FromStageId", "ToStageId", "ChangedByUserId", "ChangeType", "Notes", "CreatedAt")
    SELECT v_lead2, v_stage_prospect, v_stage_qualify, v_user_id, 'STAGE_CHANGE', 'Cliente interesado tras reunion inicial. Avanza a calificacion.', '2026-03-10 14:00:00'::TIMESTAMP
    WHERE NOT EXISTS (SELECT 1 FROM crm."LeadHistory" WHERE "LeadId" = v_lead2 AND "ChangeType" = 'STAGE_CHANGE' AND "ToStageId" = v_stage_qualify);
  END IF;

  -- Lead 3: Prospeccion -> Calificacion
  IF v_lead3 IS NOT NULL THEN
    INSERT INTO crm."LeadHistory" ("LeadId", "FromStageId", "ToStageId", "ChangedByUserId", "ChangeType", "Notes", "CreatedAt")
    SELECT v_lead3, v_stage_prospect, v_stage_qualify, v_user_id, 'STAGE_CHANGE', 'Contacto por llamada en frio. Necesitan control de lotes y vencimientos.', '2026-03-05 10:00:00'::TIMESTAMP
    WHERE NOT EXISTS (SELECT 1 FROM crm."LeadHistory" WHERE "LeadId" = v_lead3 AND "ChangeType" = 'STAGE_CHANGE' AND "ToStageId" = v_stage_qualify);
  END IF;

  -- Lead 3: Calificacion -> Propuesta
  IF v_lead3 IS NOT NULL THEN
    INSERT INTO crm."LeadHistory" ("LeadId", "FromStageId", "ToStageId", "ChangedByUserId", "ChangeType", "Notes", "CreatedAt")
    SELECT v_lead3, v_stage_qualify, v_stage_proposal, v_user_id, 'STAGE_CHANGE', 'Demo exitosa. Se envia propuesta formal con cronograma.', '2026-03-12 16:00:00'::TIMESTAMP
    WHERE NOT EXISTS (SELECT 1 FROM crm."LeadHistory" WHERE "LeadId" = v_lead3 AND "ChangeType" = 'STAGE_CHANGE' AND "ToStageId" = v_stage_proposal);
  END IF;

  -- Lead 4: Propuesta -> Negociacion
  IF v_lead4 IS NOT NULL THEN
    INSERT INTO crm."LeadHistory" ("LeadId", "FromStageId", "ToStageId", "ChangedByUserId", "ChangeType", "Notes", "CreatedAt")
    SELECT v_lead4, v_stage_proposal, v_stage_negotiation, v_user_id, 'STAGE_CHANGE', 'Aceptan propuesta base. Negociando descuento por 3 locales.', '2026-03-18 15:00:00'::TIMESTAMP
    WHERE NOT EXISTS (SELECT 1 FROM crm."LeadHistory" WHERE "LeadId" = v_lead4 AND "ChangeType" = 'STAGE_CHANGE' AND "ToStageId" = v_stage_negotiation);
  END IF;

  -- Lead 5: Negociacion -> Cierre ganado
  IF v_lead5 IS NOT NULL THEN
    INSERT INTO crm."LeadHistory" ("LeadId", "FromStageId", "ToStageId", "ChangedByUserId", "ChangeType", "Notes", "CreatedAt")
    SELECT v_lead5, v_stage_negotiation, v_stage_closed_won, v_user_id, 'STAGE_CHANGE', 'Contrato firmado. Implementacion inicia 2026-04-01. Valor: $25,000 USD.', '2026-03-15 16:00:00'::TIMESTAMP
    WHERE NOT EXISTS (SELECT 1 FROM crm."LeadHistory" WHERE "LeadId" = v_lead5 AND "ChangeType" = 'STAGE_CHANGE' AND "ToStageId" = v_stage_closed_won);
  END IF;

  RAISE NOTICE '=== Seed demo: CRM — COMPLETO ===';
END $$;
