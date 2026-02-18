Namespace DatqBox.Infrastructure.Legacy
    Public Module LegacySqlCatalog
        Public Const VentasPorFecha As String = "SELECT * FROM Ventas WHERE Fecha BETWEEN @Desde AND @Hasta"
    End Module
End Namespace
