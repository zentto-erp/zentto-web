-- usp_crm_Company_Upsert (SQL Server 2012+)

IF OBJECT_ID('dbo.usp_crm_Company_Upsert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Company_Upsert;
GO

CREATE PROCEDURE dbo.usp_crm_Company_Upsert
    @CompanyId        INT,
    @CrmCompanyId     BIGINT         = NULL,
    @Name             NVARCHAR(200),
    @LegalName        NVARCHAR(200)  = NULL,
    @TaxId            VARCHAR(50)    = NULL,
    @Industry         VARCHAR(100)   = NULL,
    @Size             VARCHAR(20)    = NULL,
    @Website          VARCHAR(255)   = NULL,
    @Phone            VARCHAR(50)    = NULL,
    @Email            VARCHAR(255)   = NULL,
    @BillingAddress   NVARCHAR(MAX)  = NULL,
    @ShippingAddress  NVARCHAR(MAX)  = NULL,
    @Notes            NVARCHAR(MAX)  = NULL,
    @IsActive         BIT            = 1,
    @UserId           INT            = NULL,
    @Resultado        BIT            OUTPUT,
    @Mensaje          NVARCHAR(500)  OUTPUT,
    @Id               BIGINT         OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@Name, N'') = N''
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'Nombre requerido';
        SET @Id        = NULL;
        RETURN;
    END

    IF @CrmCompanyId IS NULL
    BEGIN
        INSERT INTO crm.[Company] (
            CompanyId, [Name], LegalName, TaxId, Industry, [Size], Website,
            Phone, Email, BillingAddress, ShippingAddress, Notes,
            IsActive, CreatedByUserId, UpdatedByUserId
        ) VALUES (
            @CompanyId, @Name, @LegalName, @TaxId, @Industry, @Size, @Website,
            @Phone, @Email, @BillingAddress, @ShippingAddress, @Notes,
            ISNULL(@IsActive, 1), @UserId, @UserId
        );

        SET @Id = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE crm.[Company] SET
            [Name]           = ISNULL(@Name,            [Name]),
            LegalName        = ISNULL(@LegalName,       LegalName),
            TaxId            = ISNULL(@TaxId,           TaxId),
            Industry         = ISNULL(@Industry,        Industry),
            [Size]           = ISNULL(@Size,            [Size]),
            Website          = ISNULL(@Website,         Website),
            Phone            = ISNULL(@Phone,           Phone),
            Email            = ISNULL(@Email,           Email),
            BillingAddress   = ISNULL(@BillingAddress,  BillingAddress),
            ShippingAddress  = ISNULL(@ShippingAddress, ShippingAddress),
            Notes            = ISNULL(@Notes,           Notes),
            IsActive         = ISNULL(@IsActive,        IsActive),
            UpdatedByUserId  = @UserId,
            UpdatedAt        = SYSUTCDATETIME(),
            RowVer           = RowVer + 1
          WHERE CrmCompanyId = @CrmCompanyId
            AND CompanyId    = @CompanyId
            AND IsDeleted    = 0;

        IF @@ROWCOUNT = 0
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje   = N'Empresa no encontrada';
            SET @Id        = NULL;
            RETURN;
        END

        SET @Id = @CrmCompanyId;
    END

    SET @Resultado = 1;
    SET @Mensaje   = N'OK';
END
GO
