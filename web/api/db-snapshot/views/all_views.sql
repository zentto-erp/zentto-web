-- =============================================
-- VIEW: dbo.AccesoUsuarios
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- --- dbo.AccesoUsuarios ---
CREATE VIEW dbo.AccesoUsuarios AS
SELECT
    UserCode   AS Cod_Usuario,
    ModuleCode AS Modulo,
    IsAllowed  AS Permitido,
    CreatedAt,
    UpdatedAt
FROM sec.UserModuleAccess;

GO
 
 
-- =============================================
-- VIEW: dbo.DocumentosCompra
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- --- dbo.DocumentosCompra ---
CREATE VIEW dbo.DocumentosCompra AS
SELECT
    DocumentId                     AS ID,
    DocumentNumber                 AS NUM_DOC,
    SerialType                     AS SERIALTIPO,
    OperationType                  AS TIPO_OPERACION,
    SupplierCode                   AS COD_PROVEEDOR,
    SupplierName                   AS NOMBRE,
    FiscalId                       AS RIF,
    DocumentDate                   AS FECHA,
    DueDate                        AS FECHA_VENCE,
    ReceiptDate                    AS FECHA_RECIBO,
    PaymentDate                    AS FECHA_PAGO,
    DocumentTime                   AS HORA,
    CAST(SubTotal           AS FLOAT)  AS SUBTOTAL,
    CAST(TaxableAmount      AS FLOAT)  AS MONTO_GRA,
    CAST(ExemptAmount       AS FLOAT)  AS MONTO_EXE,
    CAST(TaxAmount          AS FLOAT)  AS IVA,
    CAST(TaxRate            AS FLOAT)  AS ALICUOTA,
    CAST(TotalAmount        AS FLOAT)  AS TOTAL,
    CAST(ExemptTotalAmount  AS FLOAT)  AS EXENTO,
    CAST(DiscountAmount     AS FLOAT)  AS DESCUENTO,
    IsVoided                           AS ANULADA,
    IsPaid                             AS CANCELADA,
    IsReceived                         AS RECIBIDA,
    IsLegal                            AS LEGAL,
    OriginDocumentNumber               AS DOC_ORIGEN,
    ControlNumber                      AS NUM_CONTROL,
    VoucherNumber                      AS NRO_COMPROBANTE,
    VoucherDate                        AS FECHA_COMPROBANTE,
    CAST(RetainedTax        AS FLOAT)  AS IVA_RETENIDO,
    IsrCode                            AS ISLR,
    CAST(IsrAmount          AS FLOAT)  AS MONTO_ISLR,
    IsrCode                            AS CODIGO_ISLR,
    CAST(IsrSubjectAmount   AS FLOAT)  AS SUJETO_ISLR,
    CAST(RetentionRate      AS FLOAT)  AS TASA_RETENCION,
    CAST(ImportAmount       AS FLOAT)  AS IMPORTACION,
    CAST(ImportTax          AS FLOAT)  AS IVA_IMPORT,
    CAST(ImportBase         AS FLOAT)  AS BASE_IMPORT,
    CAST(FreightAmount      AS FLOAT)  AS FLETE,
    Concept                            AS CONCEPTO,
    Notes                              AS OBSERV,
    OrderNumber                        AS PEDIDO,
    ReceivedBy                         AS RECIBIDO,
    WarehouseCode                      AS ALMACEN,
    CurrencyCode                       AS MONEDA,
    CAST(ExchangeRate       AS FLOAT)  AS TASA_CAMBIO,
    CAST(UsdAmount          AS FLOAT)  AS PRECIO_DOLLAR,
    UserCode                           AS COD_USUARIO,
    ShortUserCode                      AS CO_USUARIO,
    ReportDate                         AS FECHA_REPORTE,
    HostName                           AS COMPUTER,
    CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId,
    IsDeleted, DeletedAt, DeletedByUserId,
    RowVer
FROM ap.PurchaseDocument;

