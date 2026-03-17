-- =============================================
-- usp_sys_Lead_Upsert
-- Registra o actualiza un lead desde la landing page
-- =============================================
IF OBJECT_ID('sys.usp_sys_Lead_Upsert', 'P') IS NOT NULL
    DROP PROCEDURE sys.usp_sys_Lead_Upsert;
GO

CREATE PROCEDURE sys.usp_sys_Lead_Upsert
    @Email        NVARCHAR(255),
    @FullName     NVARCHAR(255),
    @Company      NVARCHAR(255) = NULL,
    @Country      NVARCHAR(10)  = NULL,
    @Source       NVARCHAR(100) = 'zentto-landing',
    @Resultado    INT           OUTPUT,
    @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM sys.Lead WHERE Email = @Email)
        BEGIN
            UPDATE sys.Lead
            SET FullName    = @FullName,
                Company     = ISNULL(@Company, Company),
                Country     = ISNULL(@Country, Country),
                Source      = @Source,
                UpdatedAt   = SYSUTCDATETIME()
            WHERE Email = @Email;

            SET @Resultado = 1;
            SET @Mensaje = 'Lead actualizado';
        END
        ELSE
        BEGIN
            INSERT INTO sys.Lead (Email, FullName, Company, Country, Source, CreatedAt, UpdatedAt)
            VALUES (@Email, @FullName, @Company, @Country, @Source, SYSUTCDATETIME(), SYSUTCDATETIME());

            SET @Resultado = 1;
            SET @Mensaje = 'Lead registrado';
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END;
GO
