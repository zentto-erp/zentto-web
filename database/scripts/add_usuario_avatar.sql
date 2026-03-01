-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: Add Avatar column to Usuarios table
-- Stores the user profile picture as a base64 data URL (data:image/...;base64,...)
-- Run once against the DatQBoxWeb database
-- ─────────────────────────────────────────────────────────────────────────────

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Usuarios' AND COLUMN_NAME = 'Avatar'
)
BEGIN
    ALTER TABLE [dbo].[Usuarios]
    ADD [Avatar] [NVARCHAR](MAX) NULL;

    PRINT 'Column Usuarios.Avatar added successfully.';
END
ELSE
BEGIN
    PRINT 'Column Usuarios.Avatar already exists, skipping.';
END
GO
