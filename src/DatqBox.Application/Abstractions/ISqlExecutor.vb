Imports System.Data

Namespace DatqBox.Application.Abstractions
    Public Interface ISqlExecutor
        Function Query(queryText As String, Optional parameters As IDictionary(Of String, Object) = Nothing) As DataTable
        Function Execute(queryText As String, Optional parameters As IDictionary(Of String, Object) = Nothing) As Integer

        ''' <summary>
        ''' Ejecuta multiples operaciones dentro de una transaccion SQL.
        ''' Si el Action completa sin excepcion, hace Commit; si falla, Rollback.
        ''' </summary>
        Sub ExecuteInTransaction(actions As Action(Of ISqlExecutor))
    End Interface
End Namespace
