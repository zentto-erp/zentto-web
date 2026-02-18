Imports System.Windows.Forms

Friend Class ComActiveXHost
    Inherits AxHost

    Public Sub New(clsid As String)
        MyBase.New(clsid)
    End Sub

    Public Function GetComObject() As Object
        Try
            Return GetOcx()
        Catch
            Return Nothing
        End Try
    End Function
End Class
