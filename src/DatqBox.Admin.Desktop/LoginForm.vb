Imports System.Windows.Forms
Imports DatqBox.Infrastructure.Legacy

Public Class LoginForm
    Inherits Form

    Private ReadOnly _txtUsuario As New TextBox()
    Private ReadOnly _txtClave As New TextBox()
    Private ReadOnly _btnEntrar As New Button()
    Private ReadOnly _btnCancelar As New Button()

    Public ReadOnly Property Usuario As String
        Get
            Return _txtUsuario.Text.Trim()
        End Get
    End Property

    Public ReadOnly Property PasswordPlain As String
        Get
            Return _txtClave.Text.Trim()
        End Get
    End Property

    Public ReadOnly Property EncryptedPassword As String
        Get
            Return LegacyCrypto.Encrypt(_txtClave.Text.Trim())
        End Get
    End Property

    Public Sub New()
        Text = "Login"
        Width = 380
        Height = 210
        StartPosition = FormStartPosition.CenterParent
        FormBorderStyle = FormBorderStyle.FixedDialog
        MaximizeBox = False
        MinimizeBox = False
        BuildUi()
    End Sub

    Private Sub BuildUi()
        Dim lblUsuario As New Label() With {
            .Text = "Usuario:",
            .Left = 20,
            .Top = 24,
            .Width = 80
        }

        _txtUsuario.Left = 110
        _txtUsuario.Top = 20
        _txtUsuario.Width = 230

        Dim lblClave As New Label() With {
            .Text = "Clave:",
            .Left = 20,
            .Top = 64,
            .Width = 80
        }

        _txtClave.Left = 110
        _txtClave.Top = 60
        _txtClave.Width = 230
        _txtClave.UseSystemPasswordChar = True

        _btnEntrar.Text = "Entrar"
        _btnEntrar.Left = 170
        _btnEntrar.Top = 110
        _btnEntrar.Width = 80
        AddHandler _btnEntrar.Click, AddressOf OnEntrarClick

        _btnCancelar.Text = "Cancelar"
        _btnCancelar.Left = 260
        _btnCancelar.Top = 110
        _btnCancelar.Width = 80
        AddHandler _btnCancelar.Click, Sub()
                                            DialogResult = DialogResult.Cancel
                                            Close()
                                        End Sub

        Controls.Add(lblUsuario)
        Controls.Add(_txtUsuario)
        Controls.Add(lblClave)
        Controls.Add(_txtClave)
        Controls.Add(_btnEntrar)
        Controls.Add(_btnCancelar)
    End Sub

    Private Sub OnEntrarClick(sender As Object, e As EventArgs)
        If String.IsNullOrWhiteSpace(_txtUsuario.Text) Then
            MessageBox.Show("Ingrese usuario.", "Login", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            _txtUsuario.Focus()
            Return
        End If

        DialogResult = DialogResult.OK
        Close()
    End Sub
End Class
