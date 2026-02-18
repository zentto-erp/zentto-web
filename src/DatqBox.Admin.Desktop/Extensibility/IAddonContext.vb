Imports System.Windows.Forms

Public Interface IAddonContext
    ReadOnly Property ConnectionString As String
    Function TryGetControl(referenceId As Integer, ByRef control As Control) As Boolean
    Function TryResolveReference(referenceKey As String, ByRef referenceId As Integer) As Boolean
    Sub AddActionButton(request As AddonButtonRequest)
    Sub RegisterUdf(definition As UdfDefinition)
    Sub SetStatus(message As String)
End Interface