GO
 
 
-- =============================================
-- VIEW: dbo.DocumentosCompraDetalle
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- --- dbo.DocumentosCompraDetalle ---
CREATE VIEW dbo.DocumentosCompraDetalle AS
SELECT
    LineId                         AS ID,
    DocumentNumber                 AS NUM_DOC,
    OperationType                  AS TIPO_OPERACION,
    LineNumber                     AS RENGLON,
    ProductCode                    AS COD_SERV,
    Description                    AS DESCRIPCION,
    CAST(Quantity       AS FLOAT)  AS CANTIDAD,
    CAST(UnitPrice      AS FLOAT)  AS PRECIO,
    CAST(UnitCost       AS FLOAT)  AS COSTO,
    CAST(SubTotal       AS FLOAT)  AS SUBTOTAL,
    CAST(DiscountAmount AS FLOAT)  AS DESCUENTO,
    CAST(TotalAmount    AS FLOAT)  AS TOTAL,
    CAST(TaxRate        AS FLOAT)  AS ALICUOTA,
    CAST(TaxAmount      AS FLOAT)  AS MONTO_IVA,
    IsVoided                       AS ANULADA,
    UserCode                       AS CO_USUARIO,
    LineDate                       AS FECHA,
    CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId,
    IsDeleted, DeletedAt, DeletedByUserId,
    RowVer
FROM ap.PurchaseDocumentLine;

GO
 
 
-- =============================================
-- VIEW: dbo.DocumentosCompraPago
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- --- dbo.DocumentosCompraPago ---
CREATE VIEW dbo.DocumentosCompraPago AS
SELECT
    PaymentId                      AS ID,
    DocumentNumber                 AS NUM_DOC,
    OperationType                  AS TIPO_OPERACION,
    PaymentMethod                  AS TIPO_PAGO,
    BankCode                       AS BANCO,
    PaymentNumber                  AS NUMERO,
    CAST(Amount         AS FLOAT)  AS MONTO,
    PaymentDate                    AS FECHA,
    DueDate                        AS FECHA_VENCE,
    ReferenceNumber                AS REFERENCIA,
    UserCode                       AS CO_USUARIO,
    CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId,
    IsDeleted, DeletedAt, DeletedByUserId,
    RowVer
FROM ap.PurchaseDocumentPayment;

GO
 
 
-- =============================================
-- VIEW: dbo.DocumentosVenta
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- =============================================================================
-- SECCIÇ"N 5: VISTAS DE COMPATIBILIDAD dbo.* ƒÅ' canÇünicas
-- Exponen los nombres de columna originales para que el cÇüdigo TypeScript
-- no necesite cambios (INFORMATION_SCHEMA.COLUMNS las devuelve correctamente)
-- =============================================================================

-- --- dbo.DocumentosVenta ---
CREATE VIEW dbo.DocumentosVenta AS
SELECT
    DocumentId                     AS ID,
    DocumentNumber                 AS NUM_DOC,
    SerialType                     AS SERIALTIPO,
    OperationType                  AS TIPO_OPERACION,
    CustomerCode                   AS CODIGO,
    CustomerName                   AS NOMBRE,
    FiscalId                       AS RIF,
    DocumentDate                   AS FECHA,
    DueDate                        AS FECHA_VENCE,
    DocumentTime                   AS HORA,
    CAST(SubTotal       AS FLOAT)  AS SUBTOTAL,
    CAST(TaxableAmount  AS FLOAT)  AS MONTO_GRA,
    CAST(ExemptAmount   AS FLOAT)  AS MONTO_EXE,
    CAST(TaxAmount      AS FLOAT)  AS IVA,
    CAST(TaxRate        AS FLOAT)  AS ALICUOTA,
    CAST(TotalAmount    AS FLOAT)  AS TOTAL,
    CAST(DiscountAmount AS FLOAT)  AS DESCUENTO,
    IsVoided                       AS ANULADA,
    IsPaid                         AS CANCELADA,
    IsInvoiced                     AS FACTURADA,
    IsDelivered                    AS ENTREGADA,
    OriginDocumentNumber           AS DOC_ORIGEN,
    OriginDocumentType             AS TIPO_DOC_ORIGEN,
    ControlNumber                  AS NUM_CONTROL,
    IsLegal                        AS LEGAL,
    IsPrinted                      AS IMPRESA,
    Notes                          AS OBSERV,
    Concept                        AS CONCEPTO,
    PaymentTerms                   AS TERMINOS,
    ShipToAddress                  AS DESPACHAR,
    SellerCode                     AS VENDEDOR,
    DepartmentCode                 AS DEPARTAMENTO,
    LocationCode                   AS LOCACION,
    CurrencyCode                   AS MONEDA,
    CAST(ExchangeRate   AS FLOAT)  AS TASA_CAMBIO,
    UserCode                       AS COD_USUARIO,
    ReportDate                     AS FECHA_REPORTE,
    HostName                       AS COMPUTER,
    VehiclePlate                   AS PLACAS,
    Mileage                        AS KILOMETROS,
    CAST(TollAmount     AS FLOAT)  AS PEAJE,
    CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId,
    IsDeleted, DeletedAt, DeletedByUserId,
    RowVer
