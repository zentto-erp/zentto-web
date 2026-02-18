Imports System.Text.Json
Imports DatqBox.Infrastructure.Legacy

Friend Class AdminRuntimeConfig
    Public Property ConnectionString As String = String.Empty
    Public Property LegacyIniPath As String = String.Empty

    Public Shared Function Load(basePath As String) As AdminRuntimeConfig
        Dim cfg As New AdminRuntimeConfig()
        Dim filePath As String = IO.Path.Combine(basePath, "appsettings.json")

        If Not IO.File.Exists(filePath) Then
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
        If String.IsNullOrWhiteSpace(LegacyIniPath) Then Return

        Dim resolvedPath As String = LegacyIniPath
        If Not IO.Path.IsPathRooted(resolvedPath) Then
            resolvedPath = IO.Path.GetFullPath(IO.Path.Combine(basePath, resolvedPath))
        End If
        If Not IO.File.Exists(resolvedPath) Then Return

        Dim ini = LegacyIniFile.Load(resolvedPath)
        Dim rawConn = ini.GetRaw("DatosSQL", "Conexion", "")

        If LooksLikeSqlConnection(rawConn) Then
            ConnectionString = NormalizeLegacyConnection(rawConn)
            Return
        End If

        Dim decConn = LegacyCrypto.Decrypt(rawConn)
        If LooksLikeSqlConnection(decConn) Then
            ConnectionString = NormalizeLegacyConnection(decConn)
        End If
    End Sub

    Private Shared Function LooksLikeSqlConnection(value As String) As Boolean
        If String.IsNullOrWhiteSpace(value) Then Return False
        Dim x = value.ToUpperInvariant()
        Return x.Contains("SERVER=") AndAlso x.Contains("DATABASE=")
    End Function

    Private Shared Function NormalizeLegacyConnection(value As String) As String
        If String.IsNullOrWhiteSpace(value) Then Return value

        Dim raw = value.Replace("SQLNCLI10;", "", StringComparison.OrdinalIgnoreCase).
                        Replace("SQLNCLI11;", "", StringComparison.OrdinalIgnoreCase)

        Dim parts = raw.Split(";"c, StringSplitOptions.RemoveEmptyEntries)
        Dim cleaned As New List(Of String)()
        Dim hasEncrypt As Boolean = False
        Dim hasTrust As Boolean = False
        For Each part In parts
            Dim kv = part.Split({"="c}, 2)
            If kv.Length <> 2 Then Continue For
            Dim key = kv(0).Trim()
            Dim val = kv(1).Trim()
            If key.Equals("Provider", StringComparison.OrdinalIgnoreCase) Then Continue For
            If key.Equals("OLE DB Services", StringComparison.OrdinalIgnoreCase) Then Continue For
            If key.Equals("Persist Security Info", StringComparison.OrdinalIgnoreCase) Then Continue For
            If key.Equals("Encrypt", StringComparison.OrdinalIgnoreCase) Then hasEncrypt = True
            If key.Equals("TrustServerCertificate", StringComparison.OrdinalIgnoreCase) Then hasTrust = True
            cleaned.Add($"{key}={val}")
        Next
        If Not hasEncrypt Then cleaned.Add("Encrypt=False")
        If Not hasTrust Then cleaned.Add("TrustServerCertificate=True")
        Return String.Join(";", cleaned)
    End Function
End Class
