Imports DatqBox.Application.Abstractions
Imports System.Data
Imports System.Windows.Forms

''' <summary>
''' Cambio masivo de precios de inventario.
''' Replica frmCambiaPrecios.frm de VB6.
''' </summary>
Public Class FrmCambiaPrecios
    Inherits Form

    Private ReadOnly _sql As ISqlExecutor

    Private ReadOnly _cboCategoria As New ComboBox()
    Private ReadOnly _txtPorcentaje As New TextBox()
    Private ReadOnly _cboPrecio As New ComboBox()
    Private ReadOnly _btnAplicar As New Button()
    Private ReadOnly _btnPreview As New Button()
    Private ReadOnly _grid As New DataGridView()
    Private ReadOnly _lblEstado As New Label()

    Public Sub New(sql As ISqlExecutor)
        _sql = sql
        AutoScaleMode = AutoScaleMode.Dpi
        BuildUi()
    End Sub

    Private Sub BuildUi()
        Text = "Cambiar Precios (.NET)"
        Width = 900
        Height = 600
        MinimumSize = New Drawing.Size(700, 450)
        StartPosition = FormStartPosition.CenterScreen

        Dim panelTop As New FlowLayoutPanel() With {
            .Dock = DockStyle.Top, .Height = 44,
            .FlowDirection = FlowDirection.LeftToRight, .Padding = New Padding(4)
        }

        _cboCategoria.Width = 150
        _cboCategoria.DropDownStyle = ComboBoxStyle.DropDownList
        _cboCategoria.Items.Add("(Todas)")

        _cboPrecio.Width = 130
        _cboPrecio.DropDownStyle = ComboBoxStyle.DropDownList
        _cboPrecio.Items.AddRange({"PRECIO_VENTA", "PRECIO_VENTA1", "PRECIO_VENTA2", "PRECIO_VENTA3"})
        _cboPrecio.SelectedIndex = 0

        _txtPorcentaje.Width = 70
        _txtPorcentaje.Text = "10"
        _txtPorcentaje.PlaceholderText = "%"

        _btnPreview.Text = "Vista Previa" : _btnPreview.Width = 90 : _btnPreview.Height = 28
        AddHandler _btnPreview.Click, AddressOf OnPreviewClick

        _btnAplicar.Text = "Aplicar Cambio" : _btnAplicar.Width = 110 : _btnAplicar.Height = 28
        AddHandler _btnAplicar.Click, AddressOf OnAplicarClick

        panelTop.Controls.Add(New Label() With {.Text = "Categoria:", .AutoSize = True, .Margin = New Padding(0, 6, 0, 0)})
        panelTop.Controls.Add(_cboCategoria)
        panelTop.Controls.Add(New Label() With {.Text = "Campo:", .AutoSize = True, .Margin = New Padding(4, 6, 0, 0)})
        panelTop.Controls.Add(_cboPrecio)
        panelTop.Controls.Add(New Label() With {.Text = "%:", .AutoSize = True, .Margin = New Padding(4, 6, 0, 0)})
        panelTop.Controls.Add(_txtPorcentaje)
        panelTop.Controls.Add(_btnPreview)
        panelTop.Controls.Add(_btnAplicar)

        _grid.Dock = DockStyle.Fill
        _grid.ReadOnly = True
        _grid.AllowUserToAddRows = False
        _grid.AllowUserToDeleteRows = False
        _grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect
        _grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
        _grid.RowHeadersVisible = False

        _lblEstado.Dock = DockStyle.Bottom
        _lblEstado.Height = 22 : _lblEstado.AutoSize = False
        _lblEstado.TextAlign = ContentAlignment.MiddleLeft
        _lblEstado.Text = "Seleccione categoria y porcentaje."

        Controls.Add(_grid)
        Controls.Add(_lblEstado)
        Controls.Add(panelTop)

        AddHandler Shown, Sub() CargarCategorias()
    End Sub

    Private Sub CargarCategorias()
        Try
            Dim dt = _sql.Query("SELECT DISTINCT Categoria FROM Inventario WHERE Eliminado = 0 AND Categoria IS NOT NULL ORDER BY Categoria")
            For Each row As DataRow In dt.Rows
                Dim cat = Convert.ToString(row(0))
                If Not String.IsNullOrWhiteSpace(cat) Then _cboCategoria.Items.Add(cat)
            Next
            _cboCategoria.SelectedIndex = 0
        Catch
        End Try
    End Sub

    Private Sub OnPreviewClick(sender As Object, e As EventArgs)
        Try
            Dim campo = _cboPrecio.SelectedItem.ToString()
            Dim porc As Decimal
            If Not Decimal.TryParse(_txtPorcentaje.Text, porc) Then
                MessageBox.Show("Porcentaje invalido.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning)
                Return
            End If

            Dim query = "SELECT Codigo, Descripcion, Categoria, " &
                        campo & " AS PrecioActual, " &
                        "ROUND(" & campo & " * (1 + @Porc / 100.0), 2) AS PrecioNuevo " &
                        "FROM Inventario WHERE Eliminado = 0"

            Dim params As New Dictionary(Of String, Object) From {{"@Porc", porc}}

            If _cboCategoria.SelectedIndex > 0 Then
                query &= " AND Categoria = @Cat"
                params.Add("@Cat", _cboCategoria.SelectedItem.ToString())
            End If

            query &= " ORDER BY Descripcion"

            Dim dt = _sql.Query(query, params)
            _grid.DataSource = dt
            _lblEstado.Text = $"Vista previa: {dt.Rows.Count} productos afectados con {porc}%"
        Catch ex As Exception
            MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub OnAplicarClick(sender As Object, e As EventArgs)
        Dim campo = _cboPrecio.SelectedItem.ToString()
        Dim porc As Decimal
        If Not Decimal.TryParse(_txtPorcentaje.Text, porc) Then
            MessageBox.Show("Porcentaje invalido.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        If MessageBox.Show($"Aplicar {porc}% a {campo}?", "Confirmar",
                           MessageBoxButtons.YesNo, MessageBoxIcon.Question) <> DialogResult.Yes Then Return

        Try
            Dim query = "UPDATE Inventario SET " & campo & " = ROUND(" & campo & " * (1 + @Porc / 100.0), 2) " &
                        "WHERE Eliminado = 0"
            Dim params As New Dictionary(Of String, Object) From {{"@Porc", porc}}

            If _cboCategoria.SelectedIndex > 0 Then
                query &= " AND Categoria = @Cat"
                params.Add("@Cat", _cboCategoria.SelectedItem.ToString())
            End If

            Dim rows = _sql.Execute(query, params)
            _lblEstado.Text = $"Precios actualizados: {rows} productos."
            OnPreviewClick(Nothing, Nothing)
        Catch ex As Exception
            MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub
End Class

