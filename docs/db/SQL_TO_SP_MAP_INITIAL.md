# Mapa Inicial SQL Embebido -> SP

- Fecha: 2026-02-13 14:46:40
- Archivos analizados: 30
- Sentencias candidatas detectadas: 2307

## Resumen por Archivo

| Archivo | Sentencias | SELECT | INSERT | UPDATE | DELETE | EXEC |
|---|---:|---:|---:|---:|---:|---:|
| DatQBox Admin\frmPorPagar.frm | 213 | 103 | 40 | 31 | 36 | 3 |
| DatQBox Compras\frmPorPagar.frm | 196 | 88 | 39 | 30 | 36 | 3 |
| DatQBox Admin\frmPorPagarActual.frm | 189 | 92 | 33 | 28 | 32 | 4 |
| DatQBox PtoVenta\Global.bas | 126 | 104 | 6 | 14 | 0 | 2 |
| DatQBox PtoVenta\frmControls.frm | 124 | 69 | 9 | 36 | 9 | 1 |
| DatQBox PtoVenta\frmControl.frm | 118 | 67 | 9 | 32 | 9 | 1 |
| DatQBox PtoVenta\FrmFacturaPedido.frm | 110 | 74 | 14 | 19 | 0 | 3 |
| DatQBox Compras\frmTablas.frm | 95 | 76 | 6 | 9 | 2 | 2 |
| DatQBox PtoVenta\frmVentasAdd.frm | 94 | 39 | 19 | 12 | 21 | 3 |
| DatQBox PtoVenta\frmControlsPOS.frm | 89 | 46 | 7 | 26 | 9 | 1 |
| DatQBox Compras\frmComprasAdd.frm | 82 | 35 | 14 | 12 | 18 | 3 |
| DatQBox Compras\frmCompras.frm | 79 | 44 | 11 | 16 | 7 | 1 |
| DatQBox Admin\frmDocumentos.frm | 76 | 41 | 5 | 27 | 2 | 1 |
| DatQBox PtoVenta\Sanjose.bas | 64 | 58 | 4 | 0 | 0 | 2 |
| DatQBox Compras\frmInventarioAux.frm | 59 | 44 | 2 | 3 | 4 | 6 |
| DatQBox PtoVenta\Winapis.bas | 57 | 45 | 0 | 10 | 0 | 2 |
| DatQBox Admin\WinapisAdmin.bas | 49 | 44 | 0 | 4 | 0 | 1 |
| DatQBox PtoVenta\FrmDetalleFormaPago.frm | 49 | 23 | 4 | 11 | 10 | 1 |
| DatQBox Compras\frmArticulos.frm | 48 | 35 | 6 | 5 | 0 | 2 |
| DatQBox Compras\frmInventario.frm | 44 | 34 | 2 | 2 | 4 | 2 |
| DatQBox Admin\WinapisAdminGym.bas | 43 | 38 | 0 | 4 | 0 | 1 |
| DatQBox Compras\frmConsultasCompras.frm | 43 | 12 | 2 | 14 | 12 | 3 |
| DatQBox Compras\WinapisCompras.bas | 41 | 38 | 0 | 2 | 0 | 1 |
| DatQBox Admin\frmMovCtas.frm | 40 | 29 | 2 | 3 | 4 | 2 |
| DatQBox PtoVenta\FrmFacturaCotiza.frm | 39 | 22 | 2 | 13 | 0 | 2 |
| DatQBox Compras\frmTrasladosInventario.frm | 37 | 23 | 10 | 3 | 0 | 1 |
| DatQBox Admin\frmConsultasVentas.frm | 29 | 21 | 3 | 1 | 3 | 1 |
| DatQBox PtoVenta\frmDetalleTrans.frm | 27 | 15 | 0 | 11 | 0 | 1 |
| DatQBox PtoVenta\Querys.bas | 27 | 20 | 0 | 2 | 0 | 5 |
| DatQBox Compras\frmCambiaPrecios.frm | 20 | 9 | 0 | 8 | 0 | 3 |

## Mapeo Propuesto

### DatQBox Admin\frmPorPagar.frm
- L2853 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_1
  SQL: SQL = " (SELECT SUM( PEND) AS SumaDePEND"
- L2853 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_2
  SQL: (SELECT SUM( PEND) AS SumaDePEND
- L2863 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_3
  SQL: SQL = " (SELECT SUM(PEND) AS SumaDePEND"
- L2863 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_4
  SQL: (SELECT SUM(PEND) AS SumaDePEND
- L2902 [UPDATE] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Admin_PROVEEDORES_Update_5
  SQL: SQL = " Update Proveedores"
- L2902 [UPDATE] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Admin_PROVEEDORES_Update_6
  SQL: Update Proveedores
- L2904 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Update_7
  SQL: SQL = " Update Clientes "
- L2904 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Update_8
  SQL: Update Clientes
- L2917 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Admin_SQL_Exec_9
  SQL: DbConnection.Execute SQL
- L3124 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_10
  SQL: vReporte.Tag = "select * from Abonos where tipo = '" & Data3.Recordset!Tipo & "' AND RECNUM = '" & Data3.Recordset!RECNUM & "' "
- L3124 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_11
  SQL: select * from Abonos where tipo = '
- L3127 [SELECT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Admin_PAGOSC_Get_12
  SQL: vReporte.Tag = "select * from PAGOSC where tipo = '" & Data3.Recordset!Tipo & "' AND RECNUM = '" & Data3.Recordset!RECNUM & "' "
- L3127 [SELECT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Admin_PAGOSC_Get_13
  SQL: select * from PAGOSC where tipo = '
- L3129 [SELECT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Admin_PAGOS_Get_14
  SQL: vReporte.Tag = "select * from PAGOS where tipo = '" & Data3.Recordset!Tipo & "' AND RECNUM = '" & Data3.Recordset!RECNUM & "' "
- L3129 [SELECT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Admin_PAGOS_Get_15
  SQL: select * from PAGOS where tipo = '
- L3300 [INSERT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Insert_16
  SQL: SQL = " INSERT INTO P_Pagar"
- L3300 [INSERT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Insert_17
  SQL: INSERT INTO P_Pagar
- L3302 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_18
  SQL: SQL = SQL & " SELECT '" & DATA1.Recordset!codigo & "' AS Codigo, '" & xFecha & "' AS Fecha, NUM_FACT ,Tipo, DEBE,HABER, " & XPEND & " AS Pend, " & Saldo & " ,Num_Comp, Descripcion,...
- L3323 [INSERT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Insert_19
  SQL: SQL = " INSERT INTO Abonos "
- L3323 [INSERT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Insert_20
  SQL: INSERT INTO Abonos
- L3325 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_21
  SQL: SQL = SQL & " SELECT '" & DATA1.Recordset!codigo & "' AS Codigo, '" & RECNUM & "' AS RECNUM , '" & xFecha & "' AS Fecha, NUM_FACT ,Tipo, " & apend & " AS Pend, HABER, " & XSALDO & ...
- L3364 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Get_22
  SQL: SQL = "SELECT * from COMPRAS WHERE NUM_FACT = '" & data4.Recordset!NUM_FACT & "' AND COD_PROVEEDOR ='" & DATA1.Recordset!codigo & "' AND CLASE <> 'NOTA CREDITO'"
- L3364 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Get_23
  SQL: SELECT * from COMPRAS WHERE NUM_FACT = '
- L3371 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Update_24
  SQL: SQL = " UPDATE COMPRAS SET TASARETENCION= " & TASAIVA & ",FECHA_PAGO = '" & xFecha & "', CANCELADA = '" & XCANCELADA & "',NRO_COMPROBANTE ='" & NROIVA & "', IVARETENIDO = " & MONTO...
- L3371 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Update_25
  SQL: UPDATE COMPRAS SET TASARETENCION=
- L3385 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Delete_26
  SQL: SQL = " DELETE FROM COMPRAS WHERE CLASE = 'NOTA CREDITO' AND COD_PROVEEDOR = '" & DATA1.Recordset!codigo & "' AND NUM_FACT = '" & Adodc1.Recordset!num_comp & "'"
- L3385 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Delete_27
  SQL: DELETE FROM COMPRAS WHERE CLASE = 'NOTA CREDITO' AND COD_PROVEEDOR = '
- L3394 [INSERT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Insert_28
  SQL: SQL = " INSERT INTO Compras ( NUM_FACT, COD_PROVEEDOR, NOMBRE, RIF, FECHA, HORA, COD_USUARIO, "
- L3394 [INSERT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Insert_29
  SQL: INSERT INTO Compras ( NUM_FACT, COD_PROVEEDOR, NOMBRE, RIF, FECHA, HORA, COD_USUARIO,
- L3457 [INSERT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Insert_30
  SQL: SQL = " INSERT INTO Movimiento_Cuenta "
- L3457 [INSERT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Insert_31
  SQL: INSERT INTO Movimiento_Cuenta
- L3459 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_32
  SQL: SQL = SQL & " SELECT '" & RECNUM & "', '" & XCUENTA & "' ,'" & XCHEQUE & "' ,'" & DATA1.Recordset!codigo & "' AS Codigo, '" & xFecha & "' AS Fecha, NUM_FACT , " & Adodc1.Recordset!...
- L3473 [INSERT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Insert_33
  SQL: SQL = " INSERT INTO P_Cobrarc"
- L3473 [INSERT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Insert_34
  SQL: INSERT INTO P_Cobrarc
- L3475 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Insert_35
  SQL: SQL = " INSERT INTO P_Cobrar"
- L3475 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Insert_36
  SQL: INSERT INTO P_Cobrar
- L3490 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_37
  SQL: SQL = SQL & " SELECT '" & XCODUSER & "', '" & DATA1.Recordset!codigo & "' AS Codigo, '" & xFecha & "' AS Fecha, NUM_FACT ,Tipo, debe,haber, " & XPEND & " AS Pend,Num_Comp, " & Sald...
- L3512 [INSERT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Admin_PAGOSC_Insert_38
  SQL: SQL = " INSERT INTO Pagosc "
- L3512 [INSERT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Admin_PAGOSC_Insert_39
  SQL: INSERT INTO Pagosc
- L3514 [INSERT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Admin_PAGOS_Insert_40
  SQL: SQL = " INSERT INTO Pagos "
- L3514 [INSERT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Admin_PAGOS_Insert_41
  SQL: INSERT INTO Pagos
- L3518 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_42
  SQL: SQL = SQL & " SELECT '" & DATA1.Recordset!codigo & "' AS Codigo, '" & RECNUM & "' AS RECNUM , '" & xFecha & "' AS Fecha, NUM_FACT ,Tipo, " & XPEND1 & " AS Pend, HABER," & XPEND1 & ...
- L3538 [UPDATE] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Update_43
  SQL: SQL = "UPDATE P_PAGAR SET PEND = " & data4.Recordset!Saldo & " WHERE DOCUMENTO = '" & data4.Recordset!NUM_FACT & "' AND TIPO = 'FACT' AND CODIGO = '" & DATA1.Recordset!codigo & "' ...
- L3538 [UPDATE] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Update_44
  SQL: UPDATE P_PAGAR SET PEND =
- L3560 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Update_45
  SQL: SQL = " UPDATE COMPRAS SET ISRL = '" & NROISLR & "', MONTOISRL = " & MONTOISLR & ", CODIGOISLR = '" & CODIGOislr & "' WHERE NUM_FACT = '" & data4.Recordset!NUM_FACT & "' AND COD_PR...
- L3560 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Update_46
  SQL: UPDATE COMPRAS SET ISRL = '
- L3595 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Update_47
  SQL: 'SQL = " UPDATE FACTURAS SET FECHA_RETENCION = '" & XFECHA & "', CANCELADA = '" & XCANCELADA & "',NRO_RETENCION ='" & NROIVA & "', RETENCIONIVA = " & MONTOIVA & ",MONTO_RETENCION =...
- L3595 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Update_48
  SQL: UPDATE FACTURAS SET FECHA_RETENCION = '
- L3598 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Admin_SQL_Exec_49
  SQL: ' DbConnection.Execute SQL
- L3606 [UPDATE] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Update_50
  SQL: SQL = "UPDATE P_COBRARC SET PEND = " & data4.Recordset!Saldo & " WHERE DOCUMENTO = '" & data4.Recordset!NUM_FACT & "' AND TIPO = 'FACT' AND CODIGO = '" & DATA1.Recordset!codigo & "...
- L3606 [UPDATE] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Update_51
  SQL: UPDATE P_COBRARC SET PEND =
- L3609 [UPDATE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Update_52
  SQL: SQL = "UPDATE P_COBRAR SET PEND = " & data4.Recordset!Saldo & " WHERE DOCUMENTO = '" & data4.Recordset!NUM_FACT & "' AND TIPO = 'FACT' AND CODIGO = '" & DATA1.Recordset!codigo & "'...
- L3609 [UPDATE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Update_53
  SQL: UPDATE P_COBRAR SET PEND =
- L3674 [SELECT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Admin_PAGOSC_Get_54
  SQL: Data3.RecordSource = " select * from Pagosc where codigo = '" & CODIGOS & "' and documento = '" & data4.Recordset!NUM_FACT & "' ORDER BY ID, fecha,documento, TIPO"
- L3674 [SELECT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Admin_PAGOSC_Get_55
  SQL: select * from Pagosc where codigo = '
- L3677 [SELECT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Admin_PAGOS_Get_56
  SQL: Data3.RecordSource = " select * from Pagos where codigo = '" & CODIGOS & "' and documento = '" & data4.Recordset!NUM_FACT & "' ORDER BY ID, fecha,documento, TIPO"
- L3677 [SELECT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Admin_PAGOS_Get_57
  SQL: select * from Pagos where codigo = '
- L3761 [DELETE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Delete_58
  SQL: SQL = " delete from detallepago where codigo = '" & DATA1.Recordset!codigo & "'"
- L3761 [DELETE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Delete_59
  SQL: delete from detallepago where codigo = '
- L3780 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_60
  SQL: TDBGrid4.Update
- L3867 [SELECT] objeto: ABONOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_ABONOS_DETALLE_Get_61
  SQL: SQL = " select * from ABONOS_DETALLE WHERE RECNUM = '" & Data3.Recordset!RECNUM & "' AND CODIGO = '" & Data3.Recordset!codigo & "' "
- L3867 [SELECT] objeto: ABONOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_ABONOS_DETALLE_Get_62
  SQL: select * from ABONOS_DETALLE WHERE RECNUM = '
- L3878 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Delete_63
  SQL: SQL = "Delete from movcuentas where nro_ref = '" & xabonos!numero & "' and nro_cta = '" & xabonos!Cuenta & "'"
- L3878 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Delete_64
  SQL: Delete from movcuentas where nro_ref = '
- L3881 [DELETE] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Admin_DETALLE_CHEQUE_Delete_65
  SQL: SQL = "Delete from detalle_cheque where nro_trans = '" & xabonos!numero & "' and nro_cta = '" & xabonos!Cuenta & "'"
- L3881 [DELETE] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Admin_DETALLE_CHEQUE_Delete_66
  SQL: Delete from detalle_cheque where nro_trans = '
- L3886 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Delete_67
  SQL: SQL = "Delete from movimiento_cuenta where CHEQUE = '" & xabonos!numero & "' AND cod_oper = '" & Data3.Recordset!Cheque & "' and cod_cuenta like '*" & xabonos!Cuenta & "'"
- L3886 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Delete_68
  SQL: Delete from movimiento_cuenta where CHEQUE = '
- L3889 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Admin_DISTRIBUCION_GASTO_Delete_69
  SQL: SQL = "Delete from distribucion_gasto where numero = '" & xabonos!numero & "' AND cuenta = '" & xabonos!Cuenta & "'"
- L3889 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Admin_DISTRIBUCION_GASTO_Delete_70
  SQL: Delete from distribucion_gasto where numero = '
- L3897 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Delete_71
  SQL: SQL = "Delete from movimiento_cuenta where cod_oper = '" & Data3.Recordset!Documento & "' and cod_proveedor = '" & Data3.Recordset!codigo & "' and numrec = '" & Data3.Recordset!REC...
- L3897 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Delete_72
  SQL: Delete from movimiento_cuenta where cod_oper = '
- L3902 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Delete_73
  SQL: SQL = " delete from " & TablaOrigen & " where documento = '" & Data3.Recordset!Documento & "' and codigo = '" & Data3.Recordset!codigo & "' and numrec = '" & Data3.Recordset!RECNUM...
- L3910 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Update_74
  SQL: SQL = "update compras set fecha_pago = null, nro_comprobante = 0, ivaretenido = 0, ISRL = 0, MontoISRL = 0, RECNUM = 0, cancelada = 'N', cancelado = 0 where num_fact = '" & Data3.R...
- L3910 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Update_75
  SQL: update compras set fecha_pago = null, nro_comprobante = 0, ivaretenido = 0, ISRL = 0, MontoISRL = 0, RECNUM = 0, cancelada = 'N', cancelado = 0 where num_fact = '
- L3914 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_76
  SQL: SQL = "update " & TablaOrigen & " set pend = DEBE where documento = " & Data3.Recordset!Documento & " and tipo = 'FACT' and codigo = '" & Data3.Recordset!codigo & "'"
- L3917 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_77
  SQL: SQL = "update " & TablaOrigen & " set pend = DEBE where documento = '" & Data3.Recordset!Documento & "' and tipo = 'FACT' and codigo = '" & Data3.Recordset!codigo & "'"
- L3927 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Delete_78
  SQL: SQL = " delete from " & TablaOrigen & " where documento = '" & Data3.Recordset!Documento & "' and codigo = '" & Data3.Recordset!codigo & "' and HABER > 0"
- L3930 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Delete_79
  SQL: ' SQL = " delete from " & TablaOrigen & " where documento = '" & data3.Recordset!Documento & "' and codigo = '" & data3.Recordset!Codigo & "' and (tipo = 'PAGO' or tipo = 'NOTA' or...
- L3939 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Update_80
  SQL: SQL = "update facturas set cancelada = 'N' where num_fact = '" & Data3.Recordset!Documento & "' and codigo = '" & Data3.Recordset!codigo & "'"
- L3939 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Update_81
  SQL: update facturas set cancelada = 'N' where num_fact = '
- L3942 [UPDATE] objeto: COBRADOS
  SP sugerido: usp_DatQBox_Admin_COBRADOS_Update_82
  SQL: ' SQL = "update cobrados set cancelada = 'N' where num_fact = " & data3.Recordset!Documento & " and codigo = '" & data3.Recordset!codigo & "'"
- L3942 [UPDATE] objeto: COBRADOS
  SP sugerido: usp_DatQBox_Admin_COBRADOS_Update_83
  SQL: update cobrados set cancelada = 'N' where num_fact =
- L3961 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Delete_84
  SQL: SQL = " delete from " & tablas & " where documento = '" & Data3.Recordset!Documento & "' and codigo = '" & Data3.Recordset!codigo & "' and RECNUM = '" & RECNUM & "' "
- L3969 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Delete_85
  SQL: SQL = " delete from compras where NUM_FACT = '" & Data3.Recordset!nota & "' and COD_PROVEEDOR = '" & Data3.Recordset!codigo & "' and clase = 'NOTA CREDITO' "
- L3969 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Delete_86
  SQL: delete from compras where NUM_FACT = '
- L4016 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Get_87
  SQL: SQL = "Select * from compras where num_fact = '" & Data3.Recordset!Documento & "' and cod_proveedor = '" & DATA1.Recordset!codigo & "' "
- L4099 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Get_88
  SQL: 'SQL = "Select * from movimiento_cuenta where cod_oper = '" & data3.Recordset!Documento & "' and cod_proveedor = '" & data1.Recordset!Codigo & "' and retiva = 1 "
- L4099 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Get_89
  SQL: Select * from movimiento_cuenta where cod_oper = '
- L4324 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_90
  SQL: cr = "select * from " & tablas & " where recnum = " & Data3.Recordset!RECNUM & " and codigo = '" & Data3.Recordset!codigo & "' and anulado = 0 ORDER BY SALDO DESC"
- L4324 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_91
  SQL: select * from
- L4350 [SELECT] objeto: NOTA
  SP sugerido: usp_DatQBox_Admin_NOTA_Get_92
  SQL: ' cr = "select * from NOTA where NUM_FACT = '" & Data3.Recordset!Documento & "' and serialtipo = '" & vSerialFiscal & "' and tipo_orden = '" & vMemoriaFiscal & "' "
- L4350 [SELECT] objeto: NOTA
  SP sugerido: usp_DatQBox_Admin_NOTA_Get_93
  SQL: select * from NOTA where NUM_FACT = '
- L4351 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_94
  SQL: cr = "select * from FACTURAS where NUM_FACT = '" & Data3.Recordset!Documento & "' and serialtipo = '" & vSerialFiscal & "' and tipo_orden = '" & vMemoriaFiscal & "' "
- L4351 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_95
  SQL: select * from FACTURAS where NUM_FACT = '
- L4414 [SELECT] objeto: PAGOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_PAGOS_DETALLE_Get_96
  SQL: cr = "select * from PAGOS_DETALLE where recnum = " & Data3.Recordset!RECNUM & " AND codigo = '" & Data3.Recordset!codigo & "' "
- L4414 [SELECT] objeto: PAGOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_PAGOS_DETALLE_Get_97
  SQL: select * from PAGOS_DETALLE where recnum =
- L4586 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_98
  SQL: ''cr = "SElect sum(aplicado) as total from abonos where Codigo = '" & Codigo & "' and recnum = " & Numero & " "
- L4586 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_99
  SQL: SElect sum(aplicado) as total from abonos where Codigo = '
- L4679 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_100
  SQL: Data3.RecordSource = "Select * from abonos where Codigo = '" & DATA1.Recordset!codigo & "' and recnum = " & Data3.Recordset!RECNUM & ""
- L4679 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_101
  SQL: Select * from abonos where Codigo = '
- L4688 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Get_102
  SQL: cr = "select * from compras where NUM_FACT = '" & Data3.Recordset!Documento & "'"
- L4823 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Get_103
  SQL: SQL = " SELECT DOCUMENTO, CODIGO FROM P_PAGAR WHERE DOCUMENTO = '" & NumFind & "'"
- L4823 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Get_104
  SQL: SELECT DOCUMENTO, CODIGO FROM P_PAGAR WHERE DOCUMENTO = '
- L4826 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Get_105
  SQL: SQL = " SELECT DOCUMENTO, CODIGO FROM P_COBRARC WHERE DOCUMENTO = '" & NumFind & "'"
- L4826 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Get_106
  SQL: SELECT DOCUMENTO, CODIGO FROM P_COBRARC WHERE DOCUMENTO = '
- L4828 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Get_107
  SQL: SQL = " SELECT DOCUMENTO, CODIGO FROM P_COBRAR WHERE DOCUMENTO = '" & NumFind & "'"
- L4828 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Get_108
  SQL: SELECT DOCUMENTO, CODIGO FROM P_COBRAR WHERE DOCUMENTO = '
- L4873 [SELECT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Get_109
  SQL: SQL = "select * from detallepago where codigo = '" & DATA1.Recordset!codigo & "'"
- L4873 [SELECT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Get_110
  SQL: select * from detallepago where codigo = '
- L4913 [DELETE] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Delete_111
  SQL: DbConnection.Execute "Delete from AbonosPagos where codigo = '" & DATA1.Recordset!codigo & "'"
- L4913 [DELETE] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Delete_112
  SQL: Delete from AbonosPagos where codigo = '
- L4915 [INSERT] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Insert_113
  SQL: SQL = " INSERT INTO AbonosPagos"
- L4915 [INSERT] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Insert_114
  SQL: INSERT INTO AbonosPagos
- L4917 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_115
  SQL: SQL = SQL & " SELECT P_Pagar.Codigo, P_Pagar.FECHA, P_Pagar.DOCUMENTO, P_Pagar.PEND, P_Pagar.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, P_Pagar.PorcentajeDescuento,"
- L4917 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_116
  SQL: SELECT P_Pagar.Codigo, P_Pagar.FECHA, P_Pagar.DOCUMENTO, P_Pagar.PEND, P_Pagar.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, P_Pagar.PorcentajeDescuento,
- L4925 [SELECT] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Get_117
  SQL: data4.RecordSource = "select Codigo, Num_Fact, Fecha,Monto, Aplicado,Retenido, Saldo, Descuento, Aceptada,Porcentaje as Alicuota, SujetoISRL as Monto_Gra, MontoIva as Iva, Exento, ...
- L4925 [SELECT] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Get_118
  SQL: select Codigo, Num_Fact, Fecha,Monto, Aplicado,Retenido, Saldo, Descuento, Aceptada,Porcentaje as Alicuota, SujetoISRL as Monto_Gra, MontoIva as Iva, Exento, Monto_retencion as Tot...
- L4929 [DELETE] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Delete_119
  SQL: DbConnection.Execute "Delete from AbonosPagosClientes where codigo = '" & DATA1.Recordset!codigo & "'"
- L4929 [DELETE] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Delete_120
  SQL: Delete from AbonosPagosClientes where codigo = '
- L4932 [INSERT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Insert_121
  SQL: SQL = " INSERT INTO AbonosPagosClientes "
- L4932 [INSERT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Insert_122
  SQL: INSERT INTO AbonosPagosClientes
- L4934 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_123
  SQL: SQL = SQL & " SELECT P_Cobrarc.CODIGO,P_Cobrarc.FECHA, P_Cobrarc.DOCUMENTO, P_Cobrarc.PEND, P_Cobrarc.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, "
- L4934 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_124
  SQL: SELECT P_Cobrarc.CODIGO,P_Cobrarc.FECHA, P_Cobrarc.DOCUMENTO, P_Cobrarc.PEND, P_Cobrarc.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4,
- L4941 [INSERT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Insert_125
  SQL: ' SQL = " INSERT INTO AbonosPagosClientes "
- L4943 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_126
  SQL: ' SQL = SQL & " SELECT P_Cobrarc.CODIGO,P_Cobrarc.FECHA, P_Cobrarc.DOCUMENTO, P_Cobrarc.PEND, P_Cobrarc.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, "
- L4962 [INSERT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Insert_127
  SQL: SQL = " INSERT INTO AbonosPagosClientes"
- L4964 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_128
  SQL: SQL = SQL & " SELECT P_Cobrar.CODIGO,P_Cobrar.FECHA, P_Cobrar.DOCUMENTO, P_Cobrar.PEND, P_Cobrar.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, "
- L4964 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_129
  SQL: SELECT P_Cobrar.CODIGO,P_Cobrar.FECHA, P_Cobrar.DOCUMENTO, P_Cobrar.PEND, P_Cobrar.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4,
- L4973 [SELECT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Get_130
  SQL: data4.RecordSource = "select Codigo, Num_Fact, Fecha,Monto, Aplicado,Retenido, Saldo, Descuento, Aceptada,Porcentaje as Alicuota, SujetoISRL as Monto_Gra, MontoIva as Iva, Exento, ...
- L4973 [SELECT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Get_131
  SQL: select Codigo, Num_Fact, Fecha,Monto, Aplicado,Retenido, Saldo, Descuento, Aceptada,Porcentaje as Alicuota, SujetoISRL as Monto_Gra, MontoIva as Iva, Exento, Monto_retencion as Tot...
- L4994 [DELETE] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Delete_132
  SQL: DbConnection.Execute "Delete from AbonosPagos where codigo '" & DATA1.Recordset!codigo & "'"
- L4994 [DELETE] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Delete_133
  SQL: Delete from AbonosPagos where codigo '
- L4996 [DELETE] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Delete_134
  SQL: DbConnection.Execute "Delete from AbonosPagosClientes where codigo '" & DATA1.Recordset!codigo & "'"
- L4996 [DELETE] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Delete_135
  SQL: Delete from AbonosPagosClientes where codigo '
- L5033 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_136
  SQL: SQL = "select * from Abonos where codigo = '" & pRecordset!codigo & "' ORDER BY ID,fecha,documento, TIPO"
- L5052 [SELECT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Admin_PAGOSC_Get_137
  SQL: SQL = "select * from Pagosc where codigo = '" & pRecordset!codigo & "' and documento = '" & pRecordset!Documento & "' ORDER BY ID, fecha,documento, TIPO"
- L5055 [SELECT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Admin_PAGOS_Get_138
  SQL: SQL = "select * from Pagos where codigo = '" & pRecordset!codigo & "' and documento = '" & pRecordset!Documento & "' ORDER BY ID, fecha,documento, TIPO"
- L5372 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Admin_TASA_MONEDA_Get_139
  SQL: c = "SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_venta, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE "
- L5372 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Admin_TASA_MONEDA_Get_140
  SQL: SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_venta, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE
- L5392 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_141
  SQL: TDBGrid5.Update
- L5479 [UPDATE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Update_142
  SQL: DbConnection.Execute "UPDATE DETALLEPAGO SET HABER = " & haber & " WHERE NUM_FACT = '" & data4.Recordset!NUM_FACT & "' AND TIPO = 'PAGO'"
- L5479 [UPDATE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Update_143
  SQL: UPDATE DETALLEPAGO SET HABER =
- L5716 [INSERT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Insert_144
  SQL: SQL = " INSERT INTO detallepago (Tipo, Descripcion, Alicuota, Num_Fact, Fact_Afect, Debe, Haber, Codigo,tasa_ret, Sujeto_ret,Monto_Fact, TASACAMBIO)"
- L5716 [INSERT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Insert_145
  SQL: INSERT INTO detallepago (Tipo, Descripcion, Alicuota, Num_Fact, Fact_Afect, Debe, Haber, Codigo,tasa_ret, Sujeto_ret,Monto_Fact, TASACAMBIO)
- L5721 [INSERT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Insert_146
  SQL: SQL = " INSERT INTO detallepago (Tipo, Descripcion, Alicuota, Num_Fact, Fact_Afect, Debe, Haber, Codigo, tasa_ret,Sujeto_ret,Monto_fact, TASACAMBIO)"
- L5721 [INSERT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Insert_147
  SQL: INSERT INTO detallepago (Tipo, Descripcion, Alicuota, Num_Fact, Fact_Afect, Debe, Haber, Codigo, tasa_ret,Sujeto_ret,Monto_fact, TASACAMBIO)
- L5801 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_148
  SQL: TDBGrid6.Update
- L5831 [SELECT] objeto: BANCOS
  SP sugerido: usp_DatQBox_Admin_BANCOS_Get_149
  SQL: SQL = " Select nombre from bancos"
- L5831 [SELECT] objeto: BANCOS
  SP sugerido: usp_DatQBox_Admin_BANCOS_Get_150
  SQL: Select nombre from bancos
- L5844 [SELECT] objeto: CUENTASBANK
  SP sugerido: usp_DatQBox_Admin_CUENTASBANK_Get_151
  SQL: SQL = " Select Nro_Cta, Descripcion, Banco from CuentasBank"
- L5844 [SELECT] objeto: CUENTASBANK
  SP sugerido: usp_DatQBox_Admin_CUENTASBANK_Get_152
  SQL: Select Nro_Cta, Descripcion, Banco from CuentasBank
- L5856 [SELECT] objeto: CENTRO_COSTO
  SP sugerido: usp_DatQBox_Admin_CENTRO_COSTO_Get_153
  SQL: SQL = " Select Descripcion, Codigo from Centro_Costo"
- L5856 [SELECT] objeto: CENTRO_COSTO
  SP sugerido: usp_DatQBox_Admin_CENTRO_COSTO_Get_154
  SQL: Select Descripcion, Codigo from Centro_Costo
- L5942 [INSERT] objeto: ABONOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_ABONOS_DETALLE_Insert_155
  SQL: SQL = " INSERT INTO Abonos_Detalle"
- L5942 [INSERT] objeto: ABONOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_ABONOS_DETALLE_Insert_156
  SQL: INSERT INTO Abonos_Detalle
- L5949 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_Admin_DETALLE_DEPOSITO_Delete_157
  SQL: SQL = "DELETE FROM DETALLE_DEPOSITO WHERE CHEQUE = '" & TDataLite1.Recordset!numero & "';"
- L5949 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_Admin_DETALLE_DEPOSITO_Delete_158
  SQL: DELETE FROM DETALLE_DEPOSITO WHERE CHEQUE = '
- L5952 [INSERT] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_Admin_DETALLE_DEPOSITO_Insert_159
  SQL: SQL = "INSERT INTO DETALLE_DEPOSITO "
- L5952 [INSERT] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_Admin_DETALLE_DEPOSITO_Insert_160
  SQL: INSERT INTO DETALLE_DEPOSITO
- L5961 [INSERT] objeto: PAGOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_PAGOS_DETALLE_Insert_161
  SQL: SQL = " INSERT INTO Pagos_Detalle"
- L5961 [INSERT] objeto: PAGOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_PAGOS_DETALLE_Insert_162
  SQL: INSERT INTO Pagos_Detalle
- L6003 [UPDATE] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Update_163
  SQL: SQL = " UPDATE ABONOS SET CHEQUE = '" & numero & "', banco = '" & Cuenta & "' WHERE RECNUM = '" & RECNUM & "' "
- L6003 [UPDATE] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Update_164
  SQL: UPDATE ABONOS SET CHEQUE = '
- L6008 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Delete_165
  SQL: SQL = "DELETE from MovCuentas where nro_cta = '" & Cuenta & "' and nro_ref = '" & numero & "' "
- L6008 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Delete_166
  SQL: DELETE from MovCuentas where nro_cta = '
- L6013 [INSERT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Insert_167
  SQL: SQL = " INSERT INTO MOVCUENTAS "
- L6013 [INSERT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Insert_168
  SQL: INSERT INTO MOVCUENTAS
- L6027 [INSERT] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Admin_DETALLE_CHEQUE_Insert_169
  SQL: SQL = " INSERT INTO detalle_cheque "
- L6027 [INSERT] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Admin_DETALLE_CHEQUE_Insert_170
  SQL: INSERT INTO detalle_cheque
- L6044 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_171
  SQL: SQL = " SELECT Tipo, Tipo + '/' + Num_Comp AS Tipos, Descripcion + ' a Fact. No.: ' + Num_Fact AS Concepto, Num_Comp, SUM(Haber) AS Monto, Codigo, Id, NUM_FACT, Monto_Fact"
- L6044 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_172
  SQL: SELECT Tipo, Tipo + '/' + Num_Comp AS Tipos, Descripcion + ' a Fact. No.: ' + Num_Fact AS Concepto, Num_Comp, SUM(Haber) AS Monto, Codigo, Id, NUM_FACT, Monto_Fact
- L6054 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Admin_DISTRIBUCION_GASTO_Delete_173
  SQL: SQL = "DELETE from Distribucion_gasto where cuenta = '" & Cuenta & "' and numero = '" & numero & "' "
- L6054 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Admin_DISTRIBUCION_GASTO_Delete_174
  SQL: DELETE from Distribucion_gasto where cuenta = '
- L6077 [INSERT] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Admin_DISTRIBUCION_GASTO_Insert_175
  SQL: SQL = " INSERT INTO Distribucion_gasto "
- L6077 [INSERT] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Admin_DISTRIBUCION_GASTO_Insert_176
  SQL: INSERT INTO Distribucion_gasto
- L6101 [INSERT] objeto: [DISTRIBUCION_GASTO]
  SP sugerido: usp_DatQBox_Admin_DISTRIBUCION_GASTO_Insert_177
  SQL: SQL = " INSERT INTO [Distribucion_gasto]"
- L6101 [INSERT] objeto: [DISTRIBUCION_GASTO]
  SP sugerido: usp_DatQBox_Admin_DISTRIBUCION_GASTO_Insert_178
  SQL: INSERT INTO [Distribucion_gasto]
- L6109 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_179
  SQL: SQL = SQL & " SELECT '" & Cuenta & "', "
- L6338 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Get_180
  SQL: 'cr = " Select " & vCampo_Uno & "+" & "' '+" & vCampo_Dos & "+" & "' '+" & vCampo_Tres & "+" & "' '+" & vCampo_Cuatro & "+" & "' '+" & vCampo_Cinco & " as Descripciones,descripcion...
- L6341 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Admin_PROVEEDORES_Get_181
  SQL: ''cr = "Select Codigo,Nombre, RIF, Saldo_30, Saldo_60, Saldo_90, Saldo_91, Saldo_Tot,Direccion,Estado, Ciudad,Cpostal, Telefono, Email, Pagina_WWW, Ult_Pago From Proveedores order ...
- L6341 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Admin_PROVEEDORES_Get_182
  SQL: Select Codigo,Nombre, RIF, Saldo_30, Saldo_60, Saldo_90, Saldo_91, Saldo_Tot,Direccion,Estado, Ciudad,Cpostal, Telefono, Email, Pagina_WWW, Ult_Pago From Proveedores order by NOMBR...
- L6345 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_183
  SQL: cr = " SELECT Clientes.CODIGO, Clientes.Status, Clientes.UltimaFechaCompra, Clientes.Creditos, Clientes.Saldo_prepago,"
- L6345 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_184
  SQL: SELECT Clientes.CODIGO, Clientes.Status, Clientes.UltimaFechaCompra, Clientes.Creditos, Clientes.Saldo_prepago,
- L6407 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_185
  SQL: cr = " SELECT Proveedores.CODIGO, Proveedores.NOMBRE, Proveedores.RIF, Proveedores.NIT, Proveedores.DIRECCION, "
- L6407 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_186
  SQL: SELECT Proveedores.CODIGO, Proveedores.NOMBRE, Proveedores.RIF, Proveedores.NIT, Proveedores.DIRECCION,
- L6448 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Get_187
  SQL: cr = "SELECT * FROM CLIENTES "
- L6448 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Get_188
  SQL: SELECT * FROM CLIENTES
- L6450 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Admin_PROVEEDORES_Get_189
  SQL: cr = " SELECT * FROM PROVEEDORES"
- L6450 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Admin_PROVEEDORES_Get_190
  SQL: SELECT * FROM PROVEEDORES
- L6475 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Get_191
  SQL: SQL = "select * from P_Pagar ORDER BY fecha,documento, TIPO"
- L6475 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Get_192
  SQL: select * from P_Pagar ORDER BY fecha,documento, TIPO
- L6482 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Get_193
  SQL: SQL = "select * from P_Cobrarc WHERE COD_USUARIO <> 'COTIZACION' ORDER BY fecha,documento, TIPO"
- L6482 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Get_194
  SQL: select * from P_Cobrarc WHERE COD_USUARIO <> 'COTIZACION' ORDER BY fecha,documento, TIPO
- L6484 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Get_195
  SQL: SQL = "select * from P_Cobrarc WHERE COD_USUARIO = 'COTIZACION' ORDER BY fecha,documento, TIPO "
- L6484 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Get_196
  SQL: select * from P_Cobrarc WHERE COD_USUARIO = 'COTIZACION' ORDER BY fecha,documento, TIPO
- L6487 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Get_197
  SQL: SQL = "select * from P_Cobrar ORDER BY fecha,documento, TIPO"
- L6487 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Get_198
  SQL: select * from P_Cobrar ORDER BY fecha,documento, TIPO
- L6513 [DELETE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Delete_199
  SQL: 'SQL = " delete from detallepago "
- L6513 [DELETE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Delete_200
  SQL: delete from detallepago
- L6514 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Admin_SQL_Exec_201
  SQL: 'DbConnection.Execute SQL
- L6525 [SELECT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Get_202
  SQL: ' SQL = "select * from detallepago "
- L6525 [SELECT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Get_203
  SQL: select * from detallepago
- L6530 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Get_204
  SQL: ' SQL = "select * from P_Pagar where codigo = '" & DATA1.Recordset!Codigo & "' ORDER BY fecha,documento, TIPO"
- L6530 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Get_205
  SQL: select * from P_Pagar where codigo = '
- L6531 [SELECT] objeto: RETENCIONES
  SP sugerido: usp_DatQBox_Admin_RETENCIONES_Get_206
  SQL: SQL = "select Codigo, Descripcion, Porcentaje,MontoMimimo,Sustraendo from retenciones order by codigo "
- L6531 [SELECT] objeto: RETENCIONES
  SP sugerido: usp_DatQBox_Admin_RETENCIONES_Get_207
  SQL: select Codigo, Descripcion, Porcentaje,MontoMimimo,Sustraendo from retenciones order by codigo
- L6542 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_208
  SQL: SQL = "select * from Abonos ORDER BY fecha,documento, TIPO"
- L6542 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_209
  SQL: select * from Abonos ORDER BY fecha,documento, TIPO
- L6545 [SELECT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Admin_PAGOSC_Get_210
  SQL: SQL = "select * from Pagosc ORDER BY fecha,documento, TIPO"
- L6545 [SELECT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Admin_PAGOSC_Get_211
  SQL: select * from Pagosc ORDER BY fecha,documento, TIPO
- L6547 [SELECT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Admin_PAGOS_Get_212
  SQL: SQL = "select * from Pagos ORDER BY fecha,documento, TIPO"
- L6547 [SELECT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Admin_PAGOS_Get_213
  SQL: select * from Pagos ORDER BY fecha,documento, TIPO

### DatQBox Compras\frmPorPagar.frm
- L2753 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_1
  SQL: SQL = " (SELECT SUM( PEND) AS SumaDePEND"
- L2753 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_2
  SQL: (SELECT SUM( PEND) AS SumaDePEND
- L2763 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_3
  SQL: SQL = " (SELECT SUM(PEND) AS SumaDePEND"
- L2763 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_4
  SQL: (SELECT SUM(PEND) AS SumaDePEND
- L2802 [UPDATE] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Compras_PROVEEDORES_Update_5
  SQL: SQL = " Update Proveedores"
- L2802 [UPDATE] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Compras_PROVEEDORES_Update_6
  SQL: Update Proveedores
- L2804 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Compras_CLIENTES_Update_7
  SQL: SQL = " Update Clientes "
- L2804 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Compras_CLIENTES_Update_8
  SQL: Update Clientes
- L2817 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_9
  SQL: DbConnection.Execute SQL
- L3146 [INSERT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Insert_10
  SQL: SQL = " INSERT INTO P_Pagar"
- L3146 [INSERT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Insert_11
  SQL: INSERT INTO P_Pagar
- L3148 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_12
  SQL: SQL = SQL & " SELECT '" & DATA1.Recordset!Codigo & "' AS Codigo, '" & xFecha & "' AS Fecha, NUM_FACT ,Tipo, DEBE,HABER, " & XPEND & " AS Pend, " & Saldo & " ,Num_Comp, Descripcion,...
- L3169 [INSERT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Insert_13
  SQL: SQL = " INSERT INTO Abonos "
- L3169 [INSERT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Insert_14
  SQL: INSERT INTO Abonos
- L3171 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_15
  SQL: SQL = SQL & " SELECT '" & DATA1.Recordset!Codigo & "' AS Codigo, '" & RECNUM & "' AS RECNUM , '" & xFecha & "' AS Fecha, NUM_FACT ,Tipo, " & apend & " AS Pend, HABER, " & XSALDO & ...
- L3210 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_16
  SQL: SQL = "SELECT * from COMPRAS WHERE NUM_FACT = '" & data4.Recordset!NUM_FACT & "' AND COD_PROVEEDOR ='" & DATA1.Recordset!Codigo & "' AND CLASE <> 'NOTA CREDITO'"
- L3210 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_17
  SQL: SELECT * from COMPRAS WHERE NUM_FACT = '
- L3217 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Update_18
  SQL: SQL = " UPDATE COMPRAS SET TASARETENCION= " & TASAIVA & ",FECHA_PAGO = '" & xFecha & "', CANCELADA = '" & XCANCELADA & "',NRO_COMPROBANTE ='" & NROIVA & "', IVARETENIDO = " & MONTO...
- L3217 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Update_19
  SQL: UPDATE COMPRAS SET TASARETENCION=
- L3231 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Delete_20
  SQL: SQL = " DELETE FROM COMPRAS WHERE CLASE = 'NOTA CREDITO' AND COD_PROVEEDOR = '" & DATA1.Recordset!Codigo & "' AND NUM_FACT = '" & Adodc1.Recordset!num_comp & "'"
- L3231 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Delete_21
  SQL: DELETE FROM COMPRAS WHERE CLASE = 'NOTA CREDITO' AND COD_PROVEEDOR = '
- L3240 [INSERT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Insert_22
  SQL: SQL = " INSERT INTO Compras ( NUM_FACT, COD_PROVEEDOR, NOMBRE, RIF, FECHA, HORA, COD_USUARIO, "
- L3240 [INSERT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Insert_23
  SQL: INSERT INTO Compras ( NUM_FACT, COD_PROVEEDOR, NOMBRE, RIF, FECHA, HORA, COD_USUARIO,
- L3303 [INSERT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Insert_24
  SQL: SQL = " INSERT INTO Movimiento_Cuenta "
- L3303 [INSERT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Insert_25
  SQL: INSERT INTO Movimiento_Cuenta
- L3305 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_26
  SQL: SQL = SQL & " SELECT '" & RECNUM & "', '" & XCUENTA & "' ,'" & XCHEQUE & "' ,'" & DATA1.Recordset!Codigo & "' AS Codigo, '" & xFecha & "' AS Fecha, NUM_FACT , " & Adodc1.Recordset!...
- L3319 [INSERT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Compras_P_COBRARC_Insert_27
  SQL: SQL = " INSERT INTO P_Cobrarc"
- L3319 [INSERT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Compras_P_COBRARC_Insert_28
  SQL: INSERT INTO P_Cobrarc
- L3321 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Compras_P_COBRAR_Insert_29
  SQL: SQL = " INSERT INTO P_Cobrar"
- L3321 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Compras_P_COBRAR_Insert_30
  SQL: INSERT INTO P_Cobrar
- L3325 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_31
  SQL: SQL = SQL & " SELECT '" & DATA1.Recordset!Codigo & "' AS Codigo, '" & xFecha & "' AS Fecha, NUM_FACT ,Tipo, debe,haber, " & XPEND & " AS Pend,Num_Comp, " & Saldo & ", Descripcion,'...
- L3347 [INSERT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Compras_PAGOSC_Insert_32
  SQL: SQL = " INSERT INTO Pagosc "
- L3347 [INSERT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Compras_PAGOSC_Insert_33
  SQL: INSERT INTO Pagosc
- L3349 [INSERT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Compras_PAGOS_Insert_34
  SQL: SQL = " INSERT INTO Pagos "
- L3349 [INSERT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Compras_PAGOS_Insert_35
  SQL: INSERT INTO Pagos
- L3353 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_36
  SQL: SQL = SQL & " SELECT '" & DATA1.Recordset!Codigo & "' AS Codigo, '" & RECNUM & "' AS RECNUM , '" & xFecha & "' AS Fecha, NUM_FACT ,Tipo, " & XPEND1 & " AS Pend, HABER," & XPEND1 & ...
- L3373 [UPDATE] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Update_37
  SQL: SQL = "UPDATE P_PAGAR SET PEND = " & data4.Recordset!Saldo & " WHERE DOCUMENTO = '" & data4.Recordset!NUM_FACT & "' AND TIPO = 'FACT' AND CODIGO = '" & DATA1.Recordset!Codigo & "' ...
- L3373 [UPDATE] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Update_38
  SQL: UPDATE P_PAGAR SET PEND =
- L3395 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Update_39
  SQL: SQL = " UPDATE COMPRAS SET ISRL = '" & NROISLR & "', MONTOISRL = " & MONTOISLR & ", CODIGOISLR = '" & CODIGOislr & "' WHERE NUM_FACT = '" & data4.Recordset!NUM_FACT & "' AND COD_PR...
- L3395 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Update_40
  SQL: UPDATE COMPRAS SET ISRL = '
- L3430 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Update_41
  SQL: 'SQL = " UPDATE FACTURAS SET FECHA_RETENCION = '" & XFECHA & "', CANCELADA = '" & XCANCELADA & "',NRO_RETENCION ='" & NROIVA & "', RETENCIONIVA = " & MONTOIVA & ",MONTO_RETENCION =...
- L3430 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Update_42
  SQL: UPDATE FACTURAS SET FECHA_RETENCION = '
- L3433 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_43
  SQL: ' DbConnection.Execute SQL
- L3441 [UPDATE] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Compras_P_COBRARC_Update_44
  SQL: SQL = "UPDATE P_COBRARC SET PEND = " & data4.Recordset!Saldo & " WHERE DOCUMENTO = '" & data4.Recordset!NUM_FACT & "' AND TIPO = 'FACT' AND CODIGO = '" & DATA1.Recordset!Codigo & "...
- L3441 [UPDATE] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Compras_P_COBRARC_Update_45
  SQL: UPDATE P_COBRARC SET PEND =
- L3444 [UPDATE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Compras_P_COBRAR_Update_46
  SQL: SQL = "UPDATE P_COBRAR SET PEND = " & data4.Recordset!Saldo & " WHERE DOCUMENTO = '" & data4.Recordset!NUM_FACT & "' AND TIPO = 'FACT' AND CODIGO = '" & DATA1.Recordset!Codigo & "'...
- L3444 [UPDATE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Compras_P_COBRAR_Update_47
  SQL: UPDATE P_COBRAR SET PEND =
- L3570 [DELETE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Compras_DETALLEPAGO_Delete_48
  SQL: SQL = " delete from detallepago where codigo = '" & DATA1.Recordset!Codigo & "'"
- L3570 [DELETE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Compras_DETALLEPAGO_Delete_49
  SQL: delete from detallepago where codigo = '
- L3589 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Update_50
  SQL: TDBGrid4.Update
- L3676 [SELECT] objeto: ABONOS_DETALLE
  SP sugerido: usp_DatQBox_Compras_ABONOS_DETALLE_Get_51
  SQL: SQL = " select * from ABONOS_DETALLE WHERE RECNUM = '" & Data3.Recordset!RECNUM & "' AND CODIGO = '" & Data3.Recordset!Codigo & "' "
- L3676 [SELECT] objeto: ABONOS_DETALLE
  SP sugerido: usp_DatQBox_Compras_ABONOS_DETALLE_Get_52
  SQL: select * from ABONOS_DETALLE WHERE RECNUM = '
- L3687 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Compras_MOVCUENTAS_Delete_53
  SQL: SQL = "Delete from movcuentas where nro_ref = '" & xabonos!numero & "' and nro_cta = '" & xabonos!Cuenta & "'"
- L3687 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Compras_MOVCUENTAS_Delete_54
  SQL: Delete from movcuentas where nro_ref = '
- L3690 [DELETE] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Compras_DETALLE_CHEQUE_Delete_55
  SQL: SQL = "Delete from detalle_cheque where nro_trans = '" & xabonos!numero & "' and nro_cta = '" & xabonos!Cuenta & "'"
- L3690 [DELETE] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Compras_DETALLE_CHEQUE_Delete_56
  SQL: Delete from detalle_cheque where nro_trans = '
- L3695 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Delete_57
  SQL: SQL = "Delete from movimiento_cuenta where CHEQUE = '" & xabonos!numero & "' AND cod_oper = '" & Data3.Recordset!Cheque & "' and cod_cuenta like '*" & xabonos!Cuenta & "'"
- L3695 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Delete_58
  SQL: Delete from movimiento_cuenta where CHEQUE = '
- L3698 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Compras_DISTRIBUCION_GASTO_Delete_59
  SQL: SQL = "Delete from distribucion_gasto where numero = '" & xabonos!numero & "' AND cuenta = '" & xabonos!Cuenta & "'"
- L3698 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Compras_DISTRIBUCION_GASTO_Delete_60
  SQL: Delete from distribucion_gasto where numero = '
- L3706 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Delete_61
  SQL: SQL = "Delete from movimiento_cuenta where cod_oper = '" & Data3.Recordset!Documento & "' and cod_proveedor = '" & Data3.Recordset!Codigo & "' and numrec = '" & Data3.Recordset!REC...
- L3706 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Delete_62
  SQL: Delete from movimiento_cuenta where cod_oper = '
- L3711 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Delete_63
  SQL: SQL = " delete from " & TablaOrigen & " where documento = '" & Data3.Recordset!Documento & "' and codigo = '" & Data3.Recordset!Codigo & "' and numrec = '" & Data3.Recordset!RECNUM...
- L3719 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Update_64
  SQL: SQL = "update compras set fecha_pago = null, nro_comprobante = 0, ivaretenido = 0, ISRL = 0, MontoISRL = 0, RECNUM = 0, cancelada = 'N', cancelado = 0 where num_fact = '" & Data3.R...
- L3719 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Update_65
  SQL: update compras set fecha_pago = null, nro_comprobante = 0, ivaretenido = 0, ISRL = 0, MontoISRL = 0, RECNUM = 0, cancelada = 'N', cancelado = 0 where num_fact = '
- L3723 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Update_66
  SQL: SQL = "update " & TablaOrigen & " set pend = DEBE where documento = " & Data3.Recordset!Documento & " and tipo = 'FACT' and codigo = '" & Data3.Recordset!Codigo & "'"
- L3726 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Update_67
  SQL: SQL = "update " & TablaOrigen & " set pend = DEBE where documento = '" & Data3.Recordset!Documento & "' and tipo = 'FACT' and codigo = '" & Data3.Recordset!Codigo & "'"
- L3736 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Delete_68
  SQL: SQL = " delete from " & TablaOrigen & " where documento = '" & Data3.Recordset!Documento & "' and codigo = '" & Data3.Recordset!Codigo & "' and HABER > 0"
- L3739 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Delete_69
  SQL: ' SQL = " delete from " & TablaOrigen & " where documento = '" & data3.Recordset!Documento & "' and codigo = '" & data3.Recordset!Codigo & "' and (tipo = 'PAGO' or tipo = 'NOTA' or...
- L3748 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Update_70
  SQL: SQL = "update facturas set cancelada = 'N' where num_fact = '" & Data3.Recordset!Documento & "' and codigo = '" & Data3.Recordset!Codigo & "'"
- L3748 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Update_71
  SQL: update facturas set cancelada = 'N' where num_fact = '
- L3751 [UPDATE] objeto: COBRADOS
  SP sugerido: usp_DatQBox_Compras_COBRADOS_Update_72
  SQL: ' SQL = "update cobrados set cancelada = 'N' where num_fact = " & data3.Recordset!Documento & " and codigo = '" & data3.Recordset!codigo & "'"
- L3751 [UPDATE] objeto: COBRADOS
  SP sugerido: usp_DatQBox_Compras_COBRADOS_Update_73
  SQL: update cobrados set cancelada = 'N' where num_fact =
- L3770 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Delete_74
  SQL: SQL = " delete from " & tablas & " where documento = '" & Data3.Recordset!Documento & "' and codigo = '" & Data3.Recordset!Codigo & "' and RECNUM = '" & RECNUM & "' "
- L3778 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Delete_75
  SQL: SQL = " delete from compras where NUM_FACT = '" & Data3.Recordset!nota & "' and COD_PROVEEDOR = '" & Data3.Recordset!Codigo & "' and clase = 'NOTA CREDITO' "
- L3778 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Delete_76
  SQL: delete from compras where NUM_FACT = '
- L3825 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_77
  SQL: SQL = "Select * from compras where num_fact = '" & Data3.Recordset!Documento & "' and cod_proveedor = '" & DATA1.Recordset!Codigo & "' "
- L3908 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Get_78
  SQL: 'SQL = "Select * from movimiento_cuenta where cod_oper = '" & data3.Recordset!Documento & "' and cod_proveedor = '" & data1.Recordset!Codigo & "' and retiva = 1 "
- L3908 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Get_79
  SQL: Select * from movimiento_cuenta where cod_oper = '
- L4131 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_80
  SQL: cr = "select * from " & tablas & " where recnum = " & Data3.Recordset!RECNUM & " and codigo = '" & Data3.Recordset!Codigo & "' and anulado = 0 ORDER BY SALDO DESC"
- L4131 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_81
  SQL: select * from
- L4156 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_82
  SQL: cr = "select * from FACTURAS where NUM_FACT = '" & Data3.Recordset!Documento & "'"
- L4156 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_83
  SQL: select * from FACTURAS where NUM_FACT = '
- L4211 [SELECT] objeto: PAGOS_DETALLE
  SP sugerido: usp_DatQBox_Compras_PAGOS_DETALLE_Get_84
  SQL: cr = "select * from PAGOS_DETALLE where recnum = " & Data3.Recordset!RECNUM & " AND codigo = '" & Data3.Recordset!Codigo & "' "
- L4211 [SELECT] objeto: PAGOS_DETALLE
  SP sugerido: usp_DatQBox_Compras_PAGOS_DETALLE_Get_85
  SQL: select * from PAGOS_DETALLE where recnum =
- L4362 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Get_86
  SQL: ''cr = "SElect sum(aplicado) as total from abonos where Codigo = '" & Codigo & "' and recnum = " & Numero & " "
- L4362 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Get_87
  SQL: SElect sum(aplicado) as total from abonos where Codigo = '
- L4455 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Get_88
  SQL: Data3.RecordSource = "Select * from abonos where Codigo = '" & DATA1.Recordset!Codigo & "' and recnum = " & Data3.Recordset!RECNUM & ""
- L4455 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Get_89
  SQL: Select * from abonos where Codigo = '
- L4464 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_90
  SQL: cr = "select * from compras where NUM_FACT = '" & Data3.Recordset!Documento & "'"
- L4597 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Get_91
  SQL: SQL = " SELECT DOCUMENTO, CODIGO FROM P_PAGAR WHERE DOCUMENTO = '" & NumFind & "'"
- L4597 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Get_92
  SQL: SELECT DOCUMENTO, CODIGO FROM P_PAGAR WHERE DOCUMENTO = '
- L4600 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Compras_P_COBRARC_Get_93
  SQL: SQL = " SELECT DOCUMENTO, CODIGO FROM P_COBRARC WHERE DOCUMENTO = '" & NumFind & "'"
- L4600 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Compras_P_COBRARC_Get_94
  SQL: SELECT DOCUMENTO, CODIGO FROM P_COBRARC WHERE DOCUMENTO = '
- L4602 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Compras_P_COBRAR_Get_95
  SQL: SQL = " SELECT DOCUMENTO, CODIGO FROM P_COBRAR WHERE DOCUMENTO = '" & NumFind & "'"
- L4602 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Compras_P_COBRAR_Get_96
  SQL: SELECT DOCUMENTO, CODIGO FROM P_COBRAR WHERE DOCUMENTO = '
- L4647 [SELECT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Compras_DETALLEPAGO_Get_97
  SQL: SQL = "select * from detallepago where codigo = '" & DATA1.Recordset!Codigo & "'"
- L4647 [SELECT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Compras_DETALLEPAGO_Get_98
  SQL: select * from detallepago where codigo = '
- L4687 [DELETE] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOS_Delete_99
  SQL: DbConnection.Execute "Delete from AbonosPagos where codigo = '" & DATA1.Recordset!Codigo & "'"
- L4687 [DELETE] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOS_Delete_100
  SQL: Delete from AbonosPagos where codigo = '
- L4689 [INSERT] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOS_Insert_101
  SQL: SQL = " INSERT INTO AbonosPagos"
- L4689 [INSERT] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOS_Insert_102
  SQL: INSERT INTO AbonosPagos
- L4691 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_103
  SQL: SQL = SQL & " SELECT P_Pagar.Codigo, P_Pagar.FECHA, P_Pagar.DOCUMENTO, P_Pagar.PEND, P_Pagar.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, P_Pagar.PorcentajeDescuento,"
- L4691 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_104
  SQL: SELECT P_Pagar.Codigo, P_Pagar.FECHA, P_Pagar.DOCUMENTO, P_Pagar.PEND, P_Pagar.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, P_Pagar.PorcentajeDescuento,
- L4699 [SELECT] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOS_Get_105
  SQL: data4.RecordSource = "select Codigo, Num_Fact, Fecha,Monto, Aplicado,Retenido, Saldo, Descuento, Aceptada,Porcentaje as Alicuota, SujetoISRL as Monto_Gra, MontoIva as Iva, Exento, ...
- L4699 [SELECT] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOS_Get_106
  SQL: select Codigo, Num_Fact, Fecha,Monto, Aplicado,Retenido, Saldo, Descuento, Aceptada,Porcentaje as Alicuota, SujetoISRL as Monto_Gra, MontoIva as Iva, Exento, Monto_retencion as Tot...
- L4703 [DELETE] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOSCLIENTES_Delete_107
  SQL: DbConnection.Execute "Delete from AbonosPagosClientes where codigo = '" & DATA1.Recordset!Codigo & "'"
- L4703 [DELETE] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOSCLIENTES_Delete_108
  SQL: Delete from AbonosPagosClientes where codigo = '
- L4706 [INSERT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOSCLIENTES_Insert_109
  SQL: SQL = " INSERT INTO AbonosPagosClientes "
- L4706 [INSERT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOSCLIENTES_Insert_110
  SQL: INSERT INTO AbonosPagosClientes
- L4708 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_111
  SQL: SQL = SQL & " SELECT P_Cobrarc.CODIGO,P_Cobrarc.FECHA, P_Cobrarc.DOCUMENTO, P_Cobrarc.PEND, P_Cobrarc.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, "
- L4708 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_112
  SQL: SELECT P_Cobrarc.CODIGO,P_Cobrarc.FECHA, P_Cobrarc.DOCUMENTO, P_Cobrarc.PEND, P_Cobrarc.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4,
- L4715 [INSERT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOSCLIENTES_Insert_113
  SQL: SQL = " INSERT INTO AbonosPagosClientes"
- L4717 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_114
  SQL: SQL = SQL & " SELECT P_Cobrar.CODIGO,P_Cobrar.FECHA, P_Cobrar.DOCUMENTO, P_Cobrar.PEND, P_Cobrar.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, "
- L4717 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_115
  SQL: SELECT P_Cobrar.CODIGO,P_Cobrar.FECHA, P_Cobrar.DOCUMENTO, P_Cobrar.PEND, P_Cobrar.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4,
- L4726 [SELECT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOSCLIENTES_Get_116
  SQL: data4.RecordSource = "select Codigo, Num_Fact, Fecha,Monto, Aplicado,Retenido, Saldo, Descuento, Aceptada,Porcentaje as Alicuota, SujetoISRL as Monto_Gra, MontoIva as Iva, Exento, ...
- L4726 [SELECT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOSCLIENTES_Get_117
  SQL: select Codigo, Num_Fact, Fecha,Monto, Aplicado,Retenido, Saldo, Descuento, Aceptada,Porcentaje as Alicuota, SujetoISRL as Monto_Gra, MontoIva as Iva, Exento, Monto_retencion as Tot...
- L4747 [DELETE] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOS_Delete_118
  SQL: DbConnection.Execute "Delete from AbonosPagos where codigo '" & DATA1.Recordset!Codigo & "'"
- L4747 [DELETE] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOS_Delete_119
  SQL: Delete from AbonosPagos where codigo '
- L4749 [DELETE] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOSCLIENTES_Delete_120
  SQL: DbConnection.Execute "Delete from AbonosPagosClientes where codigo '" & DATA1.Recordset!Codigo & "'"
- L4749 [DELETE] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Compras_ABONOSPAGOSCLIENTES_Delete_121
  SQL: Delete from AbonosPagosClientes where codigo '
- L4786 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Get_122
  SQL: SQL = "select * from Abonos where codigo = '" & pRecordset!Codigo & "' ORDER BY ID,fecha,documento, TIPO"
- L4805 [SELECT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Compras_PAGOSC_Get_123
  SQL: SQL = "select * from Pagosc where codigo = '" & pRecordset!Codigo & "' and documento = '" & pRecordset!Documento & "' ORDER BY ID, fecha,documento, TIPO"
- L4805 [SELECT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Compras_PAGOSC_Get_124
  SQL: select * from Pagosc where codigo = '
- L4808 [SELECT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Compras_PAGOS_Get_125
  SQL: SQL = "select * from Pagos where codigo = '" & pRecordset!Codigo & "' and documento = '" & pRecordset!Documento & "' ORDER BY ID, fecha,documento, TIPO"
- L4808 [SELECT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Compras_PAGOS_Get_126
  SQL: select * from Pagos where codigo = '
- L5143 [UPDATE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Compras_DETALLEPAGO_Update_127
  SQL: DbConnection.Execute "UPDATE DETALLEPAGO SET HABER = " & haber & " WHERE NUM_FACT = '" & data4.Recordset!NUM_FACT & "' AND TIPO = 'PAGO'"
- L5143 [UPDATE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Compras_DETALLEPAGO_Update_128
  SQL: UPDATE DETALLEPAGO SET HABER =
- L5370 [INSERT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Compras_DETALLEPAGO_Insert_129
  SQL: SQL = " INSERT INTO detallepago (Tipo, Descripcion, Alicuota, Num_Fact, Fact_Afect, Debe, Haber, Codigo,tasa_ret, Sujeto_ret,Monto_Fact)"
- L5370 [INSERT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Compras_DETALLEPAGO_Insert_130
  SQL: INSERT INTO detallepago (Tipo, Descripcion, Alicuota, Num_Fact, Fact_Afect, Debe, Haber, Codigo,tasa_ret, Sujeto_ret,Monto_Fact)
- L5375 [INSERT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Compras_DETALLEPAGO_Insert_131
  SQL: SQL = " INSERT INTO detallepago (Tipo, Descripcion, Alicuota, Num_Fact, Fact_Afect, Debe, Haber, Codigo, tasa_ret,Sujeto_ret,Monto_fact)"
- L5375 [INSERT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Compras_DETALLEPAGO_Insert_132
  SQL: INSERT INTO detallepago (Tipo, Descripcion, Alicuota, Num_Fact, Fact_Afect, Debe, Haber, Codigo, tasa_ret,Sujeto_ret,Monto_fact)
- L5453 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Update_133
  SQL: TDBGrid6.Update
- L5483 [SELECT] objeto: BANCOS
  SP sugerido: usp_DatQBox_Compras_BANCOS_Get_134
  SQL: SQL = " Select nombre from bancos"
- L5483 [SELECT] objeto: BANCOS
  SP sugerido: usp_DatQBox_Compras_BANCOS_Get_135
  SQL: Select nombre from bancos
- L5496 [SELECT] objeto: CUENTASBANK
  SP sugerido: usp_DatQBox_Compras_CUENTASBANK_Get_136
  SQL: SQL = " Select Nro_Cta, Descripcion, Banco from CuentasBank"
- L5496 [SELECT] objeto: CUENTASBANK
  SP sugerido: usp_DatQBox_Compras_CUENTASBANK_Get_137
  SQL: Select Nro_Cta, Descripcion, Banco from CuentasBank
- L5508 [SELECT] objeto: CENTRO_COSTO
  SP sugerido: usp_DatQBox_Compras_CENTRO_COSTO_Get_138
  SQL: SQL = " Select Descripcion, Codigo from Centro_Costo"
- L5508 [SELECT] objeto: CENTRO_COSTO
  SP sugerido: usp_DatQBox_Compras_CENTRO_COSTO_Get_139
  SQL: Select Descripcion, Codigo from Centro_Costo
- L5594 [INSERT] objeto: ABONOS_DETALLE
  SP sugerido: usp_DatQBox_Compras_ABONOS_DETALLE_Insert_140
  SQL: SQL = " INSERT INTO Abonos_Detalle"
- L5594 [INSERT] objeto: ABONOS_DETALLE
  SP sugerido: usp_DatQBox_Compras_ABONOS_DETALLE_Insert_141
  SQL: INSERT INTO Abonos_Detalle
- L5601 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_Compras_DETALLE_DEPOSITO_Delete_142
  SQL: SQL = "DELETE FROM DETALLE_DEPOSITO WHERE CHEQUE = '" & TDataLite1.Recordset!numero & "';"
- L5601 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_Compras_DETALLE_DEPOSITO_Delete_143
  SQL: DELETE FROM DETALLE_DEPOSITO WHERE CHEQUE = '
- L5604 [INSERT] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_Compras_DETALLE_DEPOSITO_Insert_144
  SQL: SQL = "INSERT INTO DETALLE_DEPOSITO "
- L5604 [INSERT] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_Compras_DETALLE_DEPOSITO_Insert_145
  SQL: INSERT INTO DETALLE_DEPOSITO
- L5613 [INSERT] objeto: PAGOS_DETALLE
  SP sugerido: usp_DatQBox_Compras_PAGOS_DETALLE_Insert_146
  SQL: SQL = " INSERT INTO Pagos_Detalle"
- L5613 [INSERT] objeto: PAGOS_DETALLE
  SP sugerido: usp_DatQBox_Compras_PAGOS_DETALLE_Insert_147
  SQL: INSERT INTO Pagos_Detalle
- L5655 [UPDATE] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Update_148
  SQL: SQL = " UPDATE ABONOS SET CHEQUE = '" & numero & "', banco = '" & Cuenta & "' WHERE RECNUM = '" & RECNUM & "' "
- L5655 [UPDATE] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Update_149
  SQL: UPDATE ABONOS SET CHEQUE = '
- L5660 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Compras_MOVCUENTAS_Delete_150
  SQL: SQL = "DELETE from MovCuentas where nro_cta = '" & Cuenta & "' and nro_ref = '" & numero & "' "
- L5660 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Compras_MOVCUENTAS_Delete_151
  SQL: DELETE from MovCuentas where nro_cta = '
- L5665 [INSERT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Compras_MOVCUENTAS_Insert_152
  SQL: SQL = " INSERT INTO MOVCUENTAS "
- L5665 [INSERT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Compras_MOVCUENTAS_Insert_153
  SQL: INSERT INTO MOVCUENTAS
- L5679 [INSERT] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Compras_DETALLE_CHEQUE_Insert_154
  SQL: SQL = " INSERT INTO detalle_cheque "
- L5679 [INSERT] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Compras_DETALLE_CHEQUE_Insert_155
  SQL: INSERT INTO detalle_cheque
- L5696 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_156
  SQL: SQL = " SELECT Tipo, Tipo + '/' + Num_Comp AS Tipos, Descripcion + ' a Fact. No.: ' + Num_Fact AS Concepto, Num_Comp, SUM(Haber) AS Monto, Codigo, Id, NUM_FACT, Monto_Fact"
- L5696 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_157
  SQL: SELECT Tipo, Tipo + '/' + Num_Comp AS Tipos, Descripcion + ' a Fact. No.: ' + Num_Fact AS Concepto, Num_Comp, SUM(Haber) AS Monto, Codigo, Id, NUM_FACT, Monto_Fact
- L5706 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Compras_DISTRIBUCION_GASTO_Delete_158
  SQL: SQL = "DELETE from Distribucion_gasto where cuenta = '" & Cuenta & "' and numero = '" & numero & "' "
- L5706 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Compras_DISTRIBUCION_GASTO_Delete_159
  SQL: DELETE from Distribucion_gasto where cuenta = '
- L5729 [INSERT] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Compras_DISTRIBUCION_GASTO_Insert_160
  SQL: SQL = " INSERT INTO Distribucion_gasto "
- L5729 [INSERT] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Compras_DISTRIBUCION_GASTO_Insert_161
  SQL: INSERT INTO Distribucion_gasto
- L5753 [INSERT] objeto: [DISTRIBUCION_GASTO]
  SP sugerido: usp_DatQBox_Compras_DISTRIBUCION_GASTO_Insert_162
  SQL: SQL = " INSERT INTO [Distribucion_gasto]"
- L5753 [INSERT] objeto: [DISTRIBUCION_GASTO]
  SP sugerido: usp_DatQBox_Compras_DISTRIBUCION_GASTO_Insert_163
  SQL: INSERT INTO [Distribucion_gasto]
- L5761 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_164
  SQL: SQL = SQL & " SELECT '" & Cuenta & "', "
- L5996 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_165
  SQL: 'cr = " Select " & vCampo_Uno & "+" & "' '+" & vCampo_Dos & "+" & "' '+" & vCampo_Tres & "+" & "' '+" & vCampo_Cuatro & "+" & "' '+" & vCampo_Cinco & " as Descripciones,descripcion...
- L5999 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Compras_PROVEEDORES_Get_166
  SQL: ''cr = "Select Codigo,Nombre, RIF, Saldo_30, Saldo_60, Saldo_90, Saldo_91, Saldo_Tot,Direccion,Estado, Ciudad,Cpostal, Telefono, Email, Pagina_WWW, Ult_Pago From Proveedores order ...
- L5999 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Compras_PROVEEDORES_Get_167
  SQL: Select Codigo,Nombre, RIF, Saldo_30, Saldo_60, Saldo_90, Saldo_91, Saldo_Tot,Direccion,Estado, Ciudad,Cpostal, Telefono, Email, Pagina_WWW, Ult_Pago From Proveedores order by NOMBR...
- L6003 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_168
  SQL: cr = " SELECT Clientes.CODIGO, Clientes.Status, Clientes.UltimaFechaCompra, Clientes.Creditos, Clientes.Saldo_prepago,"
- L6003 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_169
  SQL: SELECT Clientes.CODIGO, Clientes.Status, Clientes.UltimaFechaCompra, Clientes.Creditos, Clientes.Saldo_prepago,
- L6061 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_170
  SQL: cr = " SELECT Proveedores.CODIGO, Proveedores.NOMBRE, Proveedores.RIF, Proveedores.NIT, Proveedores.DIRECCION, "
- L6061 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_171
  SQL: SELECT Proveedores.CODIGO, Proveedores.NOMBRE, Proveedores.RIF, Proveedores.NIT, Proveedores.DIRECCION,
- L6100 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Compras_CLIENTES_Get_172
  SQL: cr = "SELECT * FROM CLIENTES "
- L6100 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Compras_CLIENTES_Get_173
  SQL: SELECT * FROM CLIENTES
- L6102 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Compras_PROVEEDORES_Get_174
  SQL: cr = " SELECT * FROM PROVEEDORES"
- L6102 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Compras_PROVEEDORES_Get_175
  SQL: SELECT * FROM PROVEEDORES
- L6113 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Get_176
  SQL: SQL = "select * from P_Pagar ORDER BY fecha,documento, TIPO"
- L6113 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Get_177
  SQL: select * from P_Pagar ORDER BY fecha,documento, TIPO
- L6120 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Compras_P_COBRARC_Get_178
  SQL: SQL = "select * from P_Cobrarc ORDER BY fecha,documento, TIPO"
- L6120 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Compras_P_COBRARC_Get_179
  SQL: select * from P_Cobrarc ORDER BY fecha,documento, TIPO
- L6122 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Compras_P_COBRAR_Get_180
  SQL: SQL = "select * from P_Cobrar ORDER BY fecha,documento, TIPO"
- L6122 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Compras_P_COBRAR_Get_181
  SQL: select * from P_Cobrar ORDER BY fecha,documento, TIPO
- L6148 [DELETE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Compras_DETALLEPAGO_Delete_182
  SQL: 'SQL = " delete from detallepago "
- L6148 [DELETE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Compras_DETALLEPAGO_Delete_183
  SQL: delete from detallepago
- L6149 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_184
  SQL: 'DbConnection.Execute SQL
- L6160 [SELECT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Compras_DETALLEPAGO_Get_185
  SQL: ' SQL = "select * from detallepago "
- L6160 [SELECT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Compras_DETALLEPAGO_Get_186
  SQL: select * from detallepago
- L6165 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Get_187
  SQL: ' SQL = "select * from P_Pagar where codigo = '" & DATA1.Recordset!Codigo & "' ORDER BY fecha,documento, TIPO"
- L6165 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Get_188
  SQL: select * from P_Pagar where codigo = '
- L6166 [SELECT] objeto: RETENCIONES
  SP sugerido: usp_DatQBox_Compras_RETENCIONES_Get_189
  SQL: SQL = "select Codigo, Descripcion, Porcentaje,MontoMimimo,Sustraendo from retenciones order by codigo "
- L6166 [SELECT] objeto: RETENCIONES
  SP sugerido: usp_DatQBox_Compras_RETENCIONES_Get_190
  SQL: select Codigo, Descripcion, Porcentaje,MontoMimimo,Sustraendo from retenciones order by codigo
- L6177 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Get_191
  SQL: SQL = "select * from Abonos ORDER BY fecha,documento, TIPO"
- L6177 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Get_192
  SQL: select * from Abonos ORDER BY fecha,documento, TIPO
- L6180 [SELECT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Compras_PAGOSC_Get_193
  SQL: SQL = "select * from Pagosc ORDER BY fecha,documento, TIPO"
- L6180 [SELECT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Compras_PAGOSC_Get_194
  SQL: select * from Pagosc ORDER BY fecha,documento, TIPO
- L6182 [SELECT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Compras_PAGOS_Get_195
  SQL: SQL = "select * from Pagos ORDER BY fecha,documento, TIPO"
- L6182 [SELECT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Compras_PAGOS_Get_196
  SQL: select * from Pagos ORDER BY fecha,documento, TIPO

### DatQBox Admin\frmPorPagarActual.frm
- L2734 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_1
  SQL: SQL = " (SELECT SUM( PEND) AS SumaDePEND"
- L2734 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_2
  SQL: (SELECT SUM( PEND) AS SumaDePEND
- L2744 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_3
  SQL: SQL = " (SELECT SUM(PEND) AS SumaDePEND"
- L2744 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_4
  SQL: (SELECT SUM(PEND) AS SumaDePEND
- L2783 [UPDATE] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Admin_PROVEEDORES_Update_5
  SQL: SQL = " Update Proveedores"
- L2783 [UPDATE] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Admin_PROVEEDORES_Update_6
  SQL: Update Proveedores
- L2785 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Update_7
  SQL: SQL = " Update Clientes "
- L2785 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Update_8
  SQL: Update Clientes
- L2798 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Admin_SQL_Exec_9
  SQL: DbConnection.Execute SQL
- L3124 [INSERT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Insert_10
  SQL: SQL = " INSERT INTO P_Pagar"
- L3124 [INSERT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Insert_11
  SQL: INSERT INTO P_Pagar
- L3126 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_12
  SQL: SQL = SQL & " SELECT '" & DATA1.Recordset!codigo & "' AS Codigo, '" & XFECHA & "' AS Fecha, NUM_FACT ,Tipo, DEBE,HABER, " & XPEND & " AS Pend, " & Saldo & " ,Num_Comp, Descripcion,...
- L3147 [INSERT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Insert_13
  SQL: SQL = " INSERT INTO Abonos "
- L3147 [INSERT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Insert_14
  SQL: INSERT INTO Abonos
- L3149 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_15
  SQL: SQL = SQL & " SELECT '" & DATA1.Recordset!codigo & "' AS Codigo, '" & RECNUM & "' AS RECNUM , '" & XFECHA & "' AS Fecha, NUM_FACT ,Tipo, " & apend & " AS Pend, HABER, " & XSALDO & ...
- L3186 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Delete_16
  SQL: SQL = " DELETE FROM COMPRAS WHERE CLASE = 'NOTA CREDITO' AND COD_PROVEEDOR = '" & DATA1.Recordset!codigo & "' AND NUM_FACT = '" & Adodc1.Recordset!num_comp & "'"
- L3186 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Delete_17
  SQL: DELETE FROM COMPRAS WHERE CLASE = 'NOTA CREDITO' AND COD_PROVEEDOR = '
- L3195 [INSERT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Insert_18
  SQL: SQL = " INSERT INTO Compras ( NUM_FACT, COD_PROVEEDOR, NOMBRE, RIF, FECHA, HORA, COD_USUARIO, "
- L3195 [INSERT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Insert_19
  SQL: INSERT INTO Compras ( NUM_FACT, COD_PROVEEDOR, NOMBRE, RIF, FECHA, HORA, COD_USUARIO,
- L3258 [INSERT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Insert_20
  SQL: SQL = " INSERT INTO Movimiento_Cuenta "
- L3258 [INSERT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Insert_21
  SQL: INSERT INTO Movimiento_Cuenta
- L3260 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_22
  SQL: SQL = SQL & " SELECT '" & RECNUM & "', '" & XCUENTA & "' ,'" & XCHEQUE & "' ,'" & DATA1.Recordset!codigo & "' AS Codigo, '" & XFECHA & "' AS Fecha, NUM_FACT , " & Adodc1.Recordset!...
- L3274 [INSERT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Insert_23
  SQL: SQL = " INSERT INTO P_Cobrarc"
- L3274 [INSERT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Insert_24
  SQL: INSERT INTO P_Cobrarc
- L3276 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Insert_25
  SQL: SQL = " INSERT INTO P_Cobrar"
- L3276 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Insert_26
  SQL: INSERT INTO P_Cobrar
- L3280 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_27
  SQL: SQL = SQL & " SELECT '" & DATA1.Recordset!codigo & "' AS Codigo, '" & XFECHA & "' AS Fecha, NUM_FACT ,Tipo, debe,haber, " & XPEND & " AS Pend,Num_Comp, " & Saldo & ", Descripcion,'...
- L3302 [INSERT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Admin_PAGOSC_Insert_28
  SQL: SQL = " INSERT INTO Pagosc "
- L3302 [INSERT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Admin_PAGOSC_Insert_29
  SQL: INSERT INTO Pagosc
- L3304 [INSERT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Admin_PAGOS_Insert_30
  SQL: SQL = " INSERT INTO Pagos "
- L3304 [INSERT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Admin_PAGOS_Insert_31
  SQL: INSERT INTO Pagos
- L3308 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_32
  SQL: SQL = SQL & " SELECT '" & DATA1.Recordset!codigo & "' AS Codigo, '" & RECNUM & "' AS RECNUM , '" & XFECHA & "' AS Fecha, NUM_FACT ,Tipo, " & XPEND1 & " AS Pend, HABER," & XPEND1 & ...
- L3328 [UPDATE] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Update_33
  SQL: SQL = "UPDATE P_PAGAR SET PEND = " & Data4.Recordset!Saldo & " WHERE DOCUMENTO = '" & Data4.Recordset!num_fact & "' AND TIPO = 'FACT' AND CODIGO = '" & DATA1.Recordset!codigo & "' ...
- L3328 [UPDATE] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Update_34
  SQL: UPDATE P_PAGAR SET PEND =
- L3350 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Update_35
  SQL: SQL = " UPDATE COMPRAS SET ISRL = '" & NROISLR & "', MONTOISRL = " & MONTOISLR & ", CODIGOISLR = '" & CODIGOislr & "' WHERE NUM_FACT = '" & Data4.Recordset!num_fact & "' AND COD_PR...
- L3350 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Update_36
  SQL: UPDATE COMPRAS SET ISRL = '
- L3358 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Get_37
  SQL: SQL = "SELECT * from COMPRAS WHERE NUM_FACT = '" & Data4.Recordset!num_fact & "' AND COD_PROVEEDOR ='" & DATA1.Recordset!codigo & "' AND CLASE <> 'NOTA CREDITO'"
- L3358 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Get_38
  SQL: SELECT * from COMPRAS WHERE NUM_FACT = '
- L3365 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Update_39
  SQL: SQL = " UPDATE COMPRAS SET TASARETENCION= " & TASAIVA & ",FECHA_PAGO = '" & XFECHA & "', CANCELADA = '" & XCANCELADA & "',NRO_COMPROBANTE ='" & NROIVA & "', IVARETENIDO = " & MONTO...
- L3365 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Update_40
  SQL: UPDATE COMPRAS SET TASARETENCION=
- L3385 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Update_41
  SQL: SQL = " UPDATE FACTURAS SET FECHA_RETENCION = '" & XFECHA & "', CANCELADA = '" & XCANCELADA & "',NRO_RETENCION ='" & NROIVA & "', RETENCIONIVA = " & MONTOIVA & ",MONTO_RETENCION = ...
- L3385 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Update_42
  SQL: UPDATE FACTURAS SET FECHA_RETENCION = '
- L3396 [UPDATE] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Update_43
  SQL: SQL = "UPDATE P_COBRARC SET PEND = " & Data4.Recordset!Saldo & " WHERE DOCUMENTO = '" & Data4.Recordset!num_fact & "' AND TIPO = 'FACT' AND CODIGO = '" & DATA1.Recordset!codigo & "...
- L3396 [UPDATE] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Update_44
  SQL: UPDATE P_COBRARC SET PEND =
- L3399 [UPDATE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Update_45
  SQL: SQL = "UPDATE P_COBRAR SET PEND = " & Data4.Recordset!Saldo & " WHERE DOCUMENTO = '" & Data4.Recordset!num_fact & "' AND TIPO = 'FACT' AND CODIGO = '" & DATA1.Recordset!codigo & "'...
- L3399 [UPDATE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Update_46
  SQL: UPDATE P_COBRAR SET PEND =
- L3523 [DELETE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Delete_47
  SQL: SQL = " delete from detallepago where codigo = '" & DATA1.Recordset!codigo & "'"
- L3523 [DELETE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Delete_48
  SQL: delete from detallepago where codigo = '
- L3542 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_49
  SQL: TDBGrid4.Update
- L3629 [SELECT] objeto: ABONOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_ABONOS_DETALLE_Get_50
  SQL: SQL = " select * from ABONOS_DETALLE WHERE RECNUM = '" & Data3.Recordset!RECNUM & "' AND CODIGO = '" & Data3.Recordset!codigo & "' "
- L3629 [SELECT] objeto: ABONOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_ABONOS_DETALLE_Get_51
  SQL: select * from ABONOS_DETALLE WHERE RECNUM = '
- L3640 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Delete_52
  SQL: SQL = "Delete from movcuentas where nro_ref = '" & xabonos!numero & "' and nro_cta = '" & xabonos!cuenta & "'"
- L3640 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Delete_53
  SQL: Delete from movcuentas where nro_ref = '
- L3643 [DELETE] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Admin_DETALLE_CHEQUE_Delete_54
  SQL: SQL = "Delete from detalle_cheque where nro_trans = '" & xabonos!numero & "' and nro_cta = '" & xabonos!cuenta & "'"
- L3643 [DELETE] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Admin_DETALLE_CHEQUE_Delete_55
  SQL: Delete from detalle_cheque where nro_trans = '
- L3648 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Delete_56
  SQL: SQL = "Delete from movimiento_cuenta where CHEQUE = '" & xabonos!numero & "' AND cod_oper = '" & Data3.Recordset!Cheque & "' and cod_cuenta like '*" & xabonos!cuenta & "'"
- L3648 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Delete_57
  SQL: Delete from movimiento_cuenta where CHEQUE = '
- L3651 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Admin_DISTRIBUCION_GASTO_Delete_58
  SQL: SQL = "Delete from distribucion_gasto where numero = '" & xabonos!numero & "' AND cuenta = '" & xabonos!cuenta & "'"
- L3651 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Admin_DISTRIBUCION_GASTO_Delete_59
  SQL: Delete from distribucion_gasto where numero = '
- L3659 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Delete_60
  SQL: SQL = "Delete from movimiento_cuenta where cod_oper = '" & Data3.Recordset!Documento & "' and cod_proveedor = '" & Data3.Recordset!codigo & "' and numrec = '" & Data3.Recordset!REC...
- L3659 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Delete_61
  SQL: Delete from movimiento_cuenta where cod_oper = '
- L3664 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Delete_62
  SQL: SQL = " delete from " & TablaOrigen & " where documento = '" & Data3.Recordset!Documento & "' and codigo = '" & Data3.Recordset!codigo & "' and numrec = '" & Data3.Recordset!RECNUM...
- L3672 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Update_63
  SQL: SQL = "update compras set fecha_pago = null, nro_comprobante = 0, ivaretenido = 0, ISRL = 0, MontoISRL = 0, RECNUM = 0, cancelada = 'N', cancelado = 0 where num_fact = '" & Data3.R...
- L3672 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Update_64
  SQL: update compras set fecha_pago = null, nro_comprobante = 0, ivaretenido = 0, ISRL = 0, MontoISRL = 0, RECNUM = 0, cancelada = 'N', cancelado = 0 where num_fact = '
- L3676 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_65
  SQL: SQL = "update " & TablaOrigen & " set pend = DEBE where documento = " & Data3.Recordset!Documento & " and tipo = 'FACT' and codigo = '" & Data3.Recordset!codigo & "'"
- L3679 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_66
  SQL: SQL = "update " & TablaOrigen & " set pend = DEBE where documento = '" & Data3.Recordset!Documento & "' and tipo = 'FACT' and codigo = '" & Data3.Recordset!codigo & "'"
- L3689 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Delete_67
  SQL: SQL = " delete from " & TablaOrigen & " where documento = '" & Data3.Recordset!Documento & "' and codigo = '" & Data3.Recordset!codigo & "' and HABER > 0"
- L3692 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Delete_68
  SQL: ' SQL = " delete from " & TablaOrigen & " where documento = '" & data3.Recordset!Documento & "' and codigo = '" & data3.Recordset!Codigo & "' and (tipo = 'PAGO' or tipo = 'NOTA' or...
- L3701 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Update_69
  SQL: SQL = "update facturas set cancelada = 'N' where num_fact = '" & Data3.Recordset!Documento & "' and codigo = '" & Data3.Recordset!codigo & "'"
- L3701 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Update_70
  SQL: update facturas set cancelada = 'N' where num_fact = '
- L3704 [UPDATE] objeto: COBRADOS
  SP sugerido: usp_DatQBox_Admin_COBRADOS_Update_71
  SQL: ' SQL = "update cobrados set cancelada = 'N' where num_fact = " & data3.Recordset!Documento & " and codigo = '" & data3.Recordset!codigo & "'"
- L3704 [UPDATE] objeto: COBRADOS
  SP sugerido: usp_DatQBox_Admin_COBRADOS_Update_72
  SQL: update cobrados set cancelada = 'N' where num_fact =
- L3705 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Admin_SQL_Exec_73
  SQL: ' DbConnection.Execute SQL
- L3723 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Delete_74
  SQL: SQL = " delete from " & tablas & " where documento = '" & Data3.Recordset!Documento & "' and codigo = '" & Data3.Recordset!codigo & "' and RECNUM = '" & RECNUM & "' "
- L3731 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Delete_75
  SQL: SQL = " delete from compras where NUM_FACT = '" & Data3.Recordset!nota & "' and COD_PROVEEDOR = '" & Data3.Recordset!codigo & "' and clase = 'NOTA CREDITO' "
- L3731 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Delete_76
  SQL: delete from compras where NUM_FACT = '
- L3778 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Get_77
  SQL: SQL = "Select * from compras where num_fact = '" & Data3.Recordset!Documento & "' and cod_proveedor = '" & DATA1.Recordset!codigo & "' "
- L3856 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Get_78
  SQL: 'SQL = "Select * from movimiento_cuenta where cod_oper = '" & data3.Recordset!Documento & "' and cod_proveedor = '" & data1.Recordset!Codigo & "' and retiva = 1 "
- L3856 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Admin_MOVIMIENTO_CUENTA_Get_79
  SQL: Select * from movimiento_cuenta where cod_oper = '
- L4065 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_80
  SQL: cr = "select * from " & tablas & " where recnum = " & Data3.Recordset!RECNUM & " and codigo = '" & Data3.Recordset!codigo & "' and anulado = 0 ORDER BY SALDO DESC"
- L4065 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_81
  SQL: select * from
- L4090 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_82
  SQL: cr = "select * from FACTURAS where NUM_FACT = '" & Data3.Recordset!Documento & "'"
- L4090 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_83
  SQL: select * from FACTURAS where NUM_FACT = '
- L4145 [SELECT] objeto: PAGOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_PAGOS_DETALLE_Get_84
  SQL: cr = "select * from PAGOS_DETALLE where recnum = " & Data3.Recordset!RECNUM & " AND codigo = '" & Data3.Recordset!codigo & "' "
- L4145 [SELECT] objeto: PAGOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_PAGOS_DETALLE_Get_85
  SQL: select * from PAGOS_DETALLE where recnum =
- L4296 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_86
  SQL: ''cr = "SElect sum(aplicado) as total from abonos where Codigo = '" & Codigo & "' and recnum = " & Numero & " "
- L4296 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_87
  SQL: SElect sum(aplicado) as total from abonos where Codigo = '
- L4389 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_88
  SQL: Data3.RecordSource = "Select * from abonos where Codigo = '" & DATA1.Recordset!codigo & "' and recnum = " & Data3.Recordset!RECNUM & ""
- L4389 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_89
  SQL: Select * from abonos where Codigo = '
- L4398 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Get_90
  SQL: cr = "select * from compras where NUM_FACT = '" & Data3.Recordset!Documento & "'"
- L4531 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Get_91
  SQL: SQL = " SELECT DOCUMENTO, CODIGO FROM P_PAGAR WHERE DOCUMENTO = '" & NumFind & "'"
- L4531 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Get_92
  SQL: SELECT DOCUMENTO, CODIGO FROM P_PAGAR WHERE DOCUMENTO = '
- L4534 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Get_93
  SQL: SQL = " SELECT DOCUMENTO, CODIGO FROM P_COBRARC WHERE DOCUMENTO = '" & NumFind & "'"
- L4534 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Get_94
  SQL: SELECT DOCUMENTO, CODIGO FROM P_COBRARC WHERE DOCUMENTO = '
- L4536 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Get_95
  SQL: SQL = " SELECT DOCUMENTO, CODIGO FROM P_COBRAR WHERE DOCUMENTO = '" & NumFind & "'"
- L4536 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Get_96
  SQL: SELECT DOCUMENTO, CODIGO FROM P_COBRAR WHERE DOCUMENTO = '
- L4581 [SELECT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Get_97
  SQL: SQL = "select * from detallepago where codigo = '" & DATA1.Recordset!codigo & "'"
- L4581 [SELECT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Get_98
  SQL: select * from detallepago where codigo = '
- L4621 [DELETE] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Delete_99
  SQL: DbConnection.Execute "Delete from AbonosPagos where codigo = '" & DATA1.Recordset!codigo & "'"
- L4621 [DELETE] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Delete_100
  SQL: Delete from AbonosPagos where codigo = '
- L4623 [INSERT] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Insert_101
  SQL: SQL = " INSERT INTO AbonosPagos"
- L4623 [INSERT] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Insert_102
  SQL: INSERT INTO AbonosPagos
- L4625 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_103
  SQL: SQL = SQL & " SELECT P_Pagar.Codigo, P_Pagar.FECHA, P_Pagar.DOCUMENTO, P_Pagar.PEND, P_Pagar.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, P_Pagar.PorcentajeDescuento,"
- L4625 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_104
  SQL: SELECT P_Pagar.Codigo, P_Pagar.FECHA, P_Pagar.DOCUMENTO, P_Pagar.PEND, P_Pagar.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, P_Pagar.PorcentajeDescuento,
- L4633 [SELECT] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Get_105
  SQL: Data4.RecordSource = "select Codigo, Num_Fact, Fecha,Monto, Aplicado,Retenido, Saldo, Descuento, Aceptada,Porcentaje as Alicuota, SujetoISRL as Monto_Gra, MontoIva as Iva, Exento, ...
- L4633 [SELECT] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Get_106
  SQL: select Codigo, Num_Fact, Fecha,Monto, Aplicado,Retenido, Saldo, Descuento, Aceptada,Porcentaje as Alicuota, SujetoISRL as Monto_Gra, MontoIva as Iva, Exento, Monto_retencion as Tot...
- L4637 [DELETE] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Delete_107
  SQL: DbConnection.Execute "Delete from AbonosPagosClientes where codigo = '" & DATA1.Recordset!codigo & "'"
- L4637 [DELETE] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Delete_108
  SQL: Delete from AbonosPagosClientes where codigo = '
- L4640 [INSERT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Insert_109
  SQL: SQL = " INSERT INTO AbonosPagosClientes "
- L4640 [INSERT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Insert_110
  SQL: INSERT INTO AbonosPagosClientes
- L4642 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_111
  SQL: SQL = SQL & " SELECT P_Cobrarc.CODIGO,P_Cobrarc.FECHA, P_Cobrarc.DOCUMENTO, P_Cobrarc.PEND, P_Cobrarc.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, "
- L4642 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_112
  SQL: SELECT P_Cobrarc.CODIGO,P_Cobrarc.FECHA, P_Cobrarc.DOCUMENTO, P_Cobrarc.PEND, P_Cobrarc.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4,
- L4649 [INSERT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Insert_113
  SQL: SQL = " INSERT INTO AbonosPagosClientes"
- L4651 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_114
  SQL: SQL = SQL & " SELECT P_Cobrar.CODIGO,P_Cobrar.FECHA, P_Cobrar.DOCUMENTO, P_Cobrar.PEND, P_Cobrar.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4, "
- L4651 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_115
  SQL: SELECT P_Cobrar.CODIGO,P_Cobrar.FECHA, P_Cobrar.DOCUMENTO, P_Cobrar.PEND, P_Cobrar.PEND AS Expr1, 0 AS Expr2, 0 AS Expr3, 0 AS Expr4,
- L4660 [SELECT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Get_116
  SQL: Data4.RecordSource = "select Codigo, Num_Fact, Fecha,Monto, Aplicado,Retenido, Saldo, Descuento, Aceptada,Porcentaje as Alicuota, SujetoISRL as Monto_Gra, MontoIva as Iva, Exento, ...
- L4660 [SELECT] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Get_117
  SQL: select Codigo, Num_Fact, Fecha,Monto, Aplicado,Retenido, Saldo, Descuento, Aceptada,Porcentaje as Alicuota, SujetoISRL as Monto_Gra, MontoIva as Iva, Exento, Monto_retencion as Tot...
- L4681 [DELETE] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Delete_118
  SQL: DbConnection.Execute "Delete from AbonosPagos where codigo '" & DATA1.Recordset!codigo & "'"
- L4681 [DELETE] objeto: ABONOSPAGOS
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOS_Delete_119
  SQL: Delete from AbonosPagos where codigo '
- L4683 [DELETE] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Delete_120
  SQL: DbConnection.Execute "Delete from AbonosPagosClientes where codigo '" & DATA1.Recordset!codigo & "'"
- L4683 [DELETE] objeto: ABONOSPAGOSCLIENTES
  SP sugerido: usp_DatQBox_Admin_ABONOSPAGOSCLIENTES_Delete_121
  SQL: Delete from AbonosPagosClientes where codigo '
- L4720 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_122
  SQL: SQL = "select * from Abonos where codigo = '" & pRecordset!codigo & "' ORDER BY ID,fecha,documento, TIPO"
- L4739 [SELECT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Admin_PAGOSC_Get_123
  SQL: SQL = "select * from Pagosc where codigo = '" & pRecordset!codigo & "' and documento = '" & pRecordset!Documento & "' ORDER BY ID, fecha,documento, TIPO"
- L4739 [SELECT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Admin_PAGOSC_Get_124
  SQL: select * from Pagosc where codigo = '
- L4742 [SELECT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Admin_PAGOS_Get_125
  SQL: SQL = "select * from Pagos where codigo = '" & pRecordset!codigo & "' and documento = '" & pRecordset!Documento & "' ORDER BY ID, fecha,documento, TIPO"
- L4742 [SELECT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Admin_PAGOS_Get_126
  SQL: select * from Pagos where codigo = '
- L5077 [UPDATE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Update_127
  SQL: DbConnection.Execute "UPDATE DETALLEPAGO SET HABER = " & haber & " WHERE NUM_FACT = '" & Data4.Recordset!num_fact & "' AND TIPO = 'PAGO'"
- L5077 [UPDATE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Update_128
  SQL: UPDATE DETALLEPAGO SET HABER =
- L5304 [INSERT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Insert_129
  SQL: SQL = " INSERT INTO detallepago (Tipo, Descripcion, Alicuota, Num_Fact, Fact_Afect, Debe, Haber, Codigo,tasa_ret, Sujeto_ret,Monto_Fact)"
- L5304 [INSERT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Insert_130
  SQL: INSERT INTO detallepago (Tipo, Descripcion, Alicuota, Num_Fact, Fact_Afect, Debe, Haber, Codigo,tasa_ret, Sujeto_ret,Monto_Fact)
- L5309 [INSERT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Insert_131
  SQL: SQL = " INSERT INTO detallepago (Tipo, Descripcion, Alicuota, Num_Fact, Fact_Afect, Debe, Haber, Codigo, tasa_ret,Sujeto_ret,Monto_fact)"
- L5309 [INSERT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Insert_132
  SQL: INSERT INTO detallepago (Tipo, Descripcion, Alicuota, Num_Fact, Fact_Afect, Debe, Haber, Codigo, tasa_ret,Sujeto_ret,Monto_fact)
- L5387 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_133
  SQL: TDBGrid6.Update
- L5417 [SELECT] objeto: BANCOS
  SP sugerido: usp_DatQBox_Admin_BANCOS_Get_134
  SQL: SQL = " Select nombre from bancos"
- L5417 [SELECT] objeto: BANCOS
  SP sugerido: usp_DatQBox_Admin_BANCOS_Get_135
  SQL: Select nombre from bancos
- L5430 [SELECT] objeto: CUENTASBANK
  SP sugerido: usp_DatQBox_Admin_CUENTASBANK_Get_136
  SQL: SQL = " Select Nro_Cta, Descripcion, Banco from CuentasBank"
- L5430 [SELECT] objeto: CUENTASBANK
  SP sugerido: usp_DatQBox_Admin_CUENTASBANK_Get_137
  SQL: Select Nro_Cta, Descripcion, Banco from CuentasBank
- L5515 [INSERT] objeto: ABONOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_ABONOS_DETALLE_Insert_138
  SQL: SQL = " INSERT INTO Abonos_Detalle"
- L5515 [INSERT] objeto: ABONOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_ABONOS_DETALLE_Insert_139
  SQL: INSERT INTO Abonos_Detalle
- L5522 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_Admin_DETALLE_DEPOSITO_Delete_140
  SQL: SQL = "DELETE FROM DETALLE_DEPOSITO WHERE CHEQUE = '" & TDataLite1.Recordset!numero & "';"
- L5522 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_Admin_DETALLE_DEPOSITO_Delete_141
  SQL: DELETE FROM DETALLE_DEPOSITO WHERE CHEQUE = '
- L5525 [INSERT] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_Admin_DETALLE_DEPOSITO_Insert_142
  SQL: SQL = "INSERT INTO DETALLE_DEPOSITO "
- L5525 [INSERT] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_Admin_DETALLE_DEPOSITO_Insert_143
  SQL: INSERT INTO DETALLE_DEPOSITO
- L5534 [INSERT] objeto: PAGOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_PAGOS_DETALLE_Insert_144
  SQL: SQL = " INSERT INTO Pagos_Detalle"
- L5534 [INSERT] objeto: PAGOS_DETALLE
  SP sugerido: usp_DatQBox_Admin_PAGOS_DETALLE_Insert_145
  SQL: INSERT INTO Pagos_Detalle
- L5574 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Get_146
  SQL: cr = "Select * from MovCuentas where nro_cta = '" & cuenta & "' and nro_ref = '" & numero & "' "
- L5574 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Get_147
  SQL: Select * from MovCuentas where nro_cta = '
- L5609 [SELECT] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Admin_DETALLE_CHEQUE_Get_148
  SQL: cr = "Select * from detalle_cheque where nro_cta = '" & cuenta & "' and nro_trans = '" & numero & "' "
- L5609 [SELECT] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Admin_DETALLE_CHEQUE_Get_149
  SQL: Select * from detalle_cheque where nro_cta = '
- L5637 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_150
  SQL: SQL = " SELECT Tipo, Tipo + '/' + Num_Comp AS Tipos, Descripcion + ' a Fact. No.: ' + Num_Fact AS Concepto, Num_Comp, SUM(Haber) AS Monto, Codigo, Id, NUM_FACT, Monto_Fact"
- L5637 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_151
  SQL: SELECT Tipo, Tipo + '/' + Num_Comp AS Tipos, Descripcion + ' a Fact. No.: ' + Num_Fact AS Concepto, Num_Comp, SUM(Haber) AS Monto, Codigo, Id, NUM_FACT, Monto_Fact
- L5646 [SELECT] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Admin_DISTRIBUCION_GASTO_Get_152
  SQL: cr = "Select * from Distribucion_gasto where cuenta = '" & cuenta & "' and numero = '" & numero & "' "
- L5646 [SELECT] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Admin_DISTRIBUCION_GASTO_Get_153
  SQL: Select * from Distribucion_gasto where cuenta = '
- L5714 [INSERT] objeto: [DISTRIBUCION_GASTO]
  SP sugerido: usp_DatQBox_Admin_DISTRIBUCION_GASTO_Insert_154
  SQL: SQL = " INSERT INTO [Distribucion_gasto]"
- L5714 [INSERT] objeto: [DISTRIBUCION_GASTO]
  SP sugerido: usp_DatQBox_Admin_DISTRIBUCION_GASTO_Insert_155
  SQL: INSERT INTO [Distribucion_gasto]
- L5722 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_156
  SQL: SQL = SQL & " SELECT '" & cuenta & "', "
- L5730 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Admin_SQL_Exec_157
  SQL: DbConnectionAux.Execute SQL
- L5951 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Get_158
  SQL: 'cr = " Select " & vCampo_Uno & "+" & "' '+" & vCampo_Dos & "+" & "' '+" & vCampo_Tres & "+" & "' '+" & vCampo_Cuatro & "+" & "' '+" & vCampo_Cinco & " as Descripciones,descripcion...
- L5954 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Admin_PROVEEDORES_Get_159
  SQL: ''cr = "Select Codigo,Nombre, RIF, Saldo_30, Saldo_60, Saldo_90, Saldo_91, Saldo_Tot,Direccion,Estado, Ciudad,Cpostal, Telefono, Email, Pagina_WWW, Ult_Pago From Proveedores order ...
- L5954 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Admin_PROVEEDORES_Get_160
  SQL: Select Codigo,Nombre, RIF, Saldo_30, Saldo_60, Saldo_90, Saldo_91, Saldo_Tot,Direccion,Estado, Ciudad,Cpostal, Telefono, Email, Pagina_WWW, Ult_Pago From Proveedores order by NOMBR...
- L5958 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_161
  SQL: cr = " SELECT Clientes.CODIGO, Clientes.upsize_ts, Clientes.Status, Clientes.UltimaFechaCompra, Clientes.Creditos, Clientes.Saldo_prepago,"
- L5958 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_162
  SQL: SELECT Clientes.CODIGO, Clientes.upsize_ts, Clientes.Status, Clientes.UltimaFechaCompra, Clientes.Creditos, Clientes.Saldo_prepago,
- L6016 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_163
  SQL: cr = " SELECT Proveedores.CODIGO, Proveedores.NOMBRE, Proveedores.RIF, Proveedores.NIT, Proveedores.DIRECCION, "
- L6016 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_164
  SQL: SELECT Proveedores.CODIGO, Proveedores.NOMBRE, Proveedores.RIF, Proveedores.NIT, Proveedores.DIRECCION,
- L6055 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Get_165
  SQL: cr = "SELECT * FROM CLIENTES "
- L6055 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Get_166
  SQL: SELECT * FROM CLIENTES
- L6057 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Admin_PROVEEDORES_Get_167
  SQL: cr = " SELECT * FROM PROVEEDORES"
- L6057 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Admin_PROVEEDORES_Get_168
  SQL: SELECT * FROM PROVEEDORES
- L6068 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Get_169
  SQL: SQL = "select * from P_Pagar ORDER BY fecha,documento, TIPO"
- L6068 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Get_170
  SQL: select * from P_Pagar ORDER BY fecha,documento, TIPO
- L6075 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Get_171
  SQL: SQL = "select * from P_Cobrarc ORDER BY fecha,documento, TIPO"
- L6075 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Get_172
  SQL: select * from P_Cobrarc ORDER BY fecha,documento, TIPO
- L6077 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Get_173
  SQL: SQL = "select * from P_Cobrar ORDER BY fecha,documento, TIPO"
- L6077 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Get_174
  SQL: select * from P_Cobrar ORDER BY fecha,documento, TIPO
- L6103 [DELETE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Delete_175
  SQL: 'SQL = " delete from detallepago "
- L6103 [DELETE] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Delete_176
  SQL: delete from detallepago
- L6104 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Admin_SQL_Exec_177
  SQL: 'DbConnection.Execute SQL
- L6115 [SELECT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Get_178
  SQL: ' SQL = "select * from detallepago "
- L6115 [SELECT] objeto: DETALLEPAGO
  SP sugerido: usp_DatQBox_Admin_DETALLEPAGO_Get_179
  SQL: select * from detallepago
- L6120 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Get_180
  SQL: ' SQL = "select * from P_Pagar where codigo = '" & DATA1.Recordset!Codigo & "' ORDER BY fecha,documento, TIPO"
- L6120 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Admin_P_PAGAR_Get_181
  SQL: select * from P_Pagar where codigo = '
- L6121 [SELECT] objeto: RETENCIONES
  SP sugerido: usp_DatQBox_Admin_RETENCIONES_Get_182
  SQL: SQL = "select Codigo, Descripcion, Porcentaje,MontoMimimo,Sustraendo from retenciones order by codigo "
- L6121 [SELECT] objeto: RETENCIONES
  SP sugerido: usp_DatQBox_Admin_RETENCIONES_Get_183
  SQL: select Codigo, Descripcion, Porcentaje,MontoMimimo,Sustraendo from retenciones order by codigo
- L6132 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_184
  SQL: SQL = "select * from Abonos ORDER BY fecha,documento, TIPO"
- L6132 [SELECT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Admin_ABONOS_Get_185
  SQL: select * from Abonos ORDER BY fecha,documento, TIPO
- L6135 [SELECT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Admin_PAGOSC_Get_186
  SQL: SQL = "select * from Pagosc ORDER BY fecha,documento, TIPO"
- L6135 [SELECT] objeto: PAGOSC
  SP sugerido: usp_DatQBox_Admin_PAGOSC_Get_187
  SQL: select * from Pagosc ORDER BY fecha,documento, TIPO
- L6137 [SELECT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Admin_PAGOS_Get_188
  SQL: SQL = "select * from Pagos ORDER BY fecha,documento, TIPO"
- L6137 [SELECT] objeto: PAGOS
  SP sugerido: usp_DatQBox_Admin_PAGOS_Get_189
  SQL: select * from Pagos ORDER BY fecha,documento, TIPO

### DatQBox PtoVenta\Global.bas
- L514 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_PtoVenta_MOVCUENTAS_Get_1
  SQL: cr = "Select * from movcuentas where nro_ref = '" & Trim(Cheque) & "' and nro_cta = '" & Trim(Cuenta) & "'"
- L514 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_PtoVenta_MOVCUENTAS_Get_2
  SQL: Select * from movcuentas where nro_ref = '
- L570 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_3
  SQL: Select Case UCase(crParamDef.ParameterFieldName)
- L653 [SELECT] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Get_4
  SQL: cr = "Select * from Correlativo where Correlativo.Tipo = '" & tipo & "'"
- L653 [SELECT] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Get_5
  SQL: Select * from Correlativo where Correlativo.Tipo = '
- L665 [INSERT] objeto: [DBO].[CORRELATIVO]
  SP sugerido: usp_DatQBox_PtoVenta_DBO_CORRELATIVO_Insert_6
  SQL: cr = " INSERT INTO [dbo].[Correlativo]"
- L665 [INSERT] objeto: [DBO].[CORRELATIVO]
  SP sugerido: usp_DatQBox_PtoVenta_DBO_CORRELATIVO_Insert_7
  SQL: INSERT INTO [dbo].[Correlativo]
- L671 [EXEC] objeto: CR
  SP sugerido: usp_DatQBox_PtoVenta_CR_Exec_8
  SQL: DbConnection.Execute cr
- L677 [UPDATE] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Update_9
  SQL: cr = "Update Correlativo Set Correlativo.valor = Correlativo.Valor + 1 where Correlativo.tipo = '" & tipo & "'"
- L677 [UPDATE] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Update_10
  SQL: Update Correlativo Set Correlativo.valor = Correlativo.Valor + 1 where Correlativo.tipo = '
- L835 [SELECT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Get_11
  SQL: ''cr = " Select * from Detalle_Facturas where fecha >= '" & fecha & "' and fecha <= '" & Fecha1 & "' AND (DESCRIPCION LIKE '%ALINEACION%' OR DESCRIPCION LIKE '%TRICA%' OR DESCRIPCI...
- L835 [SELECT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Get_12
  SQL: Select * from Detalle_Facturas where fecha >= '
- L837 [UPDATE] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Update_13
  SQL: '' SQL = "Update detalle_facturas set relacionada = 0 where fecha >= '" & fecha & "' and fecha <= '" & Fecha1 & "' AND (DESCRIPCION LIKE '%ALINEACION%' OR DESCRIPCION LIKE '%TRICA%...
- L837 [UPDATE] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Update_14
  SQL: Update detalle_facturas set relacionada = 0 where fecha >= '
- L840 [SELECT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Get_15
  SQL: cr = " Select * from Detalle_Facturas where fecha >= '" & FECHA & "' and fecha <= '" & Fecha1 & "' AND (DESCRIPCION LIKE '%ALINEACION%' ) and anulada = 0 and relacionada = 0 order ...
- L842 [UPDATE] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Update_16
  SQL: SQL = "Update detalle_facturas set relacionada = 0 where fecha >= '" & FECHA & "' and fecha <= '" & Fecha1 & "' AND (DESCRIPCION LIKE '%ALINEACION%')"
- L845 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_PtoVenta_SQL_Exec_17
  SQL: DbConnection.Execute SQL
- L890 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_18
  SQL: ' Facturas.Update
- L894 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_19
  SQL: 'cr = " Select * from Facturas where num_fact >= '" & facturas!num_fact & "' "
- L894 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_20
  SQL: Select * from Facturas where num_fact >= '
- L980 [SELECT] objeto: DETALLE_COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_COTIZACION_Get_21
  SQL: ''cr = " Select * from Detalle_Cotizacion where fecha >= '" & fecha & "' and fecha <= '" & Fecha1 & "' AND (DESCRIPCION LIKE '%ALINEACION%' OR DESCRIPCION LIKE '%TRICA%' OR DESCRIP...
- L980 [SELECT] objeto: DETALLE_COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_COTIZACION_Get_22
  SQL: Select * from Detalle_Cotizacion where fecha >= '
- L982 [UPDATE] objeto: DETALLE_COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_COTIZACION_Update_23
  SQL: ''SQL = "Update detalle_Cotizacion set relacionada = 0 where fecha >= '" & fecha & "' and fecha <= '" & Fecha1 & "' AND (DESCRIPCION LIKE '%ALINEACION%' OR DESCRIPCION LIKE '%TRICA...
- L982 [UPDATE] objeto: DETALLE_COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_COTIZACION_Update_24
  SQL: Update detalle_Cotizacion set relacionada = 0 where fecha >= '
- L984 [SELECT] objeto: DETALLE_COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_COTIZACION_Get_25
  SQL: cr = " Select * from Detalle_Cotizacion where fecha >= '" & FECHA & "' and fecha <= '" & Fecha1 & "' AND (DESCRIPCION LIKE '%ALINEACION%' ) order by num_fact"
- L986 [UPDATE] objeto: DETALLE_COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_COTIZACION_Update_26
  SQL: SQL = "Update detalle_Cotizacion set relacionada = 0 where fecha >= '" & FECHA & "' and fecha <= '" & Fecha1 & "' AND (DESCRIPCION LIKE '%ALINEACION%' )"
- L1037 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_27
  SQL: ' cr = " Select * from cotizacion where num_fact >= '" & facturas!num_fact & "' "
- L1037 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_28
  SQL: Select * from cotizacion where num_fact >= '
- L1122 [SELECT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Get_29
  SQL: 'cr = " Select * from Detalle_Facturas where fecha >= " & Fecha & " and fecha <= " & Fecha1 & " AND (DESCRIPCION LIKE '*ALINEACION*' OR DESCRIPCION LIKE '*TRICA*' OR DESCRIPCION LI...
- L1122 [SELECT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Get_30
  SQL: Select * from Detalle_Facturas where fecha >=
- L1123 [SELECT] objeto: DETALLE_NOTA
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_NOTA_Get_31
  SQL: ''cr = " Select * from Detalle_nota where fecha >= '" & fecha & "' and fecha <= '" & Fecha1 & "' AND (DESCRIPCION LIKE '*ALINEACION*' OR DESCRIPCION LIKE '*TRICA*' OR DESCRIPCION L...
- L1123 [SELECT] objeto: DETALLE_NOTA
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_NOTA_Get_32
  SQL: Select * from Detalle_nota where fecha >= '
- L1124 [UPDATE] objeto: DETALLE_NOTA
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_NOTA_Update_33
  SQL: ''SQL = "Update detalle_nota set relacionada = 0 where fecha >= '" & fecha & "' and fecha <= '" & Fecha1 & "' AND (DESCRIPCION LIKE '*ALINEACION*' OR DESCRIPCION LIKE '*TRICA*' OR ...
- L1124 [UPDATE] objeto: DETALLE_NOTA
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_NOTA_Update_34
  SQL: Update detalle_nota set relacionada = 0 where fecha >= '
- L1126 [SELECT] objeto: DETALLE_NOTA
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_NOTA_Get_35
  SQL: cr = " Select * from Detalle_nota where fecha >= '" & FECHA & "' and fecha <= '" & Fecha1 & "' AND (DESCRIPCION LIKE '*ALINEACION*' ) and anulada = 0 and relacionada = 0 order by n...
- L1127 [UPDATE] objeto: DETALLE_NOTA
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_NOTA_Update_36
  SQL: SQL = "Update detalle_nota set relacionada = 0 where fecha >= '" & FECHA & "' and fecha <= '" & Fecha1 & "' AND (DESCRIPCION LIKE '*ALINEACION*' )"
- L1173 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_37
  SQL: 'facturas.Update
- L1174 [SELECT] objeto: NOTA
  SP sugerido: usp_DatQBox_PtoVenta_NOTA_Get_38
  SQL: 'cr = " Select * from nota where num_fact >= '" & facturas!num_fact & "' "
- L1174 [SELECT] objeto: NOTA
  SP sugerido: usp_DatQBox_PtoVenta_NOTA_Get_39
  SQL: Select * from nota where num_fact >= '
- L1304 [SELECT] objeto: MODULOS
  SP sugerido: usp_DatQBox_PtoVenta_MODULOS_Get_40
  SQL: SQL = "select * from Modulos where Modulo = '" & Modulo & "' "
- L1304 [SELECT] objeto: MODULOS
  SP sugerido: usp_DatQBox_PtoVenta_MODULOS_Get_41
  SQL: select * from Modulos where Modulo = '
- L1310 [INSERT] objeto: MODULOS
  SP sugerido: usp_DatQBox_PtoVenta_MODULOS_Insert_42
  SQL: SQL = " INSERT INTO Modulos ( Modulo, Nivel )"
- L1310 [INSERT] objeto: MODULOS
  SP sugerido: usp_DatQBox_PtoVenta_MODULOS_Insert_43
  SQL: INSERT INTO Modulos ( Modulo, Nivel )
- L1320 [SELECT] objeto: ACCESOUSUARIOS
  SP sugerido: usp_DatQBox_PtoVenta_ACCESOUSUARIOS_Get_44
  SQL: SQL = "select * from AccesoUsuarios where Modulo = '" & Modulo & "' and Cod_Usuario = '" & COD_USUARIO & "'"
- L1320 [SELECT] objeto: ACCESOUSUARIOS
  SP sugerido: usp_DatQBox_PtoVenta_ACCESOUSUARIOS_Get_45
  SQL: select * from AccesoUsuarios where Modulo = '
- L1327 [INSERT] objeto: ACCESOUSUARIOS
  SP sugerido: usp_DatQBox_PtoVenta_ACCESOUSUARIOS_Insert_46
  SQL: SQL = " INSERT INTO AccesoUsuarios ( cod_usuario,Modulo, Permitido )"
- L1327 [INSERT] objeto: ACCESOUSUARIOS
  SP sugerido: usp_DatQBox_PtoVenta_ACCESOUSUARIOS_Insert_47
  SQL: INSERT INTO AccesoUsuarios ( cod_usuario,Modulo, Permitido )
- L1518 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_PtoVenta_TASA_MONEDA_Get_48
  SQL: c = "SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_compra, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE "
- L1518 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_PtoVenta_TASA_MONEDA_Get_49
  SQL: SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_compra, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE
- L1586 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_50
  SQL: cr = " Select * from Cotizacion where fecha = '" & FECHA & "' order by num_fact"
- L1586 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_51
  SQL: Select * from Cotizacion where fecha = '
- L1588 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_52
  SQL: cr = " Select * from Cotizacion where COD_USUARIO = '" & COD_USUARIO & "' AND fecha = '" & FECHA & "' order by num_fact"
- L1588 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_53
  SQL: Select * from Cotizacion where COD_USUARIO = '
- L1777 [SELECT] objeto: GASTOS_CAJA
  SP sugerido: usp_DatQBox_PtoVenta_GASTOS_CAJA_Get_54
  SQL: cr = " Select * from gastos_Caja where fecha = '" & FECHA & "' order by num_fact"
- L1777 [SELECT] objeto: GASTOS_CAJA
  SP sugerido: usp_DatQBox_PtoVenta_GASTOS_CAJA_Get_55
  SQL: Select * from gastos_Caja where fecha = '
- L1880 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_56
  SQL: cr = " SELECT * "
- L2332 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_57
  SQL: cr = " Select REPLICATE('0', 4 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total from FACTURAS where fecha = '" & FECHA & ...
- L2332 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_58
  SQL: Select REPLICATE('0', 4 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total from FACTURAS where fecha = '
- L2334 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_59
  SQL: cr = " Select REPLICATE('0', 4 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total from FACTURAS where COD_USUARIO = '" & CO...
- L2334 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_60
  SQL: Select REPLICATE('0', 4 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total from FACTURAS where COD_USUARIO = '
- L2438 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_61
  SQL: cr = " Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total from FACTURAS where fecha = '" & FECHA & ...
- L2438 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_62
  SQL: Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total from FACTURAS where fecha = '
- L2440 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_63
  SQL: cr = " Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total from FACTURAS where COD_USUARIO = '" & CO...
- L2440 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_64
  SQL: Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total from FACTURAS where COD_USUARIO = '
- L2547 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_65
  SQL: cr = " Select * from NOTACREDITO where fecha = '" & FECHA & "' order by num_fact"
- L2547 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_66
  SQL: Select * from NOTACREDITO where fecha = '
- L2549 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_67
  SQL: cr = " Select * from NOTACREDITO where COD_USUARIO = '" & COD_USUARIO & "' AND fecha = '" & FECHA & "' order by num_fact"
- L2549 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_68
  SQL: Select * from NOTACREDITO where COD_USUARIO = '
- L2649 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_69
  SQL: cr = " Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, MONTO_GRABS from FACTURAS where fecha = ...
- L2649 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_70
  SQL: Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, MONTO_GRABS from FACTURAS where fecha = '
- L2651 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_71
  SQL: cr = " Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, MONTO_GRABS from FACTURAS where COD_USUA...
- L2651 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_72
  SQL: Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, MONTO_GRABS from FACTURAS where COD_USUARIO = '
- L2754 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_73
  SQL: cr = " Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, MONTO_GRABS from NOTACREDITO where fecha...
- L2754 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_74
  SQL: Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, MONTO_GRABS from NOTACREDITO where fecha = '
- L2756 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_75
  SQL: cr = " Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, MONTO_GRABS from NOTACREDITO where COD_U...
- L2756 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_76
  SQL: Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, MONTO_GRABS from NOTACREDITO where COD_USUARIO ...
- L2858 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_77
  SQL: cr = " Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, MONTO_GRABS from FACTURAS where fecha = ...
- L2860 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_78
  SQL: cr = " Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, MONTO_GRABS from FACTURAS where COD_USUA...
- L3023 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_79
  SQL: SQL = " SELECT Detalle_FormaPagoFacturas.Tipo, SUM(Detalle_FormaPagoFacturas.Monto) AS TotalPagado " & _
- L3023 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_80
  SQL: SELECT Detalle_FormaPagoFacturas.Tipo, SUM(Detalle_FormaPagoFacturas.Monto) AS TotalPagado
- L3090 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_81
  SQL: 'cr = " SELECT pagosC.DOCUMENTO as Num_fact, Pagos_Detalle.TIPO as Pago, Pagos_Detalle.FECHA, Pagosc.Aplicado as Total, Clientes.NOMBRE"
- L3090 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_82
  SQL: SELECT pagosC.DOCUMENTO as Num_fact, Pagos_Detalle.TIPO as Pago, Pagos_Detalle.FECHA, Pagosc.Aplicado as Total, Clientes.NOMBRE
- L3212 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_83
  SQL: cr = " Select * from facturas where Pago = 'Credito' and Locacion = 'Compañia' and fecha = '" & FECHA & "' order by num_fact"
- L3212 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_84
  SQL: Select * from facturas where Pago = 'Credito' and Locacion = 'Compañia' and fecha = '
- L3214 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_85
  SQL: cr = " Select * from facturas where COD_USUARIO = '" & COD_USUARIO & "' AND Pago = 'Credito' and Locacion = 'Compañia' and fecha = '" & FECHA & "' order by num_fact"
- L3214 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_86
  SQL: Select * from facturas where COD_USUARIO = '
- L3311 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_87
  SQL: cr = " Select * from facturas where Pago = 'Credito' and Locacion = 'Particular' and fecha = '" & FECHA & "' order by num_fact"
- L3311 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_88
  SQL: Select * from facturas where Pago = 'Credito' and Locacion = 'Particular' and fecha = '
- L3313 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_89
  SQL: cr = " Select * from facturas where COD_USUARIO = '" & COD_USUARIO & "' AND Pago = 'Credito' and Locacion = 'Particular' and fecha = '" & FECHA & "' order by num_fact"
- L3424 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_90
  SQL: cr = cr & "SELECT DISTINCT Num_fact, Pago, FECHA, Total, NOMBRE, Fecha_Factura, Numero_Factura, Monto_Total "
- L3424 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_91
  SQL: SELECT DISTINCT Num_fact, Pago, FECHA, Total, NOMBRE, Fecha_Factura, Numero_Factura, Monto_Total
- L3427 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_92
  SQL: cr = cr & "SELECT pd.RECNUM AS Num_fact, pd.TIPO AS Pago, pd.FECHA, pd.MONTO AS Total, "
- L3427 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_93
  SQL: SELECT pd.RECNUM AS Num_fact, pd.TIPO AS Pago, pd.FECHA, pd.MONTO AS Total,
- L3439 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_94
  SQL: cr = cr & "SELECT pcd.RECNUM AS Num_fact, pcd.TIPO AS Pago, pcd.FECHA, pcd.MONTO AS Total, "
- L3439 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_95
  SQL: SELECT pcd.RECNUM AS Num_fact, pcd.TIPO AS Pago, pcd.FECHA, pcd.MONTO AS Total,
- L3570 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_96
  SQL: Select Case facturas!pago
- L3629 [SELECT] objeto: GASTOS
  SP sugerido: usp_DatQBox_PtoVenta_GASTOS_Get_97
  SQL: cr = " Select * from gastos where fecha = '" & FECHA & "' order by num_fact"
- L3629 [SELECT] objeto: GASTOS
  SP sugerido: usp_DatQBox_PtoVenta_GASTOS_Get_98
  SQL: Select * from gastos where fecha = '
- L3730 [SELECT] objeto: EGRESODEVOLUCION
  SP sugerido: usp_DatQBox_PtoVenta_EGRESODEVOLUCION_Get_99
  SQL: cr = " Select * from EgresoDevolucion where fecha = '" & FECHA & "' order by num_fact"
- L3730 [SELECT] objeto: EGRESODEVOLUCION
  SP sugerido: usp_DatQBox_PtoVenta_EGRESODEVOLUCION_Get_100
  SQL: Select * from EgresoDevolucion where fecha = '
- L4027 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_101
  SQL: SQL = " SELECT Sum(Facturas.TOTAL) AS SumaDeTOTAL"
- L4027 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_102
  SQL: SELECT Sum(Facturas.TOTAL) AS SumaDeTOTAL
- L7023 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_103
  SQL: cr = " Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, Alicuota from FACTURAS where ALICUOTA = ...
- L7023 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_104
  SQL: Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, Alicuota from FACTURAS where ALICUOTA = 12 AND ...
- L7132 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_105
  SQL: cr = " Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, Alicuota from FACTURAS where ALICUOTA = ...
- L7132 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_106
  SQL: Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, Alicuota from FACTURAS where ALICUOTA = 9 AND f...
- L7240 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_107
  SQL: cr = " Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, Alicuota from FACTURAS where ALICUOTA = ...
- L7240 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_108
  SQL: Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, Alicuota from FACTURAS where ALICUOTA = 7 AND f...
- L7363 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_109
  SQL: cr = " Select * from NOTACREDITO where ALICUOTA = 12 AND fecha = '" & FECHA & "' order by num_fact"
- L7363 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_110
  SQL: Select * from NOTACREDITO where ALICUOTA = 12 AND fecha = '
- L7463 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_111
  SQL: cr = " Select * from NOTACREDITO where alicuota = 9 and fecha = '" & FECHA & "' order by num_fact"
- L7463 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_112
  SQL: Select * from NOTACREDITO where alicuota = 9 and fecha = '
- L7563 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_113
  SQL: cr = " Select * from NOTACREDITO where ALICUOTA = 7 AND fecha = '" & FECHA & "' order by num_fact"
- L7563 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_114
  SQL: Select * from NOTACREDITO where ALICUOTA = 7 AND fecha = '
- L8080 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_115
  SQL: cr = " SELECT Pagos_Detalle.RECNUM as Num_fact, Pagos_Detalle.TIPO as Pago, Pagos_Detalle.FECHA, Pagos_Detalle.MONTO as Total, Clientes.NOMBRE"
- L8080 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_116
  SQL: SELECT Pagos_Detalle.RECNUM as Num_fact, Pagos_Detalle.TIPO as Pago, Pagos_Detalle.FECHA, Pagos_Detalle.MONTO as Total, Clientes.NOMBRE
- L9276 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_117
  SQL: cr = " Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, Alicuota from FACTURAS where ALICUOTA = ...
- L9276 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_118
  SQL: Select REPLICATE('0', 6 - DATALENGTH(Num_fact)) + Num_fact as Num_factura, Num_fact , Fecha,fechaanulada,anulada, SerialTipo, Total, Alicuota from FACTURAS where ALICUOTA = 10 AND ...
- L9506 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_119
  SQL: cr = " Select * from NOTACREDITO where alicuota = 10 and fecha = '" & FECHA & "' order by num_fact"
- L9506 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_120
  SQL: Select * from NOTACREDITO where alicuota = 10 and fecha = '
- L11083 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_121
  SQL: Select Case Month(FECHA)
- L11184 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_122
  SQL: cr = " SELECT COTIZACION.FECHAANULADA, COTIZACION.CANCELADA, COTIZACION.Fecha,COTIZACION.aLICUOTA, Detalle_FormaPagoCOTIZACION.Num_fact, Detalle_FormaPagoCOTIZACION.Tipo, Detalle_F...
- L11184 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_123
  SQL: SELECT COTIZACION.FECHAANULADA, COTIZACION.CANCELADA, COTIZACION.Fecha,COTIZACION.aLICUOTA, Detalle_FormaPagoCOTIZACION.Num_fact, Detalle_FormaPagoCOTIZACION.Tipo, Detalle_FormaPag...
- L11433 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_124
  SQL: cr = " SELECT Facturas.FECHAANULADA, FACTURAS.CANCELADA, FACTURAS.Fecha,fACTURAS.aLICUOTA, Detalle_FormaPagoFacturas.Num_fact, Detalle_FormaPagoFacturas.Tipo, Detalle_FormaPagoFact...
- L11433 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_125
  SQL: SELECT Facturas.FECHAANULADA, FACTURAS.CANCELADA, FACTURAS.Fecha,fACTURAS.aLICUOTA, Detalle_FormaPagoFacturas.Num_fact, Detalle_FormaPagoFacturas.Tipo, Detalle_FormaPagoFacturas.Fe...
- L11857 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_126
  SQL: Obj_Email.Configuration.Fields.Update

### DatQBox PtoVenta\frmControls.frm
- L1971 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_1
  SQL: Select Case UCase(crParamDef.ParameterFieldName)
- L2034 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_2
  SQL: SQL = " SELECT Facturas.FECHA, Facturas.CODIGO, Facturas.NUM_FACT, Facturas.NOMBRE, Detalle_facturas.CANTIDAD, Detalle_facturas.PRECIO, Facturas.RIF"
- L2034 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_3
  SQL: SELECT Facturas.FECHA, Facturas.CODIGO, Facturas.NUM_FACT, Facturas.NOMBRE, Detalle_facturas.CANTIDAD, Detalle_facturas.PRECIO, Facturas.RIF
- L2109 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_4
  SQL: SQL = "SELECT * FROM INVENTARIO WHERE categoria ='xxxxxxxACEITE' and CODIGO = '" & xArrrayCodigo(i) & "'"
- L2109 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_5
  SQL: SELECT * FROM INVENTARIO WHERE categoria ='xxxxxxxACEITE' and CODIGO = '
- L2213 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_6
  SQL: SQL = "SELECT * FROM INVENTARIO WHERE categoria ='POLLO' and CODIGO = '" & xArrrayCodigo(i) & "'"
- L2213 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_7
  SQL: SELECT * FROM INVENTARIO WHERE categoria ='POLLO' and CODIGO = '
- L2318 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_8
  SQL: SQL = "SELECT * FROM INVENTARIO WHERE Eliminado = 0 and CODIGO = '" & xArrrayCodigo(i) & "'"
- L2318 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_9
  SQL: SELECT * FROM INVENTARIO WHERE Eliminado = 0 and CODIGO = '
- L2430 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Get_10
  SQL: SQL = "SELECT SUM(EXISTENCIA_ACTUAL) AS EXISTENCIA, CODIGO, ALMACEN FROM DETALLE_INVENTARIO WHERE CODIGO = '" & xArrrayCodigo(i) & "' AND ALMACEN = '" & vAlmacen & "' GROUP BY CODI...
- L2430 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Get_11
  SQL: SELECT SUM(EXISTENCIA_ACTUAL) AS EXISTENCIA, CODIGO, ALMACEN FROM DETALLE_INVENTARIO WHERE CODIGO = '
- L2479 [DELETE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Delete_12
  SQL: SQL = "DELETE from P_cobrar where codigo = '" & CODIGOS & "' and documento = '" & NUM_FACT & "' "
- L2479 [DELETE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Delete_13
  SQL: DELETE from P_cobrar where codigo = '
- L2480 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_PtoVenta_SQL_Exec_14
  SQL: DbConnection.Execute SQL
- L2488 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_15
  SQL: SQL = "UPDATE CLIENTES SET saldo_relacionar = saldo_relacionar - " & Format(total, "########0.00") & ""
- L2488 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_16
  SQL: UPDATE CLIENTES SET saldo_relacionar = saldo_relacionar -
- L2504 [DELETE] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Delete_17
  SQL: SQL = "DELETE from P_cobrarc where codigo = '" & CODIGOS & "' and documento = '" & NUM_FACT & "' "
- L2504 [DELETE] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Delete_18
  SQL: DELETE from P_cobrarc where codigo = '
- L2542 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_19
  SQL: SQL = "select * from " & PrinTabla & " where num_fact = '" & Factur & "' and serialtipo = '" & vSerieFact & "' and TIPO_ORDEN = '" & vMemoria & "'"
- L2542 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_20
  SQL: select * from
- L2598 [SELECT] objeto: VENDEDOR
  SP sugerido: usp_DatQBox_PtoVenta_VENDEDOR_Get_21
  SQL: SQL = "Select * from Vendedor order by CODIGO"
- L2598 [SELECT] objeto: VENDEDOR
  SP sugerido: usp_DatQBox_PtoVenta_VENDEDOR_Get_22
  SQL: Select * from Vendedor order by CODIGO
- L2973 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_PtoVenta_TASA_MONEDA_Get_23
  SQL: c = "SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_compra, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE "
- L2973 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_PtoVenta_TASA_MONEDA_Get_24
  SQL: SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_compra, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE
- L3132 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_PtoVenta_PROVEEDORES_Get_25
  SQL: SQL = "Select * from Proveedores where Rif = '" & cliente.Text & "'"
- L3132 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_PtoVenta_PROVEEDORES_Get_26
  SQL: Select * from Proveedores where Rif = '
- L3134 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Get_27
  SQL: SQL = "Select * from clientes where Rif = '" & cliente.Text & "'"
- L3134 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Get_28
  SQL: Select * from clientes where Rif = '
- L3306 [DELETE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Delete_29
  SQL: SQL = " DELETE FROM dETALLE_" & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' and nota = '" & vMemoria & "' and serialtipo = '" & vSerieFact & "'"
- L3306 [DELETE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Delete_30
  SQL: DELETE FROM dETALLE_
- L3317 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_31
  SQL: SQL = "Select * From Inventario where eliminado = 0 and Codigo = '" & !referencia & "'"
- L3447 [INSERT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Insert_32
  SQL: SQL = "INSERT INTO Detalle_" & Tb_Table & " (relacionada, tasacambio, comision, Almacen, Lote, CostoLote,Cantidadlote, fechalote, facturalote, NUM_FACT,SERIALTIPO, COD_SERV, DESCRI...
- L3447 [INSERT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Insert_33
  SQL: INSERT INTO Detalle_
- L3475 [INSERT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_PtoVenta_MOVINVENT_Insert_34
  SQL: SQL = "INSERT INTO MovInvent (CODIGO, PRODUCT,DOCUMENTO,FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, cantidad, cantidad_nueva, CO_USUARIO,PRECIO_COMPRA,ALICUOTA,PRECIO_VENTA)"
- L3475 [INSERT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_PtoVenta_MOVINVENT_Insert_35
  SQL: INSERT INTO MovInvent (CODIGO, PRODUCT,DOCUMENTO,FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, cantidad, cantidad_nueva, CO_USUARIO,PRECIO_COMPRA,ALICUOTA,PRECIO_VENTA)
- L3485 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_36
  SQL: SQL = " UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA - " & !cantidad & " WHERE CODIGO = '" & !referencia & "'"
- L3485 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_37
  SQL: UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA -
- L3488 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_38
  SQL: SQL = " UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA - " & !cantidad & ", precio_venta = " & !Precio & " WHERE CODIGO = '" & !referencia & "'"
- L3497 [UPDATE] objeto: INVENTARIO_AUX
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_AUX_Update_39
  SQL: SQL = " UPDATE INVENTARIO_aux SET CANTIDAD = CANTIDAD - " & !cantidad & " WHERE CODIGO = '" & !Codigo & "'"
- L3497 [UPDATE] objeto: INVENTARIO_AUX
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_AUX_Update_40
  SQL: UPDATE INVENTARIO_aux SET CANTIDAD = CANTIDAD -
- L3506 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Get_41
  SQL: SQL = "Select * From DETALLE_INVENTARIO where Codigo = '" & !referencia & "' AND EXISTENCIA_ACTUAL > 0 ORDER BY FECHA DESC "
- L3506 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Get_42
  SQL: Select * From DETALLE_INVENTARIO where Codigo = '
- L3508 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Get_43
  SQL: SQL = "Select * From DETALLE_INVENTARIO where EXISTENCIA_ACTUAL > 0 AND Codigo = '" & !referencia & "' AND ALMACEN = '" & !almacen & "' ORDER BY FECHA DESC "
- L3508 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Get_44
  SQL: Select * From DETALLE_INVENTARIO where EXISTENCIA_ACTUAL > 0 AND Codigo = '
- L3538 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Update_45
  SQL: SQL = " UPDATE DETALLE_INVENTARIO SET old = 0, existencia_actual = existencia_actual - " & ReSto & " WHERE CODIGO = '" & !referencia & "' AND ALMACEN = '" & ProductDetalle!almacen ...
- L3538 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Update_46
  SQL: UPDATE DETALLE_INVENTARIO SET old = 0, existencia_actual = existencia_actual -
- L3574 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_47
  SQL: SQL = "Select * from " & tabla & " where num_fact = '" & NUM_FACT & "' and serialtipo = '" & vSerieFact & "' and nota = '" & vMemoria & "'"
- L3627 [INSERT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Insert_48
  SQL: SQL = " INSERT INTO P_COBRARC (CODIGO,COD_USUARIO,FECHA,DOCUMENTO,DEBE,PEND,SALDO,TIPO, OBS) "
- L3627 [INSERT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Insert_49
  SQL: INSERT INTO P_COBRARC (CODIGO,COD_USUARIO,FECHA,DOCUMENTO,DEBE,PEND,SALDO,TIPO, OBS)
- L3632 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Insert_50
  SQL: SQL = " INSERT INTO P_COBRAR (CODIGO,COD_USUARIO,FECHA,DOCUMENTO,DEBE,PEND,SALDO,TIPO, OBS) "
- L3632 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Insert_51
  SQL: INSERT INTO P_COBRAR (CODIGO,COD_USUARIO,FECHA,DOCUMENTO,DEBE,PEND,SALDO,TIPO, OBS)
- L4027 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_52
  SQL: Select Case Tb_Table
- L4231 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_53
  SQL: SQL = " Update " & ptabla & " set cancelada = 'S', nota = '" & NUM_FACT & "' where num_fact = '" & pnum_Espera & "' and serialtipo = '" & vSerialFiscal & "' and tipo_orden = ' " & ...
- L4321 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Delete_54
  SQL: SQL = " DELETE FROM " & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' and serialtipo = '" & vSerialFiscal & "' and tipo_orden = '" & vMemoria & "'"
- L4326 [INSERT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Insert_55
  SQL: SQL = " INSERT INTO " & Tb_Table & ""
- L4367 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_56
  SQL: SQL = "UPDATE CLIENTES SET ULTIMAFECHACOMPRA = '" & xFecha & "' WHERE CODIGO = '" & CODIGOS & "'"
- L4367 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_57
  SQL: UPDATE CLIENTES SET ULTIMAFECHACOMPRA = '
- L4370 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_58
  SQL: '' RecSetClientes.Update
- L4587 [SELECT] objeto: VENDEDOR
  SP sugerido: usp_DatQBox_PtoVenta_VENDEDOR_Get_59
  SQL: SQL = "Select * from Vendedor where codigo = '" & vVendedor & "' order by CODIGO"
- L4587 [SELECT] objeto: VENDEDOR
  SP sugerido: usp_DatQBox_PtoVenta_VENDEDOR_Get_60
  SQL: Select * from Vendedor where codigo = '
- L4977 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_DEPOSITO_Delete_61
  SQL: SQL = "delete from Detalle_Deposito where cheque = " & RecordFacturas!Cheque & " and banco = '" & RecordFacturas!banco_Cheque & "' and cliente = '" & RecordFacturas!Codigo & "'"
- L4977 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_DEPOSITO_Delete_62
  SQL: delete from Detalle_Deposito where cheque =
- L4988 [UPDATE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Update_63
  SQL: SQL = "update detalle_" & Tb_Table & " set anulada = true where num_fact = '" & NUM_FACT & "' AND COD_SERV = '" & TDataLite1.Recordset!Codigo & "'"
- L4988 [UPDATE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Update_64
  SQL: update detalle_
- L4992 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_65
  SQL: SQL = " UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA + " & TDataLite1.Recordset!cantidad & " WHERE CODIGO = '" & TDataLite1.Recordset!Codigo & "'"
- L4992 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_66
  SQL: UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA +
- L4998 [UPDATE] objeto: INVENTARIO_AUX
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_AUX_Update_67
  SQL: SQL = " UPDATE INVENTARIO_aux SET cantidad = cantidad + " & TDataLite1.Recordset!cantidad & " WHERE CODIGO = '" & TDataLite1.Recordset!Codigo & "'"
- L4998 [UPDATE] objeto: INVENTARIO_AUX
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_AUX_Update_68
  SQL: UPDATE INVENTARIO_aux SET cantidad = cantidad +
- L5004 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Update_69
  SQL: SQL = " UPDATE DETALLE_INVENTARIO SET old = 0, existencia_actual = existencia_actual + " & TDataLite1.Recordset!cantidad & " WHERE CODIGO = '" & TDataLite1.Recordset!Codigo & "' AN...
- L5004 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Update_70
  SQL: UPDATE DETALLE_INVENTARIO SET old = 0, existencia_actual = existencia_actual +
- L5035 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_71
  SQL: SQL = "UPDATE " & Tb_Table & " SET ANULADA = 0, Observ = '" & Motivo & "', fechaanulada = '" & xFecha & "' WHERE NUM_FACT = '" & NUM_FACT & "' and serialtipo = '" & vSerialFiscal &...
- L5039 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_72
  SQL: SQL = "UPDATE " & Tb_Table & " SET ANULADA = 1, Observ = '" & Motivo & "', fechaanulada = '" & xFecha & "' WHERE NUM_FACT = '" & NUM_FACT & "' and serialtipo = '" & vSerialFiscal &...
- L5045 [UPDATE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Update_73
  SQL: SQL = "UPDATE Detalle_" & Tb_Table & " SET ANULADA = 1 WHERE NUM_FACT = '" & NUM_FACT & "' and serialtipo = '" & vSerialFiscal & "'"
- L5052 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Update_74
  SQL: SQL = "UPDATE facturas SET ANULADA = TRUE, Observ = '" & Motivo & "', fechaanulada = '" & xFecha & "' WHERE NUM_FACT = '" & NUM_FACT & "' AND PAGO = 'Nota' and serialtipo = '" & vS...
- L5052 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Update_75
  SQL: UPDATE facturas SET ANULADA = TRUE, Observ = '
- L5283 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_76
  SQL: SQL = "SELECT * From Inventario WHERE Eliminado = 0 and Codigo = '" & TDataLite1.Recordset!Codigo & "' "
- L5291 [SELECT] objeto: FALLAS
  SP sugerido: usp_DatQBox_PtoVenta_FALLAS_Get_77
  SQL: SQL = "SELECT * From Fallas WHERE Codigo = '" & TDataLite1.Recordset!Codigo & "' "
- L5291 [SELECT] objeto: FALLAS
  SP sugerido: usp_DatQBox_PtoVenta_FALLAS_Get_78
  SQL: SELECT * From Fallas WHERE Codigo = '
- L5300 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_79
  SQL: FallasR.Update
- L5384 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_PtoVenta_MOVIMIENTO_CUENTA_Get_80
  SQL: 'SQL = "Select * from movimiento_cuenta where cod_oper = '" & data3.Recordset!Documento & "' and cod_proveedor = '" & data1.Recordset!Codigo & "' and retiva = 1 "
- L5384 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_PtoVenta_MOVIMIENTO_CUENTA_Get_81
  SQL: Select * from movimiento_cuenta where cod_oper = '
- L5403 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_82
  SQL: SQL = "Select * from " & Tb_Table & " where num_fact = '" & NUM_FACT & "' and codigo = '" & CODIGOS & "' and serialtipo = '" & vSerieFact & "' and tipo_orden = '" & vMemoria & "' "
- L5904 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_PtoVenta_TABLA_TEMP_Get_83
  SQL: 'cr = "Select * from tabla_temp where numero = " & Num & ""
- L5904 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_PtoVenta_TABLA_TEMP_Get_84
  SQL: Select * from tabla_temp where numero =
- L6505 [SELECT] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Get_85
  SQL: SQL = "select * FROM Detalle_FormaPagoFacturas WHERE NUM_FACT = '" & DocActual & "' and MEMORIA = '" & vMemoriaFiscal & "' ;"
- L6505 [SELECT] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Get_86
  SQL: select * FROM Detalle_FormaPagoFacturas WHERE NUM_FACT = '
- L6508 [SELECT] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Get_87
  SQL: SQL = "select * FROM Detalle_FormaPagoFacturas WHERE NUM_FACT = '" & NUM_FACT & "' and MEMORIA = '" & vMemoriaFiscal & "' ;"
- L6924 [SELECT] objeto: DETALLE_FORMAPAGOCOTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOCOTIZACION_Get_88
  SQL: SQL = "select * FROM Detalle_FormaPagoCOTIZACION WHERE NUM_FACT = '" & NUM_FACT & "' and MEMORIA = '" & vMemoriaFiscal & "' ;"
- L6924 [SELECT] objeto: DETALLE_FORMAPAGOCOTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOCOTIZACION_Get_89
  SQL: select * FROM Detalle_FormaPagoCOTIZACION WHERE NUM_FACT = '
- L7309 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Update_90
  SQL: SQL = " UPDATE PEDIDOS SET ANULADA = 0, CANCELADA = 'N' WHERE NUM_FACT = '" & NUM_FACT & "'"
- L7309 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Update_91
  SQL: UPDATE PEDIDOS SET ANULADA = 0, CANCELADA = 'N' WHERE NUM_FACT = '
- L7312 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_92
  SQL: SQL = " Update Inventario"
- L7312 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_93
  SQL: Update Inventario
- L7315 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_94
  SQL: SQL = SQL & " (SELECT Detalle_Pedidos.COD_SERV, SUM([DETALLE_PEDIDOS].[CANTIDAD]) AS TOTAL"
- L7315 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_95
  SQL: (SELECT Detalle_Pedidos.COD_SERV, SUM([DETALLE_PEDIDOS].[CANTIDAD]) AS TOTAL
- L7321 [UPDATE] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_PtoVenta_MOVINVENT_Update_96
  SQL: SQL = " UPDATE MOVINVENT SET ANULADA = 0 WHERE DOCUMENTO = '" & NUM_FACT & "'"
- L7321 [UPDATE] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_PtoVenta_MOVINVENT_Update_97
  SQL: UPDATE MOVINVENT SET ANULADA = 0 WHERE DOCUMENTO = '
- L7583 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_98
  SQL: SQL = "select * from Facturas where num_fact = '" & NUM_FACT & "' and serialtipo = '" & vSerieFact & "' AND Tipo_Orden = '" & vMemoriaFiscal & "'"
- L7583 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_99
  SQL: select * from Facturas where num_fact = '
- L7633 [UPDATE] objeto: AS
  SP sugerido: usp_DatQBox_PtoVenta_AS_Update_100
  SQL: Private Sub TDataLite1_DataWrite(Bookmark As Variant, Values As Variant, ByVal NewRow As Boolean, ByVal Update As Boolean, Done As Boolean, Cancel As Boolean)
- L7635 [UPDATE] objeto: THEN
  SP sugerido: usp_DatQBox_PtoVenta_THEN_Update_101
  SQL: If Update Then
- L8313 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_102
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "=" + Chr(&H2) 'Select the peripheral device.
- L8317 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_103
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L8318 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_104
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L8419 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_105
  SQL: ''sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L8420 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_106
  SQL: ''sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L9379 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_107
  SQL: 'sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L9380 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_108
  SQL: 'sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L9387 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_109
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters
- L10188 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_110
  SQL: SQL = "SELECT * From Inventario WHERE eliminado = 0 and Codigo = '" & TDBGrid1.Columns("referencia").Value & "' "
- L10225 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_111
  SQL: '' SQL = "SELECT * From Inventario WHERE referencia = '" & TDBGrid1.Columns("Codigo").Value & "'"
- L10225 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_112
  SQL: SELECT * From Inventario WHERE referencia = '
- L10280 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_113
  SQL: SQL = "SELECT 0 AS pasa, aux.CODIGO, NULL AS Referencia, aux.CATEGORIA, '' AS Tipo, aux.DESCRIPCION, " & _
- L10280 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_114
  SQL: SELECT 0 AS pasa, aux.CODIGO, NULL AS Referencia, aux.CATEGORIA, '' AS Tipo, aux.DESCRIPCION,
- L10289 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_115
  SQL: SQL = "SELECT * From Inventario WHERE eliminado = 0 and Inventario.Codigo = '" & TDBGrid1.Columns("Codigo").Value & "' or referencia = '" & TDBGrid1.Columns("Codigo").Value & "' "
- L10289 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_116
  SQL: SELECT * From Inventario WHERE eliminado = 0 and Inventario.Codigo = '
- L10307 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_117
  SQL: SQL = " SELECT dbo.Inventario.pasa, dbo.Inventario.CODIGO, dbo.Inventario.Referencia, dbo.Inventario.Categoria, dbo.Inventario.Tipo, dbo.Inventario.DESCRIPCION,"
- L10307 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_118
  SQL: SELECT dbo.Inventario.pasa, dbo.Inventario.CODIGO, dbo.Inventario.Referencia, dbo.Inventario.Categoria, dbo.Inventario.Tipo, dbo.Inventario.DESCRIPCION,
- L10644 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_119
  SQL: SQL = "SELECT * From Inventario WHERE eliminado = 0 and Codigo = '" & TDBGrid1.Columns("Referencia").Value & "' or referencia = '" & TDBGrid1.Columns("Referencia").Value & "' "
- L10651 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_120
  SQL: SQL = "SELECT * From Inventario "
- L10651 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_121
  SQL: SELECT * From Inventario
- L10656 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_122
  SQL: SQL = " SELECT dbo.Inventario.CODIGO, dbo.Inventario.Referencia, dbo.Inventario.Categoria, dbo.Inventario.Tipo, dbo.Inventario.DESCRIPCION,"
- L10656 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_123
  SQL: SELECT dbo.Inventario.CODIGO, dbo.Inventario.Referencia, dbo.Inventario.Categoria, dbo.Inventario.Tipo, dbo.Inventario.DESCRIPCION,
- L10733 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_124
  SQL: TDBGrid1.Update

### DatQBox PtoVenta\frmControl.frm
- L1940 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_1
  SQL: Select Case UCase(crParamDef.ParameterFieldName)
- L2003 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_2
  SQL: SQL = " SELECT Facturas.FECHA, Facturas.CODIGO, Facturas.NUM_FACT, Facturas.NOMBRE, Detalle_facturas.CANTIDAD, Detalle_facturas.PRECIO, Facturas.RIF"
- L2003 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_3
  SQL: SELECT Facturas.FECHA, Facturas.CODIGO, Facturas.NUM_FACT, Facturas.NOMBRE, Detalle_facturas.CANTIDAD, Detalle_facturas.PRECIO, Facturas.RIF
- L2078 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_4
  SQL: SQL = "SELECT * FROM INVENTARIO WHERE categoria ='xxxxxxxACEITE' and CODIGO = '" & xArrrayCodigo(i) & "'"
- L2078 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_5
  SQL: SELECT * FROM INVENTARIO WHERE categoria ='xxxxxxxACEITE' and CODIGO = '
- L2182 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_6
  SQL: SQL = "SELECT * FROM INVENTARIO WHERE categoria ='POLLO' and CODIGO = '" & xArrrayCodigo(i) & "'"
- L2182 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_7
  SQL: SELECT * FROM INVENTARIO WHERE categoria ='POLLO' and CODIGO = '
- L2287 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_8
  SQL: SQL = "SELECT * FROM INVENTARIO WHERE Eliminado = 0 and CODIGO = '" & xArrrayCodigo(i) & "'"
- L2287 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_9
  SQL: SELECT * FROM INVENTARIO WHERE Eliminado = 0 and CODIGO = '
- L2399 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Get_10
  SQL: SQL = "SELECT SUM(EXISTENCIA_ACTUAL) AS EXISTENCIA, CODIGO, ALMACEN FROM DETALLE_INVENTARIO WHERE CODIGO = '" & xArrrayCodigo(i) & "' AND ALMACEN = '" & vAlmacen & "' GROUP BY CODI...
- L2399 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Get_11
  SQL: SELECT SUM(EXISTENCIA_ACTUAL) AS EXISTENCIA, CODIGO, ALMACEN FROM DETALLE_INVENTARIO WHERE CODIGO = '
- L2448 [DELETE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Delete_12
  SQL: SQL = "DELETE from P_cobrar where codigo = '" & CODIGOS & "' and documento = '" & num_fact & "' "
- L2448 [DELETE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Delete_13
  SQL: DELETE from P_cobrar where codigo = '
- L2449 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_PtoVenta_SQL_Exec_14
  SQL: DbConnection.Execute SQL
- L2457 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_15
  SQL: SQL = "UPDATE CLIENTES SET saldo_relacionar = saldo_relacionar - " & Format(total, "########0.00") & ""
- L2457 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_16
  SQL: UPDATE CLIENTES SET saldo_relacionar = saldo_relacionar -
- L2473 [DELETE] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Delete_17
  SQL: SQL = "DELETE from P_cobrarc where codigo = '" & CODIGOS & "' and documento = '" & num_fact & "' "
- L2473 [DELETE] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Delete_18
  SQL: DELETE from P_cobrarc where codigo = '
- L2511 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_19
  SQL: SQL = "select * from " & PrinTabla & " where num_fact = '" & Factur & "' and serialtipo = '" & vSerieFact & "' and TIPO_ORDEN = '" & vMemoria & "'"
- L2511 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_20
  SQL: select * from
- L2561 [SELECT] objeto: VENDEDOR
  SP sugerido: usp_DatQBox_PtoVenta_VENDEDOR_Get_21
  SQL: SQL = "Select * from Vendedor order by CODIGO"
- L2561 [SELECT] objeto: VENDEDOR
  SP sugerido: usp_DatQBox_PtoVenta_VENDEDOR_Get_22
  SQL: Select * from Vendedor order by CODIGO
- L2892 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_PtoVenta_TASA_MONEDA_Get_23
  SQL: c = "SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_compra, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE "
- L2892 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_PtoVenta_TASA_MONEDA_Get_24
  SQL: SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_compra, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE
- L3025 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_PtoVenta_PROVEEDORES_Get_25
  SQL: SQL = "Select * from Proveedores where Rif = '" & cliente.Text & "'"
- L3025 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_PtoVenta_PROVEEDORES_Get_26
  SQL: Select * from Proveedores where Rif = '
- L3027 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Get_27
  SQL: SQL = "Select * from clientes where Rif = '" & cliente.Text & "'"
- L3027 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Get_28
  SQL: Select * from clientes where Rif = '
- L3199 [DELETE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Delete_29
  SQL: SQL = " DELETE FROM dETALLE_" & Tb_Table & " WHERE NUM_FACT = '" & num_fact & "' and nota = '" & vMemoria & "' and serialtipo = '" & vSerieFact & "'"
- L3199 [DELETE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Delete_30
  SQL: DELETE FROM dETALLE_
- L3210 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_31
  SQL: SQL = "Select * From Inventario where eliminado = 0 and Codigo = '" & !referencia & "'"
- L3334 [INSERT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Insert_32
  SQL: SQL = "INSERT INTO Detalle_" & Tb_Table & " ( comision, Almacen, Lote, CostoLote,Cantidadlote, fechalote, facturalote, NUM_FACT,SERIALTIPO, COD_SERV, DESCRIPCION, FECHA, CANTIDAD, ...
- L3334 [INSERT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Insert_33
  SQL: INSERT INTO Detalle_
- L3362 [INSERT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_PtoVenta_MOVINVENT_Insert_34
  SQL: SQL = "INSERT INTO MovInvent (CODIGO, PRODUCT,DOCUMENTO,FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, cantidad, cantidad_nueva, CO_USUARIO,PRECIO_COMPRA,ALICUOTA,PRECIO_VENTA)"
- L3362 [INSERT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_PtoVenta_MOVINVENT_Insert_35
  SQL: INSERT INTO MovInvent (CODIGO, PRODUCT,DOCUMENTO,FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, cantidad, cantidad_nueva, CO_USUARIO,PRECIO_COMPRA,ALICUOTA,PRECIO_VENTA)
- L3372 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_36
  SQL: SQL = " UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA - " & !cantidad & " WHERE CODIGO = '" & !referencia & "'"
- L3372 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_37
  SQL: UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA -
- L3375 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_38
  SQL: SQL = " UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA - " & !cantidad & ", precio_venta = " & !Precio & " WHERE CODIGO = '" & !referencia & "'"
- L3386 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Get_39
  SQL: SQL = "Select * From DETALLE_INVENTARIO where Codigo = '" & !referencia & "' AND EXISTENCIA_ACTUAL > 0 ORDER BY FECHA DESC "
- L3386 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Get_40
  SQL: Select * From DETALLE_INVENTARIO where Codigo = '
- L3388 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Get_41
  SQL: SQL = "Select * From DETALLE_INVENTARIO where EXISTENCIA_ACTUAL > 0 AND Codigo = '" & !referencia & "' AND ALMACEN = '" & !almacen & "' ORDER BY FECHA DESC "
- L3388 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Get_42
  SQL: Select * From DETALLE_INVENTARIO where EXISTENCIA_ACTUAL > 0 AND Codigo = '
- L3418 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Update_43
  SQL: SQL = " UPDATE DETALLE_INVENTARIO SET old = 0, existencia_actual = existencia_actual - " & ReSto & " WHERE CODIGO = '" & !referencia & "' AND ALMACEN = '" & ProductDetalle!almacen ...
- L3418 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Update_44
  SQL: UPDATE DETALLE_INVENTARIO SET old = 0, existencia_actual = existencia_actual -
- L3454 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_45
  SQL: SQL = "Select * from " & TABLA & " where num_fact = '" & num_fact & "' and serialtipo = '" & vSerieFact & "' and nota = '" & vMemoria & "'"
- L3507 [INSERT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Insert_46
  SQL: SQL = " INSERT INTO P_COBRARC (CODIGO,COD_USUARIO,FECHA,DOCUMENTO,DEBE,PEND,SALDO,TIPO, OBS) "
- L3507 [INSERT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Insert_47
  SQL: INSERT INTO P_COBRARC (CODIGO,COD_USUARIO,FECHA,DOCUMENTO,DEBE,PEND,SALDO,TIPO, OBS)
- L3512 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Insert_48
  SQL: SQL = " INSERT INTO P_COBRAR (CODIGO,COD_USUARIO,FECHA,DOCUMENTO,DEBE,PEND,SALDO,TIPO, OBS) "
- L3512 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Insert_49
  SQL: INSERT INTO P_COBRAR (CODIGO,COD_USUARIO,FECHA,DOCUMENTO,DEBE,PEND,SALDO,TIPO, OBS)
- L3914 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_50
  SQL: Select Case Tb_Table
- L4110 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_51
  SQL: SQL = " Update " & ptabla & " set cancelada = 'S', nota = '" & num_fact & "' where num_fact = '" & pnum_Espera & "' and serialtipo = '" & vSerialFiscal & "' and tipo_orden = ' " & ...
- L4200 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Delete_52
  SQL: SQL = " DELETE FROM " & Tb_Table & " WHERE NUM_FACT = '" & num_fact & "' and serialtipo = '" & vSerialFiscal & "' and tipo_orden = '" & vMemoria & "'"
- L4205 [INSERT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Insert_53
  SQL: SQL = " INSERT INTO " & Tb_Table & ""
- L4238 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_54
  SQL: SQL = "UPDATE CLIENTES SET ULTIMAFECHACOMPRA = '" & xFecha & "' WHERE CODIGO = '" & CODIGOS & "'"
- L4238 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_55
  SQL: UPDATE CLIENTES SET ULTIMAFECHACOMPRA = '
- L4241 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_56
  SQL: '' RecSetClientes.Update
- L4458 [SELECT] objeto: VENDEDOR
  SP sugerido: usp_DatQBox_PtoVenta_VENDEDOR_Get_57
  SQL: SQL = "Select * from Vendedor where codigo = '" & vVendedor & "' order by CODIGO"
- L4458 [SELECT] objeto: VENDEDOR
  SP sugerido: usp_DatQBox_PtoVenta_VENDEDOR_Get_58
  SQL: Select * from Vendedor where codigo = '
- L4847 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_DEPOSITO_Delete_59
  SQL: SQL = "delete from Detalle_Deposito where cheque = " & RecordFacturas!Cheque & " and banco = '" & RecordFacturas!banco_Cheque & "' and cliente = '" & RecordFacturas!codigo & "'"
- L4847 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_DEPOSITO_Delete_60
  SQL: delete from Detalle_Deposito where cheque =
- L4858 [UPDATE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Update_61
  SQL: SQL = "update detalle_" & Tb_Table & " set anulada = true where num_fact = '" & num_fact & "' AND COD_SERV = '" & TDataLite1.Recordset!codigo & "'"
- L4858 [UPDATE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Update_62
  SQL: update detalle_
- L4862 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_63
  SQL: SQL = " UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA + " & TDataLite1.Recordset!cantidad & " WHERE CODIGO = '" & TDataLite1.Recordset!codigo & "'"
- L4862 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_64
  SQL: UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA +
- L4867 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Update_65
  SQL: SQL = " UPDATE DETALLE_INVENTARIO SET old = 0, existencia_actual = existencia_actual + " & TDataLite1.Recordset!cantidad & " WHERE CODIGO = '" & TDataLite1.Recordset!codigo & "' AN...
- L4867 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_INVENTARIO_Update_66
  SQL: UPDATE DETALLE_INVENTARIO SET old = 0, existencia_actual = existencia_actual +
- L4898 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_67
  SQL: SQL = "UPDATE " & Tb_Table & " SET ANULADA = 0, Observ = '" & Motivo & "', fechaanulada = '" & xFecha & "' WHERE NUM_FACT = '" & num_fact & "' and serialtipo = '" & vSerialFiscal &...
- L4902 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_68
  SQL: SQL = "UPDATE " & Tb_Table & " SET ANULADA = 1, Observ = '" & Motivo & "', fechaanulada = '" & xFecha & "' WHERE NUM_FACT = '" & num_fact & "' " ' and serialtipo = '" & vSerialFisc...
- L4908 [UPDATE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Update_69
  SQL: SQL = "UPDATE Detalle_" & Tb_Table & " SET ANULADA = 1 WHERE NUM_FACT = '" & num_fact & "' and serialtipo = '" & vSerialFiscal & "'"
- L4915 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Update_70
  SQL: SQL = "UPDATE facturas SET ANULADA = TRUE, Observ = '" & Motivo & "', fechaanulada = '" & xFecha & "' WHERE NUM_FACT = '" & num_fact & "' AND PAGO = 'Nota' and serialtipo = '" & vS...
- L4915 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Update_71
  SQL: UPDATE facturas SET ANULADA = TRUE, Observ = '
- L5146 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_72
  SQL: SQL = "SELECT * From Inventario WHERE Eliminado = 0 and Codigo = '" & TDataLite1.Recordset!codigo & "' "
- L5154 [SELECT] objeto: FALLAS
  SP sugerido: usp_DatQBox_PtoVenta_FALLAS_Get_73
  SQL: SQL = "SELECT * From Fallas WHERE Codigo = '" & TDataLite1.Recordset!codigo & "' "
- L5154 [SELECT] objeto: FALLAS
  SP sugerido: usp_DatQBox_PtoVenta_FALLAS_Get_74
  SQL: SELECT * From Fallas WHERE Codigo = '
- L5163 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_75
  SQL: FallasR.Update
- L5247 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_PtoVenta_MOVIMIENTO_CUENTA_Get_76
  SQL: 'SQL = "Select * from movimiento_cuenta where cod_oper = '" & data3.Recordset!Documento & "' and cod_proveedor = '" & data1.Recordset!Codigo & "' and retiva = 1 "
- L5247 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_PtoVenta_MOVIMIENTO_CUENTA_Get_77
  SQL: Select * from movimiento_cuenta where cod_oper = '
- L5266 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_78
  SQL: SQL = "Select * from " & Tb_Table & " where num_fact = '" & num_fact & "' and codigo = '" & CODIGOS & "' and serialtipo = '" & vSerieFact & "' and tipo_orden = '" & vMemoria & "' "
- L5767 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_PtoVenta_TABLA_TEMP_Get_79
  SQL: 'cr = "Select * from tabla_temp where numero = " & Num & ""
- L5767 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_PtoVenta_TABLA_TEMP_Get_80
  SQL: Select * from tabla_temp where numero =
- L6338 [SELECT] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Get_81
  SQL: SQL = "select * FROM Detalle_FormaPagoFacturas WHERE NUM_FACT = '" & DocActual & "' and MEMORIA = '" & vMemoriaFiscal & "' ;"
- L6338 [SELECT] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Get_82
  SQL: select * FROM Detalle_FormaPagoFacturas WHERE NUM_FACT = '
- L6341 [SELECT] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Get_83
  SQL: SQL = "select * FROM Detalle_FormaPagoFacturas WHERE NUM_FACT = '" & num_fact & "' and MEMORIA = '" & vMemoriaFiscal & "' ;"
- L6722 [SELECT] objeto: DETALLE_FORMAPAGOCOTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOCOTIZACION_Get_84
  SQL: SQL = "select * FROM Detalle_FormaPagoCOTIZACION WHERE NUM_FACT = '" & num_fact & "' and MEMORIA = '" & vMemoriaFiscal & "' ;"
- L6722 [SELECT] objeto: DETALLE_FORMAPAGOCOTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOCOTIZACION_Get_85
  SQL: select * FROM Detalle_FormaPagoCOTIZACION WHERE NUM_FACT = '
- L7098 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Update_86
  SQL: SQL = " UPDATE PEDIDOS SET ANULADA = 0, CANCELADA = 'N' WHERE NUM_FACT = '" & num_fact & "'"
- L7098 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Update_87
  SQL: UPDATE PEDIDOS SET ANULADA = 0, CANCELADA = 'N' WHERE NUM_FACT = '
- L7101 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_88
  SQL: SQL = " Update Inventario"
- L7101 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_89
  SQL: Update Inventario
- L7104 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_90
  SQL: SQL = SQL & " (SELECT Detalle_Pedidos.COD_SERV, SUM([DETALLE_PEDIDOS].[CANTIDAD]) AS TOTAL"
- L7104 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_91
  SQL: (SELECT Detalle_Pedidos.COD_SERV, SUM([DETALLE_PEDIDOS].[CANTIDAD]) AS TOTAL
- L7110 [UPDATE] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_PtoVenta_MOVINVENT_Update_92
  SQL: SQL = " UPDATE MOVINVENT SET ANULADA = 0 WHERE DOCUMENTO = '" & num_fact & "'"
- L7110 [UPDATE] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_PtoVenta_MOVINVENT_Update_93
  SQL: UPDATE MOVINVENT SET ANULADA = 0 WHERE DOCUMENTO = '
- L7372 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_94
  SQL: SQL = "select * from Facturas where num_fact = '" & num_fact & "' and serialtipo = '" & vSerieFact & "' AND Tipo_Orden = '" & vMemoriaFiscal & "'"
- L7372 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_95
  SQL: select * from Facturas where num_fact = '
- L7422 [UPDATE] objeto: AS
  SP sugerido: usp_DatQBox_PtoVenta_AS_Update_96
  SQL: Private Sub TDataLite1_DataWrite(Bookmark As Variant, Values As Variant, ByVal NewRow As Boolean, ByVal Update As Boolean, Done As Boolean, Cancel As Boolean)
- L7424 [UPDATE] objeto: THEN
  SP sugerido: usp_DatQBox_PtoVenta_THEN_Update_97
  SQL: If Update Then
- L8102 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_98
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "=" + Chr(&H2) 'Select the peripheral device.
- L8106 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_99
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L8107 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_100
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L8208 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_101
  SQL: ''sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L8209 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_102
  SQL: ''sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L9168 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_103
  SQL: 'sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L9169 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_104
  SQL: 'sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L9176 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_105
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters
- L9977 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_106
  SQL: SQL = "SELECT * From Inventario WHERE eliminado = 0 and Codigo = '" & TDBGrid1.Columns("referencia").Value & "' "
- L10014 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_107
  SQL: '' SQL = "SELECT * From Inventario WHERE referencia = '" & TDBGrid1.Columns("Codigo").Value & "'"
- L10014 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_108
  SQL: SELECT * From Inventario WHERE referencia = '
- L10066 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_109
  SQL: SQL = "SELECT * From Inventario WHERE eliminado = 0 and Inventario.Codigo = '" & TDBGrid1.Columns("Codigo").Value & "' or referencia = '" & TDBGrid1.Columns("Codigo").Value & "' "
- L10066 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_110
  SQL: SELECT * From Inventario WHERE eliminado = 0 and Inventario.Codigo = '
- L10073 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_111
  SQL: SQL = " SELECT dbo.Inventario.pasa, dbo.Inventario.CODIGO, dbo.Inventario.Referencia, dbo.Inventario.Categoria, dbo.Inventario.Tipo, dbo.Inventario.DESCRIPCION,"
- L10073 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_112
  SQL: SELECT dbo.Inventario.pasa, dbo.Inventario.CODIGO, dbo.Inventario.Referencia, dbo.Inventario.Categoria, dbo.Inventario.Tipo, dbo.Inventario.DESCRIPCION,
- L10351 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_113
  SQL: SQL = "SELECT * From Inventario WHERE eliminado = 0 and Codigo = '" & TDBGrid1.Columns("Referencia").Value & "' or referencia = '" & TDBGrid1.Columns("Referencia").Value & "' "
- L10358 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_114
  SQL: SQL = "SELECT * From Inventario "
- L10358 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_115
  SQL: SELECT * From Inventario
- L10363 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_116
  SQL: SQL = " SELECT dbo.Inventario.CODIGO, dbo.Inventario.Referencia, dbo.Inventario.Categoria, dbo.Inventario.Tipo, dbo.Inventario.DESCRIPCION,"
- L10363 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_117
  SQL: SELECT dbo.Inventario.CODIGO, dbo.Inventario.Referencia, dbo.Inventario.Categoria, dbo.Inventario.Tipo, dbo.Inventario.DESCRIPCION,
- L10440 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_118
  SQL: TDBGrid1.Update

### DatQBox PtoVenta\FrmFacturaPedido.frm
- L1097 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_1
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "=" + Chr(&H2) 'Select the peripheral device.
- L1101 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_2
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L1102 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_3
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L1187 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_4
  SQL: 'sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L1188 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_5
  SQL: 'sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L1195 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_6
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters
- L1644 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_7
  SQL: ''sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L1645 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_8
  SQL: ''sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L1673 [SELECT] objeto: DETALLE_PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_PEDIDOS_Get_9
  SQL: SQL = "Select * from Detalle_pedidos where num_fact = '" & TDBGrid1.Columns("Num_fact").Value & "' AND SERIALTIPO = '" & EsperasRecordSet!SERIALTIPO & "' AND NOTA = '" & EsperasRec...
- L1673 [SELECT] objeto: DETALLE_PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_PEDIDOS_Get_10
  SQL: Select * from Detalle_pedidos where num_fact = '
- L2710 [SELECT] objeto: DETALLE_FORMAPAGOCOTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOCOTIZACION_Get_11
  SQL: SQL = "select * FROM Detalle_FormaPagoCOTIZACION WHERE NUM_FACT = '" & NUM_FACT & "' and MEMORIA = '" & EsperasRecordSet!tipo_orden & "' and serialfiscal = '" & EsperasRecordSet!SE...
- L2710 [SELECT] objeto: DETALLE_FORMAPAGOCOTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOCOTIZACION_Get_12
  SQL: select * FROM Detalle_FormaPagoCOTIZACION WHERE NUM_FACT = '
- L3074 [SELECT] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Get_13
  SQL: SQL = "select * FROM Detalle_FormaPagoFacturas WHERE NUM_FACT = '" & DocActual & "' and MEMORIA = '" & EsperasRecordSet!tipo_orden & "' and serialfiscal = '" & EsperasRecordSet!SER...
- L3074 [SELECT] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Get_14
  SQL: select * FROM Detalle_FormaPagoFacturas WHERE NUM_FACT = '
- L3077 [SELECT] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Get_15
  SQL: SQL = "select * FROM Detalle_FormaPagoFacturas WHERE NUM_FACT = '" & NUM_FACT & "' and MEMORIA = '" & EsperasRecordSet!tipo_orden & "' and serialfiscal = '" & EsperasRecordSet!SERI...
- L3204 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_16
  SQL: SQL = " SELECT dbo.Facturas.FECHAANULADA, dbo.NOTACREDITO.NUM_FACT, dbo.NOTACREDITO.CODIGO, dbo.NOTACREDITO.FECHA"
- L3204 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_17
  SQL: SELECT dbo.Facturas.FECHAANULADA, dbo.NOTACREDITO.NUM_FACT, dbo.NOTACREDITO.CODIGO, dbo.NOTACREDITO.FECHA
- L3214 [UPDATE] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Update_18
  SQL: SQL = "UPDATE notacredito SET fecha = '" & Detaller!fechaanulada & "' where num_fact = '" & Detaller!NUM_FACT & "'"
- L3214 [UPDATE] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Update_19
  SQL: UPDATE notacredito SET fecha = '
- L3215 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_PtoVenta_SQL_Exec_20
  SQL: DbConnection.Execute SQL
- L3289 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Get_21
  SQL: SQL = "Select * from clientes where Rif = '" & Cliente & "'"
- L3289 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Get_22
  SQL: Select * from clientes where Rif = '
- L3412 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_PtoVenta_TABLA_TEMP_Get_23
  SQL: 'cr = "Select * from tabla_temp where numero = " & Num & ""
- L3412 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_PtoVenta_TABLA_TEMP_Get_24
  SQL: Select * from tabla_temp where numero =
- L3431 [SELECT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Get_25
  SQL: SQL = "Select * from DETALLE_FACTURAS where num_fact = '" & NUM_FACT & "' and serialtipo = 'MANUAL' and nota = '" & vMemoriaFiscal & "'"
- L3431 [SELECT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Get_26
  SQL: Select * from DETALLE_FACTURAS where num_fact = '
- L3657 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_27
  SQL: SQL = "Select * from FACTURAS where num_fact = '" & NUM_FACT & "' and serialtipo = 'MANUAL' and tipo_orden = '" & vMemoriaFiscal & "'"
- L3657 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_28
  SQL: Select * from FACTURAS where num_fact = '
- L3795 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_29
  SQL: SQL = "UPDATE CLIENTES SET SALDO_TOT = SALDO_TOT + " & total & ", SALDO_30 = SALDO_30 + " & total & " where codigo = '" & CODIGOS & "';"
- L3795 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_30
  SQL: UPDATE CLIENTES SET SALDO_TOT = SALDO_TOT +
- L3807 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Insert_31
  SQL: SQL = "INSERT INTO P_COBRAR (CODIGO, COD_USUARIO, FECHA,DOCUMENTO ,DEBE,PEND,SALDO,TIPO)"
- L3807 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Insert_32
  SQL: INSERT INTO P_COBRAR (CODIGO, COD_USUARIO, FECHA,DOCUMENTO ,DEBE,PEND,SALDO,TIPO)
- L3891 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_33
  SQL: SQL = " SELECT PEDIDOS.NUM_FACT, PEDIDOS.FECHA, PEDIDOS.Vendedor, PEDIDOS.RIF, PEDIDOS.NOMBRE, PEDIDOS.TOTAL, PEDIDOS.TOTAL / PEDIDOS.tasacambio as Dolares, PEDIDOS.MONTO_GRA * " &...
- L3891 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_34
  SQL: SELECT PEDIDOS.NUM_FACT, PEDIDOS.FECHA, PEDIDOS.Vendedor, PEDIDOS.RIF, PEDIDOS.NOMBRE, PEDIDOS.TOTAL, PEDIDOS.TOTAL / PEDIDOS.tasacambio as Dolares, PEDIDOS.MONTO_GRA *
- L3929 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_35
  SQL: SQL = "SELECT SUM(TOTAL) as totalfact FROM FACTURAS WHERE FECHA = '" & fechas & "'"
- L3929 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_36
  SQL: SELECT SUM(TOTAL) as totalfact FROM FACTURAS WHERE FECHA = '
- L3944 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_37
  SQL: SQL = " SELECT Facturas.NUM_FACT,Facturas.SERIALTIPO, Facturas.FECHA, Facturas.Vendedor, Facturas.RIF, Facturas.NOMBRE, Facturas.TOTAL, facturas.total / facturas.tasacambio as Dola...
- L3944 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_38
  SQL: SELECT Facturas.NUM_FACT,Facturas.SERIALTIPO, Facturas.FECHA, Facturas.Vendedor, Facturas.RIF, Facturas.NOMBRE, Facturas.TOTAL, facturas.total / facturas.tasacambio as Dolares, Fac...
- L3982 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_39
  SQL: SQL = " SELECT COTIZACION.NUM_FACT,COTIZACION.SERIALTIPO, COTIZACION.FECHA, COTIZACION.Vendedor, COTIZACION.RIF, COTIZACION.NOMBRE, COTIZACION.TOTAL, Cotizacion.total / cotizacion....
- L3982 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_40
  SQL: SELECT COTIZACION.NUM_FACT,COTIZACION.SERIALTIPO, COTIZACION.FECHA, COTIZACION.Vendedor, COTIZACION.RIF, COTIZACION.NOMBRE, COTIZACION.TOTAL, Cotizacion.total / cotizacion.tasacamb...
- L4037 [SELECT] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Get_41
  SQL: cr = "Select * from Correlativo where Correlativo.Tipo = '" & tipo & "'"
- L4037 [SELECT] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Get_42
  SQL: Select * from Correlativo where Correlativo.Tipo = '
- L4046 [UPDATE] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Update_43
  SQL: cr = "Update Correlativo Set Correlativo.valor = Correlativo.Valor + 1 where Correlativo.tipo = '" & tipo & "'"
- L4046 [UPDATE] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Update_44
  SQL: Update Correlativo Set Correlativo.valor = Correlativo.Valor + 1 where Correlativo.tipo = '
- L4047 [EXEC] objeto: CR
  SP sugerido: usp_DatQBox_PtoVenta_CR_Exec_45
  SQL: DbConnection.Execute cr
- L4080 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_46
  SQL: SQL = "select * from Facturas where num_fact = '" & NUM_FACT & "' AND SERIALTIPO = '" & TDBGRID2.Columns("SERIALTIPO").Value & "' AND TIPO_orden= '" & vMemoriaFiscal & "'"
- L4083 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_47
  SQL: SQL = "select * from Facturas where num_fact = '" & TDBGRID2.Columns("NUM_FACT").Value & "' AND SERIALTIPO = '" & TDBGRID2.Columns("SERIALTIPO").Value & "' AND TIPO_orden= '" & TDB...
- L4178 [SELECT] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Get_48
  SQL: SQL = "Select NUM_FACT, CANCELADA FROM PEDIDOS WHERE NUM_FACT = '" & TDBGrid1.Columns("NUM_FACT").Value & "' AND SERIALTIPO = '" & EsperasRecordSet!SERIALTIPO & "' AND TIPO_ORDEN =...
- L4178 [SELECT] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Get_49
  SQL: Select NUM_FACT, CANCELADA FROM PEDIDOS WHERE NUM_FACT = '
- L4228 [INSERT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Insert_50
  SQL: SQL = " INSERT INTO FACTURAS ( NUM_FACT, Num_Control,SERIALTIPO, RetencionIva, CODIGO, FECHA, FECHA_veN, HORA, NOMBRE, RIF, Monto_grabs, TOTALPAGO, MONTO_GRA, IVA, MONTO_EXE, TOTAL...
- L4228 [INSERT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Insert_51
  SQL: INSERT INTO FACTURAS ( NUM_FACT, Num_Control,SERIALTIPO, RetencionIva, CODIGO, FECHA, FECHA_veN, HORA, NOMBRE, RIF, Monto_grabs, TOTALPAGO, MONTO_GRA, IVA, MONTO_EXE, TOTAL, PAGO, ...
- L4229 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_52
  SQL: SQL = SQL & " SELECT " & NUM_FACT & ", '" & NUM_CONTROL & "', Pedidos.Serialtipo,Pedidos.RetencionIva, Pedidos.CODIGO, Pedidos.FECHA, Pedidos.FECHA_veN, Pedidos.HORA,"
- L4255 [INSERT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Insert_53
  SQL: SQL = " INSERT INTO Detalle_Facturas ( NUM_FACT, SERIALTIPO,COD_SERV, DESCRIPCION, FECHA, CANTIDAD, PRECIO, PRECIO_DESCUENTO, DESCUENTO, TOTAL, ANULADA, Co_Usuario, unidad, HORA, N...
- L4255 [INSERT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Insert_54
  SQL: INSERT INTO Detalle_Facturas ( NUM_FACT, SERIALTIPO,COD_SERV, DESCRIPCION, FECHA, CANTIDAD, PRECIO, PRECIO_DESCUENTO, DESCUENTO, TOTAL, ANULADA, Co_Usuario, unidad, HORA, NOTA, Ali...
- L4256 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_55
  SQL: SQL = SQL & " SELECT " & NUM_FACT & ",DETALLE_PEDIDOS.SERIALTIPO ,Detalle_Pedidos.COD_serv, Detalle_Pedidos.DESCRIPCION, Detalle_Pedidos.FECHA, Detalle_Pedidos.CANTIDAD, Detalle_Pe...
- L4263 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_56
  SQL: SQL = SQL & " SELECT " & NUM_FACT & ",DETALLE_PEDIDOS.SERIALTIPO ,Detalle_Pedidos.COD_serv, Detalle_Pedidos.DESCRIPCION, Detalle_Pedidos.FECHA, Detalle_Pedidos.CANTIDAD, round((Det...
- L4284 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Update_57
  SQL: SQL = "UPDATE PEDIDOS SET CANCELADA = 'S' , FOB = " & NUM_FACT & " WHERE NUM_FACT = '" & TDBGrid1.Columns("NUM_FACT").Value & "' AND SERIALTIPO = '" & EsperasRecordSet!SERIALTIPO &...
- L4284 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Update_58
  SQL: UPDATE PEDIDOS SET CANCELADA = 'S' , FOB =
- L4291 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_59
  SQL: 'SQL = "Select Num_Fact, Fecha, Hora, Rif, Nombre, Total, * from Facturas WHERE FECHA >= " & FECHAS & "order by num_fact desc"
- L4291 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_60
  SQL: Select Num_Fact, Fecha, Hora, Rif, Nombre, Total, * from Facturas WHERE FECHA >=
- L4637 [SELECT] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Get_61
  SQL: SQL = "Select NUM_FACT, CANCELADA, RIF, VENDEDOR FROM PEDIDOS WHERE NUM_FACT = '" & TDBGrid1.Columns("NUM_FACT").Value & "'"
- L4637 [SELECT] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Get_62
  SQL: Select NUM_FACT, CANCELADA, RIF, VENDEDOR FROM PEDIDOS WHERE NUM_FACT = '
- L4645 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Update_63
  SQL: SQL = "UPDATE PEDIDOS SET CANCELADA = 'S' , FOB = " & NUM_FACT & " WHERE NUM_FACT = '" & TDBGrid1.Columns("NUM_FACT").Value & "'"
- L4674 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_64
  SQL: SQL = SQL & " SELECT " & NUM_FACT & ", '" & NUM_CONTROL & "', 'MANUAL',Pedidos.RetencionIva, Pedidos.CODIGO, Pedidos.FECHA, Pedidos.FECHA_veN, Pedidos.HORA,"
- L4697 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_65
  SQL: SQL = SQL & " SELECT " & NUM_FACT & ",'MANUAL' ,Detalle_Pedidos.COD_serv, Detalle_Pedidos.DESCRIPCION, Detalle_Pedidos.FECHA, Detalle_Pedidos.CANTIDAD, Detalle_Pedidos.PRECIO, Deta...
- L4704 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_66
  SQL: SQL = SQL & " SELECT " & NUM_FACT & ",'MANUAL',Detalle_Pedidos.COD_serv, Detalle_Pedidos.DESCRIPCION, Detalle_Pedidos.FECHA, Detalle_Pedidos.CANTIDAD, round((Detalle_Pedidos.PRECIO...
- L4717 [INSERT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Insert_67
  SQL: ''SQL = " INSERT INTO FACTURAS ( NUM_FACT, Num_Control,Serialtipo, RetencionIva, CODIGO, FECHA, FECHA_veN, HORA, NOMBRE, RIF, Monto_grabs, TOTALPAGO, MONTO_GRA, IVA, MONTO_EXE, TOT...
- L4717 [INSERT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Insert_68
  SQL: INSERT INTO FACTURAS ( NUM_FACT, Num_Control,Serialtipo, RetencionIva, CODIGO, FECHA, FECHA_veN, HORA, NOMBRE, RIF, Monto_grabs, TOTALPAGO, MONTO_GRA, IVA, MONTO_EXE, TOTAL, PAGO, ...
- L4719 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_69
  SQL: ''SQL = SQL & " SELECT " & NUM_FACT & ", '" & NUM_CONTROL & "','MANUAL' ,Pedidos.RetencionIva, Pedidos.CODIGO, Pedidos.FECHA, Pedidos.FECHA_veN, Pedidos.HORA,"
- L4725 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_PtoVenta_SQL_Exec_70
  SQL: ''DbConnection.Execute SQL
- L4729 [INSERT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Insert_71
  SQL: ''SQL = " INSERT INTO Detalle_Facturas ( NUM_FACT, SERIALTIPO,COD_SERV, DESCRIPCION, FECHA, CANTIDAD, PRECIO, PRECIO_DESCUENTO, DESCUENTO, TOTAL, ANULADA, Co_Usuario, unidad, HORA,...
- L4729 [INSERT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Insert_72
  SQL: INSERT INTO Detalle_Facturas ( NUM_FACT, SERIALTIPO,COD_SERV, DESCRIPCION, FECHA, CANTIDAD, PRECIO, PRECIO_DESCUENTO, DESCUENTO, TOTAL, ANULADA, Co_Usuario, unidad, HORA, NOTA, Ali...
- L4730 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_73
  SQL: ''SQL = SQL & " SELECT " & NUM_FACT & ",'MANUAL' ,Detalle_Pedidos.COD_SERV, Detalle_Pedidos.DESCRIPCION, Detalle_Pedidos.FECHA, Detalle_Pedidos.CANTIDAD, Detalle_Pedidos.PRECIO, De...
- L4788 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_74
  SQL: SQL = "select * from COTIZACION where num_fact = '" & TDBGrid3.Columns("NUM_FACT").Value & "' AND SERIALTIPO = '" & TDBGrid3.Columns("SERIALTIPO").Value & "' AND TIPO_orden= '" & T...
- L4788 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_75
  SQL: select * from COTIZACION where num_fact = '
- L4918 [INSERT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Insert_76
  SQL: SQL = " INSERT INTO COTIZACION ( NUM_FACT, Num_Control,SERIALTIPO, RetencionIva, CODIGO, FECHA, FECHA_veN, HORA, NOMBRE, RIF, Monto_grabs, TOTALPAGO, MONTO_GRA, IVA, MONTO_EXE, TOT...
- L4918 [INSERT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Insert_77
  SQL: INSERT INTO COTIZACION ( NUM_FACT, Num_Control,SERIALTIPO, RetencionIva, CODIGO, FECHA, FECHA_veN, HORA, NOMBRE, RIF, Monto_grabs, TOTALPAGO, MONTO_GRA, IVA, MONTO_EXE, TOTAL, PAGO...
- L4919 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_78
  SQL: SQL = SQL & " SELECT " & NUM_FACT & ", '" & NUM_CONTROL & "', 'UNICA',Pedidos.RetencionIva, Pedidos.CODIGO, Pedidos.FECHA, Pedidos.FECHA_veN, Pedidos.HORA,"
- L4945 [INSERT] objeto: DETALLE_COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_COTIZACION_Insert_79
  SQL: SQL = " INSERT INTO Detalle_Cotizacion ( NUM_FACT, SERIALTIPO,COD_SERV, DESCRIPCION, FECHA, CANTIDAD, PRECIO, PRECIO_DESCUENTO, DESCUENTO, TOTAL, ANULADA, Co_Usuario, unidad, HORA,...
- L4945 [INSERT] objeto: DETALLE_COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_COTIZACION_Insert_80
  SQL: INSERT INTO Detalle_Cotizacion ( NUM_FACT, SERIALTIPO,COD_SERV, DESCRIPCION, FECHA, CANTIDAD, PRECIO, PRECIO_DESCUENTO, DESCUENTO, TOTAL, ANULADA, Co_Usuario, unidad, HORA, NOTA, A...
- L4946 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_81
  SQL: SQL = SQL & " SELECT " & NUM_FACT & ",'UNICA' ,Detalle_Pedidos.COD_serv, Detalle_Pedidos.DESCRIPCION, Detalle_Pedidos.FECHA, Detalle_Pedidos.CANTIDAD, Detalle_Pedidos.PRECIO, Detal...
- L4953 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_82
  SQL: SQL = SQL & " SELECT " & NUM_FACT & ",'UNICA' ,Detalle_Pedidos.COD_serv, Detalle_Pedidos.DESCRIPCION, Detalle_Pedidos.FECHA, Detalle_Pedidos.CANTIDAD, round((Detalle_Pedidos.PRECIO...
- L4996 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_83
  SQL: SQL = " SELECT COTIZACION.NUM_FACT,COTIZACION.SERIALTIPO, COTIZACION.FECHA, COTIZACION.Vendedor, COTIZACION.RIF, COTIZACION.NOMBRE, COTIZACION.TOTAL,Total / Tasacambio as Dolares, ...
- L4996 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_84
  SQL: SELECT COTIZACION.NUM_FACT,COTIZACION.SERIALTIPO, COTIZACION.FECHA, COTIZACION.Vendedor, COTIZACION.RIF, COTIZACION.NOMBRE, COTIZACION.TOTAL,Total / Tasacambio as Dolares, COTIZACI...
- L5080 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_85
  SQL: SQL = " SELECT Facturas.NUM_FACT,Facturas.SERIALTIPO, Facturas.FECHA, Facturas.Vendedor, Facturas.RIF, Facturas.NOMBRE, Facturas.TOTAL,Total / Tasacambio as Dolares, Facturas.CODIG...
- L5080 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_86
  SQL: SELECT Facturas.NUM_FACT,Facturas.SERIALTIPO, Facturas.FECHA, Facturas.Vendedor, Facturas.RIF, Facturas.NOMBRE, Facturas.TOTAL,Total / Tasacambio as Dolares, Facturas.CODIGO,
- L5134 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_87
  SQL: SQL = " SELECT Detalle_Pedidos.COD_SERV, SUM([DETALLE_PEDIDOS].[CANTIDAD]) AS TOTAL"
- L5134 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_88
  SQL: SELECT Detalle_Pedidos.COD_SERV, SUM([DETALLE_PEDIDOS].[CANTIDAD]) AS TOTAL
- L5145 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_89
  SQL: SQL = "Select * From Inventario where Codigo = '" & Detaller!COD_SERV & "'"
- L5145 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_90
  SQL: Select * From Inventario where Codigo = '
- L5155 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_91
  SQL: Product.Update
- L5164 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_92
  SQL: SQL = " Update Inventario"
- L5164 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_93
  SQL: Update Inventario
- L5167 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_94
  SQL: SQL = SQL & " (SELECT Detalle_Pedidos.COD_SERV, SUM([DETALLE_PEDIDOS].[CANTIDAD]) AS TOTAL"
- L5167 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_95
  SQL: (SELECT Detalle_Pedidos.COD_SERV, SUM([DETALLE_PEDIDOS].[CANTIDAD]) AS TOTAL
- L5176 [UPDATE] objeto: INVENTARIO_AUX
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_AUX_Update_96
  SQL: SQL = " Update Inventario_Aux"
- L5176 [UPDATE] objeto: INVENTARIO_AUX
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_AUX_Update_97
  SQL: Update Inventario_Aux
- L5179 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_98
  SQL: SQL = SQL & " (SELECT Detalle_Pedidos.COD_ALTERNO, SUM([DETALLE_PEDIDOS].[CANTIDAD]) AS TOTAL"
- L5179 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_99
  SQL: (SELECT Detalle_Pedidos.COD_ALTERNO, SUM([DETALLE_PEDIDOS].[CANTIDAD]) AS TOTAL
- L5191 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Update_100
  SQL: 'sql = "UPDATE PEDIDOS SET ANULADA = -1, CANCELADA = 'S' WHERE NUM_FACT = '" & TDBGrid1.Columns("NUM_FACT").Value & "'"
- L5191 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Update_101
  SQL: UPDATE PEDIDOS SET ANULADA = -1, CANCELADA = 'S' WHERE NUM_FACT = '
- L5193 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Update_102
  SQL: SQL = "UPDATE PEDIDOS SET ANULADA = -1, CANCELADA = 'S' WHERE NUM_FACT = '" & TDBGrid1.Columns("NUM_FACT").Value & "'"
- L5196 [UPDATE] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_PtoVenta_MOVINVENT_Update_103
  SQL: SQL = " UPDATE MOVINVENT SET ANULADA = -1 WHERE DOCUMENTO = '" & TDBGrid1.Columns("NUM_FACT").Value & "'"
- L5196 [UPDATE] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_PtoVenta_MOVINVENT_Update_104
  SQL: UPDATE MOVINVENT SET ANULADA = -1 WHERE DOCUMENTO = '
- L5329 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_105
  SQL: SQL = " SELECT COTIZACION.NUM_FACT,COTIZACION.SERIALTIPO, COTIZACION.FECHA, COTIZACION.Vendedor, COTIZACION.RIF, COTIZACION.NOMBRE, COTIZACION.TOTAL, COTIZACION.CODIGO, COTIZACION....
- L5329 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_106
  SQL: SELECT COTIZACION.NUM_FACT,COTIZACION.SERIALTIPO, COTIZACION.FECHA, COTIZACION.Vendedor, COTIZACION.RIF, COTIZACION.NOMBRE, COTIZACION.TOTAL, COTIZACION.CODIGO, COTIZACION.SERIALTI...
- L5367 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_107
  SQL: SQL = "SELECT SUM(TOTAL) as totalfact FROM cotizacion WHERE FECHA = '" & fechas & "' AND CANCELADA = 'S' "
- L5367 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_108
  SQL: SELECT SUM(TOTAL) as totalfact FROM cotizacion WHERE FECHA = '
- L5399 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_109
  SQL: SQL = " SELECT PEDIDOS.NUM_FACT, PEDIDOS.FECHA, PEDIDOS.Vendedor, PEDIDOS.RIF, PEDIDOS.NOMBRE, PEDIDOS.TOTAL, PEDIDOS.TOTAL - (PEDIDOS.IVA*75/100) AS AGENTE_RET, PEDIDOS.CODIGO, PE...
- L5399 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_110
  SQL: SELECT PEDIDOS.NUM_FACT, PEDIDOS.FECHA, PEDIDOS.Vendedor, PEDIDOS.RIF, PEDIDOS.NOMBRE, PEDIDOS.TOTAL, PEDIDOS.TOTAL - (PEDIDOS.IVA*75/100) AS AGENTE_RET, PEDIDOS.CODIGO, PEDIDOS.SE...

### DatQBox Compras\frmTablas.frm
- L861 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_1
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L862 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_2
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L954 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_3
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "=" + Chr(&H2) 'Select the peripheral device.
- L996 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_4
  SQL: 'sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L999 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_5
  SQL: 'sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L1204 [EXEC] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Exec_6
  SQL: Set rst = cn.Execute(SQL)
- L1301 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_7
  SQL: cr = "SELECT * FROM " & TABLA.Text & " where codigo = '" & Me.Tag & "' order by documento"
- L1301 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_8
  SQL: SELECT * FROM
- L1305 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_9
  SQL: cr = "SELECT * FROM " & TABLA.Text & " where codigo = '" & Me.Tag & "' and tipo = 'FACT' order by FECHA, documento"
- L1311 [SELECT] objeto: GYM_ENTRADAS
  SP sugerido: usp_DatQBox_Compras_GYM_ENTRADAS_Get_10
  SQL: SQL = "SELECT CEDULA, '" & Me.Caption & "' AS NOMBRE, FECHA, HORA_INICIO, HORA_FIN FROM GYM_ENTRADAS "
- L1311 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_11
  SQL: SELECT CEDULA, '
- L1321 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_12
  SQL: cr = " SELECT Id, NUM_FACT, Num_Control, FECHA, NOMBRE, RIF, MONTO_EXE, MONTO_GRA, IVA, TOTAL, ALICUOTA, PAGO, Nro_Retencion, Monto_Retencion, Fecha_Retencion,"
- L1321 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_13
  SQL: SELECT Id, NUM_FACT, Num_Control, FECHA, NOMBRE, RIF, MONTO_EXE, MONTO_GRA, IVA, TOTAL, ALICUOTA, PAGO, Nro_Retencion, Monto_Retencion, Fecha_Retencion,
- L1329 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_14
  SQL: cr = "SELECT RifAgente, Periodo, Fecha, TipoOper, TipoDocu, Rif_Proveedor, NUM_FACT, NUM_CONTROL, TOTAL, BaseImponible, IvaRetenido, Documento_Afectado, "
- L1329 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_15
  SQL: SELECT RifAgente, Periodo, Fecha, TipoOper, TipoDocu, Rif_Proveedor, NUM_FACT, NUM_CONTROL, TOTAL, BaseImponible, IvaRetenido, Documento_Afectado,
- L1336 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_16
  SQL: 'cr = " SELECT RifAgente, LEFT(REPLACE(CONVERT(VARCHAR(10), FECHA, 111), '/', ''), 6) AS Periodo, RIF AS RifRetenido, COD_OPER AS NumeroFactura, "
- L1336 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_17
  SQL: SELECT RifAgente, LEFT(REPLACE(CONVERT(VARCHAR(10), FECHA, 111), '/', ''), 6) AS Periodo, RIF AS RifRetenido, COD_OPER AS NumeroFactura,
- L1338 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_18
  SQL: cr = " SELECT RifAgente, LEFT(REPLACE(CONVERT(VARCHAR(10), FECHA, 111), '/', ''), 6) AS Periodo, REPLACE(CONVERT(VARCHAR(15), RIF, 1), '-', '') AS RifRetenido,"
- L1338 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_19
  SQL: SELECT RifAgente, LEFT(REPLACE(CONVERT(VARCHAR(10), FECHA, 111), '/', ''), 6) AS Periodo, REPLACE(CONVERT(VARCHAR(15), RIF, 1), '-', '') AS RifRetenido,
- L1348 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_20
  SQL: SQL = "SELECT * FROM " & TABLA.Text & " where cliente = '" & Me.Tag & "'"
- L1355 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_21
  SQL: SQL = " SELECT Detalle_facturas.NUM_FACT, Detalle_facturas.FECHA, Detalle_facturas.COD_SERV, Detalle_facturas.COD_Alterno, Detalle_facturas.DESCRIPCION, "
- L1355 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_22
  SQL: SELECT Detalle_facturas.NUM_FACT, Detalle_facturas.FECHA, Detalle_facturas.COD_SERV, Detalle_facturas.COD_Alterno, Detalle_facturas.DESCRIPCION,
- L1368 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_23
  SQL: SQL = " SELECT Facturas.NUM_FACT, Facturas.FECHA, Detalle_facturas.COD_SERV, Detalle_facturas.DESCRIPCION, "
- L1368 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_24
  SQL: SELECT Facturas.NUM_FACT, Facturas.FECHA, Detalle_facturas.COD_SERV, Detalle_facturas.DESCRIPCION,
- L1378 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_25
  SQL: SQL = " SELECT [Product]"
- L1378 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_26
  SQL: SELECT [Product]
- L1426 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_27
  SQL: SQL = " SELECT Presupuestos.NUM_FACT, Presupuestos.FECHA, Detalle_Presupuestos.COD_SERV, Detalle_Presupuestos.DESCRIPCION, "
- L1426 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_28
  SQL: SELECT Presupuestos.NUM_FACT, Presupuestos.FECHA, Detalle_Presupuestos.COD_SERV, Detalle_Presupuestos.DESCRIPCION,
- L1438 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_29
  SQL: SQL = " SELECT ordenes.Num_fact, Ordenes.FECHA, Detalle_Ordenes.COD_SERV, Detalle_Ordenes.DESCRIPCION, "
- L1438 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_30
  SQL: SELECT ordenes.Num_fact, Ordenes.FECHA, Detalle_Ordenes.COD_SERV, Detalle_Ordenes.DESCRIPCION,
- L1450 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_31
  SQL: cr = "SELECT * FROM " & TABLA.Text & " where periodo = '" & FechaDesde.Value & "' and fecha = '" & FechaHasta.Value & "' order by ordinal, periodo"
- L1456 [SELECT] objeto: RESUMENIVA
  SP sugerido: usp_DatQBox_Compras_RESUMENIVA_Get_32
  SQL: SQL = "select TOP 1 PERIODO from ResumenIva"
- L1456 [SELECT] objeto: RESUMENIVA
  SP sugerido: usp_DatQBox_Compras_RESUMENIVA_Get_33
  SQL: select TOP 1 PERIODO from ResumenIva
- L1459 [INSERT] objeto: [RESUMENIVA]
  SP sugerido: usp_DatQBox_Compras_RESUMENIVA_Insert_34
  SQL: SQL = " INSERT INTO [ResumenIva]"
- L1459 [INSERT] objeto: [RESUMENIVA]
  SP sugerido: usp_DatQBox_Compras_RESUMENIVA_Insert_35
  SQL: INSERT INTO [ResumenIva]
- L1460 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_36
  SQL: SQL = SQL & " SELECT"
- L1473 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_37
  SQL: DbConnection.Execute SQL
- L1484 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_38
  SQL: cr = "Select * From " & TABLA & " where " & Busqueda.Text & " >= '" & fdesde & "' and " & Busqueda.Text & " <= '" & fhasta & "' order by " & Busqueda.Text & " desc"
- L1503 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Compras_MOVCUENTAS_Delete_39
  SQL: SQL = " DELETE FROM MOVCUENTAS WHERE NRO_CTA = '" & pRecordset!nro_cta & "' AND NRO_REF = 'APERTURA'"
- L1503 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Compras_MOVCUENTAS_Delete_40
  SQL: DELETE FROM MOVCUENTAS WHERE NRO_CTA = '
- L1506 [INSERT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Compras_MOVCUENTAS_Insert_41
  SQL: SQL = " INSERT INTO MOVCUENTAS (NRO_CTA,TIPO,NRO_REF, INGRESOS,GASTOS,SALDO,BENEFICIARIO,CATEGORIA, CONFIRMADA,FECHA)"
- L1506 [INSERT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Compras_MOVCUENTAS_Insert_42
  SQL: INSERT INTO MOVCUENTAS (NRO_CTA,TIPO,NRO_REF, INGRESOS,GASTOS,SALDO,BENEFICIARIO,CATEGORIA, CONFIRMADA,FECHA)
- L1651 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_43
  SQL: Select Case obj_Field.Type
- L1718 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_44
  SQL: SQL = "SELECT * FROM " & TABLA.Text & " order by fecha desc"
- L1812 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_45
  SQL: SQL = "SELECT * FROM " & TABLA.Text & " where codigo = '" & Me.Tag & "' order by documento"
- L1816 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_46
  SQL: SQL = "SELECT * FROM " & TABLA.Text & " where codigo = '" & Me.Tag & "' and tipo = 'FACT' order by FECHA, documento"
- L1821 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_47
  SQL: SQL = "SELECT * FROM " & TABLA.Text & " order by num_fact"
- L1836 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_48
  SQL: SQL = "SELECT * FROM " & TABLA.Text & " where periodo = '" & FechaDesde.Value & "' and fecha = '" & FechaHasta.Value & "' order by ordinal, periodo"
- L1848 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_49
  SQL: SQL = "SELECT * FROM " & TABLA.Text & " where fecha_pago >= '" & FechaDesde.Value & "' and fecha_Pago <= '" & FechaHasta.Value & "'"
- L1850 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_50
  SQL: 'cr = "SELECT RifAgente, Periodo, Fecha, TipoOper, TipoDocu, Rif_Proveedor, NUM_FACT, NUM_CONTROL, TOTAL, BaseImponible, IvaRetenido, Documento_Afectado, "
- L1866 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_51
  SQL: 'SQL = " SELECT RifAgente, LEFT(REPLACE(CONVERT(VARCHAR(10), FECHA, 111), '/', ''), 6) AS Periodo, RIF AS RifRetenido, COD_OPER AS NumeroFactura, "
- L1869 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_52
  SQL: SQL = " SELECT RifAgente, LEFT(REPLACE(CONVERT(VARCHAR(10), FECHA, 111), '/', ''), 6) AS Periodo, REPLACE(CONVERT(VARCHAR(15), RIF, 1), '-', '') AS RifRetenido,"
- L1889 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_53
  SQL: SQL = "Select Num_fact, Cod_Proveedor, Nombre, Rif, Total from Compras where fechavence = '" & fhasta & "' and cancelada = 'N'"
- L1889 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_54
  SQL: Select Num_fact, Cod_Proveedor, Nombre, Rif, Total from Compras where fechavence = '
- L1894 [SELECT] objeto: ABONOS_DETALLE
  SP sugerido: usp_DatQBox_Compras_ABONOS_DETALLE_Get_55
  SQL: SQL = "Select * from Abonos_Detalle where recnum = '" & Me.Tag & "' "
- L1894 [SELECT] objeto: ABONOS_DETALLE
  SP sugerido: usp_DatQBox_Compras_ABONOS_DETALLE_Get_56
  SQL: Select * from Abonos_Detalle where recnum = '
- L1899 [SELECT] objeto: PAGOS_DETALLE
  SP sugerido: usp_DatQBox_Compras_PAGOS_DETALLE_Get_57
  SQL: SQL = "Select * from Pagos_Detalle where recnum = '" & Me.Tag & "' "
- L1899 [SELECT] objeto: PAGOS_DETALLE
  SP sugerido: usp_DatQBox_Compras_PAGOS_DETALLE_Get_58
  SQL: Select * from Pagos_Detalle where recnum = '
- L1903 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_59
  SQL: SQL = "SELECT * FROM " & TABLA.Text & ""
- L1952 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_60
  SQL: Select Case Col.DataField
- L2084 [SELECT] objeto: CARRERAS
  SP sugerido: usp_DatQBox_Compras_CARRERAS_Get_61
  SQL: '' SQL = "select * from Carreras"
- L2084 [SELECT] objeto: CARRERAS
  SP sugerido: usp_DatQBox_Compras_CARRERAS_Get_62
  SQL: select * from Carreras
- L2221 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Update_63
  SQL: TDBGrid1.Update
- L2450 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_64
  SQL: SQL = "select sum(Iva) as Total_iva, sum(MONTO_EXE) as Total_Exento, sum(monto_gra) as Total_Gravamen, Sum(monto_gra+Monto_exe) as Total_Debitos from Facturas where fecha >= '" & f...
- L2450 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_65
  SQL: select sum(Iva) as Total_iva, sum(MONTO_EXE) as Total_Exento, sum(monto_gra) as Total_Gravamen, Sum(monto_gra+Monto_exe) as Total_Debitos from Facturas where fecha >= '
- L2460 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_Compras_NOTACREDITO_Get_66
  SQL: SQL = "select sum(Iva) as Total_iva, sum(MONTO_EXE) as Total_Exento, sum(monto_gra) as Total_Gravamen, Sum(monto_gra+Monto_exe) as Total_Debitos from NotaCredito where fecha >= '" ...
- L2460 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_Compras_NOTACREDITO_Get_67
  SQL: select sum(Iva) as Total_iva, sum(MONTO_EXE) as Total_Exento, sum(monto_gra) as Total_Gravamen, Sum(monto_gra+Monto_exe) as Total_Debitos from NotaCredito where fecha >= '
- L2470 [UPDATE] objeto: RESUMENIVA
  SP sugerido: usp_DatQBox_Compras_RESUMENIVA_Update_68
  SQL: SQL = " UPDATE RESUMENIVA SET BASEIMPONIBLE = " & Total_Exento & " , IVA = 0 WHERE PERIODO = '" & fdesde & "' AND CAMPO = 'VENTAS_EXENTAS'"
- L2470 [UPDATE] objeto: RESUMENIVA
  SP sugerido: usp_DatQBox_Compras_RESUMENIVA_Update_69
  SQL: UPDATE RESUMENIVA SET BASEIMPONIBLE =
- L2472 [UPDATE] objeto: RESUMENIVA
  SP sugerido: usp_DatQBox_Compras_RESUMENIVA_Update_70
  SQL: SQL = " UPDATE RESUMENIVA SET BASEIMPONIBLE = " & Total_Gravamen & ", IVA = " & Total_iva & " WHERE PERIODO = '" & fdesde & "' AND CAMPO = 'VENTAS_GENERALES'"
- L2474 [UPDATE] objeto: RESUMENIVA
  SP sugerido: usp_DatQBox_Compras_RESUMENIVA_Update_71
  SQL: SQL = " UPDATE RESUMENIVA SET BASEIMPONIBLE = " & Total_Debitos & ", IVA = " & Total_iva & " WHERE PERIODO = '" & fdesde & "' AND CAMPO = 'VENTAS_TOTAL'"
- L2479 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_72
  SQL: SQL = "select sum(Iva) as Total_iva, sum(EXENTO) as Total_Exento, sum(monto_gra) as Total_Gravamen, Sum(monto_gra+EXENTO) as Total_Debitos from COMPRAS where fecha_PAGO >= '" & fde...
- L2479 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_73
  SQL: select sum(Iva) as Total_iva, sum(EXENTO) as Total_Exento, sum(monto_gra) as Total_Gravamen, Sum(monto_gra+EXENTO) as Total_Debitos from COMPRAS where fecha_PAGO >= '
- L2483 [UPDATE] objeto: RESUMENIVA
  SP sugerido: usp_DatQBox_Compras_RESUMENIVA_Update_74
  SQL: SQL = " UPDATE RESUMENIVA SET BASEIMPONIBLE = " & Carreras!Total_Exento & " , IVA = 0 WHERE PERIODO = '" & fdesde & "' AND CAMPO = 'COMPRAS_EXENTAS'"
- L2485 [UPDATE] objeto: RESUMENIVA
  SP sugerido: usp_DatQBox_Compras_RESUMENIVA_Update_75
  SQL: SQL = " UPDATE RESUMENIVA SET BASEIMPONIBLE = " & Carreras!Total_Gravamen & ", IVA = " & Carreras!Total_iva & " WHERE PERIODO = '" & fdesde & "' AND CAMPO = 'COMPRAS_GENERALES'"
- L2487 [UPDATE] objeto: RESUMENIVA
  SP sugerido: usp_DatQBox_Compras_RESUMENIVA_Update_76
  SQL: SQL = " UPDATE RESUMENIVA SET BASEIMPONIBLE = " & Carreras!Total_Debitos & ", IVA = " & Carreras!Total_iva & " WHERE PERIODO = '" & fdesde & "' AND CAMPO = 'COMPRAS_TOTAL'"
- L2496 [SELECT] objeto: [RETENCIONIVAVENTAS]
  SP sugerido: usp_DatQBox_Compras_RETENCIONIVAVENTAS_Get_77
  SQL: SQL = "select sum(Monto_retencion) as Total_Gravamen from [RetencionIvaVentas] where [Fecha_Comprobante] >= '" & fdesde & "' and [Fecha_Comprobante] <= '" & fhasta & "'"
- L2496 [SELECT] objeto: [RETENCIONIVAVENTAS]
  SP sugerido: usp_DatQBox_Compras_RETENCIONIVAVENTAS_Get_78
  SQL: select sum(Monto_retencion) as Total_Gravamen from [RetencionIvaVentas] where [Fecha_Comprobante] >= '
- L2501 [UPDATE] objeto: RESUMENIVA
  SP sugerido: usp_DatQBox_Compras_RESUMENIVA_Update_79
  SQL: SQL = " UPDATE RESUMENIVA SET BASEIMPONIBLE = " & Carreras!Total_Gravamen & ", IVA = 0 WHERE PERIODO = '" & fdesde & "' AND CAMPO = 'RETENCIONES_IVA'"
- L2568 [INSERT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Insert_80
  SQL: SQL = " INSERT INTO " & TABLA.Text & " ( Moneda,Fecha, tasa_compra, tasa_venta)"
- L2569 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_81
  SQL: SQL = SQL & " SELECT moneda, '" & FECHA & "', tasa_compra, tasa_venta "
- L2569 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_82
  SQL: SELECT moneda, '
- L2613 [INSERT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Insert_83
  SQL: SQL = " INSERT INTO " & TABLA.Text & " ( Periodo,Ordinal, Descripcion, BaseImponible, Alicuota, Iva, Fecha, Campo)"
- L2614 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_84
  SQL: SQL = SQL & " SELECT Periodo, Ordinal + '?', Descripcion, BaseImponible, Alicuota, Iva, Fecha, Campo "
- L2614 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_85
  SQL: SELECT Periodo, Ordinal + '?', Descripcion, BaseImponible, Alicuota, Iva, Fecha, Campo
- L2659 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_86
  SQL: SQL = "SELECT * From Facturas WHERE Num_fact = '" & TDBGrid1.Columns("Num_fact").Value & "' and Tipo_Orden = '" & TDBGrid1.Columns("Memoria").Value & "' "
- L2659 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_87
  SQL: SELECT * From Facturas WHERE Num_fact = '
- L2664 [SELECT] objeto: RETENCIONIVAVENTAS
  SP sugerido: usp_DatQBox_Compras_RETENCIONIVAVENTAS_Get_88
  SQL: SQL = "SELECT * From RetencionIvaVentas WHERE Num_fact = '" & TDBGrid1.Columns("Num_fact").Value & "' and memoria = '" & TDBGrid1.Columns("Memoria").Value & "'"
- L2664 [SELECT] objeto: RETENCIONIVAVENTAS
  SP sugerido: usp_DatQBox_Compras_RETENCIONIVAVENTAS_Get_89
  SQL: SELECT * From RetencionIvaVentas WHERE Num_fact = '
- L2720 [SELECT] objeto: BANCOS
  SP sugerido: usp_DatQBox_Compras_BANCOS_Get_90
  SQL: SQL = " Select nombre from Bancos "
- L2720 [SELECT] objeto: BANCOS
  SP sugerido: usp_DatQBox_Compras_BANCOS_Get_91
  SQL: Select nombre from Bancos
- L2730 [SELECT] objeto: MONEDA
  SP sugerido: usp_DatQBox_Compras_MONEDA_Get_92
  SQL: SQL = " Select Nombre from Moneda "
- L2730 [SELECT] objeto: MONEDA
  SP sugerido: usp_DatQBox_Compras_MONEDA_Get_93
  SQL: Select Nombre from Moneda
- L2748 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_94
  SQL: SQL = " Select Num_fact, Fecha,Nombre, Iva, Monto_Gra, Total from Facturas where fecha >= '" & xdesde & "' and fecha <= '" & xhasta & "'"
- L2748 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_95
  SQL: Select Num_fact, Fecha,Nombre, Iva, Monto_Gra, Total from Facturas where fecha >= '

### DatQBox PtoVenta\frmVentasAdd.frm
- L2425 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_PtoVenta_SQL_Exec_1
  SQL: DbConnection.Execute SQL
- L2431 [INSERT] objeto: DETALLE_FORMAPAGOCOMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOCOMPRAS_Insert_2
  SQL: SQL = " INSERT INTO Detalle_FormaPagoCompras"
- L2431 [INSERT] objeto: DETALLE_FORMAPAGOCOMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOCOMPRAS_Insert_3
  SQL: INSERT INTO Detalle_FormaPagoCompras
- L2463 [DELETE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Delete_4
  SQL: SQL = " DELETE FROM dETALLE_" & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' and nota = '" & vMemoria & "' and serialtipo = '" & vSerialFiscal & "'"
- L2463 [DELETE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Delete_5
  SQL: DELETE FROM dETALLE_
- L2494 [INSERT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Insert_6
  SQL: SQL = "INSERT INTO Detalle_" & Tb_Table & " (COMISION, NUM_FACT,SERIALTIPO, COD_SERV, DESCRIPCION, FECHA, CANTIDAD, PRECIO, TOTAL, "
- L2494 [INSERT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Insert_7
  SQL: INSERT INTO Detalle_
- L2511 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_PtoVenta_MOVCUENTAS_Get_8
  SQL: cr = "Select * from MovCuentas where nro_cta = '" & Cuenta & "' and nro_ref = '" & numero & "' "
- L2511 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_PtoVenta_MOVCUENTAS_Get_9
  SQL: Select * from MovCuentas where nro_cta = '
- L2544 [SELECT] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_CHEQUE_Get_10
  SQL: cr = "Select * from detalle_cheque where nro_cta = '" & Cuenta & "' and nro_trans = '" & numero & "' "
- L2544 [SELECT] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_CHEQUE_Get_11
  SQL: Select * from detalle_cheque where nro_cta = '
- L2568 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_PtoVenta_DISTRIBUCION_GASTO_Delete_12
  SQL: cr = "DELETE from Distribucion_gasto where cuenta = '" & Cuenta & "' and numero = '" & numero & "' "
- L2568 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_PtoVenta_DISTRIBUCION_GASTO_Delete_13
  SQL: DELETE from Distribucion_gasto where cuenta = '
- L2569 [EXEC] objeto: CR
  SP sugerido: usp_DatQBox_PtoVenta_CR_Exec_14
  SQL: DbConnection.Execute cr
- L2570 [SELECT] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_PtoVenta_DISTRIBUCION_GASTO_Get_15
  SQL: cr = "Select * from Distribucion_gasto where cuenta = '" & Cuenta & "' and numero = '" & numero & "' "
- L2570 [SELECT] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_PtoVenta_DISTRIBUCION_GASTO_Get_16
  SQL: Select * from Distribucion_gasto where cuenta = '
- L2644 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_17
  SQL: ' SQL = "Select * From Inventario where Codigo = '" & !codigo & "'"
- L2644 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_18
  SQL: Select * From Inventario where Codigo = '
- L2670 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_19
  SQL: SQL = " UPDATE INVENTARIO SET BARRA = '" & barra & "', REFERENCIA = '" & referencias & "' WHERE CODIGO = '" & !Codigo & "' "
- L2670 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_20
  SQL: UPDATE INVENTARIO SET BARRA = '
- L2689 [INSERT] objeto: ETIQUETAS
  SP sugerido: usp_DatQBox_PtoVenta_ETIQUETAS_Insert_21
  SQL: SQL = " INSERT INTO ETIQUETAS (EMPRESA, CODIGO, CodigoEAN13,CodigoEAN8,Codigo39, REFERENCIA,DESCRIPCION,PRECIO,PROVEEDOR,FACTURA,FECHA)"
- L2689 [INSERT] objeto: ETIQUETAS
  SP sugerido: usp_DatQBox_PtoVenta_ETIQUETAS_Insert_22
  SQL: INSERT INTO ETIQUETAS (EMPRESA, CODIGO, CodigoEAN13,CodigoEAN8,Codigo39, REFERENCIA,DESCRIPCION,PRECIO,PROVEEDOR,FACTURA,FECHA)
- L2724 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_23
  SQL: SQL = "select * from " & PrinTabla & " where num_fact = '" & Factur & "' and COD_PROVEEDOR = '" & CODIGOS & "' and clase = '" & Clase.Text & "' "
- L2724 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_24
  SQL: select * from
- L3141 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Get_25
  SQL: SQL = "Select * from clientes where Rif = '" & cliente.Text & "'"
- L3141 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Get_26
  SQL: Select * from clientes where Rif = '
- L3249 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Get_27
  SQL: SQL = " SELECT Sum(P_cobrarC.PEND) AS SumaDePEND From P_cobrarC WHERE P_cobrarC.CODIGO='" & CODIGOS & "' AND P_cobrarC.TIPO='FACT'"
- L3249 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Get_28
  SQL: SELECT Sum(P_cobrarC.PEND) AS SumaDePEND From P_cobrarC WHERE P_cobrarC.CODIGO='
- L3255 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Get_29
  SQL: SQL = " SELECT Sum(P_cobrarC.PEND) AS SumaDePEND From P_cobrarC WHERE P_cobrarC.CODIGO='" & CODIGOS & "' AND P_cobrarC.TIPO='FACT' AND " & XHOY & "-[P_cobrarC].[FECHA]<=30 "
- L3279 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Get_30
  SQL: SQL = " SELECT Sum(P_cobrar.PEND) AS SumaDePEND From P_cobrar WHERE P_cobrar.CODIGO='" & CODIGOS & "' AND P_cobrar.TIPO='FACT'"
- L3279 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Get_31
  SQL: SELECT Sum(P_cobrar.PEND) AS SumaDePEND From P_cobrar WHERE P_cobrar.CODIGO='
- L3285 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Get_32
  SQL: SQL = " SELECT Sum(P_cobrar.PEND) AS SumaDePEND From P_cobrar WHERE P_cobrar.CODIGO='" & CODIGOS & "' AND P_cobrar.TIPO='FACT' AND " & XHOY & "-[P_cobrar].[FECHA]<=30 "
- L3305 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Insert_33
  SQL: SQL = " INSERT INTO P_cobrar ( CODIGO, COD_USUARIO, FECHA, DOCUMENTO, DEBE, PEND, SALDO, TIPO, OBS) "
- L3305 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Insert_34
  SQL: INSERT INTO P_cobrar ( CODIGO, COD_USUARIO, FECHA, DOCUMENTO, DEBE, PEND, SALDO, TIPO, OBS)
- L3311 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_35
  SQL: SQL = " UPDATE CLIENTES SET "
- L3311 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_36
  SQL: UPDATE CLIENTES SET
- L3319 [INSERT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Insert_37
  SQL: SQL = " INSERT INTO P_cobrarC ( CODIGO, COD_USUARIO, FECHA, DOCUMENTO, DEBE, PEND, SALDO, TIPO, OBS) "
- L3319 [INSERT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Insert_38
  SQL: INSERT INTO P_cobrarC ( CODIGO, COD_USUARIO, FECHA, DOCUMENTO, DEBE, PEND, SALDO, TIPO, OBS)
- L3474 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_PtoVenta_MOVIMIENTO_CUENTA_Get_39
  SQL: SQL = "Select * from movimiento_cuenta where cod_oper = '" & NUM_FACT & "' and cod_proveedor = '" & CODIGOS & "' and retiva = 1 "
- L3474 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_PtoVenta_MOVIMIENTO_CUENTA_Get_40
  SQL: Select * from movimiento_cuenta where cod_oper = '
- L3509 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_COMPRAS_Get_41
  SQL: SQL = "Select * from compras where num_fact = '" & NUM_FACT & "' and cod_proveedor = '" & CODIGOS & "' "
- L3509 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_COMPRAS_Get_42
  SQL: Select * from compras where num_fact = '
- L3577 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_PtoVenta_MOVIMIENTO_CUENTA_Get_43
  SQL: SQL = "Select * from movimiento_cuenta where cod_oper = '" & Data3.Recordset!Documento & "' and cod_proveedor = '" & DATA1.Recordset!Codigo & "' and retiva = 1 "
- L3654 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_44
  SQL: TDBGrid6.Update
- L3730 [DELETE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Delete_45
  SQL: SQL = "DELETE from P_cobrar where codigo = '" & CODIGOS & "' AND DOCUMENTO = '" & NUM_FACT & "' "
- L3730 [DELETE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Delete_46
  SQL: DELETE from P_cobrar where codigo = '
- L3733 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_PtoVenta_MOVIMIENTO_CUENTA_Delete_47
  SQL: SQL = "Delete from movimiento_cuenta where cod_oper = '" & NUM_FACT & "' and cod_proveedor = '" & CODIGOS & "'"
- L3733 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_PtoVenta_MOVIMIENTO_CUENTA_Delete_48
  SQL: Delete from movimiento_cuenta where cod_oper = '
- L3736 [DELETE] objeto: ABONOS
  SP sugerido: usp_DatQBox_PtoVenta_ABONOS_Delete_49
  SQL: SQL = " delete from ABONOS where documento = '" & NUM_FACT & "' and codigo = '" & CODIGOS & "' "
- L3736 [DELETE] objeto: ABONOS
  SP sugerido: usp_DatQBox_PtoVenta_ABONOS_Delete_50
  SQL: delete from ABONOS where documento = '
- L3814 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_PtoVenta_MOVCUENTAS_Delete_51
  SQL: SQL = "Delete from movcuentas where nro_ref = '" & TDataLite1.Recordset!numero & "' and nro_cta = '" & TDataLite1.Recordset!Cuenta & "'"
- L3814 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_PtoVenta_MOVCUENTAS_Delete_52
  SQL: Delete from movcuentas where nro_ref = '
- L3817 [DELETE] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_CHEQUE_Delete_53
  SQL: SQL = "Delete from detalle_cheque where nro_trans = '" & TDataLite1.Recordset!numero & "' and nro_cta = '" & TDataLite1.Recordset!Cuenta & "'"
- L3817 [DELETE] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_CHEQUE_Delete_54
  SQL: Delete from detalle_cheque where nro_trans = '
- L3820 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_PtoVenta_MOVIMIENTO_CUENTA_Delete_55
  SQL: SQL = "Delete from movimiento_cuenta where CHEQUE = '" & TDataLite1.Recordset!numero & "' AND cod_oper = '" & TDataLite1.Recordset!numero & "' and cod_cuenta like '*" & TDataLite1....
- L3820 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_PtoVenta_MOVIMIENTO_CUENTA_Delete_56
  SQL: Delete from movimiento_cuenta where CHEQUE = '
- L3823 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_PtoVenta_DISTRIBUCION_GASTO_Delete_57
  SQL: SQL = "Delete from distribucion_gasto where numero = '" & TDataLite1.Recordset!numero & "' AND cuenta = '" & TDataLite1.Recordset!Cuenta & "'"
- L3823 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_PtoVenta_DISTRIBUCION_GASTO_Delete_58
  SQL: Delete from distribucion_gasto where numero = '
- L3840 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Insert_59
  SQL: SQL = " INSERT INTO P_cobrar"
- L3840 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Insert_60
  SQL: INSERT INTO P_cobrar
- L3862 [INSERT] objeto: ABONOS
  SP sugerido: usp_DatQBox_PtoVenta_ABONOS_Insert_61
  SQL: SQL = " INSERT INTO Abonos "
- L3862 [INSERT] objeto: ABONOS
  SP sugerido: usp_DatQBox_PtoVenta_ABONOS_Insert_62
  SQL: INSERT INTO Abonos
- L3880 [INSERT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_PtoVenta_MOVIMIENTO_CUENTA_Insert_63
  SQL: SQL = " INSERT INTO Movimiento_Cuenta "
- L3880 [INSERT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_PtoVenta_MOVIMIENTO_CUENTA_Insert_64
  SQL: INSERT INTO Movimiento_Cuenta
- L3917 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_COMPRAS_Update_65
  SQL: SQL = " UPDATE COMPRAS SET FECHA_PAGO = '" & xFecha & "', CANCELADA = '" & XCANCELADA & "',NRO_COMPROBANTE ='" & RETIVA & "', IVARETENIDO = " & MONTOIVA & " , recnum = '" & RECNUM ...
- L3917 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_COMPRAS_Update_66
  SQL: UPDATE COMPRAS SET FECHA_PAGO = '
- L3922 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_COMPRAS_Update_67
  SQL: SQL = " UPDATE COMPRAS SET FECHA_PAGO = '" & xFecha & "', CANCELADA = '" & XCANCELADA & "', ISRL = '" & RETISLR & "', MONTOISRL = " & Format(MONTOISLR, "#######0.00") & ", CODIGOIS...
- L4006 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_PtoVenta_TASA_MONEDA_Get_68
  SQL: SQL = "Select * from tasa_moneda where Moneda = 'Dollar Us' "
- L4006 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_PtoVenta_TASA_MONEDA_Get_69
  SQL: Select * from tasa_moneda where Moneda = 'Dollar Us'
- L4141 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Delete_70
  SQL: SQL = " DELETE FROM " & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' and serialtipo = '" & vSerialFiscal & "' and tipo_orden = '" & vMemoria & "'"
- L4146 [INSERT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Insert_71
  SQL: SQL = " INSERT INTO " & Tb_Table & ""
- L4268 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_COMPRAS_Get_72
  SQL: SQL = "select * from COMPRAS where num_fact = '" & NUM_FACT & "' and COD_PROVEEDOR = '" & CODIGOS & "' and clase = '" & Clase.Text & "' "
- L4275 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_COMPRAS_Delete_73
  SQL: 'SQL = " DELETE from COMPRAS WHERE NUM_FACT = '" & NUM_FACT & "' AND COD_PROVEEDOR ='" & CODIGOS & "'"
- L4275 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_COMPRAS_Delete_74
  SQL: DELETE from COMPRAS WHERE NUM_FACT = '
- L4276 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_PtoVenta_SQL_Exec_75
  SQL: ' DbConnection.Execute SQL
- L4280 [INSERT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_COMPRAS_Insert_76
  SQL: SQL = " INSERT INTO COMPRAS ( NUM_FACT, COD_PROVEEDOR, NOMBRE, RIF, FECHA, HORA, COD_USUARIO, "
- L4280 [INSERT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_COMPRAS_Insert_77
  SQL: INSERT INTO COMPRAS ( NUM_FACT, COD_PROVEEDOR, NOMBRE, RIF, FECHA, HORA, COD_USUARIO,
- L4304 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_78
  SQL: LeerImagenDB "SELECT * from " & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' AND COD_PROVEEDOR ='" & CODIGOS & "'"
- L4306 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_COMPRAS_Update_79
  SQL: SQL = " UPDATE COMPRAS SET NUM_FACT = '" & NUM_FACT & "', COD_PROVEEDOR = '" & CODIGOS & "', NOMBRE = '" & NOMBRES.Text & "',rif='" & cliente.Text & "' , FECHA = '" & xFecha & "', ...
- L4306 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_COMPRAS_Update_80
  SQL: UPDATE COMPRAS SET NUM_FACT = '
- L4321 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_81
  SQL: GrabarImagenDB "SELECT * from " & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' AND COD_PROVEEDOR ='" & CODIGOS & "'"
- L4350 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_82
  SQL: SQL = "Select * from " & tabla & " where num_fact = '" & NUM_FACT & "' and cod_proveedor = '" & CODIGOS & "' "
- L4412 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_83
  SQL: Select Case KeyAscii
- L4519 [SELECT] objeto: VENDEDOR
  SP sugerido: usp_DatQBox_PtoVenta_VENDEDOR_Get_84
  SQL: SQL = "select * from vendedor "
- L4519 [SELECT] objeto: VENDEDOR
  SP sugerido: usp_DatQBox_PtoVenta_VENDEDOR_Get_85
  SQL: select * from vendedor
- L4850 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_86
  SQL: Select Case Tb_Table
- L5003 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_PtoVenta_TABLA_TEMP_Get_87
  SQL: 'cr = "Select * from tabla_temp where numero = " & Num & ""
- L5003 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_PtoVenta_TABLA_TEMP_Get_88
  SQL: Select * from tabla_temp where numero =
- L5798 [UPDATE] objeto: AS
  SP sugerido: usp_DatQBox_PtoVenta_AS_Update_89
  SQL: Private Sub TDataLite1_DataWrite(Bookmark As Variant, Values As Variant, ByVal NewRow As Boolean, ByVal Update As Boolean, Done As Boolean, Cancel As Boolean)
- L5800 [UPDATE] objeto: THEN
  SP sugerido: usp_DatQBox_PtoVenta_THEN_Update_90
  SQL: If Update Then
- L5894 [SELECT] objeto: RETENCIONES
  SP sugerido: usp_DatQBox_PtoVenta_RETENCIONES_Get_91
  SQL: SQL = " Select Codigo, Descripcion, Porcentaje from retenciones order by Codigo"
- L5894 [SELECT] objeto: RETENCIONES
  SP sugerido: usp_DatQBox_PtoVenta_RETENCIONES_Get_92
  SQL: Select Codigo, Descripcion, Porcentaje from retenciones order by Codigo
- L5899 [SELECT] objeto: CUENTASBANK
  SP sugerido: usp_DatQBox_PtoVenta_CUENTASBANK_Get_93
  SQL: SQL = " Select nro_cta, Descripcion, Banco from cuentasbank order by nro_cta"
- L5899 [SELECT] objeto: CUENTASBANK
  SP sugerido: usp_DatQBox_PtoVenta_CUENTASBANK_Get_94
  SQL: Select nro_cta, Descripcion, Banco from cuentasbank order by nro_cta

### DatQBox PtoVenta\frmControlsPOS.frm
- L1735 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_1
  SQL: Select Case UCase(crParamDef.ParameterFieldName)
- L1798 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_2
  SQL: SQL = " SELECT Facturas.FECHA, Facturas.CODIGO, Facturas.NUM_FACT, Facturas.NOMBRE, Detalle_facturas.CANTIDAD, Detalle_facturas.PRECIO, Facturas.RIF"
- L1798 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_3
  SQL: SELECT Facturas.FECHA, Facturas.CODIGO, Facturas.NUM_FACT, Facturas.NOMBRE, Detalle_facturas.CANTIDAD, Detalle_facturas.PRECIO, Facturas.RIF
- L1873 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_4
  SQL: SQL = "SELECT * FROM INVENTARIO WHERE categoria ='ACEITE' and CODIGO = '" & xArrrayCodigo(i) & "'"
- L1873 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_5
  SQL: SELECT * FROM INVENTARIO WHERE categoria ='ACEITE' and CODIGO = '
- L1975 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_6
  SQL: SQL = "SELECT * FROM INVENTARIO WHERE Eliminado = 0 and CODIGO = '" & xArrrayCodigo(i) & "'"
- L1975 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_7
  SQL: SELECT * FROM INVENTARIO WHERE Eliminado = 0 and CODIGO = '
- L2130 [DELETE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Delete_8
  SQL: SQL = "DELETE from P_cobrar where codigo = '" & CODIGOS & "' and documento = '" & num_fact & "' "
- L2130 [DELETE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Delete_9
  SQL: DELETE from P_cobrar where codigo = '
- L2131 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_PtoVenta_SQL_Exec_10
  SQL: DbConnection.Execute SQL
- L2139 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_11
  SQL: SQL = "UPDATE CLIENTES SET saldo_relacionar = saldo_relacionar - " & Format(total, "########0.00") & ""
- L2139 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_12
  SQL: UPDATE CLIENTES SET saldo_relacionar = saldo_relacionar -
- L2155 [DELETE] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Delete_13
  SQL: SQL = "DELETE from P_cobrarc where codigo = '" & CODIGOS & "' and documento = '" & num_fact & "' "
- L2155 [DELETE] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Delete_14
  SQL: DELETE from P_cobrarc where codigo = '
- L2193 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_15
  SQL: SQL = "select * from " & PrinTabla & " where num_fact = '" & Factur & "' and serialtipo = '" & vSerieFact & "' and TIPO_ORDEN = '" & vMemoria & "'"
- L2193 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_16
  SQL: select * from
- L2243 [SELECT] objeto: VENDEDOR
  SP sugerido: usp_DatQBox_PtoVenta_VENDEDOR_Get_17
  SQL: SQL = "Select * from Vendedor order by CODIGO"
- L2243 [SELECT] objeto: VENDEDOR
  SP sugerido: usp_DatQBox_PtoVenta_VENDEDOR_Get_18
  SQL: Select * from Vendedor order by CODIGO
- L2599 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_PtoVenta_PROVEEDORES_Get_19
  SQL: SQL = "Select * from Proveedores where Rif = '" & cliente.Text & "'"
- L2599 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_PtoVenta_PROVEEDORES_Get_20
  SQL: Select * from Proveedores where Rif = '
- L2601 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Get_21
  SQL: SQL = "Select * from clientes where Rif = '" & cliente.Text & "'"
- L2601 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Get_22
  SQL: Select * from clientes where Rif = '
- L2732 [DELETE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Delete_23
  SQL: SQL = " DELETE FROM dETALLE_" & Tb_Table & " WHERE NUM_FACT = '" & num_fact & "' and nota = '" & vMemoria & "' and serialtipo = '" & vSerieFact & "'"
- L2732 [DELETE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Delete_24
  SQL: DELETE FROM dETALLE_
- L2743 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_25
  SQL: SQL = "Select * From Inventario where eliminado = 0 and Codigo = '" & !referencia & "'"
- L2808 [INSERT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Insert_26
  SQL: SQL = "INSERT INTO Detalle_" & Tb_Table & " ( NUM_FACT,SERIALTIPO, COD_SERV, DESCRIPCION, FECHA, CANTIDAD, PRECIO, TOTAL, "
- L2808 [INSERT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Insert_27
  SQL: INSERT INTO Detalle_
- L2831 [INSERT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_PtoVenta_MOVINVENT_Insert_28
  SQL: SQL = "INSERT INTO MovInvent (PRODUCT,DOCUMENTO,FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CO_USUARIO,PRECIO_COMPRA,ALICUOTA,PRECIO_VENTA)"
- L2831 [INSERT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_PtoVenta_MOVINVENT_Insert_29
  SQL: INSERT INTO MovInvent (PRODUCT,DOCUMENTO,FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CO_USUARIO,PRECIO_COMPRA,ALICUOTA,PRECIO_VENTA)
- L2839 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_30
  SQL: SQL = " UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA - " & !Cantidad & " WHERE CODIGO = '" & !referencia & "'"
- L2839 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_31
  SQL: UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA -
- L2867 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_32
  SQL: SQL = "Select * from " & TABLA & " where num_fact = '" & num_fact & "' and serialtipo = '" & vSerieFact & "' and nota = '" & vMemoria & "'"
- L2916 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Insert_33
  SQL: SQL = " INSERT INTO P_COBRAR (CODIGO,COD_USUARIO,FECHA,DOCUMENTO,DEBE,PEND,SALDO,TIPO) "
- L2916 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Insert_34
  SQL: INSERT INTO P_COBRAR (CODIGO,COD_USUARIO,FECHA,DOCUMENTO,DEBE,PEND,SALDO,TIPO)
- L3100 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_35
  SQL: Select Case Tb_Table
- L3249 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_36
  SQL: SQL = " Update " & ptabla & " set cancelada = 'S', nota = '" & num_fact & "' where num_fact = '" & pnum_Espera & "' and serialtipo = '" & vSerialFiscal & "' and tipo_orden = ' " & ...
- L3334 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Delete_37
  SQL: SQL = " DELETE FROM " & Tb_Table & " WHERE NUM_FACT = '" & num_fact & "' and serialtipo = '" & vSerialFiscal & "' and tipo_orden = '" & vMemoria & "'"
- L3339 [INSERT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Insert_38
  SQL: SQL = " INSERT INTO " & Tb_Table & ""
- L3372 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_39
  SQL: SQL = "UPDATE CLIENTES SET ULTIMAFECHACOMPRA = '" & XFECHA & "' WHERE CODIGO = '" & CODIGOS & "'"
- L3372 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_40
  SQL: UPDATE CLIENTES SET ULTIMAFECHACOMPRA = '
- L3375 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_41
  SQL: '' RecSetClientes.Update
- L3840 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_DEPOSITO_Delete_42
  SQL: SQL = "delete from Detalle_Deposito where cheque = " & RecordFacturas!Cheque & " and banco = '" & RecordFacturas!banco_Cheque & "' and cliente = '" & RecordFacturas!codigo & "'"
- L3840 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_DEPOSITO_Delete_43
  SQL: delete from Detalle_Deposito where cheque =
- L3851 [UPDATE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Update_44
  SQL: SQL = "update detalle_" & Tb_Table & " set anulada = true where num_fact = '" & num_fact & "' AND COD_SERV = '" & TDataLite1.Recordset!codigo & "'"
- L3851 [UPDATE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Update_45
  SQL: update detalle_
- L3855 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_46
  SQL: SQL = " UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA + " & TDataLite1.Recordset!Cantidad & " WHERE CODIGO = '" & TDataLite1.Recordset!codigo & "'"
- L3855 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_47
  SQL: UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA +
- L3886 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_48
  SQL: SQL = "UPDATE " & Tb_Table & " SET ANULADA = 0, Observ = '" & Motivo & "', fechaanulada = '" & XFECHA & "' WHERE NUM_FACT = '" & num_fact & "' and serialtipo = '" & vSerialFiscal &...
- L3889 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_49
  SQL: SQL = "UPDATE " & Tb_Table & " SET ANULADA = 1, Observ = '" & Motivo & "', fechaanulada = '" & XFECHA & "' WHERE NUM_FACT = '" & num_fact & "' " ' and serialtipo = '" & vSerialFisc...
- L3899 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Update_50
  SQL: SQL = "UPDATE facturas SET ANULADA = TRUE, Observ = '" & Motivo & "', fechaanulada = '" & XFECHA & "' WHERE NUM_FACT = '" & num_fact & "' AND PAGO = 'Nota' and serialtipo = '" & vS...
- L3899 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Update_51
  SQL: UPDATE facturas SET ANULADA = TRUE, Observ = '
- L4095 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_52
  SQL: SQL = "SELECT * From Inventario WHERE Eliminado = 0 and Codigo = '" & TDataLite1.Recordset!codigo & "' "
- L4103 [SELECT] objeto: FALLAS
  SP sugerido: usp_DatQBox_PtoVenta_FALLAS_Get_53
  SQL: SQL = "SELECT * From Fallas WHERE Codigo = '" & TDataLite1.Recordset!codigo & "' "
- L4103 [SELECT] objeto: FALLAS
  SP sugerido: usp_DatQBox_PtoVenta_FALLAS_Get_54
  SQL: SELECT * From Fallas WHERE Codigo = '
- L4112 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_55
  SQL: FallasR.Update
- L4194 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_PtoVenta_MOVIMIENTO_CUENTA_Get_56
  SQL: 'SQL = "Select * from movimiento_cuenta where cod_oper = '" & data3.Recordset!Documento & "' and cod_proveedor = '" & data1.Recordset!Codigo & "' and retiva = 1 "
- L4194 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_PtoVenta_MOVIMIENTO_CUENTA_Get_57
  SQL: Select * from movimiento_cuenta where cod_oper = '
- L4213 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_58
  SQL: SQL = "Select * from " & Tb_Table & " where num_fact = '" & num_fact & "' and codigo = '" & CODIGOS & "' "
- L4682 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_PtoVenta_TABLA_TEMP_Get_59
  SQL: 'cr = "Select * from tabla_temp where numero = " & Num & ""
- L4682 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_PtoVenta_TABLA_TEMP_Get_60
  SQL: Select * from tabla_temp where numero =
- L5230 [SELECT] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Get_61
  SQL: SQL = "select * FROM Detalle_FormaPagoFacturas WHERE NUM_FACT = '" & DocActual & "' and MEMORIA = '" & vMemoriaFiscal & "' ;"
- L5230 [SELECT] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Get_62
  SQL: select * FROM Detalle_FormaPagoFacturas WHERE NUM_FACT = '
- L5233 [SELECT] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Get_63
  SQL: SQL = "select * FROM Detalle_FormaPagoFacturas WHERE NUM_FACT = '" & num_fact & "' and MEMORIA = '" & vMemoriaFiscal & "' ;"
- L5581 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Update_64
  SQL: SQL = " UPDATE PEDIDOS SET ANULADA = 0, CANCELADA = 'N' WHERE NUM_FACT = '" & num_fact & "'"
- L5581 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Update_65
  SQL: UPDATE PEDIDOS SET ANULADA = 0, CANCELADA = 'N' WHERE NUM_FACT = '
- L5584 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_66
  SQL: SQL = " Update Inventario"
- L5584 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_67
  SQL: Update Inventario
- L5587 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_68
  SQL: SQL = SQL & " (SELECT Detalle_Pedidos.COD_SERV, SUM([DETALLE_PEDIDOS].[CANTIDAD]) AS TOTAL"
- L5587 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_69
  SQL: (SELECT Detalle_Pedidos.COD_SERV, SUM([DETALLE_PEDIDOS].[CANTIDAD]) AS TOTAL
- L5593 [UPDATE] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_PtoVenta_MOVINVENT_Update_70
  SQL: SQL = " UPDATE MOVINVENT SET ANULADA = 0 WHERE DOCUMENTO = '" & num_fact & "'"
- L5593 [UPDATE] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_PtoVenta_MOVINVENT_Update_71
  SQL: UPDATE MOVINVENT SET ANULADA = 0 WHERE DOCUMENTO = '
- L5841 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_72
  SQL: SQL = "select * from Facturas where num_fact = '" & num_fact & "' and serialtipo = '" & vSerieFact & "' AND Tipo_Orden = '" & vMemoriaFiscal & "'"
- L5841 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_73
  SQL: select * from Facturas where num_fact = '
- L5890 [UPDATE] objeto: AS
  SP sugerido: usp_DatQBox_PtoVenta_AS_Update_74
  SQL: Private Sub TDataLite1_DataWrite(Bookmark As Variant, Values As Variant, ByVal NewRow As Boolean, ByVal Update As Boolean, Done As Boolean, Cancel As Boolean)
- L5892 [UPDATE] objeto: THEN
  SP sugerido: usp_DatQBox_PtoVenta_THEN_Update_75
  SQL: If Update Then
- L6311 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_76
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "=" + Chr(&H2) 'Select the peripheral device.
- L6315 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_77
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L6316 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_78
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L6417 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_79
  SQL: ''sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L6418 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_80
  SQL: ''sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L7353 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_81
  SQL: 'sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L7354 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_82
  SQL: 'sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L7361 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_83
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters
- L8162 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_84
  SQL: SQL = "SELECT * From Inventario WHERE eliminado = 0 and Codigo = '" & TDBGrid1.Columns("referencia").Value & "' "
- L8190 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_85
  SQL: '' SQL = "SELECT * From Inventario WHERE referencia = '" & TDBGrid1.Columns("Codigo").Value & "'"
- L8190 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_86
  SQL: SELECT * From Inventario WHERE referencia = '
- L8194 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_87
  SQL: SQL = "SELECT * From Inventario WHERE eliminado = 0 and Codigo = '" & TDBGrid1.Columns("Codigo").Value & "' or referencia = '" & TDBGrid1.Columns("Codigo").Value & "' "
- L8286 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_88
  SQL: SQL = "SELECT * From Inventario WHERE eliminado = 0 and Codigo = '" & TDBGrid1.Columns("Referencia").Value & "' or referencia = '" & TDBGrid1.Columns("Referencia").Value & "' "
- L8338 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_89
  SQL: TDBGrid1.Update

### DatQBox Compras\frmComprasAdd.frm
- L2363 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_1
  SQL: DbConnection.Execute SQL
- L2369 [INSERT] objeto: DETALLE_FORMAPAGOCOMPRAS
  SP sugerido: usp_DatQBox_Compras_DETALLE_FORMAPAGOCOMPRAS_Insert_2
  SQL: SQL = " INSERT INTO Detalle_FormaPagoCompras"
- L2369 [INSERT] objeto: DETALLE_FORMAPAGOCOMPRAS
  SP sugerido: usp_DatQBox_Compras_DETALLE_FORMAPAGOCOMPRAS_Insert_3
  SQL: INSERT INTO Detalle_FormaPagoCompras
- L2392 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Compras_MOVCUENTAS_Get_4
  SQL: cr = "Select * from MovCuentas where nro_cta = '" & Cuenta & "' and nro_ref = '" & numero & "' "
- L2392 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Compras_MOVCUENTAS_Get_5
  SQL: Select * from MovCuentas where nro_cta = '
- L2425 [SELECT] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Compras_DETALLE_CHEQUE_Get_6
  SQL: cr = "Select * from detalle_cheque where nro_cta = '" & Cuenta & "' and nro_trans = '" & numero & "' "
- L2425 [SELECT] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Compras_DETALLE_CHEQUE_Get_7
  SQL: Select * from detalle_cheque where nro_cta = '
- L2449 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Compras_DISTRIBUCION_GASTO_Delete_8
  SQL: cr = "DELETE from Distribucion_gasto where cuenta = '" & Cuenta & "' and numero = '" & numero & "' "
- L2449 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Compras_DISTRIBUCION_GASTO_Delete_9
  SQL: DELETE from Distribucion_gasto where cuenta = '
- L2450 [EXEC] objeto: CR
  SP sugerido: usp_DatQBox_Compras_CR_Exec_10
  SQL: DbConnection.Execute cr
- L2451 [SELECT] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Compras_DISTRIBUCION_GASTO_Get_11
  SQL: cr = "Select * from Distribucion_gasto where cuenta = '" & Cuenta & "' and numero = '" & numero & "' "
- L2451 [SELECT] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Compras_DISTRIBUCION_GASTO_Get_12
  SQL: Select * from Distribucion_gasto where cuenta = '
- L2525 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_13
  SQL: ' SQL = "Select * From Inventario where Codigo = '" & !codigo & "'"
- L2525 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_14
  SQL: Select * From Inventario where Codigo = '
- L2551 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_15
  SQL: SQL = " UPDATE INVENTARIO SET BARRA = '" & barra & "', REFERENCIA = '" & referencias & "' WHERE CODIGO = '" & !Codigo & "' "
- L2551 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_16
  SQL: UPDATE INVENTARIO SET BARRA = '
- L2570 [INSERT] objeto: ETIQUETAS
  SP sugerido: usp_DatQBox_Compras_ETIQUETAS_Insert_17
  SQL: SQL = " INSERT INTO ETIQUETAS (EMPRESA, CODIGO, CodigoEAN13,CodigoEAN8,Codigo39, REFERENCIA,DESCRIPCION,PRECIO,PROVEEDOR,FACTURA,FECHA)"
- L2570 [INSERT] objeto: ETIQUETAS
  SP sugerido: usp_DatQBox_Compras_ETIQUETAS_Insert_18
  SQL: INSERT INTO ETIQUETAS (EMPRESA, CODIGO, CodigoEAN13,CodigoEAN8,Codigo39, REFERENCIA,DESCRIPCION,PRECIO,PROVEEDOR,FACTURA,FECHA)
- L2605 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_19
  SQL: SQL = "select * from " & PrinTabla & " where num_fact = '" & Factur & "' and COD_PROVEEDOR = '" & CODIGOS & "' and clase = '" & Clase.Text & "' "
- L2605 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_20
  SQL: select * from
- L3022 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Compras_PROVEEDORES_Get_21
  SQL: SQL = "Select * from Proveedores where Rif = '" & cliente.Text & "'"
- L3022 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Compras_PROVEEDORES_Get_22
  SQL: Select * from Proveedores where Rif = '
- L3127 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Get_23
  SQL: SQL = " SELECT Sum(P_PAGAR.PEND) AS SumaDePEND From P_PAGAR WHERE P_PAGAR.CODIGO='" & CODIGOS & "' AND P_PAGAR.TIPO='FACT'"
- L3127 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Get_24
  SQL: SELECT Sum(P_PAGAR.PEND) AS SumaDePEND From P_PAGAR WHERE P_PAGAR.CODIGO='
- L3133 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Get_25
  SQL: SQL = " SELECT Sum(P_PAGAR.PEND) AS SumaDePEND From P_PAGAR WHERE P_PAGAR.CODIGO='" & CODIGOS & "' AND P_PAGAR.TIPO='FACT' AND " & XHOY & "-[P_PAGAR].[FECHA]<=30 "
- L3150 [INSERT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Insert_26
  SQL: SQL = " INSERT INTO P_PAGAR ( CODIGO, COD_USUARIO, FECHA, DOCUMENTO, DEBE, PEND, SALDO, TIPO, PORCENTAJEDESCUENTO, OBS) "
- L3150 [INSERT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Insert_27
  SQL: INSERT INTO P_PAGAR ( CODIGO, COD_USUARIO, FECHA, DOCUMENTO, DEBE, PEND, SALDO, TIPO, PORCENTAJEDESCUENTO, OBS)
- L3156 [UPDATE] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Compras_PROVEEDORES_Update_28
  SQL: SQL = " UPDATE PROVEEDORES SET "
- L3156 [UPDATE] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Compras_PROVEEDORES_Update_29
  SQL: UPDATE PROVEEDORES SET
- L3311 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Get_30
  SQL: SQL = "Select * from movimiento_cuenta where cod_oper = '" & NUM_FACT & "' and cod_proveedor = '" & CODIGOS & "' and retiva = 1 "
- L3311 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Get_31
  SQL: Select * from movimiento_cuenta where cod_oper = '
- L3346 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_32
  SQL: SQL = "Select * from compras where num_fact = '" & NUM_FACT & "' and cod_proveedor = '" & CODIGOS & "' "
- L3346 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_33
  SQL: Select * from compras where num_fact = '
- L3414 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Get_34
  SQL: SQL = "Select * from movimiento_cuenta where cod_oper = '" & Data3.Recordset!Documento & "' and cod_proveedor = '" & DATA1.Recordset!Codigo & "' and retiva = 1 "
- L3491 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Update_35
  SQL: TDBGrid6.Update
- L3567 [DELETE] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Delete_36
  SQL: SQL = "DELETE from P_PAGAR where codigo = '" & CODIGOS & "' AND DOCUMENTO = '" & NUM_FACT & "' "
- L3567 [DELETE] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Delete_37
  SQL: DELETE from P_PAGAR where codigo = '
- L3570 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Delete_38
  SQL: SQL = "Delete from movimiento_cuenta where cod_oper = '" & NUM_FACT & "' and cod_proveedor = '" & CODIGOS & "'"
- L3570 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Delete_39
  SQL: Delete from movimiento_cuenta where cod_oper = '
- L3573 [DELETE] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Delete_40
  SQL: SQL = " delete from ABONOS where documento = '" & NUM_FACT & "' and codigo = '" & CODIGOS & "' "
- L3573 [DELETE] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Delete_41
  SQL: delete from ABONOS where documento = '
- L3651 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Compras_MOVCUENTAS_Delete_42
  SQL: SQL = "Delete from movcuentas where nro_ref = '" & TDataLite1.Recordset!numero & "' and nro_cta = '" & TDataLite1.Recordset!Cuenta & "'"
- L3651 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Compras_MOVCUENTAS_Delete_43
  SQL: Delete from movcuentas where nro_ref = '
- L3654 [DELETE] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Compras_DETALLE_CHEQUE_Delete_44
  SQL: SQL = "Delete from detalle_cheque where nro_trans = '" & TDataLite1.Recordset!numero & "' and nro_cta = '" & TDataLite1.Recordset!Cuenta & "'"
- L3654 [DELETE] objeto: DETALLE_CHEQUE
  SP sugerido: usp_DatQBox_Compras_DETALLE_CHEQUE_Delete_45
  SQL: Delete from detalle_cheque where nro_trans = '
- L3657 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Delete_46
  SQL: SQL = "Delete from movimiento_cuenta where CHEQUE = '" & TDataLite1.Recordset!numero & "' AND cod_oper = '" & TDataLite1.Recordset!numero & "' and cod_cuenta like '*" & TDataLite1....
- L3657 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Delete_47
  SQL: Delete from movimiento_cuenta where CHEQUE = '
- L3660 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Compras_DISTRIBUCION_GASTO_Delete_48
  SQL: SQL = "Delete from distribucion_gasto where numero = '" & TDataLite1.Recordset!numero & "' AND cuenta = '" & TDataLite1.Recordset!Cuenta & "'"
- L3660 [DELETE] objeto: DISTRIBUCION_GASTO
  SP sugerido: usp_DatQBox_Compras_DISTRIBUCION_GASTO_Delete_49
  SQL: Delete from distribucion_gasto where numero = '
- L3677 [INSERT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Insert_50
  SQL: SQL = " INSERT INTO P_Pagar"
- L3677 [INSERT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Insert_51
  SQL: INSERT INTO P_Pagar
- L3699 [INSERT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Insert_52
  SQL: SQL = " INSERT INTO Abonos "
- L3699 [INSERT] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Insert_53
  SQL: INSERT INTO Abonos
- L3717 [INSERT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Insert_54
  SQL: SQL = " INSERT INTO Movimiento_Cuenta "
- L3717 [INSERT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Insert_55
  SQL: INSERT INTO Movimiento_Cuenta
- L3754 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Update_56
  SQL: SQL = " UPDATE COMPRAS SET FECHA_PAGO = '" & xFecha & "', CANCELADA = '" & XCANCELADA & "',NRO_COMPROBANTE ='" & RETIVA & "', IVARETENIDO = " & MONTOIVA & " , recnum = '" & RECNUM ...
- L3754 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Update_57
  SQL: UPDATE COMPRAS SET FECHA_PAGO = '
- L3759 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Update_58
  SQL: SQL = " UPDATE COMPRAS SET FECHA_PAGO = '" & xFecha & "', CANCELADA = '" & XCANCELADA & "', ISRL = '" & RETISLR & "', MONTOISRL = " & Format(MONTOISLR, "#######0.00") & ", CODIGOIS...
- L3842 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Compras_TASA_MONEDA_Get_59
  SQL: SQL = "Select * from tasa_moneda where Moneda = 'Dollar Us' "
- L3842 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Compras_TASA_MONEDA_Get_60
  SQL: Select * from tasa_moneda where Moneda = 'Dollar Us'
- L3989 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_61
  SQL: SQL = "select * from COMPRAS where num_fact = '" & NUM_FACT & "' and COD_PROVEEDOR = '" & CODIGOS & "' and clase = '" & Clase.Text & "' "
- L3996 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Delete_62
  SQL: 'SQL = " DELETE from COMPRAS WHERE NUM_FACT = '" & NUM_FACT & "' AND COD_PROVEEDOR ='" & CODIGOS & "'"
- L3996 [DELETE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Delete_63
  SQL: DELETE from COMPRAS WHERE NUM_FACT = '
- L3997 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_64
  SQL: ' DbConnection.Execute SQL
- L4001 [INSERT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Insert_65
  SQL: SQL = " INSERT INTO COMPRAS ( NUM_FACT, COD_PROVEEDOR, NOMBRE, RIF, FECHA, HORA, COD_USUARIO, "
- L4001 [INSERT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Insert_66
  SQL: INSERT INTO COMPRAS ( NUM_FACT, COD_PROVEEDOR, NOMBRE, RIF, FECHA, HORA, COD_USUARIO,
- L4025 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_67
  SQL: LeerImagenDB "SELECT * from " & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' AND COD_PROVEEDOR ='" & CODIGOS & "'"
- L4027 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Update_68
  SQL: SQL = " UPDATE COMPRAS SET NUM_FACT = '" & NUM_FACT & "', COD_PROVEEDOR = '" & CODIGOS & "', NOMBRE = '" & NOMBRES.Text & "',rif='" & cliente.Text & "' , FECHA = '" & xFecha & "', ...
- L4027 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Update_69
  SQL: UPDATE COMPRAS SET NUM_FACT = '
- L4042 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_70
  SQL: GrabarImagenDB "SELECT * from " & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' AND COD_PROVEEDOR ='" & CODIGOS & "'"
- L4071 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_71
  SQL: SQL = "Select * from " & tabla & " where num_fact = '" & NUM_FACT & "' and cod_proveedor = '" & CODIGOS & "' "
- L4133 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_72
  SQL: Select Case KeyAscii
- L4555 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_73
  SQL: Select Case Tb_Table
- L4708 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_Compras_TABLA_TEMP_Get_74
  SQL: 'cr = "Select * from tabla_temp where numero = " & Num & ""
- L4708 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_Compras_TABLA_TEMP_Get_75
  SQL: Select * from tabla_temp where numero =
- L5226 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_76
  SQL: SQL = " SELECT * from COMPRAS WHERE NUM_FACT = '" & NUM_FACT & "' AND COD_PROVEEDOR ='" & CODIGOS & "' "
- L5514 [UPDATE] objeto: AS
  SP sugerido: usp_DatQBox_Compras_AS_Update_77
  SQL: Private Sub TDataLite1_DataWrite(Bookmark As Variant, Values As Variant, ByVal NewRow As Boolean, ByVal Update As Boolean, Done As Boolean, Cancel As Boolean)
- L5516 [UPDATE] objeto: THEN
  SP sugerido: usp_DatQBox_Compras_THEN_Update_78
  SQL: If Update Then
- L5610 [SELECT] objeto: RETENCIONES
  SP sugerido: usp_DatQBox_Compras_RETENCIONES_Get_79
  SQL: SQL = " Select Codigo, Descripcion, Porcentaje from retenciones order by Codigo"
- L5610 [SELECT] objeto: RETENCIONES
  SP sugerido: usp_DatQBox_Compras_RETENCIONES_Get_80
  SQL: Select Codigo, Descripcion, Porcentaje from retenciones order by Codigo
- L5615 [SELECT] objeto: CUENTASBANK
  SP sugerido: usp_DatQBox_Compras_CUENTASBANK_Get_81
  SQL: SQL = " Select nro_cta, Descripcion, Banco from cuentasbank order by nro_cta"
- L5615 [SELECT] objeto: CUENTASBANK
  SP sugerido: usp_DatQBox_Compras_CUENTASBANK_Get_82
  SQL: Select nro_cta, Descripcion, Banco from cuentasbank order by nro_cta

### DatQBox Compras\frmCompras.frm
- L1898 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_1
  SQL: ' SQL = "Select * From Inventario where Codigo = '" & !codigo & "'"
- L1898 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_2
  SQL: Select * From Inventario where Codigo = '
- L1924 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_3
  SQL: SQL = " UPDATE INVENTARIO SET BARRA = '" & barra & "', REFERENCIA = '" & referencias & "' WHERE CODIGO = '" & !codigo & "' "
- L1924 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_4
  SQL: UPDATE INVENTARIO SET BARRA = '
- L1927 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_5
  SQL: DbConnection.Execute SQL
- L1943 [INSERT] objeto: ETIQUETAS
  SP sugerido: usp_DatQBox_Compras_ETIQUETAS_Insert_6
  SQL: SQL = " INSERT INTO ETIQUETAS (EMPRESA, CODIGO, CodigoEAN13,CodigoEAN8,Codigo39, REFERENCIA,DESCRIPCION,PRECIO,PROVEEDOR,FACTURA,FECHA)"
- L1943 [INSERT] objeto: ETIQUETAS
  SP sugerido: usp_DatQBox_Compras_ETIQUETAS_Insert_7
  SQL: INSERT INTO ETIQUETAS (EMPRESA, CODIGO, CodigoEAN13,CodigoEAN8,Codigo39, REFERENCIA,DESCRIPCION,PRECIO,PROVEEDOR,FACTURA,FECHA)
- L1978 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_8
  SQL: SQL = "select * from " & PrinTabla & " where num_fact = '" & Factur & "' and COD_PROVEEDOR = '" & CODIGOS & "' "
- L1978 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_9
  SQL: select * from
- L2320 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Update_10
  SQL: TDataLite1.Recordset.Update
- L2491 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Compras_PROVEEDORES_Get_11
  SQL: SQL = "Select * from Proveedores where Rif = '" & cliente.Text & "'"
- L2491 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Compras_PROVEEDORES_Get_12
  SQL: Select * from Proveedores where Rif = '
- L2594 [DELETE] objeto: ETIQUETAS
  SP sugerido: usp_DatQBox_Compras_ETIQUETAS_Delete_13
  SQL: DbConnection.Execute "Delete from etiquetas"
- L2594 [DELETE] objeto: ETIQUETAS
  SP sugerido: usp_DatQBox_Compras_ETIQUETAS_Delete_14
  SQL: Delete from etiquetas
- L2599 [DELETE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Compras_DETALLE_Delete_15
  SQL: DbConnection.Execute "DELETE FROM Detalle_" & Tb_Table & " WHERE COD_PROVEEDOR = '" & CODIGOS & "' AND NUM_FACT = '" & NUM_FACT & "'"
- L2599 [DELETE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Compras_DETALLE_Delete_16
  SQL: DELETE FROM Detalle_
- L2609 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_17
  SQL: SQL = "Select * From Inventario where Eliminado = 0 and Codigo = '" & !codigo & "'"
- L2609 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_18
  SQL: Select * From Inventario where Eliminado = 0 and Codigo = '
- L2640 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Get_19
  SQL: SQL = " SELECT SUM(EXISTENCIA_ACTUAL) AS NEGATIVOS FROM Detalle_iNVENTARIO "
- L2640 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Get_20
  SQL: SELECT SUM(EXISTENCIA_ACTUAL) AS NEGATIVOS FROM Detalle_iNVENTARIO
- L2656 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Update_21
  SQL: SQL = " UPDATE DETALLE_INVENTARIO SET EXISTENCIA_ACTUAL = 0 "
- L2656 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Update_22
  SQL: UPDATE DETALLE_INVENTARIO SET EXISTENCIA_ACTUAL = 0
- L2668 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Get_23
  SQL: SQL = " SELECT * FROM Detalle_iNVENTARIO "
- L2668 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Get_24
  SQL: SELECT * FROM Detalle_iNVENTARIO
- L2675 [INSERT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Insert_25
  SQL: SQL = " INSERT INTO Detalle_iNVENTARIO"
- L2675 [INSERT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Insert_26
  SQL: INSERT INTO Detalle_iNVENTARIO
- L2694 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Update_27
  SQL: SQL = " UPDATE Detalle_iNVENTARIO SET "
- L2694 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Update_28
  SQL: UPDATE Detalle_iNVENTARIO SET
- L2720 [INSERT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Compras_DETALLE_Insert_29
  SQL: SQL = " INSERT INTO Detalle_" & Tb_Table & " ( NUM_FACT, CODIGO, Referencia, COD_PROVEEDOR, DESCRIPCION, Und, FECHA, CANTIDAD,"
- L2720 [INSERT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Compras_DETALLE_Insert_30
  SQL: INSERT INTO Detalle_
- L2739 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_31
  SQL: SQL = " UPDATE INVENTARIO SET "
- L2739 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_32
  SQL: UPDATE INVENTARIO SET
- L2764 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_33
  SQL: SQL = " UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA - " & !cantidad & " WHERE CODIGO = '" & !codigo & "'"
- L2764 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_34
  SQL: UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA -
- L2770 [INSERT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Compras_MOVINVENT_Insert_35
  SQL: SQL = "INSERT INTO MovInvent (DOCUMENTO,CODIGO,PRODUCT, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CO_USUARIO, PRECIO_COMPRA,Precio_venta,cantidad_nueva,Alicuota)"
- L2770 [INSERT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Compras_MOVINVENT_Insert_36
  SQL: INSERT INTO MovInvent (DOCUMENTO,CODIGO,PRODUCT, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CO_USUARIO, PRECIO_COMPRA,Precio_venta,cantidad_nueva,Alicuota)
- L2794 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_37
  SQL: "SELECT [CODIGO], [CATEGORIA], [EXISTENCIA], [LINEA], [DESCRIPCION], [CLASE], [MARCA], [PRECIO_VENTA] " & _
- L2794 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_38
  SQL: SELECT [CODIGO], [CATEGORIA], [EXISTENCIA], [LINEA], [DESCRIPCION], [CLASE], [MARCA], [PRECIO_VENTA]
- L2800 [UPDATE] objeto: SET
  SP sugerido: usp_DatQBox_Compras_SET_Update_39
  SQL: " UPDATE SET " & _
- L2842 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_40
  SQL: SQL = "Select * from " & TABLA & " where num_fact = '" & NUM_FACT & "' and cod_proveedor = '" & CODIGOS & "' "
- L2906 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Get_41
  SQL: SQL = "SELECT * from P_PAGAR where codigo = '" & CODIGOS & "' AND DOCUMENTO = '" & NUM_FACT & "' AND TIPO <>'FACT' "
- L2906 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Get_42
  SQL: SELECT * from P_PAGAR where codigo = '
- L2927 [DELETE] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Delete_43
  SQL: SQL = "DELETE from P_PAGAR where codigo = '" & CODIGOS & "' AND DOCUMENTO = '" & NUM_FACT & "' AND TIPO ='FACT' "
- L2927 [DELETE] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Delete_44
  SQL: DELETE from P_PAGAR where codigo = '
- L2931 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Get_45
  SQL: SQL = " SELECT Sum(P_PAGAR.PEND) AS SumaDePEND From P_PAGAR WHERE P_PAGAR.CODIGO='" & CODIGOS & "' AND P_PAGAR.TIPO='FACT'"
- L2931 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Get_46
  SQL: SELECT Sum(P_PAGAR.PEND) AS SumaDePEND From P_PAGAR WHERE P_PAGAR.CODIGO='
- L2937 [SELECT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Get_47
  SQL: SQL = " SELECT Sum(P_PAGAR.PEND) AS SumaDePEND From P_PAGAR WHERE P_PAGAR.CODIGO='" & CODIGOS & "' AND P_PAGAR.TIPO='FACT' AND " & XHOY & "-[P_PAGAR].[FECHA]<=30 "
- L2952 [INSERT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Insert_48
  SQL: SQL = " INSERT INTO P_PAGAR ( CODIGO, COD_USUARIO, FECHA, DOCUMENTO, DEBE, PEND, SALDO, TIPO, PORCENTAJEDESCUENTO) "
- L2952 [INSERT] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Insert_49
  SQL: INSERT INTO P_PAGAR ( CODIGO, COD_USUARIO, FECHA, DOCUMENTO, DEBE, PEND, SALDO, TIPO, PORCENTAJEDESCUENTO)
- L2957 [UPDATE] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Compras_PROVEEDORES_Update_50
  SQL: SQL = " UPDATE PROVEEDORES SET "
- L2957 [UPDATE] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Compras_PROVEEDORES_Update_51
  SQL: UPDATE PROVEEDORES SET
- L3065 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Get_52
  SQL: 'SQL = "Select * from movimiento_cuenta where cod_oper = '" & data3.Recordset!Documento & "' and cod_proveedor = '" & data1.Recordset!Codigo & "' and retiva = 1 "
- L3065 [SELECT] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Get_53
  SQL: Select * from movimiento_cuenta where cod_oper = '
- L3084 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_54
  SQL: SQL = "Select * from " & Tb_Table & " where num_fact = '" & NUM_FACT & "' and cod_PROVEEDOR = '" & CODIGOS & "' "
- L3126 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_55
  SQL: Select Case UCase(crParamDef.ParameterFieldName)
- L3258 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Compras_TASA_MONEDA_Get_56
  SQL: 'SQL = "Select * from tasa_moneda where Moneda = 'Dollar Us' "
- L3258 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Compras_TASA_MONEDA_Get_57
  SQL: Select * from tasa_moneda where Moneda = 'Dollar Us'
- L3261 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Compras_TASA_MONEDA_Get_58
  SQL: SQL = "SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_compra, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE "
- L3261 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Compras_TASA_MONEDA_Get_59
  SQL: SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_compra, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE
- L3289 [SELECT] objeto: ALMACEN
  SP sugerido: usp_DatQBox_Compras_ALMACEN_Get_60
  SQL: SQL = "Select Descripcion from almacen"
- L3289 [SELECT] objeto: ALMACEN
  SP sugerido: usp_DatQBox_Compras_ALMACEN_Get_61
  SQL: Select Descripcion from almacen
- L3363 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_62
  SQL: SQL = " SELECT * from " & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' AND COD_PROVEEDOR ='" & CODIGOS & "' "
- L3450 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_63
  SQL: LeerImagenDB "SELECT * from " & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' AND COD_PROVEEDOR ='" & CODIGOS & "'"
- L3451 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_64
  SQL: ' GrabarImagenDB "SELECT * from " & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' AND COD_PROVEEDOR ='" & CODIGOS & "'"
- L3452 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_65
  SQL: SQL = "SELECT * from " & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' AND COD_PROVEEDOR ='" & CODIGOS & "' AND CLASE <> 'NOTA CREDITO'"
- L3476 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Delete_66
  SQL: SQL = " DELETE from " & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' AND COD_PROVEEDOR ='" & CODIGOS & "' AND CLASE <> 'NOTA CREDITO'"
- L3481 [INSERT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Insert_67
  SQL: SQL = " INSERT INTO " & Tb_Table & " (ALMACEN, NUM_FACT, COD_PROVEEDOR, NOMBRE, RIF, FECHA, HORA, COD_USUARIO, "
- L3501 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_68
  SQL: GrabarImagenDB "SELECT * from " & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' AND COD_PROVEEDOR ='" & CODIGOS & "'"
- L3537 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_69
  SQL: Select Case KeyAscii
- L3881 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_70
  SQL: vReporte.Tag = "SELECT * FROM COMPRAS WHERE NUM_FACT = '" & NUM_FACT & "' AND COD_PROVEEDOR = '" & CODIGOS & "'"
- L3881 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_71
  SQL: SELECT * FROM COMPRAS WHERE NUM_FACT = '
- L4091 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_72
  SQL: Select Case Tb_Table
- L4244 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_Compras_TABLA_TEMP_Get_73
  SQL: 'cr = "Select * from tabla_temp where numero = " & Num & ""
- L4244 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_Compras_TABLA_TEMP_Get_74
  SQL: Select * from tabla_temp where numero =
- L5084 [UPDATE] objeto: AS
  SP sugerido: usp_DatQBox_Compras_AS_Update_75
  SQL: Private Sub TDataLite1_DataWrite(Bookmark As Variant, Values As Variant, ByVal NewRow As Boolean, ByVal Update As Boolean, Done As Boolean, Cancel As Boolean)
- L5086 [UPDATE] objeto: THEN
  SP sugerido: usp_DatQBox_Compras_THEN_Update_76
  SQL: If Update Then
- L5126 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_77
  SQL: SQL = "SELECT * From Inventario WHERE eliminado = 0 and referencia = '" & TDBGrid1.Columns("Codigo").Value & "'"
- L5126 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_78
  SQL: SELECT * From Inventario WHERE eliminado = 0 and referencia = '
- L5130 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_79
  SQL: SQL = "SELECT * From Inventario WHERE Eliminado = 0 and Codigo = '" & TDBGrid1.Columns("Codigo").Value & "' "

### DatQBox Admin\frmDocumentos.frm
- L1561 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_1
  SQL: SQL = " SELECT Facturas.FECHA, Facturas.CODIGO, Facturas.NUM_FACT, Facturas.NOMBRE, Detalle_facturas.CANTIDAD, Detalle_facturas.PRECIO, Facturas.RIF"
- L1561 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_2
  SQL: SELECT Facturas.FECHA, Facturas.CODIGO, Facturas.NUM_FACT, Facturas.NOMBRE, Detalle_facturas.CANTIDAD, Detalle_facturas.PRECIO, Facturas.RIF
- L1635 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Get_3
  SQL: SQL = "SELECT * FROM INVENTARIO WHERE CODIGO = '" & xArrrayCodigo(i) & "'"
- L1635 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Get_4
  SQL: SELECT * FROM INVENTARIO WHERE CODIGO = '
- L1675 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Get_5
  SQL: SQL = "select * from P_cobrar where codigo = '" & CODIGOS & "' and documento = '" & NUM_FACT & "'"
- L1675 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Get_6
  SQL: select * from P_cobrar where codigo = '
- L1684 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_7
  SQL: 'Pcobrar.Update
- L1686 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Get_8
  SQL: cr = "select * from P_cobrar where codigo = '" & CODIGOS & "' "
- L1733 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Get_9
  SQL: ' cr = "Select * From Clientes where codigo = '" & Codigo & "' "
- L1733 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Get_10
  SQL: Select * From Clientes where codigo = '
- L1745 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_11
  SQL: RecSetClientes.Update
- L1749 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Get_12
  SQL: 'cr = "Select * From Clientes where codigo = '" & Codigo & "' "
- L1770 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Get_13
  SQL: SQL = "select * from P_cobrarC where codigo = '" & CODIGOS & "' and documento = '" & NUM_FACT & "'"
- L1770 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Get_14
  SQL: select * from P_cobrarC where codigo = '
- L1780 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_Admin_P_COBRARC_Get_15
  SQL: cr = "select * from P_cobrarC where codigo = '" & CODIGOS & "' "
- L1860 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_16
  SQL: SQL = "select * from " & PrinTabla & " where num_fact = '" & FactuR & "' and serialtipo = '" & vSerialFiscal & "'"
- L1860 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_17
  SQL: select * from
- L1899 [SELECT] objeto: VENDEDOR
  SP sugerido: usp_DatQBox_Admin_VENDEDOR_Get_18
  SQL: SQL = "Select * from Vendedor order by CODIGO"
- L1899 [SELECT] objeto: VENDEDOR
  SP sugerido: usp_DatQBox_Admin_VENDEDOR_Get_19
  SQL: Select * from Vendedor order by CODIGO
- L2194 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Admin_PROVEEDORES_Get_20
  SQL: SQL = "Select * from Proveedores where Rif = '" & cliente.Text & "'"
- L2194 [SELECT] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_Admin_PROVEEDORES_Get_21
  SQL: Select * from Proveedores where Rif = '
- L2196 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Get_22
  SQL: SQL = "Select * from clientes where Rif = '" & cliente.Text & "'"
- L2196 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Get_23
  SQL: Select * from clientes where Rif = '
- L2323 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Get_24
  SQL: SQL = "Select * From Inventario where Codigo = '" & !referencia & "'"
- L2355 [INSERT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Admin_DETALLE_Insert_25
  SQL: SQL = "INSERT INTO Detalle_" & Tb_Table & " ( NUM_FACT,SERIALTIPO, COD_SERV, DESCRIPCION, FECHA, CANTIDAD, PRECIO, TOTAL, "
- L2355 [INSERT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Admin_DETALLE_Insert_26
  SQL: INSERT INTO Detalle_
- L2359 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Admin_SQL_Exec_27
  SQL: DbConnection.Execute SQL
- L2372 [INSERT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Admin_MOVINVENT_Insert_28
  SQL: SQL = "INSERT INTO MovInvent (PRODUCT,DOCUMENTO,FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CO_USUARIO,PRECIO_COMPRA,ALICUOTA,PRECIO_VENTA)"
- L2372 [INSERT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Admin_MOVINVENT_Insert_29
  SQL: INSERT INTO MovInvent (PRODUCT,DOCUMENTO,FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CO_USUARIO,PRECIO_COMPRA,ALICUOTA,PRECIO_VENTA)
- L2378 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Update_30
  SQL: SQL = " UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA - " & !CANTIDAD & " WHERE CODIGO = '" & !referencia & "'"
- L2378 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Update_31
  SQL: UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA -
- L2406 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_32
  SQL: SQL = "Select * from " & tabla & " where num_fact = '" & NUM_FACT & "' and serialtipo = '" & vSerialFiscal & "' "
- L2456 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_Admin_P_COBRAR_Get_33
  SQL: SQL = "select * from P_cobrar where codigo = '" & CODIGOS & "' "
- L2474 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_34
  SQL: Pcobrar.Update
- L2603 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_35
  SQL: Select Case Tb_Table
- L2654 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_36
  SQL: SQL = " Update " & ptabla & " set cancelada = 'S', nota = '" & NUM_FACT & "' where num_fact = '" & pnum_Espera & "' and serialtipo = '" & vSerialFiscal & "'"
- L2728 [INSERT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Insert_37
  SQL: SQL = " INSERT INTO " & Tb_Table & ""
- L2795 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Update_38
  SQL: SQL = "UPDATE CLIENTES SET ULTIMAFECHACOMPRA = '" & XFECHA & "' WHERE CODIGO = '" & CODIGOS & "'"
- L2795 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Update_39
  SQL: UPDATE CLIENTES SET ULTIMAFECHACOMPRA = '
- L2798 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_40
  SQL: '' RecSetClientes.Update
- L3189 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_Admin_DETALLE_DEPOSITO_Delete_41
  SQL: SQL = "delete from Detalle_Deposito where cheque = " & RecordFacturas!Cheque & " and banco = '" & RecordFacturas!banco_Cheque & "' and cliente = '" & RecordFacturas!Codigo & "'"
- L3189 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_Admin_DETALLE_DEPOSITO_Delete_42
  SQL: delete from Detalle_Deposito where cheque =
- L3200 [UPDATE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Admin_DETALLE_Update_43
  SQL: SQL = "update detalle_" & Tb_Table & " set anulada = true where num_fact = '" & NUM_FACT & "' AND COD_SERV = '" & TDataLite1.Recordset!Codigo & "'"
- L3200 [UPDATE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Admin_DETALLE_Update_44
  SQL: update detalle_
- L3204 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Update_45
  SQL: SQL = " UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA + " & TDataLite1.Recordset!CANTIDAD & " WHERE CODIGO = '" & TDataLite1.Recordset!Codigo & "'"
- L3204 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Update_46
  SQL: UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA +
- L3235 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_47
  SQL: SQL = "UPDATE " & Tb_Table & " SET ANULADA = 0, Observ = '" & Motivo & "', fechaanulada = '" & XFECHA & "' WHERE NUM_FACT = '" & NUM_FACT & "' and serialtipo = '" & vSerialFiscal &...
- L3238 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_48
  SQL: SQL = "UPDATE " & Tb_Table & " SET ANULADA = " & VALNULL & ", Observ = '" & Motivo & "', fechaanulada = '" & XFECHA & "' WHERE NUM_FACT = '" & NUM_FACT & "' and serialtipo = '" & v...
- L3248 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Update_49
  SQL: SQL = "UPDATE facturas SET ANULADA = TRUE, Observ = '" & Motivo & "', fechaanulada = '" & XFECHA & "' WHERE NUM_FACT = '" & NUM_FACT & "' AND PAGO = 'Nota' and serialtipo = '" & vS...
- L3248 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Update_50
  SQL: UPDATE facturas SET ANULADA = TRUE, Observ = '
- L3409 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Get_51
  SQL: SQL = "SELECT * From Inventario WHERE Codigo = '" & TDataLite1.Recordset!Codigo & "' "
- L3417 [SELECT] objeto: FALLAS
  SP sugerido: usp_DatQBox_Admin_FALLAS_Get_52
  SQL: SQL = "SELECT * From Fallas WHERE Codigo = '" & TDataLite1.Recordset!Codigo & "' "
- L3417 [SELECT] objeto: FALLAS
  SP sugerido: usp_DatQBox_Admin_FALLAS_Get_53
  SQL: SELECT * From Fallas WHERE Codigo = '
- L3426 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_54
  SQL: FallasR.Update
- L3808 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_Admin_TABLA_TEMP_Get_55
  SQL: 'cr = "Select * from tabla_temp where numero = " & Num & ""
- L3808 [SELECT] objeto: TABLA_TEMP
  SP sugerido: usp_DatQBox_Admin_TABLA_TEMP_Get_56
  SQL: Select * from tabla_temp where numero =
- L4324 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_Admin_PEDIDOS_Update_57
  SQL: SQL = " UPDATE PEDIDOS SET ANULADA = 0, CANCELADA = 'N' WHERE NUM_FACT = '" & NUM_FACT & "'"
- L4324 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_Admin_PEDIDOS_Update_58
  SQL: UPDATE PEDIDOS SET ANULADA = 0, CANCELADA = 'N' WHERE NUM_FACT = '
- L4327 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Update_59
  SQL: SQL = " Update Inventario"
- L4327 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Update_60
  SQL: Update Inventario
- L4330 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_61
  SQL: SQL = SQL & " (SELECT Detalle_Pedidos.COD_SERV, SUM([DETALLE_PEDIDOS].[CANTIDAD]) AS TOTAL"
- L4330 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_62
  SQL: (SELECT Detalle_Pedidos.COD_SERV, SUM([DETALLE_PEDIDOS].[CANTIDAD]) AS TOTAL
- L4336 [UPDATE] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Admin_MOVINVENT_Update_63
  SQL: SQL = " UPDATE MOVINVENT SET ANULADA = 0 WHERE DOCUMENTO = '" & NUM_FACT & "'"
- L4336 [UPDATE] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Admin_MOVINVENT_Update_64
  SQL: UPDATE MOVINVENT SET ANULADA = 0 WHERE DOCUMENTO = '
- L4470 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_65
  SQL: SQL = "select * from Facturas where num_fact = '" & NUM_FACT & "'"
- L4470 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_66
  SQL: select * from Facturas where num_fact = '
- L4509 [UPDATE] objeto: AS
  SP sugerido: usp_DatQBox_Admin_AS_Update_67
  SQL: Private Sub TDataLite1_DataWrite(Bookmark As Variant, Values As Variant, ByVal NewRow As Boolean, ByVal Update As Boolean, Done As Boolean, Cancel As Boolean)
- L4511 [UPDATE] objeto: THEN
  SP sugerido: usp_DatQBox_Admin_THEN_Update_68
  SQL: If Update Then
- L4563 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_69
  SQL: sWrittenData = Chr(&H1B) + "=" + Chr(&H2) 'Select the peripheral device.
- L4564 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_70
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L4565 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_71
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L4789 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Get_72
  SQL: SQL = "SELECT * From Inventario WHERE Codigo = '" & TDBGrid1.Columns("referencia").Value & "' "
- L4815 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Get_73
  SQL: '' SQL = "SELECT * From Inventario WHERE referencia = '" & TDBGrid1.Columns("Codigo").Value & "'"
- L4815 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Get_74
  SQL: SELECT * From Inventario WHERE referencia = '
- L4819 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Admin_INVENTARIO_Get_75
  SQL: SQL = "SELECT * From Inventario WHERE Codigo = '" & TDBGrid1.Columns("Codigo").Value & "' or referencia = '" & TDBGrid1.Columns("Codigo").Value & "' "
- L4899 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_76
  SQL: TDBGrid1.Update

### DatQBox PtoVenta\Sanjose.bas
- L77 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_1
  SQL: Select Case Err
- L192 [SELECT] objeto: BLOQUE
  SP sugerido: usp_DatQBox_PtoVenta_BLOQUE_Get_2
  SQL: cr = " Select * from Bloque where fecha = '" & FECHA & "' order by fecha" ' and Pago = 'Efectivo' order by fecha"
- L192 [SELECT] objeto: BLOQUE
  SP sugerido: usp_DatQBox_PtoVenta_BLOQUE_Get_3
  SQL: Select * from Bloque where fecha = '
- L295 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_4
  SQL: cr = " Select * from facturas where fecha = '" & FECHA & "' and Pago = 'Efectivo' and ( cheque > 0 or tarjeta <> '0' ) order by num_fact"
- L295 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_5
  SQL: Select * from facturas where fecha = '
- L297 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_6
  SQL: cr = " Select * from facturas where COD_USUARIO = '" & COD_USUARIO & "' AND fecha = '" & FECHA & "' and Pago = 'Efectivo' and ( cheque > 0 or tarjeta <> '0' ) order by num_fact"
- L297 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_7
  SQL: Select * from facturas where COD_USUARIO = '
- L420 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_8
  SQL: cr = " Select * from facturas where fecha = '" & FECHA & "' and Pago = 'Efectivo' AND MONTO_EFECT > 0 order by num_fact"
- L554 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_9
  SQL: cr = " Select * from FACTURAS where nro_retencion <> '0' and fecha = '" & FECHA & "' order by num_fact"
- L554 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_10
  SQL: Select * from FACTURAS where nro_retencion <> '0' and fecha = '
- L667 [SELECT] objeto: PRESUPUESTOS
  SP sugerido: usp_DatQBox_PtoVenta_PRESUPUESTOS_Get_11
  SQL: cr = " Select * from Presupuestos where fecha = '" & FECHA & "' and Locacion = 'PREFACTURA' order by num_fact"
- L667 [SELECT] objeto: PRESUPUESTOS
  SP sugerido: usp_DatQBox_PtoVenta_PRESUPUESTOS_Get_12
  SQL: Select * from Presupuestos where fecha = '
- L794 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_13
  SQL: cr = " Select * from facturas where fecha = '" & FECHA & "' and Pago = 'Efectivo' and Cancelada = 'N' order by num_fact"
- L915 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_14
  SQL: cr = " SELECT P_CobrarC.FECHA, P_CobrarC.Pago, P_CobrarC.TIPO, P_CobrarC.HABER AS TOTAL, Clientes.NOMBRE, P_CobrarC.DOCUMENTO AS NUM_FACT"
- L915 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_15
  SQL: SELECT P_CobrarC.FECHA, P_CobrarC.Pago, P_CobrarC.TIPO, P_CobrarC.HABER AS TOTAL, Clientes.NOMBRE, P_CobrarC.DOCUMENTO AS NUM_FACT
- L920 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_16
  SQL: ' cr = " SELECT PagosC.FECHA, PagosC.Pago, PagosC.TIPO, Pagosc.aplicado AS TOTAL, Clientes.NOMBRE, Pagosc.DOCUMENTO AS NUM_FACT"
- L920 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_17
  SQL: SELECT PagosC.FECHA, PagosC.Pago, PagosC.TIPO, Pagosc.aplicado AS TOTAL, Clientes.NOMBRE, Pagosc.DOCUMENTO AS NUM_FACT
- L1040 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_18
  SQL: cr = " Select * from facturas where Pago = 'Credito' and Locacion = 'Compañia' and fecha = '" & FECHA & "' order by num_fact"
- L1040 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_19
  SQL: Select * from facturas where Pago = 'Credito' and Locacion = 'Compañia' and fecha = '
- L1131 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_20
  SQL: cr = " Select * from facturas where Pago = 'Credito' and Locacion = 'Particular' and fecha = '" & FECHA & "' order by num_fact"
- L1131 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_21
  SQL: Select * from facturas where Pago = 'Credito' and Locacion = 'Particular' and fecha = '
- L1235 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_22
  SQL: cr = " SELECT P_Cobrar.FECHA, P_Cobrar.Pago, P_Cobrar.TIPO, P_Cobrar.HABER AS TOTAL, Clientes.NOMBRE, P_Cobrar.DOCUMENTO AS NUM_FACT"
- L1235 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_23
  SQL: SELECT P_Cobrar.FECHA, P_Cobrar.Pago, P_Cobrar.TIPO, P_Cobrar.HABER AS TOTAL, Clientes.NOMBRE, P_Cobrar.DOCUMENTO AS NUM_FACT
- L1239 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_24
  SQL: ' cr = " SELECT Pagos.FECHA, Pagos.Pago, Pagos.TIPO, Pagos.aplicado AS TOTAL, Clientes.NOMBRE, Pagos.DOCUMENTO AS NUM_FACT"
- L1239 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_25
  SQL: SELECT Pagos.FECHA, Pagos.Pago, Pagos.TIPO, Pagos.aplicado AS TOTAL, Clientes.NOMBRE, Pagos.DOCUMENTO AS NUM_FACT
- L1350 [SELECT] objeto: GASTOS
  SP sugerido: usp_DatQBox_PtoVenta_GASTOS_Get_26
  SQL: cr = " Select * from gastos where fecha = '" & FECHA & "' order by num_fact"
- L1350 [SELECT] objeto: GASTOS
  SP sugerido: usp_DatQBox_PtoVenta_GASTOS_Get_27
  SQL: Select * from gastos where fecha = '
- L1453 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_28
  SQL: cr = " SELECT * "
- L2157 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_29
  SQL: cr = " SELECT Sum(Facturas.Monto_gra) AS Contado From Facturas where Facturas.FECHA>='" & ini & "' And Facturas.FECHA<='" & fin & "' "
- L2157 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_30
  SQL: SELECT Sum(Facturas.Monto_gra) AS Contado From Facturas where Facturas.FECHA>='
- L2175 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_31
  SQL: cr = " SELECT Sum(Cotizacion.Total) AS Contado From Cotizacion where cotizacion.FECHA>='" & ini & "' And cotizacion.FECHA<='" & fin & "' and ISDATE(cotizacion.FECHAANULADA) = 0 "
- L2175 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_32
  SQL: SELECT Sum(Cotizacion.Total) AS Contado From Cotizacion where cotizacion.FECHA>='
- L2194 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_33
  SQL: cr = " SELECT Sum(monto_gra) AS Contado From facturas where FECHAANULADA>='" & ini & "' And FECHAANULADA<='" & fin & "' "
- L2194 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_34
  SQL: SELECT Sum(monto_gra) AS Contado From facturas where FECHAANULADA>='
- L2196 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_35
  SQL: 'cr = " SELECT Sum(notacredito.TOTAL) AS Contado From notacredito where notacredito.FECHA>='" & ini & "' And notacredito.FECHA<='" & fin & "' "
- L2196 [SELECT] objeto: NOTACREDITO
  SP sugerido: usp_DatQBox_PtoVenta_NOTACREDITO_Get_36
  SQL: SELECT Sum(notacredito.TOTAL) AS Contado From notacredito where notacredito.FECHA>='
- L2219 [SELECT] objeto: BLOQUE
  SP sugerido: usp_DatQBox_PtoVenta_BLOQUE_Get_37
  SQL: cr = " SELECT Sum(TOTAL) AS Contado From bloque where FECHA>='" & ini & "' And FECHA<='" & fin & "' "
- L2219 [SELECT] objeto: BLOQUE
  SP sugerido: usp_DatQBox_PtoVenta_BLOQUE_Get_38
  SQL: SELECT Sum(TOTAL) AS Contado From bloque where FECHA>='
- L2237 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_39
  SQL: ' cr = " SELECT Sum(Facturas.TOTAL) AS Contado From Facturas where Facturas.FECHAANULADA = null AND Facturas.PAGO='Efectivo' and facturas.cancelada = 'S' and FECHA>='" & ini & "' A...
- L2237 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_40
  SQL: SELECT Sum(Facturas.TOTAL) AS Contado From Facturas where Facturas.FECHAANULADA = null AND Facturas.PAGO='Efectivo' and facturas.cancelada = 'S' and FECHA>='
- L2241 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_41
  SQL: cr = " SELECT Sum(Facturas.Monto_gra) AS Contado From Facturas where ISDATE(FECHAANULADA) = 0 AND Facturas.PAGO='Efectivo' and facturas.cancelada = 'N' and FECHA>='" & ini & "' And...
- L2241 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_42
  SQL: SELECT Sum(Facturas.Monto_gra) AS Contado From Facturas where ISDATE(FECHAANULADA) = 0 AND Facturas.PAGO='Efectivo' and facturas.cancelada = 'N' and FECHA>='
- L2261 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_43
  SQL: cr = " SELECT Sum(Facturas.Monto_gra) AS Credito From Facturas where Facturas.PAGO='Credito' AND Facturas.FECHA>='" & ini & "' And Facturas.FECHA<='" & fin & "' AND ISDATE(FECHAANU...
- L2261 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_44
  SQL: SELECT Sum(Facturas.Monto_gra) AS Credito From Facturas where Facturas.PAGO='Credito' AND Facturas.FECHA>='
- L2298 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Get_45
  SQL: cr = " SELECT Sum(P_cobrar.haber ) AS pagos From P_Cobrar WHERE P_Cobrar.FECHA>='" & ini & "' And P_Cobrar.FECHA<='" & fin & "' and tipo ='PAGO'"
- L2298 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Get_46
  SQL: SELECT Sum(P_cobrar.haber ) AS pagos From P_Cobrar WHERE P_Cobrar.FECHA>='
- L2313 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Get_47
  SQL: cr = " SELECT Sum(P_cobrarc.haber ) AS pagos From P_Cobrarc WHERE P_Cobrarc.FECHA>='" & ini & "' And P_Cobrarc.FECHA<='" & fin & "' and tipo ='PAGO'"
- L2313 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Get_48
  SQL: SELECT Sum(P_cobrarc.haber ) AS pagos From P_Cobrarc WHERE P_Cobrarc.FECHA>='
- L2385 [SELECT] objeto: EMPLEADOS
  SP sugerido: usp_DatQBox_PtoVenta_EMPLEADOS_Get_49
  SQL: cr = "Select * from empleados where status = 'A' order by comision desc"
- L2385 [SELECT] objeto: EMPLEADOS
  SP sugerido: usp_DatQBox_PtoVenta_EMPLEADOS_Get_50
  SQL: Select * from empleados where status = 'A' order by comision desc
- L2494 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_51
  SQL: SQL = " SELECT libroFacturas.NUM_FACT, libroFacturas.Num_Control, libroFacturas.PAGO, libroFacturas.MONTO_EXE, libroFacturas.MONTO_GRA, libroFacturas.IVA, libroFacturas.ANULADA, li...
- L2494 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_52
  SQL: SELECT libroFacturas.NUM_FACT, libroFacturas.Num_Control, libroFacturas.PAGO, libroFacturas.MONTO_EXE, libroFacturas.MONTO_GRA, libroFacturas.IVA, libroFacturas.ANULADA, libroFactu...
- L2545 [SELECT] objeto: REPORTEZ
  SP sugerido: usp_DatQBox_PtoVenta_REPORTEZ_Get_53
  SQL: SQL = "Select * from ReporteZ where fecha = '" & FECHA & "'"
- L2545 [SELECT] objeto: REPORTEZ
  SP sugerido: usp_DatQBox_PtoVenta_REPORTEZ_Get_54
  SQL: Select * from ReporteZ where fecha = '
- L2558 [INSERT] objeto: LIBROFACTRESUM
  SP sugerido: usp_DatQBox_PtoVenta_LIBROFACTRESUM_Insert_55
  SQL: SQL = " INSERT INTO LibroFactResum ( NUM_FACT, NUM_FIN, ReporteZ, CantOper, "
- L2558 [INSERT] objeto: LIBROFACTRESUM
  SP sugerido: usp_DatQBox_PtoVenta_LIBROFACTRESUM_Insert_56
  SQL: INSERT INTO LibroFactResum ( NUM_FACT, NUM_FIN, ReporteZ, CantOper,
- L2565 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_PtoVenta_SQL_Exec_57
  SQL: DbConnection.Execute SQL
- L2635 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_58
  SQL: SQL = " SELECT libroFacturasHist.NUM_FACT, libroFacturasHist.Num_Control, libroFacturasHist.PAGO, libroFacturasHist.MONTO_EXE, libroFacturasHist.MONTO_GRA, libroFacturasHist.IVA, l...
- L2635 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_59
  SQL: SELECT libroFacturasHist.NUM_FACT, libroFacturasHist.Num_Control, libroFacturasHist.PAGO, libroFacturasHist.MONTO_EXE, libroFacturasHist.MONTO_GRA, libroFacturasHist.IVA, libroFact...
- L2698 [INSERT] objeto: LIBROFACTRESUMHIST
  SP sugerido: usp_DatQBox_PtoVenta_LIBROFACTRESUMHIST_Insert_60
  SQL: SQL = " INSERT INTO LibroFactResumHist (Fecha_libro,Hora_libro, Desde, Hasta, NUM_FACT, NUM_FIN, ReporteZ, CantOper, "
- L2698 [INSERT] objeto: LIBROFACTRESUMHIST
  SP sugerido: usp_DatQBox_PtoVenta_LIBROFACTRESUMHIST_Insert_61
  SQL: INSERT INTO LibroFactResumHist (Fecha_libro,Hora_libro, Desde, Hasta, NUM_FACT, NUM_FIN, ReporteZ, CantOper,
- L2757 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_62
  SQL: Select Case Trim(Left(Right(palabra, Len(palabra) - Len(ArrayParamName(j))), Len(Right(palabra, Len(palabra) - Len(ArrayParamName(j)))) - 1))
- L2782 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_63
  SQL: Select Case UCase(ArrayParamName(i))
- L2812 [EXEC] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Exec_64
  SQL: mobjCmd.Execute

### DatQBox Compras\frmInventarioAux.frm
- L1525 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_1
  SQL: Select Case obj_Field.Type
- L1550 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_2
  SQL: SQL = " Select Inventario.Codigo,Inventario.PLU, Inventario.Referencia,Inventario.Fecha, Inventario.Linea, Inventario.Categoria, Inventario.Tipo, Inventario.Descripcion, Inventario...
- L1550 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_3
  SQL: Select Inventario.Codigo,Inventario.PLU, Inventario.Referencia,Inventario.Fecha, Inventario.Linea, Inventario.Categoria, Inventario.Tipo, Inventario.Descripcion, Inventario.Marca, ...
- L1557 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_4
  SQL: SQL = " SELECT Inventario.Porcentaje,Inventario.Porcentaje1,Inventario.Porcentaje2,Inventario.Porcentaje3, Inventario.Costo_Promedio, Inventario.Costo_Referencia, Inventario.Descue...
- L1557 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_5
  SQL: SELECT Inventario.Porcentaje,Inventario.Porcentaje1,Inventario.Porcentaje2,Inventario.Porcentaje3, Inventario.Costo_Promedio, Inventario.Costo_Referencia, Inventario.Descuento_Comp...
- L1638 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_6
  SQL: SQL = " SELECT Inventario.Categoria, MovInvent.Product,"
- L1638 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_7
  SQL: SELECT Inventario.Categoria, MovInvent.Product,
- L1698 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_8
  SQL: SQL = " SELECT '0' as acceso, LEFT( dbo.Inventario.categoria + ' ' + dbo.Inventario.tipo + ' ' + dbo.Inventario.descripcion,20) as nombre,"
- L1698 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_9
  SQL: SELECT '0' as acceso, LEFT( dbo.Inventario.categoria + ' ' + dbo.Inventario.tipo + ' ' + dbo.Inventario.descripcion,20) as nombre,
- L1804 [DELETE] objeto: INVENTARIO_AUX
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_AUX_Delete_10
  SQL: SQL = SQL & " delete From inventario_aux"
- L1804 [DELETE] objeto: INVENTARIO_AUX
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_AUX_Delete_11
  SQL: delete From inventario_aux
- L1811 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_12
  SQL: DbConnection.Execute SQL
- L1813 [DELETE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Delete_13
  SQL: ' SQL = SQL & " delete From DETALLE_inventario"
- L1813 [DELETE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Delete_14
  SQL: delete From DETALLE_inventario
- L1815 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_15
  SQL: ' DbConnection.Execute SQL
- L1865 [INSERT] objeto: INVENTARIO_AUX
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_AUX_Insert_16
  SQL: SQL = "INSERT INTO Inventario_aux (" & _
- L1865 [INSERT] objeto: INVENTARIO_AUX
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_AUX_Insert_17
  SQL: INSERT INTO Inventario_aux (
- L1867 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_18
  SQL: "SELECT " & _
- L1903 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_19
  SQL: SQL1 = " UPDATE INVENTARIO SET EXISTENCIA = x.SCantidad "
- L1903 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_20
  SQL: UPDATE INVENTARIO SET EXISTENCIA = x.SCantidad
- L1906 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Get_21
  SQL: SQL1 = SQL1 & " (SELECT CODIGO, Sum(Detalle_Inventario.EXISTENCIA_ACTUAL) AS SCantidad FROM Detalle_Inventario GROUP BY CODIGO ) as X ON (INVENTARIO.CODIGO = X.codigo )"
- L1906 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Get_22
  SQL: (SELECT CODIGO, Sum(Detalle_Inventario.EXISTENCIA_ACTUAL) AS SCantidad FROM Detalle_Inventario GROUP BY CODIGO ) as X ON (INVENTARIO.CODIGO = X.codigo )
- L1911 [EXEC] objeto: SQL1
  SP sugerido: usp_DatQBox_Compras_SQL1_Exec_23
  SQL: DbConnection.Execute SQL1
- L1965 [SELECT] objeto: DETALLE_COMPRAS
  SP sugerido: usp_DatQBox_Compras_DETALLE_COMPRAS_Get_24
  SQL: SQL = "Select * from detalle_compras where Num_fact = '" & Trim(pRecordset!Documento) & "' and codigo = '" & pRecordset!Product & "' and Fecha >= '" & fdesde & "' and Fecha <= '" &...
- L1965 [SELECT] objeto: DETALLE_COMPRAS
  SP sugerido: usp_DatQBox_Compras_DETALLE_COMPRAS_Get_25
  SQL: Select * from detalle_compras where Num_fact = '
- L1973 [SELECT] objeto: DETALLE_PEDIDOS
  SP sugerido: usp_DatQBox_Compras_DETALLE_PEDIDOS_Get_26
  SQL: 'SQL = "Select * from detalle_pedidos where Num_fact = '" & Trim(pRecordset!Documento) & "' and cod_serv = '" & pRecordset!Product & "' "
- L1973 [SELECT] objeto: DETALLE_PEDIDOS
  SP sugerido: usp_DatQBox_Compras_DETALLE_PEDIDOS_Get_27
  SQL: Select * from detalle_pedidos where Num_fact = '
- L1976 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_28
  SQL: SQL = " SELECT Detalle_facturas.Id, Detalle_facturas.NUM_FACT, Detalle_facturas.SERIALTIPO, Detalle_facturas.COD_SERV, Detalle_facturas.DESCRIPCION,"
- L1976 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_29
  SQL: SELECT Detalle_facturas.Id, Detalle_facturas.NUM_FACT, Detalle_facturas.SERIALTIPO, Detalle_facturas.COD_SERV, Detalle_facturas.DESCRIPCION,
- L2001 [SELECT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_Compras_DETALLE_FACTURAS_Get_30
  SQL: SQL = "Select * from detalle_Facturas where Num_fact = '" & Trim(pRecordset!Documento) & "' and cod_serv = '" & pRecordset!Product & "' and Detalle_facturas.Fecha >= '" & fdesde & ...
- L2001 [SELECT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_Compras_DETALLE_FACTURAS_Get_31
  SQL: Select * from detalle_Facturas where Num_fact = '
- L2057 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_32
  SQL: Select Case Col.DataField
- L2264 [SELECT] objeto: ALMACEN
  SP sugerido: usp_DatQBox_Compras_ALMACEN_Get_33
  SQL: data5.RecordSource = "Select Descripcion from almacen"
- L2264 [SELECT] objeto: ALMACEN
  SP sugerido: usp_DatQBox_Compras_ALMACEN_Get_34
  SQL: Select Descripcion from almacen
- L2297 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_35
  SQL: SQL = "SELECT [ID], [CODIGO],[LINEA], [CATEGORIA], [DESCRIPCION], " & _
- L2297 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_36
  SQL: SELECT [ID], [CODIGO],[LINEA], [CATEGORIA], [DESCRIPCION],
- L2342 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_37
  SQL: SQL = "SELECT inventario_aux.CATEGORIA, MovInvent.Product, "
- L2342 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_38
  SQL: SELECT inventario_aux.CATEGORIA, MovInvent.Product,
- L2400 [SELECT] objeto: [HOJA1
  SP sugerido: usp_DatQBox_Compras_HOJA1_Get_39
  SQL: strQuery = "SELECT * FROM [Hoja1$]" ' Asume que tus datos están en Sheet1, ajusta si es necesario
- L2400 [SELECT] objeto: [HOJA1
  SP sugerido: usp_DatQBox_Compras_HOJA1_Get_40
  SQL: SELECT * FROM [Hoja1$]
- L2407 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_41
  SQL: strSQL = "IF NOT EXISTS (SELECT * FROM " & dbName & ".INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Inventario_Aux') " & _
- L2407 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_42
  SQL: IF NOT EXISTS (SELECT * FROM
- L2422 [EXEC] objeto: STRSQL
  SP sugerido: usp_DatQBox_Compras_STRSQL_Exec_43
  SQL: DbConnection.Execute strSQL
- L2428 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_44
  SQL: strSQL = "IF NOT EXISTS (SELECT * FROM " & dbName & ".INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inventario_Aux' AND COLUMN_NAME = '" & strColName & "') " & _
- L2438 [EXEC] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Exec_45
  SQL: 'strSQL = "EXEC " & dbName & ".dbo.spImportarDesdeExcelDinamico @filePath = '" & strExcelFile & "', @sheetName = 'Hoja1'"
- L2439 [EXEC] objeto: STRSQL
  SP sugerido: usp_DatQBox_Compras_STRSQL_Exec_46
  SQL: 'DbConnection.Execute strSQL
- L2447 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_47
  SQL: "USING (SELECT ? AS CATEGORIA, ? AS CANTIDAD, ? AS LINEA, ? AS CODIGO, ? AS DESCRIPCION, ? AS CLASE, ? AS MARCA, ? AS PRECIO, ? AS COSTO) AS source " & _
- L2447 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_48
  SQL: USING (SELECT ? AS CATEGORIA, ? AS CANTIDAD, ? AS LINEA, ? AS CODIGO, ? AS DESCRIPCION, ? AS CLASE, ? AS MARCA, ? AS PRECIO, ? AS COSTO) AS source
- L2450 [UPDATE] objeto: SET
  SP sugerido: usp_DatQBox_Compras_SET_Update_49
  SQL: "UPDATE SET " & _
- L2553 [SELECT] objeto: TIPOS
  SP sugerido: usp_DatQBox_Compras_TIPOS_Get_50
  SQL: SQL = " Select nombre from tipos where categoria = '" & TDBGrid1.Columns("Categoria").Value & "'"
- L2553 [SELECT] objeto: TIPOS
  SP sugerido: usp_DatQBox_Compras_TIPOS_Get_51
  SQL: Select nombre from tipos where categoria = '
- L2563 [SELECT] objeto: CATEGORIA
  SP sugerido: usp_DatQBox_Compras_CATEGORIA_Get_52
  SQL: SQL = " Select Nombre from categoria "
- L2563 [SELECT] objeto: CATEGORIA
  SP sugerido: usp_DatQBox_Compras_CATEGORIA_Get_53
  SQL: Select Nombre from categoria
- L2573 [SELECT] objeto: CLASES
  SP sugerido: usp_DatQBox_Compras_CLASES_Get_54
  SQL: SQL = " Select Descripcion from Clases "
- L2573 [SELECT] objeto: CLASES
  SP sugerido: usp_DatQBox_Compras_CLASES_Get_55
  SQL: Select Descripcion from Clases
- L2582 [SELECT] objeto: MARCAS
  SP sugerido: usp_DatQBox_Compras_MARCAS_Get_56
  SQL: SQL = " Select Descripcion from Marcas "
- L2582 [SELECT] objeto: MARCAS
  SP sugerido: usp_DatQBox_Compras_MARCAS_Get_57
  SQL: Select Descripcion from Marcas
- L2591 [SELECT] objeto: LINEAS
  SP sugerido: usp_DatQBox_Compras_LINEAS_Get_58
  SQL: SQL = " Select Descripcion from LINEAS "
- L2591 [SELECT] objeto: LINEAS
  SP sugerido: usp_DatQBox_Compras_LINEAS_Get_59
  SQL: Select Descripcion from LINEAS

### DatQBox PtoVenta\Winapis.bas
- L1187 [SELECT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Get_1
  SQL: cr = " Select * from Detalle_Facturas where fecha >= " & fecha & " and fecha <= " & Fecha1 & " AND (DESCRIPCION LIKE '*ALINEACION*' OR DESCRIPCION LIKE '*TRICA*' OR DESCRIPCION LIK...
- L1187 [SELECT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Get_2
  SQL: Select * from Detalle_Facturas where fecha >=
- L1188 [UPDATE] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Update_3
  SQL: SQL = "Update detalle_facturas set relacionada = false where fecha >= " & fecha & " and fecha <= " & Fecha1 & " AND (DESCRIPCION LIKE '*ALINEACION*' OR DESCRIPCION LIKE '*TRICA*' O...
- L1188 [UPDATE] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Update_4
  SQL: Update detalle_facturas set relacionada = false where fecha >=
- L1189 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_PtoVenta_SQL_Exec_5
  SQL: GSJoseDb.Execute SQL
- L1229 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_6
  SQL: ' Facturas.Update
- L1232 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_7
  SQL: cr = " Select * from Facturas where num_fact >= '" & facturas!num_fact & "' "
- L1232 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_8
  SQL: Select * from Facturas where num_fact >= '
- L1306 [SELECT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FACTURAS_Get_9
  SQL: 'cr = " Select * from Detalle_Facturas where fecha >= " & Fecha & " and fecha <= " & Fecha1 & " AND (DESCRIPCION LIKE '*ALINEACION*' OR DESCRIPCION LIKE '*TRICA*' OR DESCRIPCION LI...
- L1307 [SELECT] objeto: DETALLE_NOTA
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_NOTA_Get_10
  SQL: cr = " Select * from Detalle_nota where fecha >= " & fecha & " and fecha <= " & Fecha1 & " AND (DESCRIPCION LIKE '*ALINEACION*' OR DESCRIPCION LIKE '*TRICA*' OR DESCRIPCION LIKE '*...
- L1307 [SELECT] objeto: DETALLE_NOTA
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_NOTA_Get_11
  SQL: Select * from Detalle_nota where fecha >=
- L1308 [UPDATE] objeto: DETALLE_NOTA
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_NOTA_Update_12
  SQL: SQL = "Update detalle_nota set relacionada = false where fecha >= " & fecha & " and fecha <= " & Fecha1 & " AND (DESCRIPCION LIKE '*ALINEACION*' OR DESCRIPCION LIKE '*TRICA*' OR DE...
- L1308 [UPDATE] objeto: DETALLE_NOTA
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_NOTA_Update_13
  SQL: Update detalle_nota set relacionada = false where fecha >=
- L1349 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_14
  SQL: facturas.Update
- L1540 [SELECT] objeto: BLOQUE
  SP sugerido: usp_DatQBox_PtoVenta_BLOQUE_Get_15
  SQL: cr = " Select * from Bloque where fecha = " & fecha & " order by fecha" ' and Pago = 'Efectivo' order by fecha"
- L1540 [SELECT] objeto: BLOQUE
  SP sugerido: usp_DatQBox_PtoVenta_BLOQUE_Get_16
  SQL: Select * from Bloque where fecha =
- L1638 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_17
  SQL: cr = " Select * from facturas where fecha = " & fecha & " and Pago = 'Efectivo' and ( cheque > 0 or tarjeta <> '0' ) order by num_fact"
- L1638 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_18
  SQL: Select * from facturas where fecha =
- L1760 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_19
  SQL: cr = " Select * from facturas where fecha = " & fecha & " and Pago = 'Efectivo' AND MONTO_EFECT > 0 order by num_fact"
- L1894 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_20
  SQL: cr = " Select * from FACTURAS where nro_retencion <> '0' and fecha = " & fecha & " order by num_fact"
- L1894 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_21
  SQL: Select * from FACTURAS where nro_retencion <> '0' and fecha =
- L2006 [SELECT] objeto: PRESUPUESTOS
  SP sugerido: usp_DatQBox_PtoVenta_PRESUPUESTOS_Get_22
  SQL: cr = " Select * from Presupuestos where fecha = " & fecha & " and Locacion = 'PREFACTURA' order by num_fact"
- L2006 [SELECT] objeto: PRESUPUESTOS
  SP sugerido: usp_DatQBox_PtoVenta_PRESUPUESTOS_Get_23
  SQL: Select * from Presupuestos where fecha =
- L2131 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_24
  SQL: cr = " Select * from facturas where fecha = " & fecha & " and Pago = 'Efectivo' and Cancelada = 'N' order by num_fact"
- L2250 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_25
  SQL: cr = " SELECT P_CobrarC.FECHA, P_CobrarC.Pago, P_CobrarC.TIPO, P_CobrarC.HABER AS TOTAL, Clientes.NOMBRE, P_CobrarC.DOCUMENTO AS NUM_FACT"
- L2250 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_26
  SQL: SELECT P_CobrarC.FECHA, P_CobrarC.Pago, P_CobrarC.TIPO, P_CobrarC.HABER AS TOTAL, Clientes.NOMBRE, P_CobrarC.DOCUMENTO AS NUM_FACT
- L2255 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_27
  SQL: ' cr = " SELECT PagosC.FECHA, PagosC.Pago, PagosC.TIPO, Pagosc.aplicado AS TOTAL, Clientes.NOMBRE, Pagosc.DOCUMENTO AS NUM_FACT"
- L2255 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_28
  SQL: SELECT PagosC.FECHA, PagosC.Pago, PagosC.TIPO, Pagosc.aplicado AS TOTAL, Clientes.NOMBRE, Pagosc.DOCUMENTO AS NUM_FACT
- L2378 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_29
  SQL: cr = " Select * from facturas where Pago = 'Credito' and Locacion like 'Comp*' and fecha = " & fecha & " order by num_fact"
- L2378 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_30
  SQL: Select * from facturas where Pago = 'Credito' and Locacion like 'Comp*' and fecha =
- L2467 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_31
  SQL: cr = " Select * from facturas where Pago = 'Credito' and Locacion like 'Particular*' and fecha = " & fecha & " order by num_fact"
- L2467 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_32
  SQL: Select * from facturas where Pago = 'Credito' and Locacion like 'Particular*' and fecha =
- L2572 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_33
  SQL: cr = " SELECT P_Cobrar.FECHA, P_Cobrar.Pago, P_Cobrar.TIPO, P_Cobrar.HABER AS TOTAL, Clientes.NOMBRE, P_Cobrar.DOCUMENTO AS NUM_FACT"
- L2572 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_34
  SQL: SELECT P_Cobrar.FECHA, P_Cobrar.Pago, P_Cobrar.TIPO, P_Cobrar.HABER AS TOTAL, Clientes.NOMBRE, P_Cobrar.DOCUMENTO AS NUM_FACT
- L2576 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_35
  SQL: ' cr = " SELECT Pagos.FECHA, Pagos.Pago, Pagos.TIPO, Pagos.aplicado AS TOTAL, Clientes.NOMBRE, Pagos.DOCUMENTO AS NUM_FACT"
- L2576 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_36
  SQL: SELECT Pagos.FECHA, Pagos.Pago, Pagos.TIPO, Pagos.aplicado AS TOTAL, Clientes.NOMBRE, Pagos.DOCUMENTO AS NUM_FACT
- L2689 [SELECT] objeto: GASTOS
  SP sugerido: usp_DatQBox_PtoVenta_GASTOS_Get_37
  SQL: cr = " Select * from gastos where fecha = " & fecha & " order by num_fact"
- L2689 [SELECT] objeto: GASTOS
  SP sugerido: usp_DatQBox_PtoVenta_GASTOS_Get_38
  SQL: Select * from gastos where fecha =
- L2791 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_39
  SQL: cr = " SELECT * "
- L4778 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_40
  SQL: cr = " Select * from facturas where fecha = " & fecha & " and Pago = 'Efectivo' order by num_fact"
- L4901 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_41
  SQL: cr = " Select * from facturas where Pago = 'Credito' and fecha = " & fecha & " order by num_fact"
- L4901 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_42
  SQL: Select * from facturas where Pago = 'Credito' and fecha =
- L5282 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_43
  SQL: Select Case Month(fecha)
- L5374 [SELECT] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Get_44
  SQL: cr = "Select * from Correlativo where Correlativo.Tipo = '" & tipo & "'"
- L5374 [SELECT] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Get_45
  SQL: Select * from Correlativo where Correlativo.Tipo = '
- L5383 [UPDATE] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Update_46
  SQL: cr = "Update Correlativo Set Correlativo.valor = Correlativo.Valor + 1 where Correlativo.tipo = '" & tipo & "'"
- L5383 [UPDATE] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Update_47
  SQL: Update Correlativo Set Correlativo.valor = Correlativo.Valor + 1 where Correlativo.tipo = '
- L5384 [EXEC] objeto: CR
  SP sugerido: usp_DatQBox_PtoVenta_CR_Exec_48
  SQL: DbConnection.Execute cr
- L5444 [SELECT] objeto: FECHAS
  SP sugerido: usp_DatQBox_PtoVenta_FECHAS_Get_49
  SQL: SQL = "Select * from Fechas"
- L5444 [SELECT] objeto: FECHAS
  SP sugerido: usp_DatQBox_PtoVenta_FECHAS_Get_50
  SQL: Select * from Fechas
- L5448 [UPDATE] objeto: FECHAS
  SP sugerido: usp_DatQBox_PtoVenta_FECHAS_Update_51
  SQL: dnconet.Execute " update fechas set fecha = '" & Format(Date, "DD/MM/YYYY") & "'"
- L5448 [UPDATE] objeto: FECHAS
  SP sugerido: usp_DatQBox_PtoVenta_FECHAS_Update_52
  SQL: update fechas set fecha = '
- L5668 [SELECT] objeto: FORMULAS
  SP sugerido: usp_DatQBox_PtoVenta_FORMULAS_Get_53
  SQL: SQL = "SElect * from Formulas Where Codigo = '" & codigo & "'"
- L5668 [SELECT] objeto: FORMULAS
  SP sugerido: usp_DatQBox_PtoVenta_FORMULAS_Get_54
  SQL: SElect * from Formulas Where Codigo = '
- L5711 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_COMPRAS_Get_55
  SQL: cr = "Select * from Compras where fechavence = " & Dia & " and cancelada = 'N'"
- L5711 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_COMPRAS_Get_56
  SQL: Select * from Compras where fechavence =
- L5720 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_PtoVenta_COMPRAS_Get_57
  SQL: 'cr = "Select * from Compras where fechavence = " & dia & ""

### DatQBox Admin\WinapisAdmin.bas
- L63 [SELECT] objeto: SETTING
  SP sugerido: usp_DatQBox_Admin_SETTING_Get_1
  SQL: SQL = "SELECT * FROM Setting WHERE NAME = '©£¡œ' "
- L63 [SELECT] objeto: SETTING
  SP sugerido: usp_DatQBox_Admin_SETTING_Get_2
  SQL: SELECT * FROM Setting WHERE NAME = '©£¡œ'
- L80 [SELECT] objeto: ALLCUSTOMERLIC
  SP sugerido: usp_DatQBox_Admin_ALLCUSTOMERLIC_Get_3
  SQL: Rs.Open "SELECT * FROM AllCustomerLic WHERE RIF = '" & vLinea_Dos & "' AND serial = '" & Trim(txtSerial) & "' ", mConn, adOpenStatic, adLockReadOnly
- L80 [SELECT] objeto: ALLCUSTOMERLIC
  SP sugerido: usp_DatQBox_Admin_ALLCUSTOMERLIC_Get_4
  SQL: SELECT * FROM AllCustomerLic WHERE RIF = '
- L1248 [SELECT] objeto: BLOQUE
  SP sugerido: usp_DatQBox_Admin_BLOQUE_Get_5
  SQL: cr = " Select * from Bloque where fecha = " & FECHA & " order by fecha" ' and Pago = 'Efectivo' order by fecha"
- L1248 [SELECT] objeto: BLOQUE
  SP sugerido: usp_DatQBox_Admin_BLOQUE_Get_6
  SQL: Select * from Bloque where fecha =
- L1346 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_7
  SQL: cr = " Select * from facturas where fecha = " & FECHA & " and Pago = 'Efectivo' and ( cheque > 0 or tarjeta <> '0' ) order by num_fact"
- L1346 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_8
  SQL: Select * from facturas where fecha =
- L1468 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_9
  SQL: cr = " Select * from facturas where fecha = " & FECHA & " and Pago = 'Efectivo' AND MONTO_EFECT > 0 order by num_fact"
- L1602 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_10
  SQL: cr = " Select * from FACTURAS where nro_retencion <> '0' and fecha = " & FECHA & " order by num_fact"
- L1602 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_11
  SQL: Select * from FACTURAS where nro_retencion <> '0' and fecha =
- L1719 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_12
  SQL: cr = " Select * from facturas where fecha = " & FECHA & " and Pago = 'Efectivo' and Cancelada = 'N' order by num_fact"
- L1838 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_13
  SQL: cr = " SELECT P_CobrarC.FECHA, P_CobrarC.Pago, P_CobrarC.TIPO, P_CobrarC.HABER AS TOTAL, Clientes.NOMBRE, P_CobrarC.DOCUMENTO AS NUM_FACT"
- L1838 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_14
  SQL: SELECT P_CobrarC.FECHA, P_CobrarC.Pago, P_CobrarC.TIPO, P_CobrarC.HABER AS TOTAL, Clientes.NOMBRE, P_CobrarC.DOCUMENTO AS NUM_FACT
- L1843 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_15
  SQL: ' cr = " SELECT PagosC.FECHA, PagosC.Pago, PagosC.TIPO, Pagosc.aplicado AS TOTAL, Clientes.NOMBRE, Pagosc.DOCUMENTO AS NUM_FACT"
- L1843 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_16
  SQL: SELECT PagosC.FECHA, PagosC.Pago, PagosC.TIPO, Pagosc.aplicado AS TOTAL, Clientes.NOMBRE, Pagosc.DOCUMENTO AS NUM_FACT
- L1966 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_17
  SQL: cr = " Select * from facturas where Pago = 'Credito' and Locacion like 'Comp*' and fecha = " & FECHA & " order by num_fact"
- L1966 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_18
  SQL: Select * from facturas where Pago = 'Credito' and Locacion like 'Comp*' and fecha =
- L2055 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_19
  SQL: cr = " Select * from facturas where Pago = 'Credito' and Locacion like 'Particular*' and fecha = " & FECHA & " order by num_fact"
- L2055 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_20
  SQL: Select * from facturas where Pago = 'Credito' and Locacion like 'Particular*' and fecha =
- L2160 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_21
  SQL: cr = " SELECT P_Cobrar.FECHA, P_Cobrar.Pago, P_Cobrar.TIPO, P_Cobrar.HABER AS TOTAL, Clientes.NOMBRE, P_Cobrar.DOCUMENTO AS NUM_FACT"
- L2160 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_22
  SQL: SELECT P_Cobrar.FECHA, P_Cobrar.Pago, P_Cobrar.TIPO, P_Cobrar.HABER AS TOTAL, Clientes.NOMBRE, P_Cobrar.DOCUMENTO AS NUM_FACT
- L2164 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_23
  SQL: ' cr = " SELECT Pagos.FECHA, Pagos.Pago, Pagos.TIPO, Pagos.aplicado AS TOTAL, Clientes.NOMBRE, Pagos.DOCUMENTO AS NUM_FACT"
- L2164 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_24
  SQL: SELECT Pagos.FECHA, Pagos.Pago, Pagos.TIPO, Pagos.aplicado AS TOTAL, Clientes.NOMBRE, Pagos.DOCUMENTO AS NUM_FACT
- L2277 [SELECT] objeto: GASTOS
  SP sugerido: usp_DatQBox_Admin_GASTOS_Get_25
  SQL: cr = " Select * from gastos where fecha = " & FECHA & " order by num_fact"
- L2277 [SELECT] objeto: GASTOS
  SP sugerido: usp_DatQBox_Admin_GASTOS_Get_26
  SQL: Select * from gastos where fecha =
- L2379 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_27
  SQL: cr = " SELECT * "
- L2808 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_28
  SQL: cr = " Select * from facturas where fecha = " & FECHA & " and Pago = 'Efectivo' order by num_fact"
- L2931 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_29
  SQL: cr = " Select * from facturas where Pago = 'Credito' and fecha = " & FECHA & " order by num_fact"
- L2931 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_30
  SQL: Select * from facturas where Pago = 'Credito' and fecha =
- L3312 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_31
  SQL: Select Case Month(FECHA)
- L3369 [SELECT] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_Admin_CORRELATIVO_Get_32
  SQL: cr = "Select * from Correlativo where Correlativo.Tipo = '" & Tipo & "'"
- L3369 [SELECT] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_Admin_CORRELATIVO_Get_33
  SQL: Select * from Correlativo where Correlativo.Tipo = '
- L3378 [UPDATE] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_Admin_CORRELATIVO_Update_34
  SQL: cr = "Update Correlativo Set Correlativo.valor = Correlativo.Valor + 1 where Correlativo.tipo = '" & Tipo & "'"
- L3378 [UPDATE] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_Admin_CORRELATIVO_Update_35
  SQL: Update Correlativo Set Correlativo.valor = Correlativo.Valor + 1 where Correlativo.tipo = '
- L3379 [EXEC] objeto: CR
  SP sugerido: usp_DatQBox_Admin_CR_Exec_36
  SQL: DbConnection.Execute cr
- L3465 [SELECT] objeto: FECHAS
  SP sugerido: usp_DatQBox_Admin_FECHAS_Get_37
  SQL: SQL = "Select * from Fechas"
- L3465 [SELECT] objeto: FECHAS
  SP sugerido: usp_DatQBox_Admin_FECHAS_Get_38
  SQL: Select * from Fechas
- L3475 [UPDATE] objeto: FECHAS
  SP sugerido: usp_DatQBox_Admin_FECHAS_Update_39
  SQL: dnconet.Execute " update fechas set fecha = '" & Format(Date, "DD/MM/YYYY") & "'"
- L3475 [UPDATE] objeto: FECHAS
  SP sugerido: usp_DatQBox_Admin_FECHAS_Update_40
  SQL: update fechas set fecha = '
- L3489 [SELECT] objeto: EMPRESA
  SP sugerido: usp_DatQBox_Admin_EMPRESA_Get_41
  SQL: SQL = "Select * from empresa"
- L3489 [SELECT] objeto: EMPRESA
  SP sugerido: usp_DatQBox_Admin_EMPRESA_Get_42
  SQL: Select * from empresa
- L3504 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Admin_TASA_MONEDA_Get_43
  SQL: c = "SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_compra, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE "
- L3504 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Admin_TASA_MONEDA_Get_44
  SQL: SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_compra, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE
- L3698 [SELECT] objeto: FORMULAS
  SP sugerido: usp_DatQBox_Admin_FORMULAS_Get_45
  SQL: SQL = "SElect * from Formulas Where Codigo = '" & codigo & "'"
- L3698 [SELECT] objeto: FORMULAS
  SP sugerido: usp_DatQBox_Admin_FORMULAS_Get_46
  SQL: SElect * from Formulas Where Codigo = '
- L3741 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Get_47
  SQL: cr = "Select * from Compras where fechavence = " & Dia & " and cancelada = 'N'"
- L3741 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Get_48
  SQL: Select * from Compras where fechavence =
- L3750 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Get_49
  SQL: 'cr = "Select * from Compras where fechavence = " & dia & ""

### DatQBox PtoVenta\FrmDetalleFormaPago.frm
- L976 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_1
  SQL: SQL = " (SELECT SUM( PEND) AS SumaDePEND"
- L976 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_2
  SQL: (SELECT SUM( PEND) AS SumaDePEND
- L984 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_3
  SQL: SQL = " (SELECT SUM(PEND) AS SumaDePEND"
- L984 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_4
  SQL: (SELECT SUM(PEND) AS SumaDePEND
- L1022 [UPDATE] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_PtoVenta_PROVEEDORES_Update_5
  SQL: SQL = " Update Proveedores"
- L1022 [UPDATE] objeto: PROVEEDORES
  SP sugerido: usp_DatQBox_PtoVenta_PROVEEDORES_Update_6
  SQL: Update Proveedores
- L1024 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_7
  SQL: SQL = " Update Clientes "
- L1024 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_8
  SQL: Update Clientes
- L1030 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_PtoVenta_SQL_Exec_9
  SQL: DbConnection.Execute SQL
- L1043 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Get_10
  SQL: SQL = "select * from P_cobrar where codigo = '" & codigo & "' and documento = " & NUM_FACT & ""
- L1043 [SELECT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Get_11
  SQL: select * from P_cobrar where codigo = '
- L1045 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Get_12
  SQL: SQL = "select * from P_cobrarc where codigo = '" & codigo & "' and documento = '" & NUM_FACT & "'"
- L1045 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Get_13
  SQL: select * from P_cobrarc where codigo = '
- L1068 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_14
  SQL: Pcobrar.Update
- L1139 [SELECT] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Get_15
  SQL: 'SQL = "select * from P_cobrarc where codigo = '" & codigo & "' and documento = '" & NUM_FACT & "'"
- L1143 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_16
  SQL: SQL = "select sum(total) as totales from facturas where fecha = '" & xFecha & "' "
- L1143 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_17
  SQL: select sum(total) as totales from facturas where fecha = '
- L1158 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_18
  SQL: SQL = "select sum(total) as totales from cotizacion where fecha = '" & xFecha & "' "
- L1158 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_19
  SQL: select sum(total) as totales from cotizacion where fecha = '
- L1196 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_20
  SQL: ''TDataLite1.Recordset.Update
- L1275 [SELECT] objeto: DETALLE_FORMAPAGO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGO_Get_21
  SQL: SQL = "select * FROM Detalle_FormaPago" & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' and Tipo = 'SALDO PENDIENTE' and MEMORIA = '" & MEMORIA.Text & "' AND SERIALFISCAL = '" &...
- L1275 [SELECT] objeto: DETALLE_FORMAPAGO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGO_Get_22
  SQL: select * FROM Detalle_FormaPago
- L1287 [DELETE] objeto: DETALLE_FORMAPAGO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGO_Delete_23
  SQL: SQL = "DELETE FROM Detalle_FormaPago" & Tb_Table & " WHERE NUM_FACT = '" & NUM_FACT & "' AND MEMORIA = '" & MEMORIA.Text & "' AND SERIALFISCAL = '" & SERIALFISCAL.Text & "' ;"
- L1287 [DELETE] objeto: DETALLE_FORMAPAGO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGO_Delete_24
  SQL: DELETE FROM Detalle_FormaPago
- L1288 [DELETE] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Delete_25
  SQL: 'SQL = "DELETE FROM Detalle_FormaPagoFacturas WHERE NUM_FACT = " & NUM_FACT & ";"
- L1288 [DELETE] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Delete_26
  SQL: DELETE FROM Detalle_FormaPagoFacturas WHERE NUM_FACT =
- L1332 [INSERT] objeto: DETALLE_FORMAPAGO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGO_Insert_27
  SQL: SQL = " INSERT INTO Detalle_FormaPago" & Tb_Table & " (tasacambio, TIPO,NUM_FACT,MONTO,BANCO, CUENTA, FECHA_RETENCION,NUMERO, MEMORIA, SERIALFISCAL)"
- L1332 [INSERT] objeto: DETALLE_FORMAPAGO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGO_Insert_28
  SQL: INSERT INTO Detalle_FormaPago
- L1362 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_DEPOSITO_Delete_29
  SQL: SQL = "DELETE FROM DETALLE_DEPOSITO WHERE CHEQUE = '" & !Numero & "';"
- L1362 [DELETE] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_DEPOSITO_Delete_30
  SQL: DELETE FROM DETALLE_DEPOSITO WHERE CHEQUE = '
- L1365 [INSERT] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_DEPOSITO_Insert_31
  SQL: SQL = "INSERT INTO DETALLE_DEPOSITO "
- L1365 [INSERT] objeto: DETALLE_DEPOSITO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_DEPOSITO_Insert_32
  SQL: INSERT INTO DETALLE_DEPOSITO
- L1422 [DELETE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Delete_33
  SQL: SQL = "delete from P_cobrar where codigo = '" & codigo & "' and documento = '" & NUM_FACT & "' and tipo = 'FACT'"
- L1422 [DELETE] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Delete_34
  SQL: delete from P_cobrar where codigo = '
- L1424 [DELETE] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Delete_35
  SQL: SQL = "delete from P_cobrarC where codigo = '" & codigo & "' and documento = '" & NUM_FACT & "' and tipo = 'FACT'"
- L1424 [DELETE] objeto: P_COBRARC
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRARC_Delete_36
  SQL: delete from P_cobrarC where codigo = '
- L1431 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_37
  SQL: SQL = "UPDATE " & Tb_Table & " SET total = " & Format(acobrar, "########0.00") & " , MONTO_GRABS = " & Format(TotalIGTF, "########0.00") & ", MONTO_EFECT = " & Format(Efet, "######...
- L1535 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_38
  SQL: TDataLite1.Recordset.Update
- L1734 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_PtoVenta_TASA_MONEDA_Get_39
  SQL: c = "SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_compra, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE "
- L1734 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_PtoVenta_TASA_MONEDA_Get_40
  SQL: SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_compra, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE
- L1771 [SELECT] objeto: BANCOS
  SP sugerido: usp_DatQBox_PtoVenta_BANCOS_Get_41
  SQL: SQL = "select * from Bancos " ' where nombre = 'MERCANTIL' OR NOMBRE = 'VENEZUELA'"
- L1771 [SELECT] objeto: BANCOS
  SP sugerido: usp_DatQBox_PtoVenta_BANCOS_Get_42
  SQL: select * from Bancos
- L1778 [SELECT] objeto: DETALLE_FORMAPAGO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGO_Get_43
  SQL: SQL = "Select Tipo, Banco, Cuenta,Numero,Fecha_Retencion, Monto, Num_Fact, Memoria, SerialFiscal, TasaCambio from detalle_FormaPago" & Tabla & " where num_fact = '" & NUM_FACT & "'...
- L1778 [SELECT] objeto: DETALLE_FORMAPAGO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGO_Get_44
  SQL: Select Tipo, Banco, Cuenta,Numero,Fecha_Retencion, Monto, Num_Fact, Memoria, SerialFiscal, TasaCambio from detalle_FormaPago
- L1779 [SELECT] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Get_45
  SQL: 'SQL = "Select Tipo, Banco, Cuenta,Numero,Fecha_Retencion, Monto, Num_Fact from detalle_FormaPagoFacturas where num_fact = " & NUM_FACT & " order by tipo"
- L1779 [SELECT] objeto: DETALLE_FORMAPAGOFACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGOFACTURAS_Get_46
  SQL: Select Tipo, Banco, Cuenta,Numero,Fecha_Retencion, Monto, Num_Fact from detalle_FormaPagoFacturas where num_fact =
- L1957 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_47
  SQL: TDBGrid1.Update
- L2004 [UPDATE] objeto: AS
  SP sugerido: usp_DatQBox_PtoVenta_AS_Update_48
  SQL: Private Sub TDataLite1_DataWrite(Bookmark As Variant, Values As Variant, ByVal NewRow As Boolean, ByVal Update As Boolean, Done As Boolean, Cancel As Boolean)
- L2005 [UPDATE] objeto: THEN
  SP sugerido: usp_DatQBox_PtoVenta_THEN_Update_49
  SQL: If Update Then

### DatQBox Compras\frmArticulos.frm
- L2068 [SELECT] objeto: CATEGORIA
  SP sugerido: usp_DatQBox_Compras_CATEGORIA_Get_1
  SQL: cr = "Select * from Categoria where Nombre = '" & Categoria.Text & "'"
- L2068 [SELECT] objeto: CATEGORIA
  SP sugerido: usp_DatQBox_Compras_CATEGORIA_Get_2
  SQL: Select * from Categoria where Nombre = '
- L2091 [SELECT] objeto: TIPOS
  SP sugerido: usp_DatQBox_Compras_TIPOS_Get_3
  SQL: cr = "Select * from tipos where categoria = '" & Categoria.Text & "'"
- L2091 [SELECT] objeto: TIPOS
  SP sugerido: usp_DatQBox_Compras_TIPOS_Get_4
  SQL: Select * from tipos where categoria = '
- L2155 [SELECT] objeto: CLASES
  SP sugerido: usp_DatQBox_Compras_CLASES_Get_5
  SQL: cr = "Select * from ClaseS where Descripcion = '" & Clase.Text & "'"
- L2155 [SELECT] objeto: CLASES
  SP sugerido: usp_DatQBox_Compras_CLASES_Get_6
  SQL: Select * from ClaseS where Descripcion = '
- L2198 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_7
  SQL: cr = "Select * from Inventario where eliminado = 0 and Codigo = '" & Cuenta & "'"
- L2198 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_8
  SQL: Select * from Inventario where eliminado = 0 and Codigo = '
- L2278 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_9
  SQL: SQL = "UPDATE INVENTARIO SET comisiondirecta = " & Format(ComisionDirecta, "########0.00") & ", comisiondirecta1 = " & Format(comisiondirecta1, "########0.00") & ",comisiondirecta2...
- L2278 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_10
  SQL: UPDATE INVENTARIO SET comisiondirecta =
- L2286 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_11
  SQL: DbConnection.Execute SQL
- L2290 [INSERT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Insert_12
  SQL: SQL = " INSERT INTO Inventario (PASA, COMISIONDIRECTA,COMISIONDIRECTA1,COMISIONDIRECTA2,COMISIONDIRECTA3, PLU, CODIGO, Referencia, Categoria, Marca, Tipo, Unidad, Clase, DESCRIPCIO...
- L2290 [INSERT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Insert_13
  SQL: INSERT INTO Inventario (PASA, COMISIONDIRECTA,COMISIONDIRECTA1,COMISIONDIRECTA2,COMISIONDIRECTA3, PLU, CODIGO, Referencia, Categoria, Marca, Tipo, Unidad, Clase, DESCRIPCION, EXIST...
- L2313 [SELECT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Compras_MOVINVENT_Get_14
  SQL: SQL = " SELECT * FROM MovInvent "
- L2313 [SELECT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Compras_MOVINVENT_Get_15
  SQL: SELECT * FROM MovInvent
- L2322 [INSERT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Compras_MOVINVENT_Insert_16
  SQL: SQL = "INSERT INTO MovInvent (CODIGO, CANTIDAD_NUEVA, ALICUOTA,PRECIO_VENTA,PRECIO_COMPRA, DOCUMENTO,PRODUCT, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CO_USUARIO)"
- L2322 [INSERT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Compras_MOVINVENT_Insert_17
  SQL: INSERT INTO MovInvent (CODIGO, CANTIDAD_NUEVA, ALICUOTA,PRECIO_VENTA,PRECIO_COMPRA, DOCUMENTO,PRODUCT, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CO_USUARIO)
- L2343 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Get_18
  SQL: SQL = " SELECT * FROM Detalle_iNVENTARIO "
- L2343 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Get_19
  SQL: SELECT * FROM Detalle_iNVENTARIO
- L2350 [INSERT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Insert_20
  SQL: SQL = " INSERT INTO Detalle_iNVENTARIO"
- L2350 [INSERT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Insert_21
  SQL: INSERT INTO Detalle_iNVENTARIO
- L2364 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Update_22
  SQL: 'SQL = " UPDATE Detalle_iNVENTARIO SET "
- L2364 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Update_23
  SQL: UPDATE Detalle_iNVENTARIO SET
- L2367 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_24
  SQL: ' DbConnection.Execute SQL
- L2443 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Update_25
  SQL: data2.Recordset.Update
- L2502 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Compras_TASA_MONEDA_Get_26
  SQL: c = "SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_venta, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE "
- L2502 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Compras_TASA_MONEDA_Get_27
  SQL: SELECT Tasa_Moneda.Moneda, Tasa_Moneda.Tasa_venta, Tasa_Moneda.Fecha FROM Tasa_Moneda WHERE
- L2866 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Get_28
  SQL: c = "SELECT Sum(Detalle_Inventario.EXISTENCIA_ACTUAL) AS SCantidad FROM Detalle_Inventario "
- L2866 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Get_29
  SQL: SELECT Sum(Detalle_Inventario.EXISTENCIA_ACTUAL) AS SCantidad FROM Detalle_Inventario
- L2961 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_30
  SQL: data2.RecordSource = "SELECT * FROM inventario where codigo = '" & Cuenta.Text & "'"
- L2961 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_31
  SQL: SELECT * FROM inventario where codigo = '
- L3065 [SELECT] objeto: MARCAS
  SP sugerido: usp_DatQBox_Compras_MARCAS_Get_32
  SQL: cr = "Select * from Marcas"
- L3065 [SELECT] objeto: MARCAS
  SP sugerido: usp_DatQBox_Compras_MARCAS_Get_33
  SQL: Select * from Marcas
- L3081 [SELECT] objeto: UNIDADES
  SP sugerido: usp_DatQBox_Compras_UNIDADES_Get_34
  SQL: cr = "Select * from unidades"
- L3081 [SELECT] objeto: UNIDADES
  SP sugerido: usp_DatQBox_Compras_UNIDADES_Get_35
  SQL: Select * from unidades
- L3098 [SELECT] objeto: CLASES
  SP sugerido: usp_DatQBox_Compras_CLASES_Get_36
  SQL: cr = "Select * from Clases"
- L3098 [SELECT] objeto: CLASES
  SP sugerido: usp_DatQBox_Compras_CLASES_Get_37
  SQL: Select * from Clases
- L3110 [SELECT] objeto: CATEGORIA
  SP sugerido: usp_DatQBox_Compras_CATEGORIA_Get_38
  SQL: cr = "Select * from categoria"
- L3110 [SELECT] objeto: CATEGORIA
  SP sugerido: usp_DatQBox_Compras_CATEGORIA_Get_39
  SQL: Select * from categoria
- L3122 [SELECT] objeto: LINEAS
  SP sugerido: usp_DatQBox_Compras_LINEAS_Get_40
  SQL: cr = "Select * from lineas"
- L3122 [SELECT] objeto: LINEAS
  SP sugerido: usp_DatQBox_Compras_LINEAS_Get_41
  SQL: Select * from lineas
- L3157 [SELECT] objeto: LINEAS
  SP sugerido: usp_DatQBox_Compras_LINEAS_Get_42
  SQL: cr = "Select * from LINEAS where Descripcion = '" & Linea.Text & "'"
- L3157 [SELECT] objeto: LINEAS
  SP sugerido: usp_DatQBox_Compras_LINEAS_Get_43
  SQL: Select * from LINEAS where Descripcion = '
- L3197 [SELECT] objeto: MARCAS
  SP sugerido: usp_DatQBox_Compras_MARCAS_Get_44
  SQL: cr = "Select * from Marcas where Descripcion = '" & Marca.Text & "'"
- L3197 [SELECT] objeto: MARCAS
  SP sugerido: usp_DatQBox_Compras_MARCAS_Get_45
  SQL: Select * from Marcas where Descripcion = '
- L4610 [SELECT] objeto: TIPOS
  SP sugerido: usp_DatQBox_Compras_TIPOS_Get_46
  SQL: cr = "Select * from tipoS where categoria = '" & Categoria.Text & "' and nombre = '" & Tipo.Text & "'"
- L4661 [SELECT] objeto: UNIDADES
  SP sugerido: usp_DatQBox_Compras_UNIDADES_Get_47
  SQL: cr = "Select * from Unidades where unidad = '" & unidad.Text & "'"
- L4661 [SELECT] objeto: UNIDADES
  SP sugerido: usp_DatQBox_Compras_UNIDADES_Get_48
  SQL: Select * from Unidades where unidad = '

### DatQBox Compras\frmInventario.frm
- L1490 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_1
  SQL: Select Case obj_Field.Type
- L1515 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_2
  SQL: SQL = " Select Inventario.Codigo,Inventario.PLU, Inventario.Referencia,Inventario.Fecha, Inventario.Linea, Inventario.Categoria, Inventario.Tipo, Inventario.Descripcion, Inventario...
- L1515 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_3
  SQL: Select Inventario.Codigo,Inventario.PLU, Inventario.Referencia,Inventario.Fecha, Inventario.Linea, Inventario.Categoria, Inventario.Tipo, Inventario.Descripcion, Inventario.Marca, ...
- L1522 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_4
  SQL: SQL = " SELECT Inventario.Porcentaje,Inventario.Porcentaje1,Inventario.Porcentaje2,Inventario.Porcentaje3, Inventario.Costo_Promedio, Inventario.Costo_Referencia, Inventario.Descue...
- L1522 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_5
  SQL: SELECT Inventario.Porcentaje,Inventario.Porcentaje1,Inventario.Porcentaje2,Inventario.Porcentaje3, Inventario.Costo_Promedio, Inventario.Costo_Referencia, Inventario.Descuento_Comp...
- L1603 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_6
  SQL: SQL = " SELECT Inventario.Categoria, MovInvent.Product,"
- L1603 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_7
  SQL: SELECT Inventario.Categoria, MovInvent.Product,
- L1663 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_8
  SQL: SQL = " SELECT '0' as acceso, LEFT( dbo.Inventario.categoria + ' ' + dbo.Inventario.tipo + ' ' + dbo.Inventario.descripcion,20) as nombre,"
- L1663 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_9
  SQL: SELECT '0' as acceso, LEFT( dbo.Inventario.categoria + ' ' + dbo.Inventario.tipo + ' ' + dbo.Inventario.descripcion,20) as nombre,
- L1769 [DELETE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Delete_10
  SQL: SQL = SQL & " delete From inventario"
- L1769 [DELETE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Delete_11
  SQL: delete From inventario
- L1776 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_12
  SQL: DbConnection.Execute SQL
- L1778 [DELETE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Delete_13
  SQL: SQL = SQL & " delete From DETALLE_inventario"
- L1778 [DELETE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Delete_14
  SQL: delete From DETALLE_inventario
- L1826 [INSERT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Insert_15
  SQL: SQL = " INSERT INTO Inventario (pasa,PLU, Eliminado, CODIGO, Referencia, Categoria, Marca, Tipo, Unidad, Clase, DESCRIPCION, EXISTENCIA, VENTA, MINIMO, MAXIMO, PRECIO_COMPRA, PRECI...
- L1826 [INSERT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Insert_16
  SQL: INSERT INTO Inventario (pasa,PLU, Eliminado, CODIGO, Referencia, Categoria, Marca, Tipo, Unidad, Clase, DESCRIPCION, EXISTENCIA, VENTA, MINIMO, MAXIMO, PRECIO_COMPRA, PRECIO_VENTA,...
- L1827 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_17
  SQL: SQL = SQL & " SELECT inventario.Pasa, inventario.PLU, 0 as Elim, "
- L1827 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_18
  SQL: SELECT inventario.Pasa, inventario.PLU, 0 as Elim,
- L1859 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_19
  SQL: SQL1 = " UPDATE INVENTARIO SET EXISTENCIA = x.SCantidad "
- L1859 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_20
  SQL: UPDATE INVENTARIO SET EXISTENCIA = x.SCantidad
- L1862 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Get_21
  SQL: SQL1 = SQL1 & " (SELECT CODIGO, Sum(Detalle_Inventario.EXISTENCIA_ACTUAL) AS SCantidad FROM Detalle_Inventario GROUP BY CODIGO ) as X ON (INVENTARIO.CODIGO = X.codigo )"
- L1862 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Get_22
  SQL: (SELECT CODIGO, Sum(Detalle_Inventario.EXISTENCIA_ACTUAL) AS SCantidad FROM Detalle_Inventario GROUP BY CODIGO ) as X ON (INVENTARIO.CODIGO = X.codigo )
- L1867 [EXEC] objeto: SQL1
  SP sugerido: usp_DatQBox_Compras_SQL1_Exec_23
  SQL: DbConnection.Execute SQL1
- L1921 [SELECT] objeto: DETALLE_COMPRAS
  SP sugerido: usp_DatQBox_Compras_DETALLE_COMPRAS_Get_24
  SQL: SQL = "Select * from detalle_compras where Num_fact = '" & Trim(pRecordset!Documento) & "' and codigo = '" & pRecordset!Product & "' and Fecha >= '" & fdesde & "' and Fecha <= '" &...
- L1921 [SELECT] objeto: DETALLE_COMPRAS
  SP sugerido: usp_DatQBox_Compras_DETALLE_COMPRAS_Get_25
  SQL: Select * from detalle_compras where Num_fact = '
- L1929 [SELECT] objeto: DETALLE_PEDIDOS
  SP sugerido: usp_DatQBox_Compras_DETALLE_PEDIDOS_Get_26
  SQL: 'SQL = "Select * from detalle_pedidos where Num_fact = '" & Trim(pRecordset!Documento) & "' and cod_serv = '" & pRecordset!Product & "' "
- L1929 [SELECT] objeto: DETALLE_PEDIDOS
  SP sugerido: usp_DatQBox_Compras_DETALLE_PEDIDOS_Get_27
  SQL: Select * from detalle_pedidos where Num_fact = '
- L1932 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_28
  SQL: SQL = " SELECT Detalle_facturas.Id, Detalle_facturas.NUM_FACT, Detalle_facturas.SERIALTIPO, Detalle_facturas.COD_SERV, Detalle_facturas.DESCRIPCION,"
- L1932 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_29
  SQL: SELECT Detalle_facturas.Id, Detalle_facturas.NUM_FACT, Detalle_facturas.SERIALTIPO, Detalle_facturas.COD_SERV, Detalle_facturas.DESCRIPCION,
- L1957 [SELECT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_Compras_DETALLE_FACTURAS_Get_30
  SQL: SQL = "Select * from detalle_Facturas where Num_fact = '" & Trim(pRecordset!Documento) & "' and cod_serv = '" & pRecordset!Product & "' and Detalle_facturas.Fecha >= '" & fdesde & ...
- L1957 [SELECT] objeto: DETALLE_FACTURAS
  SP sugerido: usp_DatQBox_Compras_DETALLE_FACTURAS_Get_31
  SQL: Select * from detalle_Facturas where Num_fact = '
- L2012 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_32
  SQL: Select Case Col.DataField
- L2219 [SELECT] objeto: ALMACEN
  SP sugerido: usp_DatQBox_Compras_ALMACEN_Get_33
  SQL: data5.RecordSource = "Select Descripcion from almacen"
- L2219 [SELECT] objeto: ALMACEN
  SP sugerido: usp_DatQBox_Compras_ALMACEN_Get_34
  SQL: Select Descripcion from almacen
- L2257 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_35
  SQL: SQL = " SELECT dbo.Inventario.CODIGO, dbo.Inventario.Referencia, dbo.Inventario.Categoria, dbo.Inventario.Tipo, dbo.Inventario.DESCRIPCION,"
- L2257 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_36
  SQL: SELECT dbo.Inventario.CODIGO, dbo.Inventario.Referencia, dbo.Inventario.Categoria, dbo.Inventario.Tipo, dbo.Inventario.DESCRIPCION,
- L2695 [SELECT] objeto: TIPOS
  SP sugerido: usp_DatQBox_Compras_TIPOS_Get_37
  SQL: SQL = " Select nombre from tipos where categoria = '" & TDBGrid1.Columns("Categoria").Value & "'"
- L2695 [SELECT] objeto: TIPOS
  SP sugerido: usp_DatQBox_Compras_TIPOS_Get_38
  SQL: Select nombre from tipos where categoria = '
- L2705 [SELECT] objeto: CATEGORIA
  SP sugerido: usp_DatQBox_Compras_CATEGORIA_Get_39
  SQL: SQL = " Select Nombre from categoria "
- L2705 [SELECT] objeto: CATEGORIA
  SP sugerido: usp_DatQBox_Compras_CATEGORIA_Get_40
  SQL: Select Nombre from categoria
- L2715 [SELECT] objeto: CLASES
  SP sugerido: usp_DatQBox_Compras_CLASES_Get_41
  SQL: SQL = " Select Descripcion from Clases "
- L2715 [SELECT] objeto: CLASES
  SP sugerido: usp_DatQBox_Compras_CLASES_Get_42
  SQL: Select Descripcion from Clases
- L2724 [SELECT] objeto: MARCAS
  SP sugerido: usp_DatQBox_Compras_MARCAS_Get_43
  SQL: SQL = " Select Descripcion from Marcas "
- L2724 [SELECT] objeto: MARCAS
  SP sugerido: usp_DatQBox_Compras_MARCAS_Get_44
  SQL: Select Descripcion from Marcas

### DatQBox Admin\WinapisAdminGym.bas
- L1036 [SELECT] objeto: BLOQUE
  SP sugerido: usp_DatQBox_Admin_BLOQUE_Get_1
  SQL: cr = " Select * from Bloque where fecha = " & fecha & " order by fecha" ' and Pago = 'Efectivo' order by fecha"
- L1036 [SELECT] objeto: BLOQUE
  SP sugerido: usp_DatQBox_Admin_BLOQUE_Get_2
  SQL: Select * from Bloque where fecha =
- L1134 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_3
  SQL: cr = " Select * from facturas where fecha = " & fecha & " and Pago = 'Efectivo' and ( cheque > 0 or tarjeta <> '0' ) order by num_fact"
- L1134 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_4
  SQL: Select * from facturas where fecha =
- L1256 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_5
  SQL: cr = " Select * from facturas where fecha = " & fecha & " and Pago = 'Efectivo' AND MONTO_EFECT > 0 order by num_fact"
- L1390 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_6
  SQL: cr = " Select * from FACTURAS where nro_retencion <> '0' and fecha = " & fecha & " order by num_fact"
- L1390 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_7
  SQL: Select * from FACTURAS where nro_retencion <> '0' and fecha =
- L1507 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_8
  SQL: cr = " Select * from facturas where fecha = " & fecha & " and Pago = 'Efectivo' and Cancelada = 'N' order by num_fact"
- L1626 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_9
  SQL: cr = " SELECT P_CobrarC.FECHA, P_CobrarC.Pago, P_CobrarC.TIPO, P_CobrarC.HABER AS TOTAL, Clientes.NOMBRE, P_CobrarC.DOCUMENTO AS NUM_FACT"
- L1626 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_10
  SQL: SELECT P_CobrarC.FECHA, P_CobrarC.Pago, P_CobrarC.TIPO, P_CobrarC.HABER AS TOTAL, Clientes.NOMBRE, P_CobrarC.DOCUMENTO AS NUM_FACT
- L1631 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_11
  SQL: ' cr = " SELECT PagosC.FECHA, PagosC.Pago, PagosC.TIPO, Pagosc.aplicado AS TOTAL, Clientes.NOMBRE, Pagosc.DOCUMENTO AS NUM_FACT"
- L1631 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_12
  SQL: SELECT PagosC.FECHA, PagosC.Pago, PagosC.TIPO, Pagosc.aplicado AS TOTAL, Clientes.NOMBRE, Pagosc.DOCUMENTO AS NUM_FACT
- L1754 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_13
  SQL: cr = " Select * from facturas where Pago = 'Credito' and Locacion like 'Comp*' and fecha = " & fecha & " order by num_fact"
- L1754 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_14
  SQL: Select * from facturas where Pago = 'Credito' and Locacion like 'Comp*' and fecha =
- L1843 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_15
  SQL: cr = " Select * from facturas where Pago = 'Credito' and Locacion like 'Particular*' and fecha = " & fecha & " order by num_fact"
- L1843 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_16
  SQL: Select * from facturas where Pago = 'Credito' and Locacion like 'Particular*' and fecha =
- L1948 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_17
  SQL: cr = " SELECT P_Cobrar.FECHA, P_Cobrar.Pago, P_Cobrar.TIPO, P_Cobrar.HABER AS TOTAL, Clientes.NOMBRE, P_Cobrar.DOCUMENTO AS NUM_FACT"
- L1948 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_18
  SQL: SELECT P_Cobrar.FECHA, P_Cobrar.Pago, P_Cobrar.TIPO, P_Cobrar.HABER AS TOTAL, Clientes.NOMBRE, P_Cobrar.DOCUMENTO AS NUM_FACT
- L1952 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_19
  SQL: ' cr = " SELECT Pagos.FECHA, Pagos.Pago, Pagos.TIPO, Pagos.aplicado AS TOTAL, Clientes.NOMBRE, Pagos.DOCUMENTO AS NUM_FACT"
- L1952 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_20
  SQL: SELECT Pagos.FECHA, Pagos.Pago, Pagos.TIPO, Pagos.aplicado AS TOTAL, Clientes.NOMBRE, Pagos.DOCUMENTO AS NUM_FACT
- L2065 [SELECT] objeto: GASTOS
  SP sugerido: usp_DatQBox_Admin_GASTOS_Get_21
  SQL: cr = " Select * from gastos where fecha = " & fecha & " order by num_fact"
- L2065 [SELECT] objeto: GASTOS
  SP sugerido: usp_DatQBox_Admin_GASTOS_Get_22
  SQL: Select * from gastos where fecha =
- L2167 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_23
  SQL: cr = " SELECT * "
- L2596 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_24
  SQL: cr = " Select * from facturas where fecha = " & fecha & " and Pago = 'Efectivo' order by num_fact"
- L2719 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_25
  SQL: cr = " Select * from facturas where Pago = 'Credito' and fecha = " & fecha & " order by num_fact"
- L2719 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Admin_FACTURAS_Get_26
  SQL: Select * from facturas where Pago = 'Credito' and fecha =
- L3100 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_27
  SQL: Select Case Month(fecha)
- L3157 [SELECT] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_Admin_CORRELATIVO_Get_28
  SQL: cr = "Select * from Correlativo where Correlativo.Tipo = '" & Tipo & "'"
- L3157 [SELECT] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_Admin_CORRELATIVO_Get_29
  SQL: Select * from Correlativo where Correlativo.Tipo = '
- L3166 [UPDATE] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_Admin_CORRELATIVO_Update_30
  SQL: cr = "Update Correlativo Set Correlativo.valor = Correlativo.Valor + 1 where Correlativo.tipo = '" & Tipo & "'"
- L3166 [UPDATE] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_Admin_CORRELATIVO_Update_31
  SQL: Update Correlativo Set Correlativo.valor = Correlativo.Valor + 1 where Correlativo.tipo = '
- L3167 [EXEC] objeto: CR
  SP sugerido: usp_DatQBox_Admin_CR_Exec_32
  SQL: DbConnection.Execute cr
- L3297 [SELECT] objeto: FECHAS
  SP sugerido: usp_DatQBox_Admin_FECHAS_Get_33
  SQL: SQL = "Select * from Fechas"
- L3297 [SELECT] objeto: FECHAS
  SP sugerido: usp_DatQBox_Admin_FECHAS_Get_34
  SQL: Select * from Fechas
- L3304 [UPDATE] objeto: FECHAS
  SP sugerido: usp_DatQBox_Admin_FECHAS_Update_35
  SQL: dnconet.Execute " update fechas set fecha = '" & Format(Date, "DD/MM/YYYY") & "'"
- L3304 [UPDATE] objeto: FECHAS
  SP sugerido: usp_DatQBox_Admin_FECHAS_Update_36
  SQL: update fechas set fecha = '
- L3315 [SELECT] objeto: EMPRESA
  SP sugerido: usp_DatQBox_Admin_EMPRESA_Get_37
  SQL: SQL = "Select * from empresa"
- L3315 [SELECT] objeto: EMPRESA
  SP sugerido: usp_DatQBox_Admin_EMPRESA_Get_38
  SQL: Select * from empresa
- L3507 [SELECT] objeto: FORMULAS
  SP sugerido: usp_DatQBox_Admin_FORMULAS_Get_39
  SQL: SQL = "SElect * from Formulas Where Codigo = '" & codigo & "'"
- L3507 [SELECT] objeto: FORMULAS
  SP sugerido: usp_DatQBox_Admin_FORMULAS_Get_40
  SQL: SElect * from Formulas Where Codigo = '
- L3550 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Get_41
  SQL: cr = "Select * from Compras where fechavence = " & Dia & " and cancelada = 'N'"
- L3550 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Get_42
  SQL: Select * from Compras where fechavence =
- L3559 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Admin_COMPRAS_Get_43
  SQL: 'cr = "Select * from Compras where fechavence = " & dia & ""

### DatQBox Compras\frmConsultasCompras.frm
- L1251 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_1
  SQL: cr = "Select * From " & tabla & " where " & Busqueda.Text & " >= '" & fdesde & "' and " & Busqueda.Text & " <= '" & fhasta & "' order by " & Busqueda.Text & " ASC"
- L1251 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_2
  SQL: Select * From
- L1312 [DELETE] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Delete_3
  SQL: SQL = "DELETE from P_PAGAR where codigo = '" & DATA1.Recordset!cod_proveedor & "' AND DOCUMENTO = '" & DATA1.Recordset!NUM_FACT & "' "
- L1312 [DELETE] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Delete_4
  SQL: DELETE from P_PAGAR where codigo = '
- L1313 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_5
  SQL: DbConnection.Execute SQL
- L1315 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Delete_6
  SQL: SQL = "Delete from movimiento_cuenta where cod_oper = '" & DATA1.Recordset!NUM_FACT & "' and cod_proveedor = '" & DATA1.Recordset!cod_proveedor & "'"
- L1315 [DELETE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Delete_7
  SQL: Delete from movimiento_cuenta where cod_oper = '
- L1318 [DELETE] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Delete_8
  SQL: SQL = " delete from ABONOS where documento = '" & DATA1.Recordset!NUM_FACT & "' and codigo = '" & DATA1.Recordset!cod_proveedor & "' "
- L1318 [DELETE] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Delete_9
  SQL: delete from ABONOS where documento = '
- L1322 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_10
  SQL: SQL = " Update Inventario"
- L1322 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_11
  SQL: Update Inventario
- L1325 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_12
  SQL: SQL = SQL & " (SELECT Detalle_Compras.CODIGO, SUM([Detalle_Compras].[CANTIDAD]) AS TOTAL"
- L1325 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_13
  SQL: (SELECT Detalle_Compras.CODIGO, SUM([Detalle_Compras].[CANTIDAD]) AS TOTAL
- L1334 [DELETE] objeto: DETALLE_COMPRAS
  SP sugerido: usp_DatQBox_Compras_DETALLE_COMPRAS_Delete_14
  SQL: SQL = " DELETE FROM DETALLE_COMPRAS "
- L1334 [DELETE] objeto: DETALLE_COMPRAS
  SP sugerido: usp_DatQBox_Compras_DETALLE_COMPRAS_Delete_15
  SQL: DELETE FROM DETALLE_COMPRAS
- L1340 [DELETE] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Compras_MOVINVENT_Delete_16
  SQL: SQL = " DELETE FROM MovInvent "
- L1340 [DELETE] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Compras_MOVINVENT_Delete_17
  SQL: DELETE FROM MovInvent
- L1377 [UPDATE] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Update_18
  SQL: SQL = "UPDATE P_PAGAR set documento = '" & NUM_FACT & "' where codigo = '" & DATA1.Recordset!cod_proveedor & "' AND DOCUMENTO = '" & DATA1.Recordset!NUM_FACT & "' "
- L1377 [UPDATE] objeto: P_PAGAR
  SP sugerido: usp_DatQBox_Compras_P_PAGAR_Update_19
  SQL: UPDATE P_PAGAR set documento = '
- L1380 [UPDATE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Update_20
  SQL: SQL = "update movimiento_cuenta set cod_oper = '" & NUM_FACT & "' where cod_oper = '" & DATA1.Recordset!NUM_FACT & "' and cod_proveedor = '" & DATA1.Recordset!cod_proveedor & "'"
- L1380 [UPDATE] objeto: MOVIMIENTO_CUENTA
  SP sugerido: usp_DatQBox_Compras_MOVIMIENTO_CUENTA_Update_21
  SQL: update movimiento_cuenta set cod_oper = '
- L1383 [UPDATE] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Update_22
  SQL: SQL = " update ABONOS set documento = '" & NUM_FACT & "' where documento = '" & DATA1.Recordset!NUM_FACT & "' and codigo = '" & DATA1.Recordset!cod_proveedor & "' "
- L1383 [UPDATE] objeto: ABONOS
  SP sugerido: usp_DatQBox_Compras_ABONOS_Update_23
  SQL: update ABONOS set documento = '
- L1389 [UPDATE] objeto: DETALLE_COMPRAS
  SP sugerido: usp_DatQBox_Compras_DETALLE_COMPRAS_Update_24
  SQL: SQL = " UPDATE DETALLE_COMPRAS SET "
- L1389 [UPDATE] objeto: DETALLE_COMPRAS
  SP sugerido: usp_DatQBox_Compras_DETALLE_COMPRAS_Update_25
  SQL: UPDATE DETALLE_COMPRAS SET
- L1395 [UPDATE] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Compras_MOVINVENT_Update_26
  SQL: SQL = " UPDATE MovInvent SET DOCUMENTO = '" & NUM_FACT & "' "
- L1395 [UPDATE] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Compras_MOVINVENT_Update_27
  SQL: UPDATE MovInvent SET DOCUMENTO = '
- L1400 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Update_28
  SQL: SQL = " UPDATE COMPRAS SET "
- L1400 [UPDATE] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Update_29
  SQL: UPDATE COMPRAS SET
- L1466 [SELECT] objeto: LIBROCOMPRAS
  SP sugerido: usp_DatQBox_Compras_LIBROCOMPRAS_Get_30
  SQL: SQL = "SELECT * From LibroCompras WHERE fecha_pago >= '" & fdesde & "' and fecha_pago <= '" & fhasta & "'"
- L1466 [SELECT] objeto: LIBROCOMPRAS
  SP sugerido: usp_DatQBox_Compras_LIBROCOMPRAS_Get_31
  SQL: SELECT * From LibroCompras WHERE fecha_pago >= '
- L1493 [EXEC] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Exec_32
  SQL: mobjCmd.Execute
- L1502 [DELETE] objeto: [SANJOSE].[DBO].[LIBROCOMPRAS]
  SP sugerido: usp_DatQBox_Compras_SANJOSE_DBO_LIBROCOMPRAS_Delete_33
  SQL: ' SQL = " Delete FROM [Sanjose].[dbo].[LibroCompras] where FECHA_PAGO >= '" & fdesde & "' and FECHA_PAGO <='" & fhasta & "'"
- L1502 [DELETE] objeto: [SANJOSE].[DBO].[LIBROCOMPRAS]
  SP sugerido: usp_DatQBox_Compras_SANJOSE_DBO_LIBROCOMPRAS_Delete_34
  SQL: Delete FROM [Sanjose].[dbo].[LibroCompras] where FECHA_PAGO >= '
- L1503 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_35
  SQL: 'DbConnection.Execute SQL
- L1505 [INSERT] objeto: LIBROCOMPRAS
  SP sugerido: usp_DatQBox_Compras_LIBROCOMPRAS_Insert_36
  SQL: 'SQL = " INSERT INTO LibroCompras (FECHA_LIBRO, NUM_FACT,Clase, COD_PROVEEDOR, NOMBRE, FECHA, HORA, COD_CTA, COD_USUARIO, FECHARECIBO, FECHAVENCE, CONCEPTO, MONTO_GRA, IVA, TOTAL, ...
- L1505 [INSERT] objeto: LIBROCOMPRAS
  SP sugerido: usp_DatQBox_Compras_LIBROCOMPRAS_Insert_37
  SQL: INSERT INTO LibroCompras (FECHA_LIBRO, NUM_FACT,Clase, COD_PROVEEDOR, NOMBRE, FECHA, HORA, COD_CTA, COD_USUARIO, FECHARECIBO, FECHAVENCE, CONCEPTO, MONTO_GRA, IVA, TOTAL, ANULADA, ...
- L1506 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_38
  SQL: 'SQL = SQL & " SELECT '" & XFECHA3 & "' ,Compras.NUM_FACT,Compras.CLASE , Compras.COD_PROVEEDOR, Compras.NOMBRE, Compras.FECHA, Compras.HORA, Compras.COD_CTA, Compras.COD_USUARIO, ...
- L1539 [SELECT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Compras_DETALLE_Get_39
  SQL: SQL = "Select * from detalle_" & tabla & " where Num_fact = '" & pRecordset!NUM_FACT & "' and cod_proveedor = '" & pRecordset!cod_proveedor & "' "
- L1539 [SELECT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Compras_DETALLE_Get_40
  SQL: Select * from detalle_
- L1600 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_41
  SQL: vReporte.Tag = "SELECT * FROM COMPRAS WHERE NUM_FACT = '" & DATA1.Recordset!NUM_FACT & "' AND COD_PROVEEDOR = '" & DATA1.Recordset!cod_proveedor & "'"
- L1600 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_42
  SQL: SELECT * FROM COMPRAS WHERE NUM_FACT = '
- L1822 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_43
  SQL: cr = "Select * From " & xTablas & " where Fecha >= '" & fdesde & "' and Fecha <= '" & fhasta & "' order by NOMBRE"

### DatQBox Compras\WinapisCompras.bas
- L1000 [SELECT] objeto: BLOQUE
  SP sugerido: usp_DatQBox_Compras_BLOQUE_Get_1
  SQL: cr = " Select * from Bloque where fecha = " & FECHA & " order by fecha" ' and Pago = 'Efectivo' order by fecha"
- L1000 [SELECT] objeto: BLOQUE
  SP sugerido: usp_DatQBox_Compras_BLOQUE_Get_2
  SQL: Select * from Bloque where fecha =
- L1098 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_3
  SQL: cr = " Select * from facturas where fecha = " & FECHA & " and Pago = 'Efectivo' and ( cheque > 0 or tarjeta <> '0' ) order by num_fact"
- L1098 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_4
  SQL: Select * from facturas where fecha =
- L1220 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_5
  SQL: cr = " Select * from facturas where fecha = " & FECHA & " and Pago = 'Efectivo' AND MONTO_EFECT > 0 order by num_fact"
- L1354 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_6
  SQL: cr = " Select * from FACTURAS where nro_retencion <> '0' and fecha = " & FECHA & " order by num_fact"
- L1354 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_7
  SQL: Select * from FACTURAS where nro_retencion <> '0' and fecha =
- L1466 [SELECT] objeto: PRESUPUESTOS
  SP sugerido: usp_DatQBox_Compras_PRESUPUESTOS_Get_8
  SQL: cr = " Select * from Presupuestos where fecha = " & FECHA & " and Locacion = 'PREFACTURA' order by num_fact"
- L1466 [SELECT] objeto: PRESUPUESTOS
  SP sugerido: usp_DatQBox_Compras_PRESUPUESTOS_Get_9
  SQL: Select * from Presupuestos where fecha =
- L1591 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_10
  SQL: cr = " Select * from facturas where fecha = " & FECHA & " and Pago = 'Efectivo' and Cancelada = 'N' order by num_fact"
- L1710 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_11
  SQL: cr = " SELECT P_CobrarC.FECHA, P_CobrarC.Pago, P_CobrarC.TIPO, P_CobrarC.HABER AS TOTAL, Clientes.NOMBRE, P_CobrarC.DOCUMENTO AS NUM_FACT"
- L1710 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_12
  SQL: SELECT P_CobrarC.FECHA, P_CobrarC.Pago, P_CobrarC.TIPO, P_CobrarC.HABER AS TOTAL, Clientes.NOMBRE, P_CobrarC.DOCUMENTO AS NUM_FACT
- L1715 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_13
  SQL: ' cr = " SELECT PagosC.FECHA, PagosC.Pago, PagosC.TIPO, Pagosc.aplicado AS TOTAL, Clientes.NOMBRE, Pagosc.DOCUMENTO AS NUM_FACT"
- L1715 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_14
  SQL: SELECT PagosC.FECHA, PagosC.Pago, PagosC.TIPO, Pagosc.aplicado AS TOTAL, Clientes.NOMBRE, Pagosc.DOCUMENTO AS NUM_FACT
- L1838 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_15
  SQL: cr = " Select * from facturas where Pago = 'Credito' and Locacion like 'Comp*' and fecha = " & FECHA & " order by num_fact"
- L1838 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_16
  SQL: Select * from facturas where Pago = 'Credito' and Locacion like 'Comp*' and fecha =
- L1927 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_17
  SQL: cr = " Select * from facturas where Pago = 'Credito' and Locacion like 'Particular*' and fecha = " & FECHA & " order by num_fact"
- L1927 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_18
  SQL: Select * from facturas where Pago = 'Credito' and Locacion like 'Particular*' and fecha =
- L2032 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_19
  SQL: cr = " SELECT P_Cobrar.FECHA, P_Cobrar.Pago, P_Cobrar.TIPO, P_Cobrar.HABER AS TOTAL, Clientes.NOMBRE, P_Cobrar.DOCUMENTO AS NUM_FACT"
- L2032 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_20
  SQL: SELECT P_Cobrar.FECHA, P_Cobrar.Pago, P_Cobrar.TIPO, P_Cobrar.HABER AS TOTAL, Clientes.NOMBRE, P_Cobrar.DOCUMENTO AS NUM_FACT
- L2036 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_21
  SQL: ' cr = " SELECT Pagos.FECHA, Pagos.Pago, Pagos.TIPO, Pagos.aplicado AS TOTAL, Clientes.NOMBRE, Pagos.DOCUMENTO AS NUM_FACT"
- L2036 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_22
  SQL: SELECT Pagos.FECHA, Pagos.Pago, Pagos.TIPO, Pagos.aplicado AS TOTAL, Clientes.NOMBRE, Pagos.DOCUMENTO AS NUM_FACT
- L2149 [SELECT] objeto: GASTOS
  SP sugerido: usp_DatQBox_Compras_GASTOS_Get_23
  SQL: cr = " Select * from gastos where fecha = " & FECHA & " order by num_fact"
- L2149 [SELECT] objeto: GASTOS
  SP sugerido: usp_DatQBox_Compras_GASTOS_Get_24
  SQL: Select * from gastos where fecha =
- L2251 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_25
  SQL: cr = " SELECT * "
- L4238 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_26
  SQL: cr = " Select * from facturas where fecha = " & FECHA & " and Pago = 'Efectivo' order by num_fact"
- L4361 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_27
  SQL: cr = " Select * from facturas where Pago = 'Credito' and fecha = " & FECHA & " order by num_fact"
- L4361 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_Compras_FACTURAS_Get_28
  SQL: Select * from facturas where Pago = 'Credito' and fecha =
- L4742 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_29
  SQL: Select Case Month(FECHA)
- L4799 [SELECT] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_Compras_CORRELATIVO_Get_30
  SQL: cr = "Select * from Correlativo where Correlativo.Tipo = '" & tipo & "'"
- L4799 [SELECT] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_Compras_CORRELATIVO_Get_31
  SQL: Select * from Correlativo where Correlativo.Tipo = '
- L4808 [UPDATE] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_Compras_CORRELATIVO_Update_32
  SQL: cr = "Update Correlativo Set Correlativo.valor = Correlativo.Valor + 1 where Correlativo.tipo = '" & tipo & "'"
- L4808 [UPDATE] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_Compras_CORRELATIVO_Update_33
  SQL: Update Correlativo Set Correlativo.valor = Correlativo.Valor + 1 where Correlativo.tipo = '
- L4809 [EXEC] objeto: CR
  SP sugerido: usp_DatQBox_Compras_CR_Exec_34
  SQL: DbConnection.Execute cr
- L4895 [SELECT] objeto: EMPRESA
  SP sugerido: usp_DatQBox_Compras_EMPRESA_Get_35
  SQL: SQL = "Select * from empresa"
- L4895 [SELECT] objeto: EMPRESA
  SP sugerido: usp_DatQBox_Compras_EMPRESA_Get_36
  SQL: Select * from empresa
- L5085 [SELECT] objeto: FORMULAS
  SP sugerido: usp_DatQBox_Compras_FORMULAS_Get_37
  SQL: SQL = "SElect * from Formulas Where Codigo = '" & Codigo & "'"
- L5085 [SELECT] objeto: FORMULAS
  SP sugerido: usp_DatQBox_Compras_FORMULAS_Get_38
  SQL: SElect * from Formulas Where Codigo = '
- L5128 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_39
  SQL: cr = "Select * from Compras where fechavence = " & Dia & " and cancelada = 'N'"
- L5128 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_40
  SQL: Select * from Compras where fechavence =
- L5137 [SELECT] objeto: COMPRAS
  SP sugerido: usp_DatQBox_Compras_COMPRAS_Get_41
  SQL: 'cr = "Select * from Compras where fechavence = " & dia & ""

### DatQBox Admin\frmMovCtas.frm
- L1721 [UPDATE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Update_1
  SQL: DbConnection.Execute "UPDATE MOVCUENTAS SET SALDO_DIA = " & Grid.Columns(9).Value & " , gastos = " & Grid.Columns("Debitos").Value & ", ingresos = " & Grid.Columns("Creditos").Valu...
- L1721 [UPDATE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Update_2
  SQL: UPDATE MOVCUENTAS SET SALDO_DIA =
- L1789 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_3
  SQL: Select Case UCase(crParamDef.ParameterFieldName)
- L2015 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Delete_4
  SQL: DbConnection.Execute "Delete from movcuentas where nro_ref = 'ANTERIOR' and nro_cta = '" & pRecordset!nro_cta & "'"
- L2015 [DELETE] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Delete_5
  SQL: Delete from movcuentas where nro_ref = 'ANTERIOR' and nro_cta = '
- L2019 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Get_6
  SQL: cr = " Select Sum(saldo) as total from movCuentas where nro_cta = '" & pRecordset!nro_cta & "' and " & Orden.List(Orden.ListIndex) & " < #" & inicio & "# "
- L2019 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Get_7
  SQL: Select Sum(saldo) as total from movCuentas where nro_cta = '
- L2021 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Get_8
  SQL: cr = " Select Sum(saldo) as total from movCuentas where nro_cta = '" & pRecordset!nro_cta & "' and " & Orden.List(Orden.ListIndex) & " < '" & inicio & "' "
- L2040 [INSERT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Insert_9
  SQL: SQL = " INSERT INTO MOVCUENTAS (NRO_CTA,TIPO,NRO_REF, INGRESOS,GASTOS,SALDO,saldo_dia,BENEFICIARIO,CATEGORIA, CONFIRMADA,FECHA,FECHA_BANCO)"
- L2040 [INSERT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Insert_10
  SQL: INSERT INTO MOVCUENTAS (NRO_CTA,TIPO,NRO_REF, INGRESOS,GASTOS,SALDO,saldo_dia,BENEFICIARIO,CATEGORIA, CONFIRMADA,FECHA,FECHA_BANCO)
- L2043 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Admin_SQL_Exec_11
  SQL: DbConnection.Execute SQL
- L2052 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Get_12
  SQL: cr = "Select tipo, count(tipo) as Cuantos, sum(ingresos) as Ingreso,sum(Gastos) as Gasto from movCuentas where nro_cta = '" & pRecordset!nro_cta & "' and " & Orden.List(Orden.ListI...
- L2052 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Get_13
  SQL: Select tipo, count(tipo) as Cuantos, sum(ingresos) as Ingreso,sum(Gastos) as Gasto from movCuentas where nro_cta = '
- L2055 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Get_14
  SQL: cr = "Select tipo, count(tipo) as Cuantos, Sum(Ingresos) as Ingreso, Sum(Gastos) as Gasto from movCuentas where nro_cta = '" & pRecordset!nro_cta & "' and " & Orden.List(Orden.List...
- L2055 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Get_15
  SQL: Select tipo, count(tipo) as Cuantos, Sum(Ingresos) as Ingreso, Sum(Gastos) as Gasto from movCuentas where nro_cta = '
- L2066 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_16
  SQL: Select Case totales!Tipo
- L2104 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Get_17
  SQL: 'data1.RecordSource = "select * from movCuentas where nro_cta = '" & pRecordset!Nro_Cta & "' and fecha >= #" & Inicio & "# and fecha <= #" & fin & "# ORDER BY FECHA, tipo, NRO_REF"
- L2104 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Get_18
  SQL: select * from movCuentas where nro_cta = '
- L2107 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Get_19
  SQL: DATA1.RecordSource = "select * from movCuentas where nro_cta = '" & pRecordset!nro_cta & "' and " & Orden.List(Orden.ListIndex) & " >= #" & inicio & "# and " & Orden.List(Orden.Lis...
- L2110 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Get_20
  SQL: DATA1.RecordSource = "select * from movCuentas where nro_cta = '" & pRecordset!nro_cta & "' and " & Orden.List(Orden.ListIndex) & " >= #" & inicio & "# and " & Orden.List(Orden.Lis...
- L2118 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Get_21
  SQL: DATA1.RecordSource = "select * from movCuentas where nro_cta = '" & pRecordset!nro_cta & "' and " & Orden.List(Orden.ListIndex) & " >= '" & inicio & "' and " & Orden.List(Orden.Lis...
- L2121 [SELECT] objeto: MOVCUENTAS
  SP sugerido: usp_DatQBox_Admin_MOVCUENTAS_Get_22
  SQL: DATA1.RecordSource = "select * from movCuentas where nro_cta = '" & pRecordset!nro_cta & "' and " & Orden.List(Orden.ListIndex) & " >= '" & inicio & "' and " & Orden.List(Orden.Lis...
- L2146 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_23
  SQL: c = "SELECT MovCuentas.Nro_Cta, MovCuentas.Fecha,MovCuentas.concepto, MovCuentas.Tipo, MovCuentas.Nro_Ref, MovCuentas.Beneficiario, "
- L2146 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_24
  SQL: SELECT MovCuentas.Nro_Cta, MovCuentas.Fecha,MovCuentas.concepto, MovCuentas.Tipo, MovCuentas.Nro_Ref, MovCuentas.Beneficiario,
- L2189 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_25
  SQL: 'c = "SELECT Movimiento_Cuenta.COD_CUENTA, Movimiento_Cuenta.COD_OPER, Movimiento_Cuenta.COD_PROVEEDOR, "
- L2189 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_26
  SQL: SELECT Movimiento_Cuenta.COD_CUENTA, Movimiento_Cuenta.COD_OPER, Movimiento_Cuenta.COD_PROVEEDOR,
- L2198 [DELETE] objeto: CARGOS
  SP sugerido: usp_DatQBox_Admin_CARGOS_Delete_27
  SQL: 'cr = " delete from cargos"
- L2198 [DELETE] objeto: CARGOS
  SP sugerido: usp_DatQBox_Admin_CARGOS_Delete_28
  SQL: delete from cargos
- L2199 [EXEC] objeto: CR
  SP sugerido: usp_DatQBox_Admin_CR_Exec_29
  SQL: 'DbConnection.Execute cr
- L2201 [SELECT] objeto: CARGOS
  SP sugerido: usp_DatQBox_Admin_CARGOS_Get_30
  SQL: 'c = "Select * from cargos"
- L2201 [SELECT] objeto: CARGOS
  SP sugerido: usp_DatQBox_Admin_CARGOS_Get_31
  SQL: Select * from cargos
- L2321 [SELECT] objeto: CUENTASBANK
  SP sugerido: usp_DatQBox_Admin_CUENTASBANK_Get_32
  SQL: Data3.RecordSource = "Select * from cuentasbank"
- L2321 [SELECT] objeto: CUENTASBANK
  SP sugerido: usp_DatQBox_Admin_CUENTASBANK_Get_33
  SQL: Select * from cuentasbank
- L2335 [SELECT] objeto: TIPO_TRANS_BANK
  SP sugerido: usp_DatQBox_Admin_TIPO_TRANS_BANK_Get_34
  SQL: cr = "select * from Tipo_Trans_Bank "
- L2335 [SELECT] objeto: TIPO_TRANS_BANK
  SP sugerido: usp_DatQBox_Admin_TIPO_TRANS_BANK_Get_35
  SQL: select * from Tipo_Trans_Bank
- L2446 [UPDATE] objeto: SET
  SP sugerido: usp_DatQBox_Admin_SET_Update_36
  SQL: 'When the credit or debit columns are update set
- L2475 [SELECT] objeto: DEPOSITOS
  SP sugerido: usp_DatQBox_Admin_DEPOSITOS_Get_37
  SQL: cr = "Select * from depositos where nro_dep = " & Grid.Columns(3).Text & ""
- L2475 [SELECT] objeto: DEPOSITOS
  SP sugerido: usp_DatQBox_Admin_DEPOSITOS_Get_38
  SQL: Select * from depositos where nro_dep =
- L2530 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_39
  SQL: Select Case ColIndex
- L2591 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_40
  SQL: Select Case Col

### DatQBox PtoVenta\FrmFacturaCotiza.frm
- L656 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_1
  SQL: SQL = "UPDATE CLIENTES SET SALDO_TOT = SALDO_TOT + " & total & ", SALDO_30 = SALDO_30 + " & total & " where codigo = '" & CODIGOS & "';"
- L656 [UPDATE] objeto: CLIENTES
  SP sugerido: usp_DatQBox_PtoVenta_CLIENTES_Update_2
  SQL: UPDATE CLIENTES SET SALDO_TOT = SALDO_TOT +
- L657 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_PtoVenta_SQL_Exec_3
  SQL: DbConnection.Execute SQL
- L668 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Insert_4
  SQL: SQL = "INSERT INTO P_COBRAR (CODIGO, COD_USUARIO, FECHA,DOCUMENTO ,DEBE,PEND,SALDO,TIPO)"
- L668 [INSERT] objeto: P_COBRAR
  SP sugerido: usp_DatQBox_PtoVenta_P_COBRAR_Insert_5
  SQL: INSERT INTO P_COBRAR (CODIGO, COD_USUARIO, FECHA,DOCUMENTO ,DEBE,PEND,SALDO,TIPO)
- L722 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_6
  SQL: SQL = " SELECT COTIZACION.NUM_FACT, COTIZACION.FECHA, COTIZACION.Vendedor, COTIZACION.RIF, COTIZACION.NOMBRE, COTIZACION.TOTAL, COTIZACION.CODIGO,"
- L722 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_7
  SQL: SELECT COTIZACION.NUM_FACT, COTIZACION.FECHA, COTIZACION.Vendedor, COTIZACION.RIF, COTIZACION.NOMBRE, COTIZACION.TOTAL, COTIZACION.CODIGO,
- L755 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_8
  SQL: SQL = " SELECT Facturas.NUM_FACT,Facturas.SERIALTIPO, Facturas.FECHA, Facturas.Vendedor, Facturas.RIF, Facturas.NOMBRE, Facturas.TOTAL, Facturas.CODIGO,"
- L755 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_9
  SQL: SELECT Facturas.NUM_FACT,Facturas.SERIALTIPO, Facturas.FECHA, Facturas.Vendedor, Facturas.RIF, Facturas.NOMBRE, Facturas.TOTAL, Facturas.CODIGO,
- L793 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_10
  SQL: SQL = " SELECT COTIZACION.NUM_FACT,COTIZACION.SERIALTIPO, COTIZACION.FECHA, COTIZACION.Vendedor, COTIZACION.RIF, COTIZACION.NOMBRE, COTIZACION.TOTAL, COTIZACION.CODIGO,"
- L793 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_11
  SQL: SELECT COTIZACION.NUM_FACT,COTIZACION.SERIALTIPO, COTIZACION.FECHA, COTIZACION.Vendedor, COTIZACION.RIF, COTIZACION.NOMBRE, COTIZACION.TOTAL, COTIZACION.CODIGO,
- L842 [SELECT] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Get_12
  SQL: cr = "Select * from Correlativo where Correlativo.Tipo = '" & Tipo & "'"
- L842 [SELECT] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Get_13
  SQL: Select * from Correlativo where Correlativo.Tipo = '
- L851 [UPDATE] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Update_14
  SQL: cr = "Update Correlativo Set Correlativo.valor = Correlativo.Valor + 1 where Correlativo.tipo = '" & Tipo & "'"
- L851 [UPDATE] objeto: CORRELATIVO
  SP sugerido: usp_DatQBox_PtoVenta_CORRELATIVO_Update_15
  SQL: Update Correlativo Set Correlativo.valor = Correlativo.Valor + 1 where Correlativo.tipo = '
- L852 [EXEC] objeto: CR
  SP sugerido: usp_DatQBox_PtoVenta_CR_Exec_16
  SQL: DbConnection.Execute cr
- L880 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_17
  SQL: SQL = "select * from Facturas where num_fact = '" & TDBGrid2.Columns("NUM_FACT").Value & "' AND SERIALTIPO = '" & TDBGrid2.Columns("SERIALTIPO").Value & "'"
- L880 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_18
  SQL: select * from Facturas where num_fact = '
- L912 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_19
  SQL: SQL = "Select NUM_FACT, CANCELADA FROM Cotizacion WHERE NUM_FACT = '" & TDBGrid1.Columns("NUM_FACT").Value & "'"
- L912 [SELECT] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Get_20
  SQL: Select NUM_FACT, CANCELADA FROM Cotizacion WHERE NUM_FACT = '
- L921 [UPDATE] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Update_21
  SQL: SQL = "UPDATE Cotizacion SET CANCELADA = 'S', FECHA = '" & fechas & "' , FOB = " & NUM_FACT & " WHERE NUM_FACT = '" & TDBGrid1.Columns("NUM_FACT").Value & "'"
- L921 [UPDATE] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Update_22
  SQL: UPDATE Cotizacion SET CANCELADA = 'S', FECHA = '
- L930 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_23
  SQL: 'SQL = "Select Num_Fact, Fecha, Hora, Rif, Nombre, Total, * from Facturas WHERE FECHA >= " & FECHAS & "order by num_fact desc"
- L930 [SELECT] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Get_24
  SQL: Select Num_Fact, Fecha, Hora, Rif, Nombre, Total, * from Facturas WHERE FECHA >=
- L982 [SELECT] objeto: DETALLE_PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_PEDIDOS_Get_25
  SQL: SQL = "Select * from Detalle_pedidos where num_fact = " & TDBGrid1.Columns("Num_fact").Value & ""
- L982 [SELECT] objeto: DETALLE_PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_PEDIDOS_Get_26
  SQL: Select * from Detalle_pedidos where num_fact =
- L1239 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_27
  SQL: SQL = " SELECT Detalle_COTIZACION.COD_SERV, SUM([DETALLE_COTIZACION].[CANTIDAD]) AS TOTAL"
- L1239 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_28
  SQL: SELECT Detalle_COTIZACION.COD_SERV, SUM([DETALLE_COTIZACION].[CANTIDAD]) AS TOTAL
- L1250 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_29
  SQL: SQL = "Select * From Inventario where Codigo = '" & Detaller!Cod_serv & "'"
- L1250 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_30
  SQL: Select * From Inventario where Codigo = '
- L1260 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_31
  SQL: Product.Update
- L1269 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_32
  SQL: SQL = " Update Inventario"
- L1269 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_33
  SQL: Update Inventario
- L1272 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_34
  SQL: SQL = SQL & " (SELECT Detalle_Cotizacion.COD_SERV, SUM([Detalle_Cotizacion].[CANTIDAD]) AS TOTAL"
- L1272 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_35
  SQL: (SELECT Detalle_Cotizacion.COD_SERV, SUM([Detalle_Cotizacion].[CANTIDAD]) AS TOTAL
- L1283 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Update_36
  SQL: 'sql = "UPDATE PEDIDOS SET ANULADA = -1, CANCELADA = 'S' WHERE NUM_FACT = '" & TDBGrid1.Columns("NUM_FACT").Value & "'"
- L1283 [UPDATE] objeto: PEDIDOS
  SP sugerido: usp_DatQBox_PtoVenta_PEDIDOS_Update_37
  SQL: UPDATE PEDIDOS SET ANULADA = -1, CANCELADA = 'S' WHERE NUM_FACT = '
- L1285 [UPDATE] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Update_38
  SQL: SQL = "UPDATE COTIZACION SET ANULADA = -1, CANCELADA = 'S' WHERE NUM_FACT = '" & TDBGrid1.Columns("NUM_FACT").Value & "'"
- L1285 [UPDATE] objeto: COTIZACION
  SP sugerido: usp_DatQBox_PtoVenta_COTIZACION_Update_39
  SQL: UPDATE COTIZACION SET ANULADA = -1, CANCELADA = 'S' WHERE NUM_FACT = '

### DatQBox Compras\frmTrasladosInventario.frm
- L1380 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_1
  SQL: SQL = " SELECT * FROM inventario "
- L1380 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Get_2
  SQL: SELECT * FROM inventario
- L1410 [INSERT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Insert_3
  SQL: SQL = " INSERT INTO Inventario (Fecha_Inventario, ComisionDirecta3,ComisionDirecta2,ComisionDirecta1,ComisionDirecta,CuentaTiempo,Destacado,Foto,PLU, Eliminado, CODIGO, Referencia,...
- L1410 [INSERT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Insert_4
  SQL: INSERT INTO Inventario (Fecha_Inventario, ComisionDirecta3,ComisionDirecta2,ComisionDirecta1,ComisionDirecta,CuentaTiempo,Destacado,Foto,PLU, Eliminado, CODIGO, Referencia, Categor...
- L1411 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_5
  SQL: SQL = SQL & " SELECT inventario.Fecha_Inventario, inventario.ComisionDirecta3,inventario.ComisionDirecta2,inventario.ComisionDirecta1,inventario.ComisionDirecta,inventario.cuentati...
- L1411 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_6
  SQL: SELECT inventario.Fecha_Inventario, inventario.ComisionDirecta3,inventario.ComisionDirecta2,inventario.ComisionDirecta1,inventario.ComisionDirecta,inventario.cuentatiempo,inventari...
- L1423 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_7
  SQL: DbConnection.Execute SQL
- L1426 [SELECT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Compras_MOVINVENT_Get_8
  SQL: SQL = " SELECT * FROM MovInvent "
- L1426 [SELECT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Compras_MOVINVENT_Get_9
  SQL: SELECT * FROM MovInvent
- L1442 [INSERT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Compras_MOVINVENT_Insert_10
  SQL: SQL = "INSERT INTO MovInvent (CODIGO, CANTIDAD_NUEVA, ALICUOTA,PRECIO_VENTA,PRECIO_COMPRA, DOCUMENTO,PRODUCT, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CO_USUARIO)"
- L1442 [INSERT] objeto: MOVINVENT
  SP sugerido: usp_DatQBox_Compras_MOVINVENT_Insert_11
  SQL: INSERT INTO MovInvent (CODIGO, CANTIDAD_NUEVA, ALICUOTA,PRECIO_VENTA,PRECIO_COMPRA, DOCUMENTO,PRODUCT, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CO_USUARIO)
- L1578 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_12
  SQL: SQL = "Select * From " & xTablas
- L1578 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_13
  SQL: Select * From
- L1681 [INSERT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Insert_14
  SQL: SQL = " INSERT INTO Detalle_iNVENTARIO"
- L1681 [INSERT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Insert_15
  SQL: INSERT INTO Detalle_iNVENTARIO
- L1708 [INSERT] objeto: [DBO].[DETALLE_TRASLADOS]
  SP sugerido: usp_DatQBox_Compras_DBO_DETALLE_TRASLADOS_Insert_16
  SQL: SQL = " INSERT INTO [dbo].[Detalle_Traslados]"
- L1708 [INSERT] objeto: [DBO].[DETALLE_TRASLADOS]
  SP sugerido: usp_DatQBox_Compras_DBO_DETALLE_TRASLADOS_Insert_17
  SQL: INSERT INTO [dbo].[Detalle_Traslados]
- L1737 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Get_18
  SQL: SQL = "Select * From DETALLE_INVENTARIO where EXISTENCIA_ACTUAL > 0 AND Codigo = '" & !CodigoOrigen & "' AND ALMACEN = '" & origen.List(origen.ListIndex) & "' ORDER BY FECHA DESC "
- L1737 [SELECT] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Get_19
  SQL: Select * From DETALLE_INVENTARIO where EXISTENCIA_ACTUAL > 0 AND Codigo = '
- L1766 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Update_20
  SQL: SQL = " UPDATE DETALLE_INVENTARIO SET old = 0, existencia_actual = existencia_actual - " & ReSto & " WHERE CODIGO = '" & !CodigoOrigen & "' AND ALMACEN = '" & ProductDetalle!ALMACE...
- L1766 [UPDATE] objeto: DETALLE_INVENTARIO
  SP sugerido: usp_DatQBox_Compras_DETALLE_INVENTARIO_Update_21
  SQL: UPDATE DETALLE_INVENTARIO SET old = 0, existencia_actual = existencia_actual -
- L1785 [INSERT] objeto: [DBO].[TRASLADOS]
  SP sugerido: usp_DatQBox_Compras_DBO_TRASLADOS_Insert_22
  SQL: SQL = " INSERT INTO [dbo].[Traslados]"
- L1785 [INSERT] objeto: [DBO].[TRASLADOS]
  SP sugerido: usp_DatQBox_Compras_DBO_TRASLADOS_Insert_23
  SQL: INSERT INTO [dbo].[Traslados]
- L1854 [SELECT] objeto: DETALLE_TRASLADOS
  SP sugerido: usp_DatQBox_Compras_DETALLE_TRASLADOS_Get_24
  SQL: SQL = "Select * From Detalle_Traslados"
- L1854 [SELECT] objeto: DETALLE_TRASLADOS
  SP sugerido: usp_DatQBox_Compras_DETALLE_TRASLADOS_Get_25
  SQL: Select * From Detalle_Traslados
- L1895 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_26
  SQL: SQL = " SELECT dbo.Inventario.CODIGO, dbo.Inventario.Referencia, dbo.Inventario.Categoria, dbo.Inventario.Tipo, dbo.Inventario.DESCRIPCION,"
- L1895 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_27
  SQL: SELECT dbo.Inventario.CODIGO, dbo.Inventario.Referencia, dbo.Inventario.Categoria, dbo.Inventario.Tipo, dbo.Inventario.DESCRIPCION,
- L2036 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_28
  SQL: Select Case UCase(crParamDef.ParameterFieldName)
- L2311 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_29
  SQL: SQL = "Select * From " & Xtablas1
- L2364 [SELECT] objeto: ALMACEN
  SP sugerido: usp_DatQBox_Compras_ALMACEN_Get_30
  SQL: SQL = "Select Descripcion from almacen"
- L2364 [SELECT] objeto: ALMACEN
  SP sugerido: usp_DatQBox_Compras_ALMACEN_Get_31
  SQL: Select Descripcion from almacen
- L2434 [SELECT] objeto: UNIDADES
  SP sugerido: usp_DatQBox_Compras_UNIDADES_Get_32
  SQL: cr = "Select * from unidades"
- L2434 [SELECT] objeto: UNIDADES
  SP sugerido: usp_DatQBox_Compras_UNIDADES_Get_33
  SQL: Select * from unidades
- L2642 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Update_34
  SQL: TDBGrid4.Update
- L2653 [SELECT] objeto: UNIDADES
  SP sugerido: usp_DatQBox_Compras_UNIDADES_Get_35
  SQL: cr = "Select * from unidades WHERE UNIDAD = '" & TDBGrid4.Columns("Unidaddestino").Value & "'"
- L2653 [SELECT] objeto: UNIDADES
  SP sugerido: usp_DatQBox_Compras_UNIDADES_Get_36
  SQL: Select * from unidades WHERE UNIDAD = '
- L2663 [SELECT] objeto: UNIDADES
  SP sugerido: usp_DatQBox_Compras_UNIDADES_Get_37
  SQL: cr = "Select * from unidades WHERE UNIDAD = '" & TDBGrid4.Columns("UnidadOrigen").Value & "'"

### DatQBox Admin\frmConsultasVentas.frm
- L1623 [INSERT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Admin_DETALLE_Insert_1
  SQL: SQL = " INSERT INTO Detalle_" & tabla.Caption & " ( NUM_FACT, SERIALTIPO, COD_SERV, DESCRIPCION, FECHA, CANTIDAD, PRECIO, TOTAL, ANULADA, Co_Usuario, HORA, NOTA, unidad, Alicuota, ...
- L1623 [INSERT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Admin_DETALLE_Insert_2
  SQL: INSERT INTO Detalle_
- L1624 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_3
  SQL: SQL = SQL & " SELECT NUM_FACT, SERIALTIPO, COD_SERV + '?' AS COD_SERV , DESCRIPCION, FECHA, CANTIDAD, PRECIO, TOTAL, ANULADA, Co_Usuario, HORA, NOTA, unidad, Alicuota, PRECIO_DESCU...
- L1624 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_4
  SQL: SELECT NUM_FACT, SERIALTIPO, COD_SERV + '?' AS COD_SERV , DESCRIPCION, FECHA, CANTIDAD, PRECIO, TOTAL, ANULADA, Co_Usuario, HORA, NOTA, unidad, Alicuota, PRECIO_DESCUENTO, DESCUENT...
- L1631 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Admin_SQL_Exec_5
  SQL: DbConnection.Execute SQL
- L1658 [INSERT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Insert_6
  SQL: SQL = " INSERT INTO " & tabla.Caption & " (NUM_FACT , SERIALTIPO , CODIGO , FECHA , FECHA_veN , HORA , NOMBRE , "
- L1671 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_7
  SQL: SQL = SQL & " SELECT NUM_FACT + '?' AS NUM_FACT , SERIALTIPO , CODIGO , FECHA , FECHA_veN , HORA , NOMBRE , "
- L1671 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_8
  SQL: SELECT NUM_FACT + '?' AS NUM_FACT , SERIALTIPO , CODIGO , FECHA , FECHA_veN , HORA , NOMBRE ,
- L1692 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_9
  SQL: SQL = SQL & " SELECT NUM_FACT + '?' AS NUM_FACT, SERIALTIPO, COD_SERV AS COD_SERV , DESCRIPCION, FECHA, CANTIDAD, PRECIO, TOTAL, ANULADA, Co_Usuario, HORA, NOTA, unidad, Alicuota, ...
- L1692 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_10
  SQL: SELECT NUM_FACT + '?' AS NUM_FACT, SERIALTIPO, COD_SERV AS COD_SERV , DESCRIPCION, FECHA, CANTIDAD, PRECIO, TOTAL, ANULADA, Co_Usuario, HORA, NOTA, unidad, Alicuota, PRECIO_DESCUEN...
- L1751 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_11
  SQL: cr = "Select * From " & tabla & " where " & Busqueda.Text & " >= '" & fdesde & "' and " & Busqueda.Text & " <= '" & fhasta & "' order by NUM_FACT DESC"
- L1751 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_12
  SQL: Select * From
- L1762 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_13
  SQL: vReporte.Tag = "SELECT * FROM " & tabla & " WHERE NUM_FACT = '" & DATA1.Recordset!NUM_FACT & "' AND serialtipo = '" & DATA1.Recordset!serialtipo & "' and tipo_orden = '" & DATA1.Re...
- L1859 [DELETE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Admin_DETALLE_Delete_14
  SQL: SQL = SQL & " delete From Detalle_" & tabla.Caption & " "
- L1859 [DELETE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Admin_DETALLE_Delete_15
  SQL: delete From Detalle_
- L1888 [DELETE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Delete_16
  SQL: SQL = SQL & " delete From " & tabla.Caption & " "
- L1941 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Get_17
  SQL: SQL = "SELECT * From Clientes WHERE Codigo = '" & Codigo & "' "
- L1941 [SELECT] objeto: CLIENTES
  SP sugerido: usp_DatQBox_Admin_CLIENTES_Get_18
  SQL: SELECT * From Clientes WHERE Codigo = '
- L2009 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_19
  SQL: Select Case UCase(crParamDef.ParameterFieldName)
- L2088 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Update_20
  SQL: DbConnection.Execute "UPDATE " & tabla & " SET FECHAANULADA = NULL WHERE NUM_FACT = '" & DATA1.Recordset!NUM_FACT & "' AND SERIALTIPO = '" & DATA1.Recordset!serialtipo & "' "
- L2114 [SELECT] objeto: LIBROFACTURASHIST
  SP sugerido: usp_DatQBox_Admin_LIBROFACTURASHIST_Get_21
  SQL: SQL = "SELECT * From libroFacturasHist WHERE desde = '" & FechaDesde.Value & "' and hasta = '" & FechaHasta.Value & "'"
- L2114 [SELECT] objeto: LIBROFACTURASHIST
  SP sugerido: usp_DatQBox_Admin_LIBROFACTURASHIST_Get_22
  SQL: SELECT * From libroFacturasHist WHERE desde = '
- L2134 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_23
  SQL: SQL = " SELECT dbo.Inventario.Categoria, Detalle_" & tabla & ".NUM_FACT, Detalle_" & tabla & ".COD_SERV, Detalle_" & tabla & ".DESCRIPCION, Detalle_" & tabla & ".FECHA,"
- L2134 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_24
  SQL: SELECT dbo.Inventario.Categoria, Detalle_
- L2161 [SELECT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Admin_DETALLE_Get_25
  SQL: SQL = "Select * from detalle_" & tabla & " where Num_fact = '" & pRecordset!NUM_FACT & "' AND SERIALTIPO = '" & pRecordset!serialtipo & "' AND NOTA = '" & pRecordset!tipo_orden & "...
- L2161 [SELECT] objeto: DETALLE_
  SP sugerido: usp_DatQBox_Admin_DETALLE_Get_26
  SQL: Select * from detalle_
- L2447 [SELECT] objeto: CATEGORIA
  SP sugerido: usp_DatQBox_Admin_CATEGORIA_Get_27
  SQL: cr = "Select * From categoria "
- L2447 [SELECT] objeto: CATEGORIA
  SP sugerido: usp_DatQBox_Admin_CATEGORIA_Get_28
  SQL: Select * From categoria
- L2454 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Admin_UNKNOWN_Get_29
  SQL: cr = "Select * From " & xTablas & " where Fecha >= '" & fdesde & "' and Fecha <= '" & fhasta & "' order by NUM_FACT DESC"

### DatQBox PtoVenta\frmDetalleTrans.frm
- L833 [UPDATE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Update_1
  SQL: SQL = "update detalle_" & Tb_Table & " set anulada = true where num_fact = '" & NUM_FACT & "' AND COD_SERV = '" & data1.Recordset!COD_SERV & "'"
- L833 [UPDATE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Update_2
  SQL: update detalle_
- L837 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_3
  SQL: SQL = " UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA + " & data1.Recordset!cantidad & " WHERE CODIGO = '" & data1.Recordset!COD_SERV & "'"
- L837 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Update_4
  SQL: UPDATE INVENTARIO SET EXISTENCIA = EXISTENCIA +
- L838 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_PtoVenta_SQL_Exec_5
  SQL: DbConnection.Execute SQL
- L843 [UPDATE] objeto: INVENTARIO_AUX
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_AUX_Update_6
  SQL: SQL = " UPDATE INVENTARIO_aux SET cantidad = cantidad + " & data1.Recordset!cantidad & " WHERE CODIGO = '" & data1.Recordset!COD_SERV & "'"
- L843 [UPDATE] objeto: INVENTARIO_AUX
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_AUX_Update_7
  SQL: UPDATE INVENTARIO_aux SET cantidad = cantidad +
- L872 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_8
  SQL: SQL = "UPDATE " & Tb_Table & " SET ANULADA = 1, Observ = '" & Motivo & "', fechaanulada = '" & xFecha & "' WHERE NUM_FACT = '" & NUM_FACT & "' "
- L878 [UPDATE] objeto: DETALLE_
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_Update_9
  SQL: SQL = "UPDATE Detalle_" & Tb_Table & " SET ANULADA = 1 WHERE NUM_FACT = '" & NUM_FACT & "' and serialtipo = '" & vSerialFiscal & "'"
- L885 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Update_10
  SQL: SQL = "UPDATE facturas SET ANULADA = TRUE, Observ = '" & Motivo & "', fechaanulada = '" & xFecha & "' WHERE NUM_FACT = '" & NUM_FACT & "' AND PAGO = 'Nota' and serialtipo = '" & vS...
- L885 [UPDATE] objeto: FACTURAS
  SP sugerido: usp_DatQBox_PtoVenta_FACTURAS_Update_11
  SQL: UPDATE facturas SET ANULADA = TRUE, Observ = '
- L971 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_12
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "=" + Chr(&H2) 'Select the peripheral device.
- L975 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_13
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L976 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_14
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L1061 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_15
  SQL: 'sWrittenData = sWrittenData + Chr(&H1B) + "t" + Chr(&H0) 'Select the character code table.
- L1062 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_16
  SQL: 'sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters.
- L1069 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_17
  SQL: sWrittenData = sWrittenData + Chr(&H1B) + "R" + Chr(&H0) 'Select international characters
- L1428 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_18
  SQL: cr = "Select Num_Fact, Fecha, Cod_serv,Descripcion, Cantidad, Alicuota, Precio, Total From " & Me.Tag & " where num_fact = " & NUM_FACT.Text & " AND NOTA = '" & MEMORIA & "' AND SE...
- L1428 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_19
  SQL: Select Num_Fact, Fecha, Cod_serv,Descripcion, Cantidad, Alicuota, Precio, Total From
- L1431 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_20
  SQL: cr = "Select Num_Fact, Fecha, Cod_serv,Descripcion, Cantidad, Alicuota, Precio, Total From " & Me.Tag & " where num_fact = '" & NUM_FACT.Text & "' AND NOTA = '" & MEMORIA & "' AND ...
- L1458 [SELECT] objeto: DETALLE_FORMAPAGO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGO_Get_21
  SQL: SQL = "Select Tipo, Banco, Cuenta,Numero,Fecha_Retencion, Monto, Num_Fact from detalle_FormaPago" & xtab & " where num_fact = " & NUM_FACT & " AND MEMORIA = '" & MEMORIA.Text & "' ...
- L1458 [SELECT] objeto: DETALLE_FORMAPAGO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGO_Get_22
  SQL: Select Tipo, Banco, Cuenta,Numero,Fecha_Retencion, Monto, Num_Fact from detalle_FormaPago
- L1461 [SELECT] objeto: DETALLE_FORMAPAGO
  SP sugerido: usp_DatQBox_PtoVenta_DETALLE_FORMAPAGO_Get_23
  SQL: SQL = "Select Tipo, Banco, Cuenta,Numero,Fecha_Retencion, Monto, Num_Fact from detalle_FormaPago" & xtab & " where num_fact = '" & NUM_FACT & "' AND MEMORIA = '" & MEMORIA.Text & "...
- L1482 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_24
  SQL: TDataLite1.Recordset.Update
- L1690 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_25
  SQL: cr = " Select " & vCampo_Uno & "+" & "' '+" & vCampo_Dos & "+" & "' '+" & vCampo_Tres & "+" & "' '+" & vCampo_Cuatro & "+" & "' '+" & vCampo_Cinco & " as Descripciones,descripcion,...
- L1693 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_26
  SQL: cr = " Select " & vCampo_Uno & "+" & "' '+" & vCampo_Dos & "+" & "' '+" & vCampo_Tres & "+" & "' '+" & vCampo_Cuatro & "+" & "' '+" & vCampo_Cinco & " as Descripciones,descripcion,...
- L1696 [SELECT] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_PtoVenta_INVENTARIO_Get_27
  SQL: cr = " Select " & vCampo_Uno & "+" & "' '+" & vCampo_Dos & "+" & "' '+" & vCampo_Tres & "+" & "' '+" & vCampo_Cuatro & "+" & "' '+" & vCampo_Cinco & " as Descripciones,descripcion,...

### DatQBox PtoVenta\Querys.bas
- L14 [EXEC] objeto: COMMIT
  SP sugerido: usp_DatQBox_PtoVenta_COMMIT_Exec_1
  SQL: Const MSG1 = "Execute Commit or Rollback First."
- L14 [EXEC] objeto: COMMIT
  SP sugerido: usp_DatQBox_PtoVenta_COMMIT_Exec_2
  SQL: Execute Commit or Rollback First.
- L36 [EXEC] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Exec_3
  SQL: Const MSG23 = "Execute "
- L61 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_4
  SQL: Const MSG48 = "Select Microsoft Access Database to Compact"
- L61 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_5
  SQL: Select Microsoft Access Database to Compact
- L64 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_6
  SQL: Const MSG51 = "Select Microsoft Access Database to Compact to"
- L64 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_7
  SQL: Select Microsoft Access Database to Compact to
- L68 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_8
  SQL: Const MSG55 = "Select Microsoft Access Database to Create"
- L68 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_9
  SQL: Select Microsoft Access Database to Create
- L263 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_10
  SQL: Select Case qdf.Type
- L269 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_11
  SQL: ActionQueryType = "Update"
- L374 [UPDATE] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Update_12
  SQL: recRecordset2.Update
- L525 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_13
  SQL: Select Case rFldType
- L559 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_14
  SQL: Select Case rType
- L638 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_15
  SQL: Select Case rnType
- L870 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_16
  SQL: Select Case Val(sTmp)
- L891 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_17
  SQL: ' Select Case gnFormType
- L899 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_18
  SQL: 'Select Case gnRSType
- L908 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_19
  SQL: ' End Select
- L1183 [EXEC] objeto: IT
  SP sugerido: usp_DatQBox_PtoVenta_IT_Exec_20
  SQL: 'no name so just try to execute it
- L1190 [EXEC] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Exec_21
  SQL: qdfTmp.Execute
- L1424 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_22
  SQL: Select Case Mid(sTmp, 1, InStr(1, sTmp, "=") - 1)
- L1859 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_23
  SQL: Select Case gnDataType
- L1939 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_24
  SQL: GSJoseDb.Execute "select * into " & sConnect & StripOwner(sNewTblName) & " from " & StripOwner(rsFromTbl)
- L1939 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_25
  SQL: select * into
- L1964 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_26
  SQL: GSJoseDb.Execute "select " & sField & " into " & sConnect & sNewTblName & sFrom
- L2042 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_PtoVenta_UNKNOWN_Get_27
  SQL: GSJoseDb.Execute "select * into " & sNewTblName & " from " & sConnect & sOldTblName

### DatQBox Compras\frmCambiaPrecios.frm
- L1506 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_1
  SQL: SQL = " SELECT CODIGO, FECHA, " & vCampo_Uno & "+" & "' '+" & vCampo_Dos & "+" & "' '+" & vCampo_Tres & "+" & "' '+" & vCampo_Cuatro & "+" & "' '+" & vCampo_Cinco & " as DESCRIPCIO...
- L1506 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_2
  SQL: SELECT CODIGO, FECHA,
- L1982 [EXEC] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Exec_3
  SQL: cn.Execute " DROP TABLE Inventario_Temp"
- L1984 [EXEC] objeto: SQLTEXT
  SP sugerido: usp_DatQBox_Compras_SQLTEXT_Exec_4
  SQL: cn.Execute SQLTEXT
- L1988 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_5
  SQL: SQL = " UPDATE INVENTARIO SET PRECIO_VENTA =b.PRECIO_01_NEW , PRECIO_VENTA1 = b.PRECIO_02_NEW, PRECIO_VENTA2=b.PRECIO_03_NEW,"
- L1988 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_6
  SQL: UPDATE INVENTARIO SET PRECIO_VENTA =b.PRECIO_01_NEW , PRECIO_VENTA1 = b.PRECIO_02_NEW, PRECIO_VENTA2=b.PRECIO_03_NEW,
- L1995 [EXEC] objeto: SQL
  SP sugerido: usp_DatQBox_Compras_SQL_Exec_7
  SQL: cn.Execute SQL
- L1999 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_8
  SQL: SQL = " UPDATE INVENTARIO SET ALICUOTA = 1 WHERE CO_USUARIO = 'EXENTO'"
- L1999 [UPDATE] objeto: INVENTARIO
  SP sugerido: usp_DatQBox_Compras_INVENTARIO_Update_9
  SQL: UPDATE INVENTARIO SET ALICUOTA = 1 WHERE CO_USUARIO = 'EXENTO'
- L2003 [UPDATE] objeto: FORMULAS
  SP sugerido: usp_DatQBox_Compras_FORMULAS_Update_10
  SQL: SQL = "UPDATE FORMULAS SET VALOR = " & tasa_dolarN & " WHERE CODIGO = 'BSF'"
- L2003 [UPDATE] objeto: FORMULAS
  SP sugerido: usp_DatQBox_Compras_FORMULAS_Update_11
  SQL: UPDATE FORMULAS SET VALOR =
- L2011 [UPDATE] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Compras_TASA_MONEDA_Update_12
  SQL: SQL = "UPDATE tasa_moneda SET Tasa_venta = " & tasa_dolarN & " WHERE Moneda = 'Dollar US'"
- L2011 [UPDATE] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Compras_TASA_MONEDA_Update_13
  SQL: UPDATE tasa_moneda SET Tasa_venta =
- L2096 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_14
  SQL: SQL = " SELECT '0' as acceso, LEFT( dbo.Inventario.categoria + ' ' + dbo.Inventario.tipo + ' ' + dbo.Inventario.descripcion,20) as nombre,"
- L2096 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_15
  SQL: SELECT '0' as acceso, LEFT( dbo.Inventario.categoria + ' ' + dbo.Inventario.tipo + ' ' + dbo.Inventario.descripcion,20) as nombre,
- L2198 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_16
  SQL: Select Case obj_Field.Type
- L2314 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Compras_TASA_MONEDA_Get_17
  SQL: SQL = "Select * from tasa_moneda where Moneda = 'Dollar US' or Moneda = '$' "
- L2314 [SELECT] objeto: TASA_MONEDA
  SP sugerido: usp_DatQBox_Compras_TASA_MONEDA_Get_18
  SQL: Select * from tasa_moneda where Moneda = 'Dollar US' or Moneda = '$'
- L2414 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_19
  SQL: SQL = " Select Inventario.Codigo, Inventario.Referencia,Inventario.Fecha, Inventario.Linea, Inventario.Categoria, Inventario.Tipo, Inventario.Descripcion, Inventario.Marca, Inventa...
- L2414 [SELECT] objeto: UNKNOWN
  SP sugerido: usp_DatQBox_Compras_UNKNOWN_Get_20
  SQL: Select Inventario.Codigo, Inventario.Referencia,Inventario.Fecha, Inventario.Linea, Inventario.Categoria, Inventario.Tipo, Inventario.Descripcion, Inventario.Marca, Inventario.Clas...

