-- usp_crm_Contact_Upsert — SQL Server 2012+

IF OBJECT_ID('dbo.usp_crm_Contact_Upsert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Contact_Upsert;
GO

CREATE PROCEDURE dbo.usp_crm_Contact_Upsert
    @CompanyId     INT,
    @ContactId     BIGINT        = NULL,
    @CrmCompanyId  BIGINT        = NULL,
    @FirstName     NVARCHAR(100),
    @LastName      NVARCHAR(100) = NULL,
    @Email         VARCHAR(255)  = NULL,
    @Phone         VARCHAR(50)   = NULL,
    @Mobile        VARCHAR(50)   = NULL,
    @Title         NVARCHAR(100) = NULL,
    @Department    NVARCHAR(100) = NULL,
    @LinkedIn      VARCHAR(255)  = NULL,
    @Notes         NVARCHAR(MAX) = NULL,
    @IsActive      BIT           = 1,
    @UserId        INT           = NULL,
    @Resultado     BIT           OUTPUT,
    @Mensaje       NVARCHAR(500) OUTPUT,
    @Id            BIGINT        OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@FirstName, N'') = N''
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'Nombre requerido';
        SET @Id        = NULL;
        RETURN;
    END

    IF @CrmCompanyId IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM crm.[Company]
         WHERE CrmCompanyId = @CrmCompanyId
           AND CompanyId    = @CompanyId
           AND IsDeleted    = 0
    )
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'CrmCompanyId invalido';
        SET @Id        = NULL;
        RETURN;
    END

    IF @ContactId IS NULL
    BEGIN
        INSERT INTO crm.[Contact] (
            CompanyId, CrmCompanyId, FirstName, LastName, Email, Phone, Mobile,
            Title, Department, LinkedIn, Notes, IsActive,
            CreatedByUserId, UpdatedByUserId
        ) VALUES (
            @CompanyId, @CrmCompanyId, @FirstName, @LastName, @Email, @Phone, @Mobile,
            @Title, @Department, @LinkedIn, @Notes, ISNULL(@IsActive, 1),
            @UserId, @UserId
        );

        SET @Id = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE crm.[Contact] SET
            CrmCompanyId     = ISNULL(@CrmCompanyId, CrmCompanyId),
            FirstName        = ISNULL(@FirstName,    FirstName),
            LastName         = ISNULL(@LastName,     LastName),
            Email            = ISNULL(@Email,        Email),
            Phone            = ISNULL(@Phone,        Phone),
            Mobile           = ISNULL(@Mobile,       Mobile),
            Title            = ISNULL(@Title,        Title),
            Department       = ISNULL(@Department,   Department),
            LinkedIn         = ISNULL(@LinkedIn,     LinkedIn),
            Notes            = ISNULL(@Notes,        Notes),
            IsActive         = ISNULL(@IsActive,     IsActive),
            UpdatedByUserId  = @UserId,
            UpdatedAt        = SYSUTCDATETIME(),
            RowVer           = RowVer + 1
          WHERE ContactId = @ContactId
            AND CompanyId = @CompanyId
            AND IsDeleted = 0;

        IF @@ROWCOUNT = 0
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje   = N'Contacto no encontrado';
            SET @Id        = NULL;
            RETURN;
        END

        SET @Id = @ContactId;
    END

    SET @Resultado = 1;
    SET @Mensaje   = N'OK';
END
GO
