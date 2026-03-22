/*
 * ============================================================================
 *  Archivo : usp_rbac.sql
 *  Esquema : sec (tablas y procedimientos)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-22
 *
 *  Descripcion:
 *    Procedimientos almacenados para el modulo RBAC (Role-Based Access Control).
 *    Permisos granulares, restricciones de precio, reglas de aprobacion.
 *
 *  Convenciones:
 *    - Nombrado: usp_Sec_[Entity]_[Action]
 *    - Patron: CREATE OR ALTER (idempotente)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- =============================================================================
--  SECCION 1: PERMISOS (Permission Catalog)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Sec_Permission_List
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_Permission_List
    @ModuleCode NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        PermissionId,
        ModuleCode,
        PermissionCode,
        PermissionName,
        Description,
        SortOrder
    FROM sec.Permission
    WHERE (@ModuleCode IS NULL OR ModuleCode = @ModuleCode)
    ORDER BY ModuleCode, SortOrder, PermissionCode;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Sec_Permission_Seed
--  Inserta permisos por defecto para todos los modulos.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_Permission_Seed
AS
BEGIN
    SET NOCOUNT ON;

    -- Tabla temporal con los permisos base
    DECLARE @Perms TABLE (
        ModuleCode     NVARCHAR(50),
        PermissionCode NVARCHAR(100),
        PermissionName NVARCHAR(200),
        SortOrder      INT
    );

    DECLARE @Modules TABLE (Code NVARCHAR(50), Nombre NVARCHAR(100));
    INSERT INTO @Modules VALUES
        (N'ventas',        N'Ventas'),
        (N'compras',       N'Compras'),
        (N'inventario',    N'Inventario'),
        (N'bancos',        N'Bancos'),
        (N'contabilidad',  N'Contabilidad'),
        (N'nomina',        N'Nomina'),
        (N'rrhh',          N'Recursos Humanos'),
        (N'pos',           N'Punto de Venta'),
        (N'restaurante',   N'Restaurante'),
        (N'auditoria',     N'Auditoria'),
        (N'crm',           N'CRM'),
        (N'manufactura',   N'Manufactura'),
        (N'flota',         N'Flota');

    DECLARE @Actions TABLE (Action NVARCHAR(20), ActionName NVARCHAR(50), Sort INT);
    INSERT INTO @Actions VALUES
        (N'VIEW',   N'Ver',       1),
        (N'CREATE', N'Crear',     2),
        (N'EDIT',   N'Editar',    3),
        (N'DELETE', N'Eliminar',  4),
        (N'VOID',   N'Anular',    5);

    INSERT INTO @Perms (ModuleCode, PermissionCode, PermissionName, SortOrder)
    SELECT
        m.Code,
        m.Code + N'.' + a.Action,
        m.Nombre + N' - ' + a.ActionName,
        a.Sort
    FROM @Modules m
    CROSS JOIN @Actions a;

    -- Upsert: insertar solo los que no existen
    MERGE sec.Permission AS tgt
    USING @Perms AS src
    ON tgt.PermissionCode = src.PermissionCode
    WHEN NOT MATCHED THEN
        INSERT (ModuleCode, PermissionCode, PermissionName, SortOrder, CreatedAt)
        VALUES (src.ModuleCode, src.PermissionCode, src.PermissionName, src.SortOrder, SYSUTCDATETIME());

    SELECT @@ROWCOUNT AS InsertedCount;
END;
GO

-- =============================================================================
--  SECCION 2: PERMISOS POR ROL (Role Permissions)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Sec_RolePermission_List
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_RolePermission_List
    @RoleId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.PermissionId,
        p.ModuleCode,
        p.PermissionCode,
        p.PermissionName,
        CAST(CASE WHEN rp.RolePermissionId IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsGranted,
        rp.BranchId
    FROM sec.Permission p
    LEFT JOIN sec.RolePermission rp ON rp.PermissionId = p.PermissionId
        AND rp.RoleId = @RoleId
        AND rp.IsGranted = 1
    ORDER BY p.ModuleCode, p.SortOrder;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Sec_RolePermission_Set
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_RolePermission_Set
    @RoleId         INT,
    @PermissionId   INT,
    @BranchId       INT = NULL,
    @IsGranted      BIT,
    @UserId         INT,
    @Resultado      INT OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @IsGranted = 1
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM sec.RolePermission WHERE RoleId = @RoleId AND PermissionId = @PermissionId AND ISNULL(BranchId, 0) = ISNULL(@BranchId, 0))
            BEGIN
                INSERT INTO sec.RolePermission (RoleId, PermissionId, BranchId, IsGranted, CreatedAt, CreatedBy)
                VALUES (@RoleId, @PermissionId, @BranchId, 1, SYSUTCDATETIME(), @UserId);
            END
            ELSE
            BEGIN
                UPDATE sec.RolePermission SET IsGranted = 1, UpdatedAt = SYSUTCDATETIME(), UpdatedBy = @UserId
                WHERE RoleId = @RoleId AND PermissionId = @PermissionId AND ISNULL(BranchId, 0) = ISNULL(@BranchId, 0);
            END;
        END
        ELSE
        BEGIN
            DELETE FROM sec.RolePermission
            WHERE RoleId = @RoleId AND PermissionId = @PermissionId AND ISNULL(BranchId, 0) = ISNULL(@BranchId, 0);
        END;

        SET @Resultado = 1;
        SET @Mensaje = N'Permiso actualizado';
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Sec_RolePermission_BulkSet
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_RolePermission_BulkSet
    @RoleId          INT,
    @PermissionsJson NVARCHAR(MAX),
    @UserId          INT,
    @Resultado       INT OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @Count INT = 0;

        -- Eliminar permisos actuales del rol
        DELETE FROM sec.RolePermission WHERE RoleId = @RoleId;

        -- Insertar los nuevos
        INSERT INTO sec.RolePermission (RoleId, PermissionId, BranchId, IsGranted, CreatedAt, CreatedBy)
        SELECT
            @RoleId,
            j.PermissionId,
            j.BranchId,
            1,
            SYSUTCDATETIME(),
            @UserId
        FROM OPENJSON(@PermissionsJson)
        WITH (
            PermissionId INT '$.permissionId',
            BranchId     INT '$.branchId',
            IsGranted    BIT '$.isGranted'
        ) j
        WHERE j.IsGranted = 1;

        SET @Count = @@ROWCOUNT;
        SET @Resultado = 1;
        SET @Mensaje = CAST(@Count AS NVARCHAR) + N' permisos asignados';
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SECCION 3: PERMISOS DE USUARIO (User Permission Overrides)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Sec_UserPermission_List
--  Permisos efectivos (rol + overrides merged).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_UserPermission_List
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Obtener RoleId del usuario
    DECLARE @RoleId INT;
    SELECT @RoleId = RoleId FROM sec.[User] WHERE UserId = @UserId;

    SELECT
        p.PermissionId,
        p.ModuleCode,
        p.PermissionCode,
        p.PermissionName,
        -- Override > Role > default deny
        CAST(CASE
            WHEN upo.OverrideId IS NOT NULL THEN upo.IsGranted
            WHEN rp.RolePermissionId IS NOT NULL THEN rp.IsGranted
            ELSE 0
        END AS BIT) AS IsGranted,
        CASE
            WHEN upo.OverrideId IS NOT NULL THEN N'OVERRIDE'
            WHEN rp.RolePermissionId IS NOT NULL THEN N'ROLE'
            ELSE N'DEFAULT'
        END AS [Source]
    FROM sec.Permission p
    LEFT JOIN sec.RolePermission rp ON rp.PermissionId = p.PermissionId AND rp.RoleId = @RoleId
    LEFT JOIN sec.UserPermissionOverride upo ON upo.PermissionId = p.PermissionId AND upo.UserId = @UserId
    ORDER BY p.ModuleCode, p.SortOrder;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Sec_UserPermission_Override
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_UserPermission_Override
    @UserId         INT,
    @PermissionId   INT,
    @BranchId       INT = NULL,
    @IsGranted      BIT,
    @AdminUserId    INT,
    @Resultado      INT OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM sec.UserPermissionOverride WHERE UserId = @UserId AND PermissionId = @PermissionId AND ISNULL(BranchId, 0) = ISNULL(@BranchId, 0))
        BEGIN
            UPDATE sec.UserPermissionOverride SET
                IsGranted = @IsGranted,
                UpdatedAt = SYSUTCDATETIME(),
                UpdatedBy = @AdminUserId
            WHERE UserId = @UserId AND PermissionId = @PermissionId AND ISNULL(BranchId, 0) = ISNULL(@BranchId, 0);
        END
        ELSE
        BEGIN
            INSERT INTO sec.UserPermissionOverride (UserId, PermissionId, BranchId, IsGranted, CreatedAt, CreatedBy)
            VALUES (@UserId, @PermissionId, @BranchId, @IsGranted, SYSUTCDATETIME(), @AdminUserId);
        END;

        SET @Resultado = 1;
        SET @Mensaje = N'Override aplicado';
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Sec_UserPermission_Check
--  Verifica si un usuario tiene un permiso especifico.
--  Resolucion: user override > role permission > default deny.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_UserPermission_Check
    @UserId         INT,
    @PermissionCode NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RoleId INT;
    DECLARE @PermissionId INT;
    DECLARE @HasPermission BIT = 0;

    SELECT @RoleId = RoleId FROM sec.[User] WHERE UserId = @UserId;
    SELECT @PermissionId = PermissionId FROM sec.Permission WHERE PermissionCode = @PermissionCode;

    IF @PermissionId IS NULL
    BEGIN
        SELECT CAST(0 AS BIT) AS HasPermission;
        RETURN;
    END;

    -- 1. Check user override
    IF EXISTS (SELECT 1 FROM sec.UserPermissionOverride WHERE UserId = @UserId AND PermissionId = @PermissionId)
    BEGIN
        SELECT @HasPermission = IsGranted FROM sec.UserPermissionOverride
        WHERE UserId = @UserId AND PermissionId = @PermissionId;
        SELECT @HasPermission AS HasPermission;
        RETURN;
    END;

    -- 2. Check role permission
    IF EXISTS (SELECT 1 FROM sec.RolePermission WHERE RoleId = @RoleId AND PermissionId = @PermissionId AND IsGranted = 1)
    BEGIN
        SELECT CAST(1 AS BIT) AS HasPermission;
        RETURN;
    END;

    -- 3. Default deny
    SELECT CAST(0 AS BIT) AS HasPermission;
END;
GO

-- =============================================================================
--  SECCION 4: RESTRICCIONES DE PRECIO
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Sec_PriceRestriction_List
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_PriceRestriction_List
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        pr.RestrictionId,
        pr.RoleId,
        r.RoleName,
        pr.UserId_Target,
        pr.MaxDiscountPercent,
        pr.MinPricePercent,
        pr.MaxCreditLimit,
        pr.RequiresApprovalAbove,
        pr.CreatedAt
    FROM sec.PriceRestriction pr
    LEFT JOIN sec.[Role] r ON r.RoleId = pr.RoleId
    WHERE pr.CompanyId = @CompanyId
    ORDER BY pr.RoleId, pr.UserId_Target;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Sec_PriceRestriction_Upsert
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_PriceRestriction_Upsert
    @CompanyId              INT,
    @RestrictionId          INT = NULL,
    @RoleId                 INT = NULL,
    @UserId_Target          INT = NULL,
    @MaxDiscountPercent     DECIMAL(5,2),
    @MinPricePercent        DECIMAL(5,2),
    @MaxCreditLimit         DECIMAL(18,2) = NULL,
    @RequiresApprovalAbove  DECIMAL(18,2) = NULL,
    @AdminUserId            INT,
    @Resultado              INT OUTPUT,
    @Mensaje                NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @RestrictionId IS NOT NULL AND EXISTS (SELECT 1 FROM sec.PriceRestriction WHERE RestrictionId = @RestrictionId)
        BEGIN
            UPDATE sec.PriceRestriction SET
                RoleId                 = @RoleId,
                UserId_Target          = @UserId_Target,
                MaxDiscountPercent     = @MaxDiscountPercent,
                MinPricePercent        = @MinPricePercent,
                MaxCreditLimit         = @MaxCreditLimit,
                RequiresApprovalAbove  = @RequiresApprovalAbove,
                UpdatedAt              = SYSUTCDATETIME(),
                UpdatedBy              = @AdminUserId
            WHERE RestrictionId = @RestrictionId;

            SET @Resultado = 1;
            SET @Mensaje = N'Restriccion actualizada';
        END
        ELSE
        BEGIN
            INSERT INTO sec.PriceRestriction (
                CompanyId, RoleId, UserId_Target, MaxDiscountPercent, MinPricePercent,
                MaxCreditLimit, RequiresApprovalAbove, CreatedAt, CreatedBy
            ) VALUES (
                @CompanyId, @RoleId, @UserId_Target, @MaxDiscountPercent, @MinPricePercent,
                @MaxCreditLimit, @RequiresApprovalAbove, SYSUTCDATETIME(), @AdminUserId
            );

            SET @Resultado = 1;
            SET @Mensaje = N'Restriccion creada';
        END;
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Sec_PriceRestriction_Check
--  Obtiene la restriccion efectiva para un usuario (user-specific > role > null).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_PriceRestriction_Check
    @UserId    INT,
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RoleId INT;
    SELECT @RoleId = RoleId FROM sec.[User] WHERE UserId = @UserId;

    -- Prioridad: user-specific > role-level
    SELECT TOP 1
        pr.RestrictionId,
        pr.MaxDiscountPercent,
        pr.MinPricePercent,
        pr.MaxCreditLimit,
        pr.RequiresApprovalAbove
    FROM sec.PriceRestriction pr
    WHERE pr.CompanyId = @CompanyId
      AND (pr.UserId_Target = @UserId OR pr.RoleId = @RoleId)
    ORDER BY
        CASE WHEN pr.UserId_Target = @UserId THEN 0 ELSE 1 END;
END;
GO

-- =============================================================================
--  SECCION 5: REGLAS DE APROBACION
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Sec_ApprovalRule_List
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_ApprovalRule_List
    @CompanyId  INT,
    @ModuleCode NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ar.ApprovalRuleId,
        ar.ModuleCode,
        ar.DocumentType,
        ar.MinAmount,
        ar.MaxAmount,
        ar.RequiredRoleId,
        r.RoleName AS RequiredRoleName,
        ar.ApprovalLevels,
        ar.IsActive,
        ar.CreatedAt
    FROM sec.ApprovalRule ar
    LEFT JOIN sec.[Role] r ON r.RoleId = ar.RequiredRoleId
    WHERE ar.CompanyId = @CompanyId
      AND (@ModuleCode IS NULL OR ar.ModuleCode = @ModuleCode)
    ORDER BY ar.ModuleCode, ar.MinAmount;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Sec_ApprovalRule_Upsert
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_ApprovalRule_Upsert
    @CompanyId       INT,
    @ApprovalRuleId  INT = NULL,
    @ModuleCode      NVARCHAR(50),
    @DocumentType    NVARCHAR(50),
    @MinAmount       DECIMAL(18,2),
    @MaxAmount       DECIMAL(18,2) = NULL,
    @RequiredRoleId  INT,
    @ApprovalLevels  INT,
    @IsActive        BIT = 1,
    @UserId          INT,
    @Resultado       INT OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @ApprovalRuleId IS NOT NULL AND EXISTS (SELECT 1 FROM sec.ApprovalRule WHERE ApprovalRuleId = @ApprovalRuleId)
        BEGIN
            UPDATE sec.ApprovalRule SET
                ModuleCode      = @ModuleCode,
                DocumentType    = @DocumentType,
                MinAmount       = @MinAmount,
                MaxAmount       = @MaxAmount,
                RequiredRoleId  = @RequiredRoleId,
                ApprovalLevels  = @ApprovalLevels,
                IsActive        = @IsActive,
                UpdatedAt       = SYSUTCDATETIME(),
                UpdatedBy       = @UserId
            WHERE ApprovalRuleId = @ApprovalRuleId;

            SET @Resultado = 1;
            SET @Mensaje = N'Regla actualizada';
        END
        ELSE
        BEGIN
            INSERT INTO sec.ApprovalRule (
                CompanyId, ModuleCode, DocumentType, MinAmount, MaxAmount,
                RequiredRoleId, ApprovalLevels, IsActive, CreatedAt, CreatedBy
            ) VALUES (
                @CompanyId, @ModuleCode, @DocumentType, @MinAmount, @MaxAmount,
                @RequiredRoleId, @ApprovalLevels, @IsActive, SYSUTCDATETIME(), @UserId
            );

            SET @Resultado = 1;
            SET @Mensaje = N'Regla creada';
        END;
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SECCION 6: SOLICITUDES DE APROBACION
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Sec_ApprovalRequest_List
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_ApprovalRequest_List
    @CompanyId  INT,
    @Status     NVARCHAR(20) = NULL,
    @ModuleCode NVARCHAR(50) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    SELECT @TotalCount = COUNT(*)
    FROM sec.ApprovalRequest
    WHERE CompanyId = @CompanyId
      AND (@Status IS NULL OR [Status] = @Status)
      AND (@ModuleCode IS NULL OR DocumentModule = @ModuleCode);

    SELECT
        ar.ApprovalRequestId,
        ar.DocumentModule,
        ar.DocumentType,
        ar.DocumentNumber,
        ar.DocumentAmount,
        ar.[Status],
        ar.CurrentLevel,
        ar.RequiredLevels,
        ar.RequestedByUserId,
        ar.BranchId,
        ar.CreatedAt,
        ar.UpdatedAt
    FROM sec.ApprovalRequest ar
    WHERE ar.CompanyId = @CompanyId
      AND (@Status IS NULL OR ar.[Status] = @Status)
      AND (@ModuleCode IS NULL OR ar.DocumentModule = @ModuleCode)
    ORDER BY ar.CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Sec_ApprovalRequest_Create
--  Crea una solicitud y auto-resuelve la regla de aprobacion.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_ApprovalRequest_Create
    @CompanyId          INT,
    @BranchId           INT,
    @DocumentModule     NVARCHAR(50),
    @DocumentType       NVARCHAR(50),
    @DocumentNumber     NVARCHAR(50),
    @DocumentAmount     DECIMAL(18,2),
    @RequestedByUserId  INT,
    @Resultado          INT OUTPUT,
    @ApprovalRequestId  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Buscar regla aplicable
        DECLARE @RequiredLevels INT = 1;

        SELECT TOP 1 @RequiredLevels = ApprovalLevels
        FROM sec.ApprovalRule
        WHERE CompanyId = @CompanyId
          AND ModuleCode = @DocumentModule
          AND DocumentType = @DocumentType
          AND @DocumentAmount >= MinAmount
          AND (@DocumentAmount <= MaxAmount OR MaxAmount IS NULL)
          AND IsActive = 1
        ORDER BY MinAmount DESC;

        INSERT INTO sec.ApprovalRequest (
            CompanyId, BranchId, DocumentModule, DocumentType, DocumentNumber,
            DocumentAmount, RequestedByUserId, [Status], CurrentLevel, RequiredLevels,
            CreatedAt
        ) VALUES (
            @CompanyId, @BranchId, @DocumentModule, @DocumentType, @DocumentNumber,
            @DocumentAmount, @RequestedByUserId, N'PENDING', 0, @RequiredLevels,
            SYSUTCDATETIME()
        );

        SET @ApprovalRequestId = SCOPE_IDENTITY();
        SET @Resultado = 1;
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @ApprovalRequestId = 0;
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Sec_ApprovalRequest_Act
--  Aprueba o rechaza una solicitud. Si todos los niveles aprobados → APPROVED.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_ApprovalRequest_Act
    @ApprovalRequestId  INT,
    @ActionByUserId     INT,
    @Action             NVARCHAR(10),   -- APPROVE / REJECT
    @Comments           NVARCHAR(500) = NULL,
    @Resultado          INT OUTPUT,
    @NewStatus          NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @CurrentLevel INT, @RequiredLevels INT, @CurrentStatus NVARCHAR(20);

        SELECT @CurrentLevel = CurrentLevel, @RequiredLevels = RequiredLevels, @CurrentStatus = [Status]
        FROM sec.ApprovalRequest
        WHERE ApprovalRequestId = @ApprovalRequestId;

        IF @CurrentStatus <> N'PENDING'
        BEGIN
            SET @Resultado = -1;
            SET @NewStatus = @CurrentStatus;
            RETURN;
        END;

        -- Registrar accion
        INSERT INTO sec.ApprovalAction (
            ApprovalRequestId, ActionByUserId, [Action], ActionLevel, Comments, CreatedAt
        ) VALUES (
            @ApprovalRequestId, @ActionByUserId, @Action, @CurrentLevel + 1, @Comments, SYSUTCDATETIME()
        );

        IF @Action = N'REJECT'
        BEGIN
            SET @NewStatus = N'REJECTED';
            UPDATE sec.ApprovalRequest SET [Status] = @NewStatus, UpdatedAt = SYSUTCDATETIME()
            WHERE ApprovalRequestId = @ApprovalRequestId;
        END
        ELSE IF @Action = N'APPROVE'
        BEGIN
            SET @CurrentLevel = @CurrentLevel + 1;

            IF @CurrentLevel >= @RequiredLevels
                SET @NewStatus = N'APPROVED';
            ELSE
                SET @NewStatus = N'PENDING';

            UPDATE sec.ApprovalRequest SET
                [Status] = @NewStatus,
                CurrentLevel = @CurrentLevel,
                UpdatedAt = SYSUTCDATETIME()
            WHERE ApprovalRequestId = @ApprovalRequestId;
        END;

        SET @Resultado = 1;
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @NewStatus = N'ERROR';
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Sec_ApprovalRequest_Get
--  Detalle de solicitud + historial de acciones.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Sec_ApprovalRequest_Get
    @ApprovalRequestId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Recordset 1: Request
    SELECT
        ar.ApprovalRequestId,
        ar.CompanyId,
        ar.BranchId,
        ar.DocumentModule,
        ar.DocumentType,
        ar.DocumentNumber,
        ar.DocumentAmount,
        ar.RequestedByUserId,
        ar.[Status],
        ar.CurrentLevel,
        ar.RequiredLevels,
        ar.CreatedAt,
        ar.UpdatedAt
    FROM sec.ApprovalRequest ar
    WHERE ar.ApprovalRequestId = @ApprovalRequestId;

    -- Recordset 2: Actions history
    SELECT
        aa.ActionId,
        aa.ActionByUserId,
        aa.[Action],
        aa.ActionLevel,
        aa.Comments,
        aa.CreatedAt
    FROM sec.ApprovalAction aa
    WHERE aa.ApprovalRequestId = @ApprovalRequestId
    ORDER BY aa.ActionLevel, aa.CreatedAt;
END;
GO