FROM ar.SalesDocument;

GO
 
 
-- =============================================
-- VIEW: dbo.DocumentosVentaDetalle
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- --- dbo.DocumentosVentaDetalle ---
CREATE VIEW dbo.DocumentosVentaDetalle AS
SELECT
    LineId                             AS ID,
    DocumentNumber                     AS NUM_DOC,
    OperationType                      AS TIPO_OPERACION,
    LineNumber                         AS RENGLON,
    ProductCode                        AS COD_SERV,
    Description                        AS DESCRIPCION,
    AlternateCode                      AS COD_ALTERNO,
    CAST(Quantity       AS FLOAT)      AS CANTIDAD,
    CAST(UnitPrice      AS FLOAT)      AS PRECIO,
    CAST(DiscountedPrice AS FLOAT)     AS PRECIO_DESCUENTO,
    CAST(UnitCost       AS FLOAT)      AS COSTO,
    CAST(SubTotal       AS FLOAT)      AS SUBTOTAL,
    CAST(DiscountAmount AS FLOAT)      AS DESCUENTO,
    CAST(TotalAmount    AS FLOAT)      AS TOTAL,
    CAST(TaxRate        AS FLOAT)      AS ALICUOTA,
    CAST(TaxAmount      AS FLOAT)      AS MONTO_IVA,
    IsVoided                           AS ANULADA,
    RelatedRef                         AS RELACIONADA,
    UserCode                           AS CO_USUARIO,
    LineDate                           AS FECHA,
    CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId,
    IsDeleted, DeletedAt, DeletedByUserId,
    RowVer
FROM ar.SalesDocumentLine;

GO
 
 
-- =============================================
-- VIEW: dbo.DocumentosVentaPago
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- --- dbo.DocumentosVentaPago ---
CREATE VIEW dbo.DocumentosVentaPago AS
SELECT
    PaymentId                          AS ID,
    DocumentNumber                     AS NUM_DOC,
    OperationType                      AS TIPO_OPERACION,
    PaymentMethod                      AS TIPO_PAGO,
    BankCode                           AS BANCO,
    PaymentNumber                      AS NUMERO,
    CAST(Amount         AS FLOAT)      AS MONTO,
    CAST(AmountBs       AS FLOAT)      AS MONTO_BS,
    CAST(ExchangeRate   AS FLOAT)      AS TASA_CAMBIO,
    PaymentDate                        AS FECHA,
    DueDate                            AS FECHA_VENCE,
    ReferenceNumber                    AS REFERENCIA,
    UserCode                           AS CO_USUARIO,
    CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId,
    IsDeleted, DeletedAt, DeletedByUserId,
    RowVer
FROM ar.SalesDocumentPayment;

GO
 
 
-- =============================================
-- VIEW: dbo.Usuarios
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE VIEW dbo.Usuarios AS
SELECT
  UserCode          AS Cod_Usuario,
  PasswordHash      AS Password,
  UserName          AS Nombre,
  UserType          AS Tipo,
  CanUpdate         AS Updates,
  CanCreate         AS Addnews,
  CanDelete         AS Deletes,
  IsCreator         AS Creador,
  CanChangePwd      AS Cambiar,
  CanChangePrice    AS PrecioMinimo,
  CanGiveCredit     AS Credito,
  IsAdmin,
  Avatar
FROM sec.[User]
WHERE IsDeleted = 0;

GO
 
 
-- =============================================
-- VIEW: dbo.vw_ConceptosPorRegimen
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE VIEW dbo.vw_ConceptosPorRegimen
AS
SELECT
  pc.PayrollConceptId AS Id,
  pc.ConventionCode AS Convencion,
  pc.CalculationType AS TipoCalculo,
  pc.ConceptCode AS CO_CONCEPT,
  pc.ConceptName AS NB_CONCEPTO,
  pc.Formula AS FORMULA,
  pc.BaseExpression AS SOBRE,
  pc.ConceptType AS TIPO,
  CASE WHEN pc.IsBonifiable = 1 THEN 'S' ELSE 'N' END AS BONIFICABLE,
  pc.LotttArticle AS LOTTT_Articulo,
  pc.CcpClause AS CCP_Clausula,
  pc.SortOrder AS Orden,
  pc.IsActive AS Activo,
  pc.PayrollCode AS CO_NOMINA,
  pc.CompanyId
