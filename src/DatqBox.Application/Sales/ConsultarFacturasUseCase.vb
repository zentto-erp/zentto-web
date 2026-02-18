Imports DatqBox.Application.Abstractions
Imports System.Data

Namespace DatqBox.Application.Sales
    Public Class ConsultarFacturasUseCase
        Private ReadOnly _sql As ISqlExecutor

        Public Sub New(sql As ISqlExecutor)
            _sql = sql
        End Sub

        Public Function Ejecutar(filter As ConsultaFacturasFilter) As DataTable
            Dim queryText As String =
                "SELECT TOP " & filter.Limite.ToString() & " * " &
                "FROM FACTURAS " &
                "WHERE FECHA >= @Desde AND FECHA < @Hasta " &
                "ORDER BY NUM_FACT DESC"

            Dim parameters As New Dictionary(Of String, Object) From {
                {"@Desde", filter.FechaDesde.Date},
                {"@Hasta", filter.FechaHasta.Date.AddDays(1)}
            }

            Return _sql.Query(queryText, parameters)
        End Function
    End Class
End Namespace
