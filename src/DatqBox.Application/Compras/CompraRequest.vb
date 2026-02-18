Namespace DatqBox.Application.Compras
    Public Class CompraRequest
        Public Property NumFact As String = String.Empty
        Public Property NumControl As String = String.Empty
        Public Property CodProveedor As String = String.Empty
        Public Property NombreProveedor As String = String.Empty
        Public Property RifProveedor As String = String.Empty
        Public Property Fecha As DateTime
        Public Property FechaVence As DateTime
        Public Property Tipo As String = "CONTADO"
        Public Property MontoGravable As Decimal
        Public Property Iva As Decimal
        Public Property Exento As Decimal
        Public Property Total As Decimal
        Public Property Alicuota As Decimal = 16
        Public Property PrecioDollar As Decimal
        Public Property Descuento As Decimal
        Public Property Flete As Decimal
        Public Property Detalle As New List(Of CompraDetalleItem)
    End Class

    Public Class CompraDetalleItem
        Public Property Codigo As String = String.Empty
        Public Property Referencia As String = String.Empty
        Public Property Descripcion As String = String.Empty
        Public Property Unidad As String = "UND"
        Public Property Cantidad As Decimal
        Public Property PrecioCosto As Decimal
        Public Property PrecioVenta As Decimal
        Public Property Porcentaje As Decimal
        Public Property Alicuota As Decimal = 16
        Public Property Flete As Decimal
        Public Property TasaDolar As Decimal
    End Class
End Namespace
