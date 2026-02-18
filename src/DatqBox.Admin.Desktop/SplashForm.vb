Imports System.Windows.Forms

Public Class SplashForm
    Inherits Form

    Private ReadOnly _title As New Label()
    Private ReadOnly _detail As New Label()

    Public Sub New()
        FormBorderStyle = FormBorderStyle.None
        StartPosition = FormStartPosition.CenterScreen
        Width = 520
        Height = 220
        BackColor = Drawing.Color.White
        BuildUi()
    End Sub

    Private Sub BuildUi()
        _title.Dock = DockStyle.Top
        _title.Height = 80
        _title.Font = New Drawing.Font("Segoe UI", 18.0F, Drawing.FontStyle.Bold)
        _title.TextAlign = Drawing.ContentAlignment.BottomCenter
        _title.Text = "DatqBox Administrativo SQL"

        _detail.Dock = DockStyle.Fill
        _detail.Font = New Drawing.Font("Segoe UI", 10.0F, Drawing.FontStyle.Regular)
        _detail.TextAlign = Drawing.ContentAlignment.TopCenter
        _detail.Text = "Inicializando menu, configuracion e integracion SQL..."

        Controls.Add(_detail)
        Controls.Add(_title)
    End Sub
End Class
