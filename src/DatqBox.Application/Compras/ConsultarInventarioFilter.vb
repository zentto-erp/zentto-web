Namespace DatqBox.Application.Compras
    Public Class ConsultarInventarioFilter
        Public Property FechaDesde As DateTime
        Public Property FechaHasta As DateTime
        Public Property CodigoProducto As String = String.Empty
        Public Property Almacen As String = String.Empty
        Public Property Limite As Integer = 500
    End Class
End Namespace
