Imports System.Text

Namespace DatqBox.Infrastructure.Legacy
    Public Enum LegacyCryptoMode
        Standard = 0
        NtildeQuirk = 1
    End Enum

    Public Module LegacyCrypto
        Sub New()
            Encoding.RegisterProvider(CodePagesEncodingProvider.Instance)
        End Sub

        Private ReadOnly Ansi1252 As Encoding = Encoding.GetEncoding(1252)

        Public Function EnCryt(input As String, tipo As Integer, Optional mode As LegacyCryptoMode = LegacyCryptoMode.Standard) As String
            If String.IsNullOrEmpty(input) Then Return String.Empty

            Dim sourceBytes As Byte() = Ansi1252.GetBytes(input)
            Dim target(sourceBytes.Length - 1) As Byte

            For i As Integer = 0 To sourceBytes.Length - 1
                Dim code As Integer = sourceBytes(i)

                If tipo = 0 Then
                    If mode = LegacyCryptoMode.NtildeQuirk AndAlso code = 210 Then
                        code -= 1
                    Else
                        code -= 80
                    End If
                Else
                    If mode = LegacyCryptoMode.NtildeQuirk AndAlso code = 209 Then
                        code += 1
                    Else
                        code += 80
                    End If
                End If

                If code < 0 Then code = 0
                If code > 255 Then code = code Mod 256
                target(i) = CByte(code)
            Next

            Return Ansi1252.GetString(target)
        End Function

        Public Function Encrypt(input As String, Optional mode As LegacyCryptoMode = LegacyCryptoMode.Standard) As String
            Return EnCryt(input, 4, mode)
        End Function

        Public Function Decrypt(input As String, Optional mode As LegacyCryptoMode = LegacyCryptoMode.Standard) As String
            Return EnCryt(input, 0, mode)
        End Function
    End Module
End Namespace
