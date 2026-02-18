Imports DatqBox.Application.Abstractions
Imports System.Data

Namespace DatqBox.Application.Compras
    Public Class ConsultarComprasUseCase
        Private ReadOnly _sql As ISqlExecutor

        Public Sub New(sql As ISqlExecutor)
            _sql = sql
        End Sub

        ''' <summary>
        ''' Consulta compras (maestro) filtradas por fecha y campo opcional.
        ''' </summary>
        Public Function Ejecutar(filter As ConsultarComprasFilter) As DataTable
            Dim baseQuery As String =
                "SELECT TOP " & filter.Limite.ToString() &
                " NUM_FACT, Num_control, Fecha, FechaVence, Nombre, Rif, " &
                "Monto_gra, Iva, Exento, IvaRetenido, Total, Alicuota, " &
                "Precio_dollar, Cod_Proveedor, Tipo " &
                "FROM " & SanitizeTableName(filter.TipoDocumento) & " " &
                "WHERE Fecha >= @Desde AND Fecha <= @Hasta"

            Dim parameters As New Dictionary(Of String, Object) From {
                {"@Desde", filter.FechaDesde.Date},
                {"@Hasta", filter.FechaHasta.Date}
            }

            If Not String.IsNullOrWhiteSpace(filter.CampoFiltro) AndAlso
               Not String.IsNullOrWhiteSpace(filter.ValorFiltro) Then
                Dim safeField = SanitizeFieldName(filter.CampoFiltro)
                If Not String.IsNullOrEmpty(safeField) Then
                    baseQuery &= " AND " & safeField & " LIKE @Filtro"
                    parameters.Add("@Filtro", "%" & filter.ValorFiltro & "%")
                End If
            End If

            baseQuery &= " ORDER BY Fecha DESC, Nombre ASC"

            Return _sql.Query(baseQuery, parameters)
        End Function

        ''' <summary>
        ''' Obtiene el detalle de una compra específica.
        ''' </summary>
        Public Function ObtenerDetalle(numFact As String, codProveedor As String, tipoDocumento As String) As DataTable
            Dim tabla = "DETALLE_" & SanitizeTableName(tipoDocumento)
            Dim query As String =
                "SELECT CODIGO, Referencia, DESCRIPCION, Und, CANTIDAD, " &
                "PRECIO_COSTO, PRECIO_VENTA, PORCENTAJE, Alicuota, Flete, Tasa_Dolar " &
                "FROM " & tabla & " " &
                "WHERE NUM_FACT = @NumFact AND COD_PROVEEDOR = @CodProv"

            Dim parameters As New Dictionary(Of String, Object) From {
                {"@NumFact", numFact},
                {"@CodProv", codProveedor}
            }

            Return _sql.Query(query, parameters)
        End Function

        Private Shared Function SanitizeTableName(name As String) As String
            ' Solo permite nombres de tabla conocidos
            Select Case name.ToUpperInvariant()
                Case "COMPRAS" : Return "COMPRAS"
                Case "DEVOLUCIONCOMPRAS" : Return "DEVOLUCIONCOMPRAS"
                Case "COMPRASNOTAS" : Return "COMPRASNOTAS"
                Case Else : Return "COMPRAS"
            End Select
        End Function

        Private Shared Function SanitizeFieldName(name As String) As String
            ' Solo permite campos conocidos de la tabla COMPRAS
            Dim allowed = {"NUM_FACT", "Num_control", "Nombre", "Rif", "Cod_Proveedor", "Tipo"}
            Dim upper = name.ToUpperInvariant()
            For Each field In allowed
                If field.ToUpperInvariant() = upper Then Return field
            Next
            Return String.Empty
        End Function
    End Class
End Namespace
