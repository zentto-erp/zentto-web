Imports System.Windows.Forms

Friend Class AddonContext
    Implements IAddonContext

    Private ReadOnly _registry As UiReferenceRegistry
    Private ReadOnly _leftPanel As Panel
    Private ReadOnly _udfRenderer As UdfRenderer
    Private ReadOnly _statusWriter As Action(Of String)
    Private ReadOnly _connectionResolver As Func(Of String)

    Public Sub New(
        registry As UiReferenceRegistry,
        leftPanel As Panel,
        udfRenderer As UdfRenderer,
        statusWriter As Action(Of String),
        connectionResolver As Func(Of String))
        _registry = registry
        _leftPanel = leftPanel
        _udfRenderer = udfRenderer
        _statusWriter = statusWriter
        _connectionResolver = connectionResolver
    End Sub

    Public ReadOnly Property ConnectionString As String Implements IAddonContext.ConnectionString
        Get
            Return _connectionResolver.Invoke()
        End Get
    End Property

    Public Function TryGetControl(referenceId As Integer, ByRef control As Control) As Boolean Implements IAddonContext.TryGetControl
        Return _registry.TryGetControl(referenceId, control)
    End Function

    Public Function TryResolveReference(referenceKey As String, ByRef referenceId As Integer) As Boolean Implements IAddonContext.TryResolveReference
        Return _registry.TryResolveReference(referenceKey, referenceId)
    End Function

    Public Sub AddActionButton(request As AddonButtonRequest) Implements IAddonContext.AddActionButton
        If request Is Nothing Then Throw New ArgumentNullException(NameOf(request))
        If request.ReferenceId <= 0 Then Throw New ArgumentOutOfRangeException(NameOf(request.ReferenceId))
        If String.IsNullOrWhiteSpace(request.Caption) Then Throw New ArgumentException("Caption requerido.", NameOf(request.Caption))

        Dim btn As New Button() With {
            .Width = 220,
            .Height = 38,
            .Left = 16,
            .Text = request.Caption
        }

        Dim maxBottom As Integer = 0
        For Each c As Control In _leftPanel.Controls
            maxBottom = Math.Max(maxBottom, c.Bottom)
        Next
        btn.Top = Math.Max(maxBottom + 8, 14)

        If request.Action IsNot Nothing Then
            AddHandler btn.Click, Sub() request.Action.Invoke()
        End If

        _leftPanel.Controls.Add(btn)
        _registry.Register(request.ReferenceId, $"Addon.Button.{request.ReferenceId}", btn)
    End Sub

    Public Sub RegisterUdf(definition As UdfDefinition) Implements IAddonContext.RegisterUdf
        _udfRenderer.Register(definition)
    End Sub

    Public Sub SetStatus(message As String) Implements IAddonContext.SetStatus
        _statusWriter.Invoke(message)
    End Sub
End Class
