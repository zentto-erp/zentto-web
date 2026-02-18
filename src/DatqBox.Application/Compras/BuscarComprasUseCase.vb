Imports DatqBox.Application.Abstractions
Imports System.Data

Namespace DatqBox.Application.Compras
    Public Class BuscarComprasUseCase
        Private ReadOnly _sql As ISqlExecutor

        Public Sub New(sql As ISqlExecutor)
            _sql = sql
        End Sub

        ''' <summary>
        ''' Busca compras para seleccion en dialogo modal.
        ''' </summary>
        Public Function Ejecutar(filter As BuscarComprasFilter) As DataTable
            Dim tabla = SanitizeTable(filter.TipoDocumento)

            Dim query As String =
                "SELECT TOP " & filter.Limite.ToString() &
                " Num_fact, Num_control, Fecha, FechaVence, Nombre, Rif, " &
                "Total, Monto_gra, Iva, Exento, Cod_Proveedor " &
                "FROM " & tabla & " "

            Dim parameters As New Dictionary(Of String, Object)

            If Not String.IsNullOrWhiteSpace(filter.TextoBusqueda) Then
                query &= "WHERE (Nombre LIKE @Busq OR Rif LIKE @Busq OR Num_fact LIKE @Busq) "
                parameters.Add("@Busq", "%" & filter.TextoBusqueda & "%")
            End If

            query &= "ORDER BY Fecha DESC, Nombre ASC"

            Return _sql.Query(query, parameters)
        End Function

        Private Shared Function SanitizeTable(name As String) As String
            Select Case name.ToUpperInvariant()
                Case "COMPRAS" : Return "COMPRAS"
                Case "DEVOLUCIONCOMPRAS" : Return "DEVOLUCIONCOMPRAS"
                Case "COMPRASNOTAS" : Return "COMPRASNOTAS"
                Case Else : Return "COMPRAS"
            End Select
        End Function
    End Class
End Namespace
