Imports System.Reflection

Friend Class AddonHostService
    Public Function LoadAndInitialize(folderPath As String, context As IAddonContext) As AddonLoadSummary
        Dim summary As New AddonLoadSummary()
        If String.IsNullOrWhiteSpace(folderPath) Then Return summary
        If Not IO.Directory.Exists(folderPath) Then
            IO.Directory.CreateDirectory(folderPath)
            Return summary
        End If

        Dim files = IO.Directory.GetFiles(folderPath, "*.dll", IO.SearchOption.TopDirectoryOnly)
        For Each filePath In files
            Try
                Dim asm = Assembly.LoadFrom(filePath)
                For Each t In asm.GetTypes()
                    If t.IsAbstract OrElse t.IsInterface Then Continue For
                    If Not GetType(IAddonModule).IsAssignableFrom(t) Then Continue For

                    Dim addon = CType(Activator.CreateInstance(t), IAddonModule)
                    addon.Initialize(context)
                    summary.LoadedModules.Add(addon.Name & " (" & addon.Id & ")")
                Next
            Catch ex As Exception
                summary.Errors.Add(IO.Path.GetFileName(filePath) & ": " & ex.Message)
            End Try
        Next
        Return summary
    End Function
End Class

Friend Class AddonLoadSummary
    Public ReadOnly Property LoadedModules As New List(Of String)()
    Public ReadOnly Property Errors As New List(Of String)()
End Class
