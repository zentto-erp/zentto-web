Imports System.Text.Json
Imports DatqBox.Infrastructure.Legacy

Friend Class ComprasRuntimeConfig
    Public Property ConnectionString As String = String.Empty
    Public Property LegacyIniPath As String = String.Empty

    Public Shared Function Load(basePath As String) As ComprasRuntimeConfig
        Dim cfg As New ComprasRuntimeConfig()
        Dim filePath As String = IO.Path.Combine(basePath, "appsettings.json")

        If Not IO.File.Exists(filePath) Then
            cfg.ResolveFallbackConnection(basePath)
            Return cfg
        End If

        Dim json As String = IO.File.ReadAllText(filePath)
        Using doc = JsonDocument.Parse(json)
            Dim dbNode As JsonElement
            If doc.RootElement.TryGetProperty("Database", dbNode) Then
                Dim connNode As JsonElement
                If dbNode.TryGetProperty("ConnectionString", connNode) Then
                    cfg.ConnectionString = connNode.GetString()
                End If
            End If

            Dim iniNode As JsonElement
            If doc.RootElement.TryGetProperty("LegacyIni", iniNode) Then
                Dim pathNode As JsonElement
                If iniNode.TryGetProperty("FilePath", pathNode) Then
                    cfg.LegacyIniPath = pathNode.GetString()
                End If
            End If
        End Using

        cfg.ResolveFallbackConnection(basePath)
        Return cfg
    End Function

    Private Sub ResolveFallbackConnection(basePath As String)
        If Not String.IsNullOrWhiteSpace(ConnectionString) Then Return

        ' Try legacy INI path from config
        If Not String.IsNullOrWhiteSpace(LegacyIniPath) Then
            If TryLoadFromIni(basePath, LegacyIniPath) Then Return
        End If

        ' Try common legacy INI locations
        Dim commonPaths = {
            IO.Path.Combine(basePath, "DatqBox.ini"),
            IO.Path.Combine(basePath, "..", "DatqBox.ini"),
            IO.Path.Combine(basePath, "..", "..", "DatqBox.ini")
        }
        For Each iniPath In commonPaths
            If TryLoadFromIni(basePath, iniPath) Then Return
        Next
    End Sub

    Private Function TryLoadFromIni(basePath As String, iniPath As String) As Boolean
        Dim resolvedPath As String = iniPath
        If Not IO.Path.IsPathRooted(resolvedPath) Then
            resolvedPath = IO.Path.GetFullPath(IO.Path.Combine(basePath, resolvedPath))
        End If
        If Not IO.File.Exists(resolvedPath) Then Return False

        Dim ini = LegacyIniFile.Load(resolvedPath)
        Dim rawConn = ini.GetRaw("DatosSQL", "Conexion", "")

        If LooksLikeSqlConnection(rawConn) Then
            ConnectionString = NormalizeLegacyConnection(rawConn)
            Return True
        End If

        Dim decConn = LegacyCrypto.Decrypt(rawConn)
        If LooksLikeSqlConnection(decConn) Then
            ConnectionString = NormalizeLegacyConnection(decConn)
            Return True
        End If

        Return False
    End Function

    Private Shared Function LooksLikeSqlConnection(value As String) As Boolean
        If String.IsNullOrWhiteSpace(value) Then Return False
        Dim x = value.ToUpperInvariant()
        Return x.Contains("SERVER=") AndAlso x.Contains("DATABASE=")
    End Function

    Private Shared Function NormalizeLegacyConnection(value As String) As String
        If String.IsNullOrWhiteSpace(value) Then Return value
        Return value.Replace("SQLNCLI10;", "", StringComparison.OrdinalIgnoreCase).
                     Replace("SQLNCLI11;", "", StringComparison.OrdinalIgnoreCase)
    End Function
End Class