FROM hr.PayrollConcept pc
WHERE pc.ConventionCode IS NOT NULL;

GO
 
 
-- =============================================
-- VIEW: dbo.vw_Governance_AuditCoverage
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

  CREATE VIEW dbo.vw_Governance_AuditCoverage
  AS
  WITH t AS (
    SELECT s.name AS schema_name, tb.name AS table_name, tb.object_id
    FROM sys.tables tb
    INNER JOIN sys.schemas s ON s.schema_id = tb.schema_id
    WHERE tb.name <> 'sysdiagrams'
      AND tb.name <> 'EndpointDependency'
      AND tb.name NOT LIKE '%__legacy_backup_phase2%'
      AND tb.name NOT LIKE '%__legacy_backup_phase1%'
      AND tb.name NOT LIKE 'SchemaGovernance%'
  ),
  pk AS (
    SELECT DISTINCT parent_object_id AS object_id
    FROM sys.key_constraints
    WHERE type = 'PK'
  ),
  aud AS (
    SELECT
      c.object_id,
      MAX(CASE WHEN c.name IN ('CreatedAt','FechaCreacion','Fecha_Creacion','FECHA_CREACION','created_at') THEN 1 ELSE 0 END) AS has_created_at,
      MAX(CASE WHEN c.name IN ('UpdatedAt','FechaModificacion','Fecha_Modificacion','FECHA_MODIFICACION','updated_at') THEN 1 ELSE 0 END) AS has_updated_at,
      MAX(CASE WHEN c.name IN ('CreatedBy','CodUsuario','Cod_Usuario','UsuarioCreacion','USUARIO_CREACION','created_by') THEN 1 ELSE 0 END) AS has_created_by,
      MAX(CASE WHEN c.name IN ('UpdatedBy','UsuarioModificacion','USUARIO_MODIFICACION','updated_by') THEN 1 ELSE 0 END) AS has_updated_by,
      MAX(CASE WHEN c.name IN ('IsDeleted','is_deleted') THEN 1 ELSE 0 END) AS has_is_deleted
    FROM sys.columns c
    GROUP BY c.object_id
  ),
  dt AS (
    SELECT
      c.object_id,
      SUM(CASE WHEN ty.name IN ('datetime','datetime2','date','smalldatetime') THEN 1 ELSE 0 END) AS date_column_count
    FROM sys.columns c
    INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    GROUP BY c.object_id
  )
  SELECT
    t.schema_name,
    t.table_name,
    CASE WHEN pk.object_id IS NULL THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS has_pk,
    CAST(ISNULL(aud.has_created_at, 0) AS BIT) AS has_created_at,
    CAST(ISNULL(aud.has_updated_at, 0) AS BIT) AS has_updated_at,
    CAST(ISNULL(aud.has_created_by, 0) AS BIT) AS has_created_by,
    CAST(ISNULL(aud.has_updated_by, 0) AS BIT) AS has_updated_by,
    CAST(ISNULL(aud.has_is_deleted, 0) AS BIT) AS has_is_deleted,
    ISNULL(dt.date_column_count, 0) AS date_column_count
  FROM t
  LEFT JOIN pk ON pk.object_id = t.object_id
  LEFT JOIN aud ON aud.object_id = t.object_id
  LEFT JOIN dt ON dt.object_id = t.object_id;
  
GO
 
 
-- =============================================
-- VIEW: dbo.vw_Governance_DuplicateNameCandidates
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

  CREATE VIEW dbo.vw_Governance_DuplicateNameCandidates
  AS
  WITH base AS (
    SELECT
      tb.name AS table_name,
      LOWER(tb.name) AS name_lower
    FROM sys.tables tb
    WHERE tb.name <> 'sysdiagrams'
      AND tb.name <> 'EndpointDependency'
      AND tb.name NOT LIKE '%__legacy_backup_phase2%'
      AND tb.name NOT LIKE '%__legacy_backup_phase1%'
      AND tb.name NOT LIKE 'SchemaGovernance%'
  ),
  norm AS (
    SELECT
      table_name,
      CASE
        WHEN RIGHT(name_lower, 1) = 's' AND RIGHT(name_lower, 2) <> 'ss'
          THEN LEFT(name_lower, LEN(name_lower) - 1)
        ELSE name_lower
      END AS stem
    FROM base
  )
  SELECT
    a.table_name AS table_a,
    b.table_name AS table_b,
    a.stem AS normalized_name
  FROM norm a
  INNER JOIN norm b
    ON a.stem = b.stem
   AND a.table_name < b.table_name;
  
