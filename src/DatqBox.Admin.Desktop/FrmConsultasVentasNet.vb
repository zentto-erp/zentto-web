Imports DatqBox.Application.Sales
Imports System.Data
Imports System.Windows.Forms

Public Class FrmConsultasVentasNet
    Inherits Form

    Private ReadOnly _useCase As ConsultarFacturasUseCase

    Private ReadOnly _fechaDesde As New DateTimePicker()
    Private ReadOnly _fechaHasta As New DateTimePicker()
    Private ReadOnly _btnBuscar As New Button()
    Private ReadOnly _lblEstado As New Label()
    Private ReadOnly _grid As New DataGridView()

    Public Sub New(useCase As ConsultarFacturasUseCase)
        _useCase = useCase
        AutoScaleMode = AutoScaleMode.Dpi
        BuildUi()
    End Sub

    Private Sub BuildUi()
        Text = "Consultas de Ventas (.NET)"
        Width = 1100
        Height = 700
        MinimumSize = New Drawing.Size(900, 560)
        StartPosition = FormStartPosition.CenterScreen

        Dim panelTop As New TableLayoutPanel() With {
            .Dock = DockStyle.Top,
            .Height = 56,
            .ColumnCount = 6,
            .RowCount = 1,
            .Padding = New Padding(8, 10, 8, 8)
        }
        panelTop.ColumnStyles.Add(New ColumnStyle(SizeType.AutoSize))
        panelTop.ColumnStyles.Add(New ColumnStyle(SizeType.AutoSize))
        panelTop.ColumnStyles.Add(New ColumnStyle(SizeType.AutoSize))
        panelTop.ColumnStyles.Add(New ColumnStyle(SizeType.Percent, 100.0F))
        panelTop.ColumnStyles.Add(New ColumnStyle(SizeType.AutoSize))
        panelTop.ColumnStyles.Add(New ColumnStyle(SizeType.AutoSize))

        _fechaDesde.Format = DateTimePickerFormat.Short
        _fechaHasta.Format = DateTimePickerFormat.Short
        _fechaDesde.Value = DateTime.Today.AddDays(-30)
        _fechaHasta.Value = DateTime.Today

        _fechaDesde.Width = 120
        _fechaHasta.Width = 120

        _btnBuscar.Text = "Buscar"
        _btnBuscar.Width = 90
        _btnBuscar.Height = 30
        AddHandler _btnBuscar.Click, AddressOf OnBuscarClick

        _lblEstado.AutoSize = True
        _lblEstado.Anchor = AnchorStyles.Left
        _lblEstado.Text = "Listo."

        _grid.Dock = DockStyle.Fill
        _grid.ReadOnly = True
        _grid.AllowUserToAddRows = False
        _grid.AllowUserToDeleteRows = False
        _grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect
        _grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
        _grid.RowHeadersVisible = False
        _grid.EnableHeadersVisualStyles = False

        panelTop.Controls.Add(New Label() With {.Text = "Desde:", .AutoSize = True, .Anchor = AnchorStyles.Left}, 0, 0)
        panelTop.Controls.Add(_fechaDesde, 1, 0)
        panelTop.Controls.Add(New Label() With {.Text = "Hasta:", .AutoSize = True, .Anchor = AnchorStyles.Left}, 2, 0)
        panelTop.Controls.Add(_fechaHasta, 3, 0)
        panelTop.Controls.Add(_btnBuscar, 4, 0)
        panelTop.Controls.Add(_lblEstado, 5, 0)

        Controls.Add(_grid)
        Controls.Add(panelTop)
    End Sub

    Private Sub OnBuscarClick(sender As Object, e As EventArgs)
        Try
            _btnBuscar.Enabled = False
            _lblEstado.Text = "Consultando..."
            Cursor = Cursors.WaitCursor
            System.Windows.Forms.Application.DoEvents()

            Dim filter As New ConsultaFacturasFilter With {
                .FechaDesde = _fechaDesde.Value.Date,
                .FechaHasta = _fechaHasta.Value.Date,
                .Limite = 500
            }

            Dim dt As DataTable = _useCase.Ejecutar(filter)
            _grid.DataSource = dt
            _lblEstado.Text = "Filas: " & dt.Rows.Count.ToString()
        Catch ex As Exception
            _lblEstado.Text = "Error en consulta."
            MessageBox.Show(ex.Message, "Consulta de ventas", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            Cursor = Cursors.Default
            _btnBuscar.Enabled = True
        End Try
    End Sub
End Class
