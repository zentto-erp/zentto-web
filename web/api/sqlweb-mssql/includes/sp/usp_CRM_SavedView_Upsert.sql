-- usp_CRM_SavedView_Upsert
-- Insert/Update vista guardada. ViewId NULL o <=0 = crear. Solo owner actualiza.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_CRM_SavedView_Upsert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CRM_SavedView_Upsert;
GO

CREATE PROCEDURE dbo.usp_CRM_SavedView_Upsert
    @CompanyId   INT,
    @UserId      INT,
    @ViewId      BIGINT         = NULL,
    @Entity      VARCHAR(50)    = NULL,
    @Name        VARCHAR(200)   = NULL,
    @FilterJson  NVARCHAR(MAX)  = NULL,
    @ColumnsJson NVARCHAR(MAX)  = NULL,
    @SortJson    NVARCHAR(MAX)  = NULL,
    @IsShared    BIT            = 0,
    @IsDefault   BIT            = 0,
    @Resultado   INT            OUTPUT,
    @Mensaje     NVARCHAR(500)  OUTPUT,
    @OutViewId   BIGINT         OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ownerId INT;
    DECLARE @existingEntity VARCHAR(50);

    BEGIN TRY
        IF @ViewId IS NULL OR @ViewId <= 0
        BEGIN
            -- Crear
            IF @Entity IS NULL OR @Name IS NULL
            BEGIN
                SET @Resultado = 0;
                SET @Mensaje = N'Entity y Name son requeridos';
                SET @OutViewId = NULL;
                RETURN;
            END

            IF @Entity NOT IN ('LEAD','CONTACT','COMPANY','DEAL','ACTIVITY')
            BEGIN
                SET @Resultado = 0;
                SET @Mensaje = N'Entity invalida';
                SET @OutViewId = NULL;
                RETURN;
            END

            -- Validar nombre duplicado explicitamente
            IF EXISTS (
                SELECT 1 FROM crm.SavedView
                WHERE CompanyId = @CompanyId AND UserId = @UserId
                  AND Entity = @Entity AND Name = @Name
            )
            BEGIN
                SET @Resultado = 0;
                SET @Mensaje = N'Ya existe una vista con ese nombre para la entidad';
                SET @OutViewId = NULL;
                RETURN;
            END

            BEGIN TRAN;

            IF @IsDefault = 1
            BEGIN
                UPDATE crm.SavedView
                   SET IsDefault = 0,
                       UpdatedAt = SYSUTCDATETIME()
                 WHERE CompanyId = @CompanyId
                   AND UserId    = @UserId
                   AND Entity    = @Entity
                   AND IsDefault = 1;
            END

            INSERT INTO crm.SavedView (
                CompanyId, UserId, Entity, Name, FilterJson,
                ColumnsJson, SortJson, IsShared, IsDefault,
                CreatedAt, UpdatedAt
            ) VALUES (
                @CompanyId, @UserId, @Entity, @Name,
                ISNULL(@FilterJson, N'{}'),
                @ColumnsJson, @SortJson,
                ISNULL(@IsShared, 0),
                ISNULL(@IsDefault, 0),
                SYSUTCDATETIME(), SYSUTCDATETIME()
            );

            SET @OutViewId = SCOPE_IDENTITY();
            SET @Resultado = 1;
            SET @Mensaje = N'Vista creada';

            COMMIT TRAN;
            RETURN;
        END
        ELSE
        BEGIN
            -- Actualizar — solo owner del mismo tenant
            SELECT @ownerId = UserId, @existingEntity = Entity
            FROM crm.SavedView
            WHERE ViewId = @ViewId AND CompanyId = @CompanyId;

            IF @ownerId IS NULL
            BEGIN
                SET @Resultado = 0;
                SET @Mensaje = N'Vista no encontrada';
                SET @OutViewId = NULL;
                RETURN;
            END

            IF @ownerId <> @UserId
            BEGIN
                SET @Resultado = 0;
                SET @Mensaje = N'Solo el propietario puede modificar la vista';
                SET @OutViewId = NULL;
                RETURN;
            END

            BEGIN TRAN;

            IF @IsDefault = 1
            BEGIN
                UPDATE crm.SavedView
                   SET IsDefault = 0,
                       UpdatedAt = SYSUTCDATETIME()
                 WHERE CompanyId = @CompanyId
                   AND UserId    = @UserId
                   AND Entity    = ISNULL(@Entity, @existingEntity)
                   AND ViewId   <> @ViewId
                   AND IsDefault = 1;
            END

            UPDATE crm.SavedView
               SET Name        = ISNULL(@Name,        Name),
                   FilterJson  = ISNULL(@FilterJson,  FilterJson),
                   ColumnsJson = ISNULL(@ColumnsJson, ColumnsJson),
                   SortJson    = ISNULL(@SortJson,    SortJson),
                   IsShared    = ISNULL(@IsShared,    IsShared),
                   IsDefault   = ISNULL(@IsDefault,   IsDefault),
                   UpdatedAt   = SYSUTCDATETIME()
             WHERE ViewId = @ViewId;

            SET @OutViewId = @ViewId;
            SET @Resultado = 1;
            SET @Mensaje = N'Vista actualizada';

            COMMIT TRAN;
            RETURN;
        END
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Resultado = 0;
        SET @Mensaje = LEFT(ERROR_MESSAGE(), 500);
        SET @OutViewId = NULL;
    END CATCH
END
GO