GO
 
 
-- =============================================
-- VIEW: dbo.vw_Governance_EndpointReadiness
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

  CREATE VIEW dbo.vw_Governance_EndpointReadiness
  AS
  SELECT
    d.Id,
    d.ModuleName,
    d.ObjectType,
    d.ObjectName,
    d.IsCritical,
    d.SourceTag,
    d.Notes,
    CASE
      WHEN d.ObjectType = 'TABLE' AND OBJECT_ID(d.ObjectName, 'U') IS NOT NULL THEN CAST(1 AS BIT)
      WHEN d.ObjectType = 'PROC'  AND OBJECT_ID(d.ObjectName, 'P') IS NOT NULL THEN CAST(1 AS BIT)
      WHEN d.ObjectType = 'VIEW'  AND OBJECT_ID(d.ObjectName, 'V') IS NOT NULL THEN CAST(1 AS BIT)
      ELSE CAST(0 AS BIT)
    END AS ObjectExists
  FROM dbo.EndpointDependency d;
  
GO
 
 
-- =============================================
-- VIEW: dbo.vw_Governance_EndpointReadinessSummary
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

  CREATE VIEW dbo.vw_Governance_EndpointReadinessSummary
  AS
  SELECT
    ModuleName,
    COUNT(1) AS TotalDependencies,
    SUM(CASE WHEN ObjectExists = 1 THEN 1 ELSE 0 END) AS AvailableDependencies,
    SUM(CASE WHEN ObjectExists = 0 THEN 1 ELSE 0 END) AS MissingDependencies,
    SUM(CASE WHEN ObjectExists = 0 AND IsCritical = 1 THEN 1 ELSE 0 END) AS MissingCritical
  FROM dbo.vw_Governance_EndpointReadiness
  GROUP BY ModuleName;
  
GO
 
 
-- =============================================
-- VIEW: dbo.vw_Governance_TableSimilarityCandidates
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

  CREATE VIEW dbo.vw_Governance_TableSimilarityCandidates
  AS
  WITH cols AS (
    SELECT c.object_id, LOWER(c.name) AS column_name
    FROM sys.columns c
    INNER JOIN sys.tables t ON t.object_id = c.object_id
    WHERE t.name <> 'sysdiagrams'
      AND t.name <> 'EndpointDependency'
      AND t.name NOT LIKE '%__legacy_backup_phase2%'
      AND t.name NOT LIKE '%__legacy_backup_phase1%'
      AND t.name NOT LIKE 'SchemaGovernance%'
  ),
  tcols AS (
    SELECT object_id, COUNT(1) AS column_count
    FROM cols
    GROUP BY object_id
  ),
  common_cols AS (
    SELECT
      a.object_id AS object_id_a,
      b.object_id AS object_id_b,
      COUNT(1) AS common_count
    FROM cols a
    INNER JOIN cols b
      ON a.column_name = b.column_name
     AND a.object_id < b.object_id
    GROUP BY a.object_id, b.object_id
  )
  SELECT
    ta.name AS table_a,
    tb.name AS table_b,
    cc.common_count,
    ca.column_count AS columns_a,
    cb.column_count AS columns_b,
    CAST(
      CASE
        WHEN (ca.column_count + cb.column_count - cc.common_count) = 0 THEN 0
        ELSE (cc.common_count * 1.0) / (ca.column_count + cb.column_count - cc.common_count)
      END
      AS DECIMAL(9,4)
    ) AS similarity_ratio
  FROM common_cols cc
  INNER JOIN tcols ca ON ca.object_id = cc.object_id_a
  INNER JOIN tcols cb ON cb.object_id = cc.object_id_b
  INNER JOIN sys.tables ta ON ta.object_id = cc.object_id_a
  INNER JOIN sys.tables tb ON tb.object_id = cc.object_id_b
  WHERE cc.common_count >= 5;
  
