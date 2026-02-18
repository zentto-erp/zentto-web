Imports System.Windows.Forms

' Proportional auto-resize helper for legacy WinForms that use absolute coordinates.
Friend Class LegacyFormAutoScaler
    Private ReadOnly _form As Form
    Private ReadOnly _baseSize As Drawing.Size
    Private ReadOnly _metrics As New Dictionary(Of Control, ControlLayoutMetric)()
    Private _applying As Boolean

    Public Sub New(form As Form)
        _form = form
        _baseSize = form.ClientSize
        Capture(_form)
        AddHandler _form.Resize, AddressOf OnFormResize
    End Sub

    Public Shared Function Attach(form As Form) As LegacyFormAutoScaler
        Return New LegacyFormAutoScaler(form)
    End Function

    Private Sub Capture(parent As Control)
        For Each ctl As Control In parent.Controls
            If ctl.Dock = DockStyle.None Then
                _metrics(ctl) = New ControlLayoutMetric With {
                    .Left = ctl.Left,
                    .Top = ctl.Top,
                    .Width = ctl.Width,
                    .Height = ctl.Height,
                    .FontSize = ctl.Font.Size
                }
            End If
            Capture(ctl)
        Next
    End Sub

    Private Sub OnFormResize(sender As Object, e As EventArgs)
        If _applying Then Return
        If _baseSize.Width <= 0 OrElse _baseSize.Height <= 0 Then Return

        Dim sx = CDbl(_form.ClientSize.Width) / CDbl(_baseSize.Width)
        Dim sy = CDbl(_form.ClientSize.Height) / CDbl(_baseSize.Height)
        Dim sf = CSng(Math.Min(sx, sy))
        sf = Math.Max(0.9F, Math.Min(1.6F, sf))

        _applying = True
        Try
            For Each kvp In _metrics
                Dim ctl = kvp.Key
                If ctl.IsDisposed Then Continue For
                Dim m = kvp.Value
                ctl.Left = Math.Max(0, CInt(Math.Round(m.Left * sx)))
                ctl.Top = Math.Max(0, CInt(Math.Round(m.Top * sy)))
                ctl.Width = Math.Max(32, CInt(Math.Round(m.Width * sx)))
                ctl.Height = Math.Max(18, CInt(Math.Round(m.Height * sy)))
                ctl.Font = New Drawing.Font(ctl.Font.FontFamily, Math.Max(7.0F, m.FontSize * sf), ctl.Font.Style)
            Next
        Finally
            _applying = False
        End Try
    End Sub
End Class

Friend Class ControlLayoutMetric
    Public Property Left As Integer
    Public Property Top As Integer
    Public Property Width As Integer
    Public Property Height As Integer
    Public Property FontSize As Single
End Class
