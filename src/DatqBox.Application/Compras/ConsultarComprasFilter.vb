Namespace DatqBox.Application.Compras
    Public Class ConsultarComprasFilter
        Public Property FechaDesde As DateTime
        Public Property FechaHasta As DateTime
        Public Property TipoDocumento As String = "COMPRAS"
        Public Property CampoFiltro As String = String.Empty
        Public Property ValorFiltro As String = String.Empty
        Public Property Limite As Integer = 500
    End Class
End Namespace
