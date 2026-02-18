Imports DatqBox.Application.Abstractions
Imports Microsoft.Data.SqlClient
Imports System.Data

Namespace DatqBox.Infrastructure.Data
    Public Class SqlClientExecutor
        Implements ISqlExecutor

        Private ReadOnly _connectionString As String

        ' Transactional state (set during ExecuteInTransaction)
        Private _activeConnection As SqlConnection
        Private _activeTransaction As SqlTransaction

        Public Sub New(connectionString As String)
            _connectionString = connectionString
        End Sub

        Private Sub New(connection As SqlConnection, transaction As SqlTransaction)
            _connectionString = connection.ConnectionString
            _activeConnection = connection
            _activeTransaction = transaction
        End Sub

        Public Function Query(queryText As String, Optional parameters As IDictionary(Of String, Object) = Nothing) As DataTable Implements ISqlExecutor.Query
            If _activeConnection IsNot Nothing Then
                Return QueryInternal(_activeConnection, _activeTransaction, queryText, parameters)
            End If

            Dim table As New DataTable()
            Using connection As New SqlConnection(_connectionString)
                Using command As New SqlCommand(queryText, connection)
                    AddParameters(command, parameters)
                    connection.Open()
                    Using adapter As New SqlDataAdapter(command)
                        adapter.Fill(table)
                    End Using
                End Using
            End Using
            Return table
        End Function

        Public Function Execute(queryText As String, Optional parameters As IDictionary(Of String, Object) = Nothing) As Integer Implements ISqlExecutor.Execute
            If _activeConnection IsNot Nothing Then
                Return ExecuteInternal(_activeConnection, _activeTransaction, queryText, parameters)
            End If

            Using connection As New SqlConnection(_connectionString)
                Using command As New SqlCommand(queryText, connection)
                    AddParameters(command, parameters)
                    connection.Open()
                    Return command.ExecuteNonQuery()
                End Using
            End Using
        End Function

        Public Sub ExecuteInTransaction(actions As Action(Of ISqlExecutor)) Implements ISqlExecutor.ExecuteInTransaction
            Using connection As New SqlConnection(_connectionString)
                connection.Open()
                Using transaction = connection.BeginTransaction()
                    Try
                        Dim txExecutor As New SqlClientExecutor(connection, transaction)
                        actions(txExecutor)
                        transaction.Commit()
                    Catch
                        transaction.Rollback()
                        Throw
                    End Try
                End Using
            End Using
        End Sub

        Private Shared Function QueryInternal(conn As SqlConnection, tx As SqlTransaction, queryText As String, parameters As IDictionary(Of String, Object)) As DataTable
            Dim table As New DataTable()
            Using command As New SqlCommand(queryText, conn, tx)
                AddParameters(command, parameters)
                Using adapter As New SqlDataAdapter(command)
                    adapter.Fill(table)
                End Using
            End Using
            Return table
        End Function

        Private Shared Function ExecuteInternal(conn As SqlConnection, tx As SqlTransaction, queryText As String, parameters As IDictionary(Of String, Object)) As Integer
            Using command As New SqlCommand(queryText, conn, tx)
                AddParameters(command, parameters)
                Return command.ExecuteNonQuery()
            End Using
        End Function

        Private Shared Sub AddParameters(command As SqlCommand, parameters As IDictionary(Of String, Object))
            If parameters Is Nothing Then Return
            For Each item In parameters
                command.Parameters.AddWithValue(item.Key, If(item.Value, DBNull.Value))
            Next
        End Sub
    End Class
End Namespace
