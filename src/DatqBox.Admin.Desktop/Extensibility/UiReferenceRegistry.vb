Imports System.Windows.Forms
Imports System.Linq

Friend Class UiReferenceRegistry
    Private ReadOnly _byId As New Dictionary(Of Integer, Control)()
    Private ReadOnly _idByKey As New Dictionary(Of String, Integer)(StringComparer.OrdinalIgnoreCase)

    Public Sub Register(referenceId As Integer, referenceKey As String, control As Control)
        If control Is Nothing Then Return
        If referenceId <= 0 Then Throw New ArgumentOutOfRangeException(NameOf(referenceId))
        If String.IsNullOrWhiteSpace(referenceKey) Then Throw New ArgumentException("Reference key requerido.", NameOf(referenceKey))

        _byId(referenceId) = control
        _idByKey(referenceKey) = referenceId
    End Sub

    Public Function TryGetControl(referenceId As Integer, ByRef control As Control) As Boolean
        Return _byId.TryGetValue(referenceId, control)
    End Function

    Public Function TryResolveReference(referenceKey As String, ByRef referenceId As Integer) As Boolean
        If String.IsNullOrWhiteSpace(referenceKey) Then Return False
        Return _idByKey.TryGetValue(referenceKey, referenceId)
    End Function

    Public Function Snapshot() As List(Of UiReferenceSnapshotItem)
        Dim result As New List(Of UiReferenceSnapshotItem)()
        For Each kvp In _byId.OrderBy(Function(x) x.Key)
            Dim keyName = _idByKey.FirstOrDefault(Function(k) k.Value = kvp.Key).Key
            Dim ctl = kvp.Value
            Dim item As New UiReferenceSnapshotItem With {
                .ReferenceId = kvp.Key,
                .ReferenceKey = If(keyName, String.Empty),
                .ControlName = ctl.Name,
                .ControlType = ctl.GetType().FullName,
                .Bounds = ctl.Bounds
            }
            result.Add(item)
        Next
        Return result
    End Function

    Public Sub ApplyTooltips(toolTip As ToolTip)
        If toolTip Is Nothing Then Return
        For Each item In Snapshot()
            Dim ctl As Control = Nothing
            If _byId.TryGetValue(item.ReferenceId, ctl) Then
                toolTip.SetToolTip(ctl, $"Ref {item.ReferenceId} | {item.ReferenceKey}")
            End If
        Next
    End Sub
End Class

Friend Class UiReferenceSnapshotItem
    Public Property ReferenceId As Integer
    Public Property ReferenceKey As String
    Public Property ControlName As String
    Public Property ControlType As String
    Public Property Bounds As Drawing.Rectangle
End Class
