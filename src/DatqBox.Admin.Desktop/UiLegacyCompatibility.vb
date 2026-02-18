Imports System.Runtime.InteropServices

Friend Module UiLegacyCompatibility
    Friend Const SkinFrameworkClsid As String = "BD0C1912-66C3-49CC-8B12-7B347BF6C846"
    Friend Const CommandBarsClsid As String = "555E8FCC-830E-45CC-AF00-A012D5AE7451"
    Friend Const TrueDbGridClsid As String = "7FEC7313-D161-427C-A141-48E17931414B"

    Friend Function BuildCompatibilitySummary() As String
        Dim skin = ProbeCom(New Guid(SkinFrameworkClsid))
        Dim bars = ProbeCom(New Guid(CommandBarsClsid))
        Dim grid = ProbeCom(New Guid(TrueDbGridClsid))
        Return $"Codejock.Skin={skin} | Codejock.CommandBars={bars} | TrueDBGrid={grid}"
    End Function

    Friend Function IsComRegistered(clsid As String) As Boolean
        Try
            If String.IsNullOrWhiteSpace(clsid) Then Return False
            Dim t = Type.GetTypeFromCLSID(New Guid(clsid), throwOnError:=False)
            Return t IsNot Nothing
        Catch
            Return False
        End Try
    End Function

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
                ' Ignore release errors.
            End Try
            Return True
        Catch
            Return False
        End Try
    End Function

    Private Function ProbeCom(clsid As Guid) As String
        Try
            Dim t = Type.GetTypeFromCLSID(clsid, throwOnError:=False)
            If t Is Nothing Then Return "No registrado"
            Return "Registrado"
        Catch
            Return "Error"
        End Try
    End Function
End Module
