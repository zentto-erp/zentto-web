-- usp_crm_Contact_PromoteToCustomer — SQL Server 2012+
-- Crea (o reusa) mstr.Customer a partir de un crm.Contact.
-- Nota: schema master esta renombrado a mstr en SQL Server (reservado).

IF OBJECT_ID('dbo.usp_crm_Contact_PromoteToCustomer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_crm_Contact_PromoteToCustomer;
GO

CREATE PROCEDURE dbo.usp_crm_Contact_PromoteToCustomer
    @CompanyId     INT,
    @ContactId     BIGINT,
    @CustomerCode  VARCHAR(24)   = NULL,
    @UserId        INT           = NULL,
    @Resultado     BIT           OUTPUT,
    @Mensaje       NVARCHAR(500) OUTPUT,
    @Id            BIGINT        OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CustomerId BIGINT,
            @FirstName  NVARCHAR(100),
            @LastName   NVARCHAR(100),
            @Email      VARCHAR(255),
            @Phone      VARCHAR(50),
            @Promoted   BIGINT,
            @FullName   NVARCHAR(200),
            @Code       VARCHAR(24);

    SELECT @FirstName = FirstName,
           @LastName  = LastName,
           @Email     = Email,
           @Phone     = Phone,
           @Promoted  = PromotedCustomerId
      FROM crm.[Contact]
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

    IF @Promoted IS NOT NULL
    BEGIN
        SET @Resultado = 1;
        SET @Mensaje   = N'Contacto ya promovido';
        SET @Id        = @Promoted;
        RETURN;
    END

    SET @FullName = LTRIM(RTRIM(@FirstName + N' ' + ISNULL(@LastName, N'')));
    SET @Code     = ISNULL(@CustomerCode, 'CRM-' + CAST(@ContactId AS VARCHAR(20)));

    SELECT TOP 1 @CustomerId = CustomerId
      FROM mstr.[Customer]
     WHERE CompanyId = @CompanyId
       AND IsDeleted = 0
       AND ((@Email IS NOT NULL AND Email = @Email)
         OR (@Phone IS NOT NULL AND Phone = @Phone));

    IF @CustomerId IS NULL
    BEGIN
        DECLARE @NewId BIGINT;
        SELECT @NewId = ISNULL(MAX(CustomerId), 0) + 1 FROM mstr.[Customer];

        INSERT INTO mstr.[Customer] (
            CustomerId, CompanyId, CustomerCode, CustomerName,
            Email, Phone, CreatedByUserId, UpdatedByUserId
        ) VALUES (
            @NewId, @CompanyId, @Code, @FullName,
            @Email, @Phone, @UserId, @UserId
        );

        SET @CustomerId = @NewId;
    END

    UPDATE crm.[Contact]
       SET PromotedCustomerId = @CustomerId,
           UpdatedByUserId    = @UserId,
           UpdatedAt          = SYSUTCDATETIME()
     WHERE ContactId = @ContactId
       AND CompanyId = @CompanyId;

    SET @Resultado = 1;
    SET @Mensaje   = N'OK';
    SET @Id        = @CustomerId;
END
GO
