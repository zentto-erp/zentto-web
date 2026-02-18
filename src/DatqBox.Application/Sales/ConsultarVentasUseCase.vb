Imports DatqBox.Application.Abstractions
Imports System.Data

Namespace DatqBox.Application.Sales
    Public Class ConsultarVentasUseCase
        Private ReadOnly _sql As ISqlExecutor

        Public Sub New(sql As ISqlExecutor)
            _sql = sql
        End Sub

        Public Function Ejecutar(request As ConsultarVentasRequest) As DataTable
            Dim queryText As String = "SELECT * FROM Ventas WHERE Fecha BETWEEN @Desde AND @Hasta"
            Dim parameters As New Dictionary(Of String, Object) From {
                {"@Desde", request.FechaDesde},
                {"@Hasta", request.FechaHasta}
            }

            Return _sql.Query(queryText, parameters)
        End Function
    End Class
End Namespace
