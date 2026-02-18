Namespace DatqBox.Domain.ValueObjects
    Public Class DatabaseConfig
        Public Property Server As String = String.Empty
        Public Property Database As String = String.Empty
        Public Property UserName As String = String.Empty
        Public Property Password As String = String.Empty

        Public Function BuildConnectionString() As String
            Return $"Server={Server};Database={Database};User Id={UserName};Password={Password};TrustServerCertificate=True;"
        End Function
    End Class
End Namespace
