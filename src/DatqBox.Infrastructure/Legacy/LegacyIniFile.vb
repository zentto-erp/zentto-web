Imports System.Text

Namespace DatqBox.Infrastructure.Legacy
    Public Class LegacyIniFile
        Private ReadOnly _sections As New Dictionary(Of String, Dictionary(Of String, String))(StringComparer.OrdinalIgnoreCase)

        Public Shared Function Load(path As String) As LegacyIniFile
            Dim ini As New LegacyIniFile()
            ini.Parse(path)
            Return ini
        End Function

        Public Function GetRaw(section As String, key As String, Optional defaultValue As String = "") As String
            If Not _sections.ContainsKey(section) Then Return defaultValue
            Dim kv = _sections(section)
            If Not kv.ContainsKey(key) Then Return defaultValue
            Return kv(key)
        End Function

        Public Function GetDecrypted(section As String, key As String, Optional defaultValue As String = "", Optional mode As LegacyCryptoMode = LegacyCryptoMode.Standard) As String
            Dim raw = GetRaw(section, key, defaultValue)
            If String.IsNullOrWhiteSpace(raw) Then Return raw
            Return LegacyCrypto.Decrypt(raw, mode)
        End Function

        Private Sub Parse(path As String)
            If Not IO.File.Exists(path) Then Return

            Dim currentSection As String = "default"
            _sections(currentSection) = New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)

            Dim enc = Encoding.GetEncoding(1252)
            Dim lines = IO.File.ReadAllLines(path, enc)

            For Each lineRaw In lines
                Dim line = lineRaw.Trim()
                If String.IsNullOrWhiteSpace(line) Then Continue For
                If line.StartsWith(";") OrElse line.StartsWith("#") Then Continue For

                If line.StartsWith("[") AndAlso line.EndsWith("]") Then
                    currentSection = line.Substring(1, line.Length - 2).Trim()
                    If Not _sections.ContainsKey(currentSection) Then
                        _sections(currentSection) = New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)
                    End If
                    Continue For
                End If

                Dim idx = line.IndexOf("="c)
                If idx <= 0 Then Continue For

                Dim key = line.Substring(0, idx).Trim()
                Dim value = line.Substring(idx + 1)

                If Not _sections.ContainsKey(currentSection) Then
                    _sections(currentSection) = New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)
                End If
                _sections(currentSection)(key) = value
            Next
        End Sub
    End Class
End Namespace
