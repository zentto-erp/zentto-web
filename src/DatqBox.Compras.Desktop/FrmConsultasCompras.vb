Imports DatqBox.Application.Compras
Imports System.Data
Imports System.Windows.Forms

''' <summary>
''' Consulta de compras con maestro-detalle, filtros por fecha/campo, totales calculados.
''' Replica frmConsultasCompras.frm de VB6.
''' </summary>
Public Class FrmConsultasCompras
    Inherits Form

    Private ReadOnly _useCase As ConsultarComprasUseCase

    ' ── Controles de filtro ───────────────────────────────
    Private ReadOnly _fechaDesde As New DateTimePicker()
    Private ReadOnly _fechaHasta As New DateTimePicker()
    Private ReadOnly _cboTipoDoc As New ComboBox()
    Private ReadOnly _cboCampoFiltro As New ComboBox()
    Private ReadOnly _txtValorFiltro As New TextBox()
    Private ReadOnly _btnBuscar As New Button()
    Private ReadOnly _btnLimpiar As New Button()
    Private ReadOnly _btnExportar As New Button()
    Private ReadOnly _btnEliminar As New Button()

    ' ── Grids maestro-detalle ─────────────────────────────
    Private ReadOnly _gridMaestro As New DataGridView()
    Private ReadOnly _gridDetalle As New DataGridView()
    Private ReadOnly _splitter As New SplitContainer()

    ' ── Totales ───────────────────────────────────────────
    Private ReadOnly _lblMontoGra As New Label()
    Private ReadOnly _lblIva As New Label()
    Private ReadOnly _lblExento As New Label()
    Private ReadOnly _lblIvaRetenido As New Label()
    Private ReadOnly _lblTotal As New Label()
    Private ReadOnly _lblEstado As New Label()

    Private _dtMaestro As DataTable

    Public Sub New(useCase As ConsultarComprasUseCase)
        _useCase = useCase
        AutoScaleMode = AutoScaleMode.Dpi
        BuildUi()
    End Sub

    Private Sub BuildUi()
        Text = "Consultas de Compras (.NET)"
        Width = 1200
        Height = 780
        MinimumSize = New Drawing.Size(1000, 600)
        StartPosition = FormStartPosition.CenterScreen

        ' ── Panel superior: filtros ───────────────────────
        Dim panelTop As New TableLayoutPanel() With {
            .Dock = DockStyle.Top,
            .Height = 80,
            .ColumnCount = 11,
            .RowCount = 2,
            .Padding = New Padding(6, 6, 6, 4)
        }
        For i = 0 To 10
            panelTop.ColumnStyles.Add(New ColumnStyle(SizeType.AutoSize))
        Next

        ' Row 0: fechas y tipo documento
        _fechaDesde.Format = DateTimePickerFormat.Short
        _fechaHasta.Format = DateTimePickerFormat.Short
        _fechaDesde.Value = DateTime.Today.AddDays(-30)
        _fechaHasta.Value = DateTime.Today
        _fechaDesde.Width = 110
        _fechaHasta.Width = 110

        _cboTipoDoc.DropDownStyle = ComboBoxStyle.DropDownList
        _cboTipoDoc.Items.AddRange({"COMPRAS", "DEVOLUCIONCOMPRAS", "COMPRASNOTAS"})
        _cboTipoDoc.SelectedIndex = 0
        _cboTipoDoc.Width = 160

        panelTop.Controls.Add(New Label() With {.Text = "Desde:", .AutoSize = True, .Anchor = AnchorStyles.Left}, 0, 0)
        panelTop.Controls.Add(_fechaDesde, 1, 0)
        panelTop.Controls.Add(New Label() With {.Text = "Hasta:", .AutoSize = True, .Anchor = AnchorStyles.Left}, 2, 0)
        panelTop.Controls.Add(_fechaHasta, 3, 0)
        panelTop.Controls.Add(New Label() With {.Text = "Tipo:", .AutoSize = True, .Anchor = AnchorStyles.Left}, 4, 0)
        panelTop.Controls.Add(_cboTipoDoc, 5, 0)

        ' Row 1: campo filtro y botones
        _cboCampoFiltro.DropDownStyle = ComboBoxStyle.DropDownList
        _cboCampoFiltro.Items.AddRange({"(ninguno)", "Nombre", "Rif", "NUM_FACT", "Num_control", "Cod_Proveedor"})
        _cboCampoFiltro.SelectedIndex = 0
        _cboCampoFiltro.Width = 130

        _txtValorFiltro.Width = 160
        _txtValorFiltro.PlaceholderText = "Valor de filtro..."

        _btnBuscar.Text = "Buscar"
        _btnBuscar.Width = 80
        _btnBuscar.Height = 28
        AddHandler _btnBuscar.Click, AddressOf OnBuscarClick

        _btnLimpiar.Text = "Limpiar"
        _btnLimpiar.Width = 70
        _btnLimpiar.Height = 28
        AddHandler _btnLimpiar.Click, AddressOf OnLimpiarClick

        _btnExportar.Text = "Exportar Excel"
        _btnExportar.Width = 100
        _btnExportar.Height = 28
        AddHandler _btnExportar.Click, AddressOf OnExportarClick

        _btnEliminar.Text = "Eliminar"
        _btnEliminar.Width = 70
        _btnEliminar.Height = 28
        AddHandler _btnEliminar.Click, AddressOf OnEliminarClick

        panelTop.Controls.Add(New Label() With {.Text = "Filtro:", .AutoSize = True, .Anchor = AnchorStyles.Left}, 0, 1)
        panelTop.Controls.Add(_cboCampoFiltro, 1, 1)
        panelTop.Controls.Add(_txtValorFiltro, 2, 1)
        panelTop.SetColumnSpan(_txtValorFiltro, 2)
        panelTop.Controls.Add(_btnBuscar, 4, 1)
        panelTop.Controls.Add(_btnLimpiar, 5, 1)
        panelTop.Controls.Add(_btnExportar, 6, 1)
        panelTop.Controls.Add(_btnEliminar, 7, 1)

        ' ── Panel inferior: totales ───────────────────────
        Dim panelBottom As New TableLayoutPanel() With {
            .Dock = DockStyle.Bottom,
            .Height = 36,
            .ColumnCount = 11,
            .RowCount = 1,
            .Padding = New Padding(6, 4, 6, 4)
        }
        For i = 0 To 10
            panelBottom.ColumnStyles.Add(New ColumnStyle(SizeType.AutoSize))
        Next

        _lblMontoGra.AutoSize = True
        _lblIva.AutoSize = True
        _lblExento.AutoSize = True
        _lblIvaRetenido.AutoSize = True
        _lblTotal.AutoSize = True
        _lblTotal.Font = New Drawing.Font(_lblTotal.Font, Drawing.FontStyle.Bold)

        panelBottom.Controls.Add(New Label() With {.Text = "Gravable:", .AutoSize = True}, 0, 0)
        panelBottom.Controls.Add(_lblMontoGra, 1, 0)
        panelBottom.Controls.Add(New Label() With {.Text = " IVA:", .AutoSize = True}, 2, 0)
        panelBottom.Controls.Add(_lblIva, 3, 0)
        panelBottom.Controls.Add(New Label() With {.Text = " Exento:", .AutoSize = True}, 4, 0)
        panelBottom.Controls.Add(_lblExento, 5, 0)
        panelBottom.Controls.Add(New Label() With {.Text = " IVA Ret:", .AutoSize = True}, 6, 0)
        panelBottom.Controls.Add(_lblIvaRetenido, 7, 0)
        panelBottom.Controls.Add(New Label() With {.Text = " TOTAL:", .AutoSize = True}, 8, 0)
        panelBottom.Controls.Add(_lblTotal, 9, 0)

        ' ── Status ────────────────────────────────────────
        _lblEstado.Dock = DockStyle.Bottom
        _lblEstado.Height = 22
        _lblEstado.AutoSize = False
        _lblEstado.TextAlign = ContentAlignment.MiddleLeft
        _lblEstado.Text = "Listo."

        ' ── Splitter: maestro arriba, detalle abajo ───────
        _splitter.Dock = DockStyle.Fill
        _splitter.Orientation = Orientation.Horizontal
        _splitter.SplitterDistance = 350

        ConfigureGrid(_gridMaestro)
        ConfigureGrid(_gridDetalle)

        AddHandler _gridMaestro.SelectionChanged, AddressOf OnMaestroSelectionChanged

        _splitter.Panel1.Controls.Add(_gridMaestro)
        _splitter.Panel2.Controls.Add(_gridDetalle)

        ' ── Orden de controles (dock order matters) ───────
        Controls.Add(_splitter)
        Controls.Add(panelBottom)
        Controls.Add(_lblEstado)
        Controls.Add(panelTop)
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
            _lblEstado.Text = "Consultando..."
            Cursor = Cursors.WaitCursor
            System.Windows.Forms.Application.DoEvents()

            Dim campoFiltro = If(_cboCampoFiltro.SelectedIndex > 0,
                                 _cboCampoFiltro.SelectedItem.ToString(), "")

            Dim filter As New ConsultarComprasFilter With {
                .FechaDesde = _fechaDesde.Value.Date,
                .FechaHasta = _fechaHasta.Value.Date,
                .TipoDocumento = _cboTipoDoc.SelectedItem.ToString(),
                .CampoFiltro = campoFiltro,
                .ValorFiltro = _txtValorFiltro.Text.Trim()
            }

            _dtMaestro = _useCase.Ejecutar(filter)
            _gridMaestro.DataSource = _dtMaestro
            _gridDetalle.DataSource = Nothing

            CalcularTotales()
            _lblEstado.Text = $"Filas: {_dtMaestro.Rows.Count}"

        Catch ex As Exception
            _lblEstado.Text = "Error en consulta."
            MessageBox.Show(ex.Message, "Consulta de compras", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            Cursor = Cursors.Default
            _btnBuscar.Enabled = True
        End Try
    End Sub

    Private Sub OnMaestroSelectionChanged(sender As Object, e As EventArgs)
        If _gridMaestro.CurrentRow Is Nothing Then Return
        If _dtMaestro Is Nothing Then Return

        Try
            Dim row = _gridMaestro.CurrentRow
            Dim numFact = Convert.ToString(row.Cells("NUM_FACT").Value)
            Dim codProv = Convert.ToString(row.Cells("Cod_Proveedor").Value)
            Dim tipoDoc = _cboTipoDoc.SelectedItem.ToString()

            If String.IsNullOrWhiteSpace(numFact) OrElse String.IsNullOrWhiteSpace(codProv) Then Return

            Dim dtDetalle = _useCase.ObtenerDetalle(numFact, codProv, tipoDoc)
            _gridDetalle.DataSource = dtDetalle
        Catch
            ' Silently handle selection changes during data binding
        End Try
    End Sub

    Private Sub OnLimpiarClick(sender As Object, e As EventArgs)
        _cboCampoFiltro.SelectedIndex = 0
        _txtValorFiltro.Clear()
        _fechaDesde.Value = DateTime.Today.AddDays(-30)
        _fechaHasta.Value = DateTime.Today
        _cboTipoDoc.SelectedIndex = 0
        _gridMaestro.DataSource = Nothing
        _gridDetalle.DataSource = Nothing
        _dtMaestro = Nothing
        LimpiarTotales()
        _lblEstado.Text = "Filtros limpiados."
    End Sub

    Private Sub OnExportarClick(sender As Object, e As EventArgs)
        If _dtMaestro Is Nothing OrElse _dtMaestro.Rows.Count = 0 Then
            MessageBox.Show("No hay datos para exportar.", "Exportar", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        Using dlg As New SaveFileDialog()
            dlg.Filter = "CSV (*.csv)|*.csv|Texto (*.txt)|*.txt"
            dlg.DefaultExt = "csv"
            dlg.FileName = $"Compras_{DateTime.Now:yyyyMMdd_HHmmss}"

            If dlg.ShowDialog() = DialogResult.OK Then
                Try
                    ExportarCsv(_dtMaestro, dlg.FileName)
                    _lblEstado.Text = $"Exportado a: {dlg.FileName}"
                Catch ex As Exception
                    MessageBox.Show(ex.Message, "Error al exportar", MessageBoxButtons.OK, MessageBoxIcon.Error)
                End Try
            End If
        End Using
    End Sub

    Private Sub OnEliminarClick(sender As Object, e As EventArgs)
        ' Sprint 4+ implementará eliminación con cascada
        MessageBox.Show("La eliminacion de compras sera implementada en un sprint posterior.",
                        "Pendiente", MessageBoxButtons.OK, MessageBoxIcon.Information)
    End Sub

    ' ═══════════════════════════════════════════════════════════
    '  Helpers
    ' ═══════════════════════════════════════════════════════════

    Private Sub CalcularTotales()
        If _dtMaestro Is Nothing OrElse _dtMaestro.Rows.Count = 0 Then
            LimpiarTotales()
            Return
        End If

        Dim montoGra As Decimal = 0
        Dim iva As Decimal = 0
        Dim exento As Decimal = 0
        Dim ivaRet As Decimal = 0
        Dim total As Decimal = 0

        For Each row As DataRow In _dtMaestro.Rows
            Dim signo As Decimal = 1
            ' Notas de crédito restan
            Dim tipo = Convert.ToString(row("Tipo"))
            If tipo.ToUpperInvariant().Contains("NOTA") OrElse
               tipo.ToUpperInvariant().Contains("CREDIT") Then
                signo = -1
            End If

            montoGra += ToDecimal(row, "Monto_gra") * signo
            iva += ToDecimal(row, "Iva") * signo
            exento += ToDecimal(row, "Exento") * signo
            ivaRet += ToDecimal(row, "IvaRetenido") * signo
            total += ToDecimal(row, "Total") * signo
        Next

        _lblMontoGra.Text = montoGra.ToString("N2")
        _lblIva.Text = iva.ToString("N2")
        _lblExento.Text = exento.ToString("N2")
        _lblIvaRetenido.Text = ivaRet.ToString("N2")
        _lblTotal.Text = total.ToString("N2")
    End Sub

    Private Sub LimpiarTotales()
        _lblMontoGra.Text = "0.00"
        _lblIva.Text = "0.00"
        _lblExento.Text = "0.00"
        _lblIvaRetenido.Text = "0.00"
        _lblTotal.Text = "0.00"
    End Sub

    Private Shared Function ToDecimal(row As DataRow, column As String) As Decimal
        If row.IsNull(column) Then Return 0D
        Dim val = row(column)
        If TypeOf val Is Decimal Then Return CDec(val)
        Decimal.TryParse(Convert.ToString(val), ToDecimal)
    End Function

    Private Shared Sub ExportarCsv(dt As DataTable, filePath As String)
        Using writer As New IO.StreamWriter(filePath, False, System.Text.Encoding.UTF8)
            ' Header
            Dim headers = dt.Columns.Cast(Of DataColumn)().Select(Function(c) c.ColumnName)
            writer.WriteLine(String.Join(";", headers))

            ' Data
            For Each row As DataRow In dt.Rows
                Dim values = dt.Columns.Cast(Of DataColumn)().Select(
                    Function(c) Convert.ToString(row(c)).Replace(";", ","))
                writer.WriteLine(String.Join(";", values))
            Next
        End Using
    End Sub

End Class

