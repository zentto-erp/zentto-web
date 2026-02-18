Imports DatqBox.Application.Abstractions
Imports System.Data

Namespace DatqBox.Application.Compras
    Public Class ConsultarInventarioUseCase
        Private ReadOnly _sql As ISqlExecutor

        Public Sub New(sql As ISqlExecutor)
            _sql = sql
        End Sub

        ''' <summary>
        ''' Maestro de inventario con existencias.
        ''' </summary>
        Public Function ObtenerMaestro(Optional limite As Integer = 1000) As DataTable
            Return _sql.Query(
                "SELECT TOP " & limite.ToString() &
                " CODIGO, DESCRIPCION, EXISTENCIA, CATEGORIA, LINEA, MARCA, CLASE, TIPO, " &
                "PRECIO_COMPRA, PRECIO_VENTA, PRECIO_VENTA1, PRECIO_VENTA2, PRECIO_VENTA3, " &
                "PORCENTAJE, UBICACION, UNIDAD, ALICUOTA, MINIMO, MAXIMO " &
                "FROM Inventario WHERE Eliminado = 0 ORDER BY DESCRIPCION")
        End Function

        ''' <summary>
        ''' Movimientos de inventario por rango de fechas.
        ''' </summary>
        Public Function ObtenerMovimientos(filter As ConsultarInventarioFilter) As DataTable
            Dim query As String =
                "SELECT TOP " & filter.Limite.ToString() &
                " DOCUMENTO, CODIGO, PRODUCT, FECHA, MOTIVO, TIPO, " &
                "CANTIDAD_ACTUAL, CANTIDAD, CO_USUARIO, PRECIO_COMPRA, " &
                "Precio_venta, cantidad_nueva, Alicuota " &
                "FROM MovInvent WHERE FECHA >= @Desde AND FECHA <= @Hasta"

            Dim parameters As New Dictionary(Of String, Object) From {
                {"@Desde", filter.FechaDesde.Date},
                {"@Hasta", filter.FechaHasta.Date}
            }

            If Not String.IsNullOrWhiteSpace(filter.CodigoProducto) Then
                query &= " AND CODIGO = @Codigo"
                parameters.Add("@Codigo", filter.CodigoProducto)
            End If

            query &= " ORDER BY FECHA DESC"

            Return _sql.Query(query, parameters)
        End Function

        ''' <summary>
        ''' Detalle de precios por lote/almacen.
        ''' </summary>
        Public Function ObtenerDetallePorAlmacen(Optional almacen As String = "") As DataTable
            Dim query = "SELECT CODIGO, EXISTENCIA_ACTUAL, PROVEEDOR, FECHA, DOCUMENTO, LOTE, COSTO, ALMACEN " &
                        "FROM Detalle_Inventario"

            If Not String.IsNullOrWhiteSpace(almacen) Then
                query &= " WHERE ALMACEN = @Almacen"
                Return _sql.Query(query, New Dictionary(Of String, Object) From {{"@Almacen", almacen}})
            End If

            query &= " ORDER BY FECHA DESC"
            Return _sql.Query(query)
        End Function
    End Class
End Namespace
