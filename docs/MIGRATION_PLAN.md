# Plan de Migracion Inicial

## Objetivo
Migrar la aplicacion VB6 a .NET escritorio sin romper operacion en clientes activos.

## Estrategia
- Mantener VB6 operando en paralelo mientras se migra por modulo.
- Separar SQL embebido y reglas de negocio de los formularios.
- Reemplazar gradualmente UI VB6 por WinForms .NET.

## Fases
1. Inventario legacy por proyecto (`Admin`, `Compras`, `PtoVenta`, `Configurador`).
2. Extraccion de logica de negocio y acceso a datos.
3. Implementacion de casos de uso prioritarios en .NET.
4. Migracion de formularios criticos.
5. Pruebas por regresion funcional.

## Regla tecnica
- Ninguna regla de negocio nueva va en code-behind de formularios.
- Toda consulta SQL nueva debe pasar por `ISqlExecutor`.
