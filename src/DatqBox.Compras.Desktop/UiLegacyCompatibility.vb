Imports System.Runtime.InteropServices

Friend Module UiLegacyCompatibility
    Friend Const SkinFrameworkClsid As String = "BD0C1912-66C3-49CC-8B12-7B347BF6C846"
    Friend Const CommandBarsClsid As String = "555E8FCC-830E-45CC-AF00-A012D5AE7451"
    Friend Const TrueDbGridClsid As String = "7FEC7313-D161-427C-A141-48E17931414B"

    Friend Function CanCreateCom(clsid As String) As Boolean
        Try
            If String.IsNullOrWhiteSpace(clsid) Then Return False
            Dim t = Type.GetTypeFromCLSID(New Guid(clsid), throwOnError:=False)
            If t Is Nothing Then Return False
            Dim obj = Activator.CreateInstance(t)
            If obj Is Nothing Then Return False
            Try
                Marshal.FinalReleaseComObject(obj)
            Catch
            End Try
            Return True
        Catch
            Return False
        End Try
    End Function
End Module

