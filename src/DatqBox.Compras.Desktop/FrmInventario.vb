Imports DatqBox.Application.Compras
Imports System.Data
Imports System.Windows.Forms

''' <summary>
''' Dashboard de inventario con 3 tabs: Maestro, Movimientos, Detalle de precios.
''' Replica frmInventario.frm de VB6.
''' </summary>
Public Class FrmInventario
    Inherits Form

    Private ReadOnly _useCase As ConsultarInventarioUseCase

    ' ── Tab control ───────────────────────────────────────
    Private ReadOnly _tabs As New TabControl()

    ' ── Tab 1: Maestro ────────────────────────────────────
    Private ReadOnly _gridMaestro As New DataGridView()

    ' ── Tab 2: Movimientos ────────────────────────────────
    Private ReadOnly _gridMov As New DataGridView()
    Private ReadOnly _fechaMovDesde As New DateTimePicker()
    Private ReadOnly _fechaMovHasta As New DateTimePicker()
    Private ReadOnly _txtMovCodigo As New TextBox()
    Private ReadOnly _btnMovBuscar As New Button()

    ' ── Tab 3: Detalle precios ────────────────────────────
    Private ReadOnly _gridDetalle As New DataGridView()
    Private ReadOnly _txtAlmacen As New TextBox()
    Private ReadOnly _btnDetalleBuscar As New Button()

    Private ReadOnly _lblEstado As New Label()

    Public Sub New(useCase As ConsultarInventarioUseCase)
        _useCase = useCase
        AutoScaleMode = AutoScaleMode.Dpi
        BuildUi()
    End Sub

    Private Sub BuildUi()
        Text = "Control de Inventario (.NET)"
        Width = 1150
        Height = 700
        MinimumSize = New Drawing.Size(900, 550)
        StartPosition = FormStartPosition.CenterScreen

        _tabs.Dock = DockStyle.Fill

        ' ── Tab 1: Maestro de Inventario ──────────────────
        Dim tab1 As New TabPage("Maestro de Inventario")
        ConfigureGrid(_gridMaestro)
        tab1.Controls.Add(_gridMaestro)
        _tabs.TabPages.Add(tab1)

        ' ── Tab 2: Movimientos Entrada/Salida ─────────────
        Dim tab2 As New TabPage("Movimientos Entrada/Salida")
        Dim panelMovTop As New FlowLayoutPanel() With {
            .Dock = DockStyle.Top,
            .Height = 42,
            .FlowDirection = FlowDirection.LeftToRight,
            .Padding = New Padding(4)
        }

        _fechaMovDesde.Format = DateTimePickerFormat.Short
        _fechaMovHasta.Format = DateTimePickerFormat.Short
        _fechaMovDesde.Value = DateTime.Today.AddDays(-30)
        _fechaMovHasta.Value = DateTime.Today
        _fechaMovDesde.Width = 110
        _fechaMovHasta.Width = 110

        _txtMovCodigo.Width = 120
        _txtMovCodigo.PlaceholderText = "Codigo prod..."

        _btnMovBuscar.Text = "Consultar"
        _btnMovBuscar.Width = 80
        _btnMovBuscar.Height = 28
        AddHandler _btnMovBuscar.Click, AddressOf OnMovBuscarClick

        panelMovTop.Controls.Add(New Label() With {.Text = "Desde:", .AutoSize = True, .Margin = New Padding(0, 6, 0, 0)})
        panelMovTop.Controls.Add(_fechaMovDesde)
        panelMovTop.Controls.Add(New Label() With {.Text = "Hasta:", .AutoSize = True, .Margin = New Padding(4, 6, 0, 0)})
        panelMovTop.Controls.Add(_fechaMovHasta)
        panelMovTop.Controls.Add(New Label() With {.Text = "Codigo:", .AutoSize = True, .Margin = New Padding(4, 6, 0, 0)})
        panelMovTop.Controls.Add(_txtMovCodigo)
        panelMovTop.Controls.Add(_btnMovBuscar)

        ConfigureGrid(_gridMov)
        tab2.Controls.Add(_gridMov)
        tab2.Controls.Add(panelMovTop)
        _tabs.TabPages.Add(tab2)

        ' ── Tab 3: Detalle de Precios ─────────────────────
        Dim tab3 As New TabPage("Detalle de Precios por Lote")
        Dim panelDetTop As New FlowLayoutPanel() With {
            .Dock = DockStyle.Top,
            .Height = 42,
            .FlowDirection = FlowDirection.LeftToRight,
            .Padding = New Padding(4)
        }

        _txtAlmacen.Width = 120
        _txtAlmacen.PlaceholderText = "Almacen..."

        _btnDetalleBuscar.Text = "Consultar"
        _btnDetalleBuscar.Width = 80
        _btnDetalleBuscar.Height = 28
        AddHandler _btnDetalleBuscar.Click, AddressOf OnDetalleBuscarClick

        panelDetTop.Controls.Add(New Label() With {.Text = "Almacen:", .AutoSize = True, .Margin = New Padding(0, 6, 0, 0)})
        panelDetTop.Controls.Add(_txtAlmacen)
        panelDetTop.Controls.Add(_btnDetalleBuscar)

        ConfigureGrid(_gridDetalle)
        tab3.Controls.Add(_gridDetalle)
        tab3.Controls.Add(panelDetTop)
        _tabs.TabPages.Add(tab3)

        ' ── Status ────────────────────────────────────────
        _lblEstado.Dock = DockStyle.Bottom
        _lblEstado.Height = 22
        _lblEstado.AutoSize = False
        _lblEstado.TextAlign = ContentAlignment.MiddleLeft
        _lblEstado.Text = "Seleccione una pestaña y consulte."

        Controls.Add(_tabs)
        Controls.Add(_lblEstado)

        ' Cargar maestro al abrir
        AddHandler Shown, Sub() CargarMaestro()
    End Sub

    Private Shared Sub ConfigureGrid(grid As DataGridView)
        grid.Dock = DockStyle.Fill
        grid.ReadOnly = True
        grid.AllowUserToAddRows = False
        grid.AllowUserToDeleteRows = False
        grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect
        grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
        grid.RowHeadersVisible = False
    End Sub

    ' ═══════════════════════════════════════════════════════════
    '  Data Loading
    ' ═══════════════════════════════════════════════════════════

    Private Sub CargarMaestro()
        Try
            Cursor = Cursors.WaitCursor
            _lblEstado.Text = "Cargando maestro de inventario..."
            System.Windows.Forms.Application.DoEvents()

            Dim dt = _useCase.ObtenerMaestro()
            _gridMaestro.DataSource = dt
            _lblEstado.Text = $"Maestro: {dt.Rows.Count} productos"
        Catch ex As Exception
            _lblEstado.Text = "Error cargando maestro."
            MessageBox.Show(ex.Message, "Inventario", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            Cursor = Cursors.Default
        End Try
    End Sub

    Private Sub OnMovBuscarClick(sender As Object, e As EventArgs)
        Try
            Cursor = Cursors.WaitCursor
            _lblEstado.Text = "Consultando movimientos..."
            System.Windows.Forms.Application.DoEvents()

            Dim filter As New ConsultarInventarioFilter With {
                .FechaDesde = _fechaMovDesde.Value.Date,
                .FechaHasta = _fechaMovHasta.Value.Date,
                .CodigoProducto = _txtMovCodigo.Text.Trim()
            }

            Dim dt = _useCase.ObtenerMovimientos(filter)
            _gridMov.DataSource = dt
            _lblEstado.Text = $"Movimientos: {dt.Rows.Count}"
        Catch ex As Exception
            _lblEstado.Text = "Error en movimientos."
            MessageBox.Show(ex.Message, "Movimientos", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            Cursor = Cursors.Default
        End Try
    End Sub

    Private Sub OnDetalleBuscarClick(sender As Object, e As EventArgs)
        Try
            Cursor = Cursors.WaitCursor
            _lblEstado.Text = "Consultando detalle..."
            System.Windows.Forms.Application.DoEvents()

            Dim dt = _useCase.ObtenerDetallePorAlmacen(_txtAlmacen.Text.Trim())
            _gridDetalle.DataSource = dt
            _lblEstado.Text = $"Detalle: {dt.Rows.Count} registros"
        Catch ex As Exception
            _lblEstado.Text = "Error en detalle."
            MessageBox.Show(ex.Message, "Detalle", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            Cursor = Cursors.Default
        End Try
    End Sub

End Class

