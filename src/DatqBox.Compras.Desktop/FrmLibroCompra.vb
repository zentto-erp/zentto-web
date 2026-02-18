Imports DatqBox.Application.Abstractions
Imports System.Data
Imports System.Windows.Forms

''' <summary>
''' Libro de compras fiscal (registro de facturas de proveedores).
''' Replica frmLibroCompra.frm de VB6.
''' </summary>
Public Class FrmLibroCompra
    Inherits Form

    Private ReadOnly _sql As ISqlExecutor

    Private ReadOnly _grid As New DataGridView()
    Private ReadOnly _fechaDesde As New DateTimePicker()
    Private ReadOnly _fechaHasta As New DateTimePicker()
    Private ReadOnly _btnConsultar As New Button()
    Private ReadOnly _btnExportar As New Button()
    Private ReadOnly _lblSubtotal As New Label()
    Private ReadOnly _lblIva As New Label()
    Private ReadOnly _lblIvaRet As New Label()
    Private ReadOnly _lblTotal As New Label()
    Private ReadOnly _lblEstado As New Label()

    Public Sub New(sql As ISqlExecutor)
        _sql = sql
        AutoScaleMode = AutoScaleMode.Dpi
        BuildUi()
    End Sub

    Private Sub BuildUi()
        Text = "Libro de Compras (.NET)"
        Width = 1100
        Height = 650
        MinimumSize = New Drawing.Size(900, 500)
        StartPosition = FormStartPosition.CenterScreen

        Dim panelTop As New FlowLayoutPanel() With {
            .Dock = DockStyle.Top, .Height = 44,
            .FlowDirection = FlowDirection.LeftToRight, .Padding = New Padding(4)
        }

        _fechaDesde.Format = DateTimePickerFormat.Short
        _fechaHasta.Format = DateTimePickerFormat.Short
        _fechaDesde.Value = New DateTime(DateTime.Today.Year, DateTime.Today.Month, 1)
        _fechaHasta.Value = DateTime.Today
        _fechaDesde.Width = 110 : _fechaHasta.Width = 110

        _btnConsultar.Text = "Consultar" : _btnConsultar.Width = 90 : _btnConsultar.Height = 28
        AddHandler _btnConsultar.Click, AddressOf OnConsultarClick

        _btnExportar.Text = "Exportar CSV" : _btnExportar.Width = 100 : _btnExportar.Height = 28
        AddHandler _btnExportar.Click, AddressOf OnExportarClick

        panelTop.Controls.Add(New Label() With {.Text = "Desde:", .AutoSize = True, .Margin = New Padding(0, 6, 0, 0)})
        panelTop.Controls.Add(_fechaDesde)
        panelTop.Controls.Add(New Label() With {.Text = "Hasta:", .AutoSize = True, .Margin = New Padding(4, 6, 0, 0)})
        panelTop.Controls.Add(_fechaHasta)
        panelTop.Controls.Add(_btnConsultar)
        panelTop.Controls.Add(_btnExportar)

        _grid.Dock = DockStyle.Fill
        _grid.ReadOnly = True
        _grid.AllowUserToAddRows = False
        _grid.AllowUserToDeleteRows = False
        _grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect
        _grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
        _grid.RowHeadersVisible = False

        Dim panelBot As New FlowLayoutPanel() With {
            .Dock = DockStyle.Bottom, .Height = 30,
            .FlowDirection = FlowDirection.LeftToRight, .Padding = New Padding(4)
        }
        _lblSubtotal.AutoSize = True : _lblIva.AutoSize = True
        _lblIvaRet.AutoSize = True : _lblTotal.AutoSize = True
        _lblTotal.Font = New Drawing.Font(_lblTotal.Font, Drawing.FontStyle.Bold)

        panelBot.Controls.Add(New Label() With {.Text = "Base:", .AutoSize = True})
        panelBot.Controls.Add(_lblSubtotal)
        panelBot.Controls.Add(New Label() With {.Text = "  IVA:", .AutoSize = True})
        panelBot.Controls.Add(_lblIva)
        panelBot.Controls.Add(New Label() With {.Text = "  IVA Ret:", .AutoSize = True})
        panelBot.Controls.Add(_lblIvaRet)
        panelBot.Controls.Add(New Label() With {.Text = "  TOTAL:", .AutoSize = True})
        panelBot.Controls.Add(_lblTotal)

        _lblEstado.Dock = DockStyle.Bottom
        _lblEstado.Height = 22 : _lblEstado.AutoSize = False
        _lblEstado.TextAlign = ContentAlignment.MiddleLeft
        _lblEstado.Text = "Seleccione periodo."

        Controls.Add(_grid)
        Controls.Add(panelBot)
        Controls.Add(_lblEstado)
        Controls.Add(panelTop)
    End Sub

    Private Sub OnConsultarClick(sender As Object, e As EventArgs)
        Try
            Cursor = Cursors.WaitCursor
            _lblEstado.Text = "Consultando libro de compras..."
            System.Windows.Forms.Application.DoEvents()

            Dim query = "SELECT NUM_FACT AS Factura, Num_control AS Control, Fecha, " &
                        "Nombre AS Proveedor, Rif, Monto_gra AS BaseImponible, " &
                        "Iva, Exento, IvaRetenido, Total, Tipo " &
                        "FROM COMPRAS WHERE Fecha >= @Desde AND Fecha <= @Hasta " &
                        "ORDER BY Fecha, Nombre"

            Dim dt = _sql.Query(query, New Dictionary(Of String, Object) From {
                {"@Desde", _fechaDesde.Value.Date},
                {"@Hasta", _fechaHasta.Value.Date}
            })
            _grid.DataSource = dt

            Dim subtotal As Decimal = 0, iva As Decimal = 0, ivaRet As Decimal = 0, total As Decimal = 0
            For Each row As DataRow In dt.Rows
                If Not row.IsNull("BaseImponible") Then subtotal += CDec(row("BaseImponible"))
                If Not row.IsNull("Iva") Then iva += CDec(row("Iva"))
                If Not row.IsNull("IvaRetenido") Then ivaRet += CDec(row("IvaRetenido"))
                If Not row.IsNull("Total") Then total += CDec(row("Total"))
            Next

            _lblSubtotal.Text = subtotal.ToString("N2")
            _lblIva.Text = iva.ToString("N2")
            _lblIvaRet.Text = ivaRet.ToString("N2")
            _lblTotal.Text = total.ToString("N2")
            _lblEstado.Text = $"Registros: {dt.Rows.Count}"
        Catch ex As Exception
            _lblEstado.Text = "Error."
            MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            Cursor = Cursors.Default
        End Try
    End Sub

    Private Sub OnExportarClick(sender As Object, e As EventArgs)
        Dim dt = TryCast(_grid.DataSource, DataTable)
        If dt Is Nothing OrElse dt.Rows.Count = 0 Then
            MessageBox.Show("No hay datos.", "Exportar", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        Using dlg As New SaveFileDialog()
            dlg.Filter = "CSV (*.csv)|*.csv" : dlg.DefaultExt = "csv"
            dlg.FileName = $"LibroCompras_{_fechaDesde.Value:yyyyMMdd}_{_fechaHasta.Value:yyyyMMdd}"
            If dlg.ShowDialog() = DialogResult.OK Then
                Try
                    Using w As New IO.StreamWriter(dlg.FileName, False, System.Text.Encoding.UTF8)
                        w.WriteLine(String.Join(";", dt.Columns.Cast(Of DataColumn)().Select(Function(c) c.ColumnName)))
                        For Each row As DataRow In dt.Rows
                            w.WriteLine(String.Join(";", dt.Columns.Cast(Of DataColumn)().Select(
                                Function(c) Convert.ToString(row(c)).Replace(";", ","))))
                        Next
                    End Using
                    _lblEstado.Text = $"Exportado: {dlg.FileName}"
                Catch ex As Exception
                    MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
                End Try
            End If
        End Using
    End Sub
End Class