GO
 
 
-- =============================================
-- VIEW: doc.PurchaseDocument
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE VIEW [doc].[PurchaseDocument]
AS
SELECT
  dc.[ID] AS [DocumentId],
  dc.[NUM_DOC] AS [DocumentNumber],
  dc.[SERIALTIPO] AS [SerialType],
  dc.[TIPO_OPERACION] AS [DocumentType],
  dc.[COD_PROVEEDOR] AS [SupplierCode],
  dc.[NOMBRE] AS [SupplierName],
  dc.[RIF] AS [FiscalId],
  dc.[FECHA] AS [IssueDate],
  dc.[FECHA_VENCE] AS [DueDate],
  dc.[SUBTOTAL] AS [Subtotal],
  dc.[MONTO_GRA] AS [TaxableAmount],
  dc.[MONTO_EXE] AS [ExemptAmount],
  dc.[IVA] AS [TaxAmount],
  dc.[ALICUOTA] AS [TaxRate],
  dc.[TOTAL] AS [TotalAmount],
  dc.[DESCUENTO] AS [DiscountAmount],
  dc.[ANULADA] AS [IsVoided],
  dc.[CANCELADA] AS [IsCanceled],
  dc.[DOC_ORIGEN] AS [SourceDocumentNumber],
  dc.[NUM_CONTROL] AS [ControlNumber],
  dc.[OBSERV] AS [Notes],
  dc.[CONCEPTO] AS [Concept],
  dc.[MONEDA] AS [CurrencyCode],
  dc.[TASA_CAMBIO] AS [ExchangeRate],
  dc.[COD_USUARIO] AS [LegacyUserCode],
  dc.[CreatedAt],
  dc.[UpdatedAt],
  dc.[CreatedByUserId],
  dc.[UpdatedByUserId],
  dc.[IsDeleted],
  dc.[DeletedAt],
  dc.[DeletedByUserId],
  dc.[RowVer]
FROM [dbo].[DocumentosCompra] dc;

GO
 
 
-- =============================================
-- VIEW: doc.PurchaseDocumentLine
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE VIEW [doc].[PurchaseDocumentLine]
AS
SELECT
  d.[ID] AS [LineId],
  d.[NUM_DOC] AS [DocumentNumber],
  d.[TIPO_OPERACION] AS [DocumentType],
  d.[RENGLON] AS [LineNumber],
  d.[COD_SERV] AS [ProductCode],
  d.[DESCRIPCION] AS [Description],
  d.[CANTIDAD] AS [Quantity],
  d.[PRECIO] AS [UnitPrice],
  d.[COSTO] AS [UnitCost],
  d.[SUBTOTAL] AS [Subtotal],
  d.[DESCUENTO] AS [DiscountAmount],
  d.[TOTAL] AS [LineTotal],
  d.[ALICUOTA] AS [TaxRate],
  d.[MONTO_IVA] AS [TaxAmount],
  d.[ANULADA] AS [IsVoided],
  d.[CreatedAt],
  d.[UpdatedAt],
  d.[CreatedByUserId],
  d.[UpdatedByUserId],
  d.[IsDeleted],
  d.[DeletedAt],
  d.[DeletedByUserId],
  d.[RowVer]
FROM [dbo].[DocumentosCompraDetalle] d;

GO
 
 
-- =============================================
-- VIEW: doc.PurchaseDocumentPayment
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE VIEW [doc].[PurchaseDocumentPayment]
AS
SELECT
  p.[ID] AS [PaymentId],
  p.[NUM_DOC] AS [DocumentNumber],
  p.[TIPO_OPERACION] AS [DocumentType],
  p.[TIPO_PAGO] AS [PaymentType],
  p.[BANCO] AS [BankCode],
  p.[NUMERO] AS [ReferenceNumber],
  p.[MONTO] AS [Amount],
  p.[FECHA] AS [ApplyDate],
  p.[FECHA_VENCE] AS [DueDate],
  p.[REFERENCIA] AS [PaymentReference],
  p.[CreatedAt],
  p.[UpdatedAt],
  p.[CreatedByUserId],
  p.[UpdatedByUserId],
  p.[IsDeleted],
  p.[DeletedAt],
  p.[DeletedByUserId],
  p.[RowVer]
FROM [dbo].[DocumentosCompraPago] p;

