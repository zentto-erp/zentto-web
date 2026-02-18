Imports DatqBox.Application.Abstractions
Imports System.Data
Imports System.Windows.Forms

''' <summary>
''' Gestion de usuarios y permisos de acceso por modulo.
''' Replica frmCUsuarios.frm de VB6.
''' </summary>
Public Class FrmCUsuarios
    Inherits Form

    Private ReadOnly _sql As ISqlExecutor

    Private ReadOnly _gridUsuarios As New DataGridView()
    Private ReadOnly _gridAccesos As New DataGridView()
    Private ReadOnly _splitter As New SplitContainer()
    Private ReadOnly _btnNuevo As New Button()
    Private ReadOnly _btnEliminar As New Button()
    Private ReadOnly _btnDuplicar As New Button()
    Private ReadOnly _lblEstado As New Label()

    Public Sub New(sql As ISqlExecutor)
        _sql = sql
        AutoScaleMode = AutoScaleMode.Dpi
        BuildUi()
    End Sub

    Private Sub BuildUi()
        Text = "Gestion de Usuarios (.NET)"
        Width = 1000
        Height = 600
        MinimumSize = New Drawing.Size(800, 500)
        StartPosition = FormStartPosition.CenterScreen

        Dim panelTop As New FlowLayoutPanel() With {
            .Dock = DockStyle.Top, .Height = 40,
            .FlowDirection = FlowDirection.LeftToRight, .Padding = New Padding(4)
        }

        _btnNuevo.Text = "Nuevo Usuario" : _btnNuevo.Width = 110 : _btnNuevo.Height = 28
        AddHandler _btnNuevo.Click, AddressOf OnNuevoClick
        _btnEliminar.Text = "Eliminar" : _btnEliminar.Width = 80 : _btnEliminar.Height = 28
        AddHandler _btnEliminar.Click, AddressOf OnEliminarClick
        _btnDuplicar.Text = "Duplicar" : _btnDuplicar.Width = 80 : _btnDuplicar.Height = 28
        AddHandler _btnDuplicar.Click, AddressOf OnDuplicarClick

        panelTop.Controls.AddRange({_btnNuevo, _btnEliminar, _btnDuplicar})

        _splitter.Dock = DockStyle.Fill
        _splitter.Orientation = Orientation.Horizontal
        _splitter.SplitterDistance = 250

        ConfigureGrid(_gridUsuarios)
        ConfigureGrid(_gridAccesos)
        AddHandler _gridUsuarios.SelectionChanged, AddressOf OnUsuarioSelectionChanged

        _splitter.Panel1.Controls.Add(_gridUsuarios)
        _splitter.Panel2.Controls.Add(_gridAccesos)

        _lblEstado.Dock = DockStyle.Bottom : _lblEstado.Height = 22
        _lblEstado.AutoSize = False : _lblEstado.TextAlign = ContentAlignment.MiddleLeft
        _lblEstado.Text = "Cargando..."

        Controls.Add(_splitter)
        Controls.Add(_lblEstado)
        Controls.Add(panelTop)

        AddHandler Shown, Sub() CargarUsuarios()
    End Sub

    Private Shared Sub ConfigureGrid(grid As DataGridView)
        grid.Dock = DockStyle.Fill : grid.ReadOnly = True
        grid.AllowUserToAddRows = False : grid.AllowUserToDeleteRows = False
        grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect
        grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
        grid.RowHeadersVisible = False
    End Sub

    Private Sub CargarUsuarios()
        Try
            Dim dt = _sql.Query("SELECT * FROM Usuarios ORDER BY COD_USUARIO")
            _gridUsuarios.DataSource = dt
            _lblEstado.Text = $"Usuarios: {dt.Rows.Count}"
        Catch ex As Exception
            MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub OnUsuarioSelectionChanged(sender As Object, e As EventArgs)
        If _gridUsuarios.CurrentRow Is Nothing Then Return
        Try
            Dim codUsuario = Convert.ToString(_gridUsuarios.CurrentRow.Cells("COD_USUARIO").Value)
            Dim dt = _sql.Query(
                "SELECT * FROM AccesoUsuarios WHERE COD_USUARIO = @Cod",
                New Dictionary(Of String, Object) From {{"@Cod", codUsuario}})
            _gridAccesos.DataSource = dt
        Catch
        End Try
    End Sub

    Private Sub OnNuevoClick(sender As Object, e As EventArgs)
        Dim codigo = InputBox("Codigo del nuevo usuario:", "Nuevo Usuario")
        If String.IsNullOrWhiteSpace(codigo) Then Return
        Dim nombre = InputBox("Nombre del usuario:", "Nuevo Usuario")
        If String.IsNullOrWhiteSpace(nombre) Then Return

        Try
            _sql.Execute(
                "INSERT INTO Usuarios (COD_USUARIO, NOMBRE, CLAVE) VALUES (@Cod, @Nom, '')",
                New Dictionary(Of String, Object) From {{"@Cod", codigo}, {"@Nom", nombre}})
            CargarUsuarios()
            _lblEstado.Text = $"Usuario {codigo} creado."
        Catch ex As Exception
            MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub OnEliminarClick(sender As Object, e As EventArgs)
        If _gridUsuarios.CurrentRow Is Nothing Then Return
        Dim codUsuario = Convert.ToString(_gridUsuarios.CurrentRow.Cells("COD_USUARIO").Value)
        If MessageBox.Show($"Eliminar usuario {codUsuario}?", "Confirmar",
                           MessageBoxButtons.YesNo, MessageBoxIcon.Question) <> DialogResult.Yes Then Return
        Try
            _sql.Execute("DELETE FROM AccesoUsuarios WHERE COD_USUARIO = @Cod",
                New Dictionary(Of String, Object) From {{"@Cod", codUsuario}})
            _sql.Execute("DELETE FROM Usuarios WHERE COD_USUARIO = @Cod",
                New Dictionary(Of String, Object) From {{"@Cod", codUsuario}})
            CargarUsuarios()
            _lblEstado.Text = $"Usuario {codUsuario} eliminado."
        Catch ex As Exception
            MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub OnDuplicarClick(sender As Object, e As EventArgs)
        If _gridUsuarios.CurrentRow Is Nothing Then Return
        Dim codOrigen = Convert.ToString(_gridUsuarios.CurrentRow.Cells("COD_USUARIO").Value)
        Dim codNuevo = InputBox("Codigo para el usuario duplicado:", "Duplicar Usuario")
        If String.IsNullOrWhiteSpace(codNuevo) Then Return

        Try
            _sql.Execute(
                "INSERT INTO Usuarios (COD_USUARIO, NOMBRE, CLAVE) " &
                "SELECT @CodNew, NOMBRE, '' FROM Usuarios WHERE COD_USUARIO = @CodOrig",
                New Dictionary(Of String, Object) From {{"@CodNew", codNuevo}, {"@CodOrig", codOrigen}})
            _sql.Execute(
                "INSERT INTO AccesoUsuarios (COD_USUARIO, MODULO, Updates, Addnews, Deletes) " &
                "SELECT @CodNew, MODULO, Updates, Addnews, Deletes FROM AccesoUsuarios WHERE COD_USUARIO = @CodOrig",
                New Dictionary(Of String, Object) From {{"@CodNew", codNuevo}, {"@CodOrig", codOrigen}})
            CargarUsuarios()
            _lblEstado.Text = $"Usuario {codNuevo} duplicado de {codOrigen}."
        Catch ex As Exception
            MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Shared Function InputBox(prompt As String, title As String) As String
        Return Microsoft.VisualBasic.Interaction.InputBox(prompt, title)
    End Function
End Class

