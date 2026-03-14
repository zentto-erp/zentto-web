SET NOCOUNT ON;
WITH ProcDeps AS (
SELECT N'dbo.sp_anular_compra_tx' AS ObjectName
UNION ALL
SELECT N'dbo.sp_anular_factura_tx' AS ObjectName
UNION ALL
SELECT N'dbo.sp_anular_presupuesto_tx' AS ObjectName
UNION ALL
SELECT N'dbo.sp_emitir_compra_tx' AS ObjectName
UNION ALL
SELECT N'dbo.sp_emitir_cotizacion_tx' AS ObjectName
UNION ALL
SELECT N'dbo.sp_emitir_factura_tx' AS ObjectName
UNION ALL
SELECT N'dbo.sp_emitir_presupuesto_tx' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Almacen_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Almacen_GetByCodigo' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Almacen_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Almacen_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Almacen_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Categorias_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Categorias_GetByCodigo' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Categorias_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Categorias_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Categorias_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_CentroCosto_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_CentroCosto_GetByCodigo' AS ObjectName
UNION ALL
SELECT N'dbo.usp_CentroCosto_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_CentroCosto_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_CentroCosto_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Clases_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Clases_GetByCodigo' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Clases_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Clases_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Clases_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Clientes_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Clientes_GetByCodigo' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Clientes_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Clientes_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Clientes_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Compras_GetByNumFact' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Compras_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Contabilidad_Ajuste_Crear' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Contabilidad_Asiento_Anular' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Contabilidad_Asiento_Crear' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Contabilidad_Asiento_Get' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Contabilidad_Asientos_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Contabilidad_Balance_Comprobacion' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Contabilidad_Balance_General' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Contabilidad_Depreciacion_Generar' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Contabilidad_Estado_Resultados' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Contabilidad_Libro_Mayor' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Contabilidad_Mayor_Analitico' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Cotizacion_GetByNumFact' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Cotizacion_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Cuentas_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Cuentas_GetByCodigo' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Cuentas_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Cuentas_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Cuentas_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_CxC_AplicarCobro' AS ObjectName
UNION ALL
SELECT N'dbo.usp_CxP_AplicarPago' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Empleados_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Empleados_GetByCedula' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Empleados_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Empleados_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Empleados_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Empresa_Get' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Empresa_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Facturas_GetByNumFact' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Facturas_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Grupos_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Grupos_GetByCodigo' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Grupos_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Grupos_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Grupos_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Inventario_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Inventario_GetByCodigo' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Inventario_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Inventario_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Inventario_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Lineas_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Lineas_GetByCodigo' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Lineas_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Lineas_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Lineas_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Marcas_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Marcas_GetByCodigo' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Marcas_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Marcas_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Marcas_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Pedidos_GetByNumFact' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Pedidos_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Proveedores_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Proveedores_GetByCodigo' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Proveedores_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Proveedores_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Proveedores_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Tipos_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Tipos_GetByCodigo' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Tipos_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Tipos_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Tipos_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Unidades_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Unidades_GetById' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Unidades_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Unidades_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Unidades_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Usuarios_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Usuarios_GetByCodigo' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Usuarios_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Usuarios_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Usuarios_Update' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Vendedores_Delete' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Vendedores_GetByCodigo' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Vendedores_Insert' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Vendedores_List' AS ObjectName
UNION ALL
SELECT N'dbo.usp_Vendedores_Update' AS ObjectName
),
TableDeps AS (
SELECT N'dbo.Abonos' AS ObjectName
UNION ALL
SELECT N'dbo.Abonos_Detalle' AS ObjectName
UNION ALL
SELECT N'dbo.Clientes' AS ObjectName
UNION ALL
SELECT N'dbo.Cotizacion' AS ObjectName
UNION ALL
SELECT N'dbo.Detalle_Cotizacion' AS ObjectName
UNION ALL
SELECT N'dbo.DETALLE_DEPOSITO' AS ObjectName
UNION ALL
SELECT N'dbo.Detalle_facturas' AS ObjectName
UNION ALL
SELECT N'dbo.Detalle_notacredito' AS ObjectName
UNION ALL
SELECT N'dbo.Detalle_notadebito' AS ObjectName
UNION ALL
SELECT N'dbo.Detalle_Ordenes' AS ObjectName
UNION ALL
SELECT N'dbo.Detalle_Pedidos' AS ObjectName
UNION ALL
SELECT N'dbo.Detalle_Presupuestos' AS ObjectName
UNION ALL
SELECT N'dbo.DocumentosVenta' AS ObjectName
UNION ALL
SELECT N'dbo.DocumentosVentaDetalle' AS ObjectName
UNION ALL
SELECT N'dbo.DocumentosVentaPago' AS ObjectName
UNION ALL
SELECT N'dbo.Facturas' AS ObjectName
UNION ALL
SELECT N'dbo.Inventario' AS ObjectName
UNION ALL
SELECT N'dbo.Inventario_Aux' AS ObjectName
UNION ALL
SELECT N'dbo.MovInvent' AS ObjectName
UNION ALL
SELECT N'dbo.NOTACREDITO' AS ObjectName
UNION ALL
SELECT N'dbo.NOTADEBITO' AS ObjectName
UNION ALL
SELECT N'dbo.Ordenes' AS ObjectName
UNION ALL
SELECT N'dbo.P_Cobrar' AS ObjectName
UNION ALL
SELECT N'dbo.pagos' AS ObjectName
UNION ALL
SELECT N'dbo.Pagos_Detalle' AS ObjectName
UNION ALL
SELECT N'dbo.Pagosc' AS ObjectName
UNION ALL
SELECT N'dbo.PagosC_Detalle' AS ObjectName
UNION ALL
SELECT N'dbo.Pedidos' AS ObjectName
UNION ALL
SELECT N'dbo.Presupuestos' AS ObjectName
)
SELECT 'PROC' AS ObjectType, p.ObjectName
FROM ProcDeps p
WHERE OBJECT_ID(p.ObjectName, 'P') IS NULL
UNION ALL
SELECT 'TABLE' AS ObjectType, t.ObjectName
FROM TableDeps t
WHERE OBJECT_ID(t.ObjectName, 'U') IS NULL
ORDER BY ObjectType, ObjectName;