GO
 
 
-- =============================================
-- VIEW: doc.SalesDocument
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE VIEW [doc].[SalesDocument]
AS
SELECT
  dv.[ID] AS [DocumentId],
  dv.[NUM_DOC] AS [DocumentNumber],
  dv.[SERIALTIPO] AS [SerialType],
  dv.[TIPO_OPERACION] AS [DocumentType],
  dv.[CODIGO] AS [CustomerCode],
  dv.[NOMBRE] AS [CustomerName],
  dv.[RIF] AS [FiscalId],
  dv.[FECHA] AS [IssueDate],
  dv.[FECHA_VENCE] AS [DueDate],
  dv.[SUBTOTAL] AS [Subtotal],
  dv.[MONTO_GRA] AS [TaxableAmount],
  dv.[MONTO_EXE] AS [ExemptAmount],
  dv.[IVA] AS [TaxAmount],
  dv.[ALICUOTA] AS [TaxRate],
  dv.[TOTAL] AS [TotalAmount],
  dv.[DESCUENTO] AS [DiscountAmount],
  dv.[ANULADA] AS [IsVoided],
  dv.[CANCELADA] AS [IsCanceled],
  dv.[FACTURADA] AS [IsInvoiced],
  dv.[ENTREGADA] AS [IsDelivered],
  dv.[DOC_ORIGEN] AS [SourceDocumentNumber],
  dv.[TIPO_DOC_ORIGEN] AS [SourceDocumentType],
  dv.[NUM_CONTROL] AS [ControlNumber],
  dv.[OBSERV] AS [Notes],
  dv.[CONCEPTO] AS [Concept],
  dv.[MONEDA] AS [CurrencyCode],
  dv.[TASA_CAMBIO] AS [ExchangeRate],
  dv.[COD_USUARIO] AS [LegacyUserCode],
  dv.[CreatedAt],
  dv.[UpdatedAt],
  dv.[CreatedByUserId],
  dv.[UpdatedByUserId],
  dv.[IsDeleted],
  dv.[DeletedAt],
  dv.[DeletedByUserId],
  dv.[RowVer]
FROM [dbo].[DocumentosVenta] dv;

GO
 
 
-- =============================================
-- VIEW: doc.SalesDocumentLine
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE VIEW [doc].[SalesDocumentLine]
AS
SELECT
  d.[ID] AS [LineId],
  d.[NUM_DOC] AS [DocumentNumber],
  d.[TIPO_OPERACION] AS [DocumentType],
  d.[RENGLON] AS [LineNumber],
  d.[COD_SERV] AS [ProductCode],
  d.[DESCRIPCION] AS [Description],
  d.[COD_ALTERNO] AS [AlternateCode],
  d.[CANTIDAD] AS [Quantity],
  d.[PRECIO] AS [UnitPrice],
  d.[PRECIO_DESCUENTO] AS [DiscountUnitPrice],
  d.[COSTO] AS [UnitCost],
  d.[SUBTOTAL] AS [Subtotal],
  d.[DESCUENTO] AS [DiscountAmount],
  d.[TOTAL] AS [LineTotal],
  d.[ALICUOTA] AS [TaxRate],
  d.[MONTO_IVA] AS [TaxAmount],
  d.[ANULADA] AS [IsVoided],
  d.[CreatedAt],
  d.[UpdatedAt],
  d.[CreatedByUserId],
  d.[UpdatedByUserId],
  d.[IsDeleted],
  d.[DeletedAt],
  d.[DeletedByUserId],
  d.[RowVer]
FROM [dbo].[DocumentosVentaDetalle] d;

GO
 
 
-- =============================================
-- VIEW: doc.SalesDocumentPayment
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE VIEW [doc].[SalesDocumentPayment]
AS
SELECT
  p.[ID] AS [PaymentId],
  p.[NUM_DOC] AS [DocumentNumber],
  p.[TIPO_OPERACION] AS [DocumentType],
  p.[TIPO_PAGO] AS [PaymentType],
  p.[BANCO] AS [BankCode],
  p.[NUMERO] AS [ReferenceNumber],
  p.[MONTO] AS [Amount],
  p.[MONTO_BS] AS [AmountLocal],
  p.[TASA_CAMBIO] AS [ExchangeRate],
  p.[FECHA] AS [ApplyDate],
  p.[FECHA_VENCE] AS [DueDate],
  p.[REFERENCIA] AS [PaymentReference],
  p.[CreatedAt],
  p.[UpdatedAt],
  p.[CreatedByUserId],
  p.[UpdatedByUserId],
  p.[IsDeleted],
  p.[DeletedAt],
  p.[DeletedByUserId],
  p.[RowVer]
FROM [dbo].[DocumentosVentaPago] p;

GO
 
 
