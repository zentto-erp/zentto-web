Imports DatqBox.Application.Compras
Imports System.Data
Imports System.Windows.Forms

''' <summary>
''' Dialogo modal de busqueda y seleccion de compras.
''' Replica frmBuscardorCompras.frm de VB6.
''' Retorna la factura y proveedor seleccionado via propiedades publicas.
''' </summary>
Public Class FrmBuscardorCompras
    Inherits Form

    Private ReadOnly _useCase As BuscarComprasUseCase
    Private ReadOnly _useCaseDetalle As ConsultarComprasUseCase

    ' ── Resultados de seleccion ───────────────────────────
    Public Property NumFactSeleccionada As String = String.Empty
    Public Property CodProveedorSeleccionado As String = String.Empty
    Public Property NombreProveedorSeleccionado As String = String.Empty

    ' ── Controles ─────────────────────────────────────────
    Private ReadOnly _txtBuscar As New TextBox()
    Private ReadOnly _cboTipoDoc As New ComboBox()
    Private ReadOnly _btnBuscar As New Button()
    Private ReadOnly _btnSeleccionar As New Button()
    Private ReadOnly _btnCancelar As New Button()
    Private ReadOnly _btnLimpiar As New Button()
    Private ReadOnly _gridMaestro As New DataGridView()
    Private ReadOnly _gridDetalle As New DataGridView()
    Private ReadOnly _splitter As New SplitContainer()
    Private ReadOnly _lblEstado As New Label()

    Public Sub New(useCase As BuscarComprasUseCase, useCaseDetalle As ConsultarComprasUseCase)
        _useCase = useCase
        _useCaseDetalle = useCaseDetalle
        AutoScaleMode = AutoScaleMode.Dpi
        BuildUi()
    End Sub

    Private Sub BuildUi()
        Text = "Buscador de Compras"
        Width = 1000
        Height = 650
        MinimumSize = New Drawing.Size(800, 500)
        StartPosition = FormStartPosition.CenterParent
        FormBorderStyle = FormBorderStyle.Sizable
        MaximizeBox = True
        MinimizeBox = False

        ' ── Panel superior: busqueda ──────────────────────
        Dim panelTop As New TableLayoutPanel() With {
            .Dock = DockStyle.Top,
            .Height = 44,
            .ColumnCount = 7,
            .RowCount = 1,
            .Padding = New Padding(6, 6, 6, 4)
        }
        For i = 0 To 6
            panelTop.ColumnStyles.Add(New ColumnStyle(SizeType.AutoSize))
        Next

        _txtBuscar.Width = 240
        _txtBuscar.PlaceholderText = "Buscar por nombre, RIF o factura..."
        AddHandler _txtBuscar.KeyDown, Sub(s, e)
                                           If e.KeyCode = Keys.Enter Then
                                               OnBuscarClick(s, e)
                                               e.SuppressKeyPress = True
                                           End If
                                       End Sub

        _cboTipoDoc.DropDownStyle = ComboBoxStyle.DropDownList
        _cboTipoDoc.Items.AddRange({"COMPRAS", "DEVOLUCIONCOMPRAS", "COMPRASNOTAS"})
        _cboTipoDoc.SelectedIndex = 0
        _cboTipoDoc.Width = 150

        _btnBuscar.Text = "Buscar"
        _btnBuscar.Width = 70
        _btnBuscar.Height = 28
        AddHandler _btnBuscar.Click, AddressOf OnBuscarClick

        _btnLimpiar.Text = "Limpiar"
        _btnLimpiar.Width = 60
        _btnLimpiar.Height = 28
        AddHandler _btnLimpiar.Click, Sub()
                                          _txtBuscar.Clear()
                                          _gridMaestro.DataSource = Nothing
                                          _gridDetalle.DataSource = Nothing
                                      End Sub

        panelTop.Controls.Add(_txtBuscar, 0, 0)
        panelTop.Controls.Add(_cboTipoDoc, 1, 0)
        panelTop.Controls.Add(_btnBuscar, 2, 0)
        panelTop.Controls.Add(_btnLimpiar, 3, 0)

        ' ── Panel inferior: botones de accion ─────────────
        Dim panelBottom As New FlowLayoutPanel() With {
            .Dock = DockStyle.Bottom,
            .Height = 44,
            .FlowDirection = FlowDirection.RightToLeft,
            .Padding = New Padding(6, 6, 6, 6)
        }

        _btnCancelar.Text = "Cancelar"
        _btnCancelar.Width = 90
        _btnCancelar.Height = 30
        _btnCancelar.DialogResult = DialogResult.Cancel
        AddHandler _btnCancelar.Click, Sub() DialogResult = DialogResult.Cancel

        _btnSeleccionar.Text = "Seleccionar"
        _btnSeleccionar.Width = 100
        _btnSeleccionar.Height = 30
        AddHandler _btnSeleccionar.Click, AddressOf OnSeleccionarClick

        panelBottom.Controls.Add(_btnCancelar)
        panelBottom.Controls.Add(_btnSeleccionar)

        ' ── Status ────────────────────────────────────────
        _lblEstado.Dock = DockStyle.Bottom
        _lblEstado.Height = 20
        _lblEstado.AutoSize = False
        _lblEstado.TextAlign = ContentAlignment.MiddleLeft
        _lblEstado.Text = "Ingrese texto y presione Buscar o Enter."

        ' ── Splitter: maestro arriba, detalle abajo ───────
        _splitter.Dock = DockStyle.Fill
        _splitter.Orientation = Orientation.Horizontal
        _splitter.SplitterDistance = 280

        ConfigureGrid(_gridMaestro)
        ConfigureGrid(_gridDetalle)

        AddHandler _gridMaestro.SelectionChanged, AddressOf OnMaestroSelectionChanged
        AddHandler _gridMaestro.CellDoubleClick, AddressOf OnGridDoubleClick

        _splitter.Panel1.Controls.Add(_gridMaestro)
        _splitter.Panel2.Controls.Add(_gridDetalle)

        Controls.Add(_splitter)
        Controls.Add(panelBottom)
        Controls.Add(_lblEstado)
        Controls.Add(panelTop)

        AcceptButton = _btnSeleccionar
        CancelButton = _btnCancelar
    End Sub

    Private Shared Sub ConfigureGrid(grid As DataGridView)
        grid.Dock = DockStyle.Fill
        grid.ReadOnly = True
        grid.AllowUserToAddRows = False
        grid.AllowUserToDeleteRows = False
        grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect
        grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
        grid.RowHeadersVisible = False
        grid.EnableHeadersVisualStyles = False
    End Sub

    ' ═══════════════════════════════════════════════════════════
    '  Event Handlers
    ' ═══════════════════════════════════════════════════════════

    Private Sub OnBuscarClick(sender As Object, e As EventArgs)
        Try
            _btnBuscar.Enabled = False
            Cursor = Cursors.WaitCursor
            _lblEstado.Text = "Buscando..."
            System.Windows.Forms.Application.DoEvents()

            Dim filter As New BuscarComprasFilter With {
                .TipoDocumento = _cboTipoDoc.SelectedItem.ToString(),
                .TextoBusqueda = _txtBuscar.Text.Trim()
            }

            Dim dt = _useCase.Ejecutar(filter)
            _gridMaestro.DataSource = dt
            _gridDetalle.DataSource = Nothing
            _lblEstado.Text = $"Resultados: {dt.Rows.Count}"

        Catch ex As Exception
            _lblEstado.Text = "Error en busqueda."
            MessageBox.Show(ex.Message, "Busqueda", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            Cursor = Cursors.Default
            _btnBuscar.Enabled = True
        End Try
    End Sub

    Private Sub OnMaestroSelectionChanged(sender As Object, e As EventArgs)
        If _gridMaestro.CurrentRow Is Nothing Then Return

        Try
            Dim row = _gridMaestro.CurrentRow
            Dim numFact = Convert.ToString(row.Cells("Num_fact").Value)
            Dim codProv = Convert.ToString(row.Cells("Cod_Proveedor").Value)
            Dim tipoDoc = _cboTipoDoc.SelectedItem.ToString()

            If String.IsNullOrWhiteSpace(numFact) OrElse String.IsNullOrWhiteSpace(codProv) Then Return

            Dim dtDetalle = _useCaseDetalle.ObtenerDetalle(numFact, codProv, tipoDoc)
            _gridDetalle.DataSource = dtDetalle
        Catch
        End Try
    End Sub

    Private Sub OnGridDoubleClick(sender As Object, e As DataGridViewCellEventArgs)
        OnSeleccionarClick(sender, EventArgs.Empty)
    End Sub

    Private Sub OnSeleccionarClick(sender As Object, e As EventArgs)
        If _gridMaestro.CurrentRow Is Nothing Then
            MessageBox.Show("Seleccione una compra.", "Seleccion", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        Dim row = _gridMaestro.CurrentRow
        NumFactSeleccionada = Convert.ToString(row.Cells("Num_fact").Value)
        CodProveedorSeleccionado = Convert.ToString(row.Cells("Cod_Proveedor").Value)
        NombreProveedorSeleccionado = Convert.ToString(row.Cells("Nombre").Value)

        DialogResult = DialogResult.OK
    End Sub

End Class

