Namespace DatqBox.Application.Configuration
    Public Interface IAppSettings
        Function GetValue(key As String, Optional defaultValue As String = "") As String
    End Interface
End Namespace
