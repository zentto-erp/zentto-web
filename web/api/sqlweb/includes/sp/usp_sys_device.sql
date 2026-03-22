-- ============================================================================
-- sys.PushDevice — Registro de dispositivos móviles para push notifications
-- ============================================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'sys' AND TABLE_NAME = 'PushDevice')
BEGIN
    CREATE TABLE sys.PushDevice (
        DeviceId        INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId       INT NOT NULL,
        UserId          INT NULL,
        PushToken       NVARCHAR(500) NOT NULL,
        Platform        NVARCHAR(10) NOT NULL,      -- 'ios' | 'android'
        DeviceName      NVARCHAR(200) NULL,
        IsActive        BIT NOT NULL DEFAULT 1,
        CreatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_PushDevice_Token UNIQUE (PushToken)
    );

    CREATE INDEX IX_PushDevice_User ON sys.PushDevice (CompanyId, UserId) WHERE IsActive = 1;
END
GO

-- ============================================================================
-- usp_Sys_Device_Register — Registra o actualiza un push token
-- ============================================================================
CREATE OR ALTER PROCEDURE usp_Sys_Device_Register
    @CompanyId      INT,
    @UserId         INT = NULL,
    @PushToken      NVARCHAR(500),
    @Platform       NVARCHAR(10),
    @DeviceName     NVARCHAR(200) = NULL,
    @Resultado      INT OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Upsert: si el token ya existe, actualizar; si no, insertar
    IF EXISTS (SELECT 1 FROM sys.PushDevice WHERE PushToken = @PushToken)
    BEGIN
        UPDATE sys.PushDevice
        SET CompanyId   = @CompanyId,
            UserId      = @UserId,
            Platform    = @Platform,
            DeviceName  = ISNULL(@DeviceName, DeviceName),
            IsActive    = 1,
            UpdatedAt   = SYSUTCDATETIME()
        WHERE PushToken = @PushToken;

        SELECT @Resultado = DeviceId FROM sys.PushDevice WHERE PushToken = @PushToken;
        SET @Mensaje = 'Dispositivo actualizado';
    END
    ELSE
    BEGIN
        INSERT INTO sys.PushDevice (CompanyId, UserId, PushToken, Platform, DeviceName)
        VALUES (@CompanyId, @UserId, @PushToken, @Platform, @DeviceName);

        SET @Resultado = SCOPE_IDENTITY();
        SET @Mensaje = 'Dispositivo registrado';
    END
END
GO

-- ============================================================================
-- usp_Sys_Device_Unregister — Desactiva un push token
-- ============================================================================
CREATE OR ALTER PROCEDURE usp_Sys_Device_Unregister
    @PushToken      NVARCHAR(500),
    @Resultado      INT OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE sys.PushDevice
    SET IsActive = 0, UpdatedAt = SYSUTCDATETIME()
    WHERE PushToken = @PushToken;

    SET @Resultado = 1;
    SET @Mensaje = 'Dispositivo desregistrado';
END
GO

-- ============================================================================
-- usp_Sys_Device_ListByUser — Lista dispositivos activos de un usuario
-- ============================================================================
CREATE OR ALTER PROCEDURE usp_Sys_Device_ListByUser
    @CompanyId      INT,
    @UserId         INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DeviceId, PushToken, Platform, DeviceName, CreatedAt, UpdatedAt
    FROM sys.PushDevice
    WHERE CompanyId = @CompanyId
      AND UserId = @UserId
      AND IsActive = 1
    ORDER BY UpdatedAt DESC;
END
GO

-- ============================================================================
-- usp_Sys_Device_GetTokensByUser — Obtiene tokens push de un usuario (para envío)
-- ============================================================================
CREATE OR ALTER PROCEDURE usp_Sys_Device_GetTokensByUser
    @CompanyId      INT,
    @UserId         INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT PushToken, Platform
    FROM sys.PushDevice
    WHERE CompanyId = @CompanyId
      AND UserId = @UserId
      AND IsActive = 1;
END
GO
