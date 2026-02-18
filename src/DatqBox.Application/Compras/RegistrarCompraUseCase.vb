Imports DatqBox.Application.Abstractions

Namespace DatqBox.Application.Compras
    ''' <summary>
    ''' Registra una compra completa dentro de una transaccion SQL.
    ''' Inserta cabecera, detalle, actualiza inventario, registra movimientos y cuenta por pagar.
    ''' </summary>
    Public Class RegistrarCompraUseCase
        Private ReadOnly _sql As ISqlExecutor

        Public Sub New(sql As ISqlExecutor)
            _sql = sql
        End Sub

        Public Sub Ejecutar(request As CompraRequest)
            _sql.ExecuteInTransaction(
                Sub(tx)
                    InsertarCabecera(tx, request)
                    For Each item In request.Detalle
                        InsertarDetalle(tx, request, item)
                        ActualizarInventario(tx, request, item)
                        InsertarMovimiento(tx, request, item)
                    Next
                    If request.Tipo.ToUpperInvariant() = "CREDITO" Then
                        InsertarCuentaPorPagar(tx, request)
                    End If
                End Sub)
        End Sub

        Private Shared Sub InsertarCabecera(sql As ISqlExecutor, r As CompraRequest)
            sql.Execute(
                "INSERT INTO COMPRAS " &
                "(NUM_FACT, Num_control, Fecha, FechaVence, Nombre, Rif, Cod_Proveedor, " &
                "Monto_gra, Iva, Exento, Total, Alicuota, Precio_dollar, Tipo, Descuento, Flete) " &
                "VALUES (@NumFact, @NumCtrl, @Fecha, @FechaVence, @Nombre, @Rif, @CodProv, " &
                "@MontoGra, @Iva, @Exento, @Total, @Alicuota, @Dollar, @Tipo, @Desc, @Flete)",
                New Dictionary(Of String, Object) From {
                    {"@NumFact", r.NumFact},
                    {"@NumCtrl", r.NumControl},
                    {"@Fecha", r.Fecha},
                    {"@FechaVence", r.FechaVence},
                    {"@Nombre", r.NombreProveedor},
                    {"@Rif", r.RifProveedor},
                    {"@CodProv", r.CodProveedor},
                    {"@MontoGra", r.MontoGravable},
                    {"@Iva", r.Iva},
                    {"@Exento", r.Exento},
                    {"@Total", r.Total},
                    {"@Alicuota", r.Alicuota},
                    {"@Dollar", r.PrecioDollar},
                    {"@Tipo", r.Tipo},
                    {"@Desc", r.Descuento},
                    {"@Flete", r.Flete}
                })
        End Sub

        Private Shared Sub InsertarDetalle(sql As ISqlExecutor, r As CompraRequest, item As CompraDetalleItem)
            sql.Execute(
                "INSERT INTO DETALLE_COMPRAS " &
                "(NUM_FACT, CODIGO, Referencia, COD_PROVEEDOR, DESCRIPCION, Und, FECHA, " &
                "CANTIDAD, PRECIO_COSTO, PRECIO_VENTA, PORCENTAJE, Alicuota, Flete, Tasa_Dolar) " &
                "VALUES (@NumFact, @Codigo, @Ref, @CodProv, @Desc, @Und, @Fecha, " &
                "@Cant, @Costo, @Venta, @Porc, @Alic, @Flete, @Dolar)",
                New Dictionary(Of String, Object) From {
                    {"@NumFact", r.NumFact},
                    {"@Codigo", item.Codigo},
                    {"@Ref", item.Referencia},
                    {"@CodProv", r.CodProveedor},
                    {"@Desc", item.Descripcion},
                    {"@Und", item.Unidad},
                    {"@Fecha", r.Fecha},
                    {"@Cant", item.Cantidad},
                    {"@Costo", item.PrecioCosto},
                    {"@Venta", item.PrecioVenta},
                    {"@Porc", item.Porcentaje},
                    {"@Alic", item.Alicuota},
                    {"@Flete", item.Flete},
                    {"@Dolar", item.TasaDolar}
                })
        End Sub

        Private Shared Sub ActualizarInventario(sql As ISqlExecutor, r As CompraRequest, item As CompraDetalleItem)
            sql.Execute(
                "UPDATE Inventario SET " &
                "EXISTENCIA = EXISTENCIA + @Cant, " &
                "PRECIO_COMPRA = @Costo, " &
                "PRECIO_VENTA = CASE WHEN @Venta > 0 THEN @Venta ELSE PRECIO_VENTA END " &
                "WHERE CODIGO = @Codigo",
                New Dictionary(Of String, Object) From {
                    {"@Cant", item.Cantidad},
                    {"@Costo", item.PrecioCosto},
                    {"@Venta", item.PrecioVenta},
                    {"@Codigo", item.Codigo}
                })
        End Sub

        Private Shared Sub InsertarMovimiento(sql As ISqlExecutor, r As CompraRequest, item As CompraDetalleItem)
            sql.Execute(
                "INSERT INTO MovInvent " &
                "(DOCUMENTO, CODIGO, PRODUCT, FECHA, MOTIVO, TIPO, CANTIDAD, " &
                "PRECIO_COMPRA, Precio_venta, Alicuota) " &
                "VALUES (@Doc, @Codigo, @Desc, @Fecha, 'Compra', 'Ingreso', @Cant, " &
                "@Costo, @Venta, @Alic)",
                New Dictionary(Of String, Object) From {
                    {"@Doc", r.NumFact},
                    {"@Codigo", item.Codigo},
                    {"@Desc", item.Descripcion},
                    {"@Fecha", r.Fecha},
                    {"@Cant", item.Cantidad},
                    {"@Costo", item.PrecioCosto},
                    {"@Venta", item.PrecioVenta},
                    {"@Alic", item.Alicuota}
                })
        End Sub

        Private Shared Sub InsertarCuentaPorPagar(sql As ISqlExecutor, r As CompraRequest)
            sql.Execute(
                "INSERT INTO P_PAGAR " &
                "(CODIGO, FECHA, DOCUMENTO, DEBE, PEND, SALDO, TIPO) " &
                "VALUES (@CodProv, @Fecha, @NumFact, @Total, @Total, @Total, 'FACTURA')",
                New Dictionary(Of String, Object) From {
                    {"@CodProv", r.CodProveedor},
                    {"@Fecha", r.Fecha},
                    {"@NumFact", r.NumFact},
                    {"@Total", r.Total}
                })
        End Sub
    End Class
End Namespace
