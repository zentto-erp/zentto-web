-- ============================================
-- BrokerDB – Database creation
-- Compatible: SQL Server (primary) / PostgreSQL (future)
-- ============================================
USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'BrokerDB')
BEGIN
    CREATE DATABASE BrokerDB;
END
GO

USE BrokerDB;
GO

PRINT 'BrokerDB created successfully.';
GO
