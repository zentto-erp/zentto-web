Imports DatqBox.Application.Compras
Imports System.Data
Imports System.Windows.Forms

''' <summary>
''' Formulario de entrada de compras de mercancia.
''' Replica frmCompras.frm de VB6: cabecera + grid de detalle + totales.
''' Al guardar, usa RegistrarCompraUseCase con transaccion SQL.
''' </summary>
Public Class FrmCompras
    Inherits Form

    Private ReadOnly _registrarUC As RegistrarCompraUseCase
    Private ReadOnly _articuloUC As ObtenerArticuloUseCase

    ' ── Cabecera ──────────────────────────────────────────
    Private ReadOnly _txtNumFact As New TextBox()
    Private ReadOnly _txtNumControl As New TextBox()
    Private ReadOnly _txtCodProveedor As New TextBox()
    Private ReadOnly _txtNombreProv As New TextBox()
    Private ReadOnly _txtRifProv As New TextBox()
    Private ReadOnly _dtpFecha As New DateTimePicker()
    Private ReadOnly _dtpFechaVence As New DateTimePicker()
    Private ReadOnly _cboTipo As New ComboBox()
    Private ReadOnly _txtAlicuota As New TextBox()
    Private ReadOnly _txtDolar As New TextBox()

    ' ── Grid de detalle ───────────────────────────────────
    Private ReadOnly _gridDetalle As New DataGridView()

    ' ── Totales ───────────────────────────────────────────
    Private ReadOnly _txtMontoGra As New TextBox()
    Private ReadOnly _txtIva As New TextBox()
    Private ReadOnly _txtExento As New TextBox()
    Private ReadOnly _txtDescuento As New TextBox()
    Private ReadOnly _txtFlete As New TextBox()
    Private ReadOnly _txtTotal As New TextBox()

    ' ── Botones ───────────────────────────────────────────
    Private ReadOnly _btnGuardar As New Button()
    Private ReadOnly _btnNuevo As New Button()
    Private ReadOnly _btnAgregarLinea As New Button()
    Private ReadOnly _btnQuitarLinea As New Button()
    Private ReadOnly _lblEstado As New Label()

    ' ── Datos internos ────────────────────────────────────
    Private ReadOnly _dtDetalle As New DataTable()

    Public Sub New(registrarUC As RegistrarCompraUseCase, articuloUC As ObtenerArticuloUseCase)
        _registrarUC = registrarUC
        _articuloUC = articuloUC
        AutoScaleMode = AutoScaleMode.Dpi
        InitDetalleTable()
        BuildUi()
    End Sub

    Private Sub InitDetalleTable()
        _dtDetalle.Columns.Add("Codigo", GetType(String))
        _dtDetalle.Columns.Add("Referencia", GetType(String))
        _dtDetalle.Columns.Add("Descripcion", GetType(String))
        _dtDetalle.Columns.Add("Unidad", GetType(String))
        _dtDetalle.Columns.Add("Cantidad", GetType(Decimal))
        _dtDetalle.Columns.Add("PrecioCosto", GetType(Decimal))
        _dtDetalle.Columns.Add("PrecioVenta", GetType(Decimal))
        _dtDetalle.Columns.Add("Porcentaje", GetType(Decimal))
        _dtDetalle.Columns.Add("Alicuota", GetType(Decimal))
        _dtDetalle.Columns.Add("Subtotal", GetType(Decimal))
    End Sub

    Private Sub BuildUi()
        Text = "Compras de Mercancia (.NET)"
        Width = 1150
        Height = 750
        MinimumSize = New Drawing.Size(1000, 650)
        StartPosition = FormStartPosition.CenterScreen

        ' ═══ Panel superior: cabecera ═════════════════════
        Dim panelCab As New TableLayoutPanel() With {
            .Dock = DockStyle.Top,
            .Height = 110,
            .ColumnCount = 8,
            .RowCount = 3,
            .Padding = New Padding(8, 6, 8, 4)
        }
        For i = 0 To 7
            panelCab.ColumnStyles.Add(New ColumnStyle(SizeType.AutoSize))
        Next

        ' Row 0
        _txtNumFact.Width = 120
        _txtNumControl.Width = 120
        _dtpFecha.Format = DateTimePickerFormat.Short
        _dtpFecha.Width = 110
        _dtpFechaVence.Format = DateTimePickerFormat.Short
        _dtpFechaVence.Width = 110
        _dtpFechaVence.Value = DateTime.Today.AddDays(30)

        panelCab.Controls.Add(New Label() With {.Text = "Factura:", .AutoSize = True}, 0, 0)
        panelCab.Controls.Add(_txtNumFact, 1, 0)
        panelCab.Controls.Add(New Label() With {.Text = "Control:", .AutoSize = True}, 2, 0)
        panelCab.Controls.Add(_txtNumControl, 3, 0)
        panelCab.Controls.Add(New Label() With {.Text = "Fecha:", .AutoSize = True}, 4, 0)
        panelCab.Controls.Add(_dtpFecha, 5, 0)
        panelCab.Controls.Add(New Label() With {.Text = "Vence:", .AutoSize = True}, 6, 0)
        panelCab.Controls.Add(_dtpFechaVence, 7, 0)

        ' Row 1
        _txtCodProveedor.Width = 100
        _txtNombreProv.Width = 250
        _txtNombreProv.ReadOnly = True
        _txtRifProv.Width = 120
        _txtRifProv.ReadOnly = True

        panelCab.Controls.Add(New Label() With {.Text = "Proveedor:", .AutoSize = True}, 0, 1)
        panelCab.Controls.Add(_txtCodProveedor, 1, 1)
        panelCab.Controls.Add(_txtNombreProv, 2, 1)
        panelCab.SetColumnSpan(_txtNombreProv, 3)
        panelCab.Controls.Add(New Label() With {.Text = "RIF:", .AutoSize = True}, 5, 1)
        panelCab.Controls.Add(_txtRifProv, 6, 1)

        ' Row 2
        _cboTipo.DropDownStyle = ComboBoxStyle.DropDownList
        _cboTipo.Items.AddRange({"CONTADO", "CREDITO"})
        _cboTipo.SelectedIndex = 0
        _cboTipo.Width = 100

        _txtAlicuota.Width = 60
        _txtAlicuota.Text = "16"
        _txtDolar.Width = 80
        _txtDolar.Text = "0.00"

        panelCab.Controls.Add(New Label() With {.Text = "Tipo:", .AutoSize = True}, 0, 2)
        panelCab.Controls.Add(_cboTipo, 1, 2)
        panelCab.Controls.Add(New Label() With {.Text = "IVA%:", .AutoSize = True}, 2, 2)
        panelCab.Controls.Add(_txtAlicuota, 3, 2)
        panelCab.Controls.Add(New Label() With {.Text = "Tasa $:", .AutoSize = True}, 4, 2)
        panelCab.Controls.Add(_txtDolar, 5, 2)

        ' ═══ Panel inferior: totales y botones ════════════
        Dim panelBot As New TableLayoutPanel() With {
            .Dock = DockStyle.Bottom,
            .Height = 80,
            .ColumnCount = 14,
            .RowCount = 2,
            .Padding = New Padding(8, 4, 8, 4)
        }
        For i = 0 To 13
            panelBot.ColumnStyles.Add(New ColumnStyle(SizeType.AutoSize))
        Next

        _txtMontoGra.Width = 100 : _txtMontoGra.ReadOnly = True
        _txtIva.Width = 80 : _txtIva.ReadOnly = True
        _txtExento.Width = 80 : _txtExento.ReadOnly = True
        _txtDescuento.Width = 80
        _txtFlete.Width = 80
        _txtTotal.Width = 120 : _txtTotal.ReadOnly = True
        _txtTotal.Font = New Drawing.Font(_txtTotal.Font, Drawing.FontStyle.Bold)

        panelBot.Controls.Add(New Label() With {.Text = "Gravable:", .AutoSize = True}, 0, 0)
        panelBot.Controls.Add(_txtMontoGra, 1, 0)
        panelBot.Controls.Add(New Label() With {.Text = "IVA:", .AutoSize = True}, 2, 0)
        panelBot.Controls.Add(_txtIva, 3, 0)
        panelBot.Controls.Add(New Label() With {.Text = "Exento:", .AutoSize = True}, 4, 0)
        panelBot.Controls.Add(_txtExento, 5, 0)
        panelBot.Controls.Add(New Label() With {.Text = "Desc:", .AutoSize = True}, 6, 0)
        panelBot.Controls.Add(_txtDescuento, 7, 0)
        panelBot.Controls.Add(New Label() With {.Text = "Flete:", .AutoSize = True}, 8, 0)
        panelBot.Controls.Add(_txtFlete, 9, 0)
        panelBot.Controls.Add(New Label() With {.Text = "TOTAL:", .AutoSize = True}, 10, 0)
        panelBot.Controls.Add(_txtTotal, 11, 0)

        ' Botones
        _btnGuardar.Text = "Guardar (F6)"
        _btnGuardar.Width = 110
        _btnGuardar.Height = 30
        AddHandler _btnGuardar.Click, AddressOf OnGuardarClick

        _btnNuevo.Text = "Nuevo (F7)"
        _btnNuevo.Width = 100
        _btnNuevo.Height = 30
        AddHandler _btnNuevo.Click, AddressOf OnNuevoClick

        _btnAgregarLinea.Text = "+ Linea"
        _btnAgregarLinea.Width = 80
        _btnAgregarLinea.Height = 30
        AddHandler _btnAgregarLinea.Click, AddressOf OnAgregarLineaClick

        _btnQuitarLinea.Text = "- Linea"
        _btnQuitarLinea.Width = 80
        _btnQuitarLinea.Height = 30
        AddHandler _btnQuitarLinea.Click, AddressOf OnQuitarLineaClick

        panelBot.Controls.Add(_btnAgregarLinea, 0, 1)
        panelBot.Controls.Add(_btnQuitarLinea, 1, 1)
        panelBot.Controls.Add(_btnGuardar, 10, 1)
        panelBot.Controls.Add(_btnNuevo, 11, 1)

        ' ═══ Grid de detalle ══════════════════════════════
        _gridDetalle.Dock = DockStyle.Fill
        _gridDetalle.DataSource = _dtDetalle
        _gridDetalle.AllowUserToAddRows = False
        _gridDetalle.AllowUserToDeleteRows = False
        _gridDetalle.SelectionMode = DataGridViewSelectionMode.FullRowSelect
        _gridDetalle.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
        _gridDetalle.RowHeadersVisible = False
        AddHandler _gridDetalle.CellEndEdit, AddressOf OnCellEndEdit

        ' ═══ Status ═══════════════════════════════════════
        _lblEstado.Dock = DockStyle.Bottom
        _lblEstado.Height = 22
        _lblEstado.AutoSize = False
        _lblEstado.TextAlign = ContentAlignment.MiddleLeft
        _lblEstado.Text = "Nuevo documento — ingrese datos."

        Controls.Add(_gridDetalle)
        Controls.Add(panelBot)
        Controls.Add(_lblEstado)
        Controls.Add(panelCab)

        ' Teclas rapidas
        KeyPreview = True
        AddHandler KeyDown, Sub(s, e)
                                If e.KeyCode = Keys.F6 Then OnGuardarClick(s, e)
                                If e.KeyCode = Keys.F7 Then OnNuevoClick(s, e)
                            End Sub

        ' Eventos de recalculo de totales
        AddHandler _txtDescuento.Leave, Sub() RecalcularTotales()
        AddHandler _txtFlete.Leave, Sub() RecalcularTotales()
    End Sub

    ' ═══════════════════════════════════════════════════════════
    '  Event Handlers
    ' ═══════════════════════════════════════════════════════════

    Private Sub OnAgregarLineaClick(sender As Object, e As EventArgs)
        Dim row = _dtDetalle.NewRow()
        row("Unidad") = "UND"
        row("Cantidad") = 1D
        row("PrecioCosto") = 0D
        row("PrecioVenta") = 0D
        row("Porcentaje") = 0D
        row("Alicuota") = ParseDec(_txtAlicuota.Text)
        row("Subtotal") = 0D
        _dtDetalle.Rows.Add(row)
    End Sub

    Private Sub OnQuitarLineaClick(sender As Object, e As EventArgs)
        If _gridDetalle.CurrentRow Is Nothing Then Return
        Dim idx = _gridDetalle.CurrentRow.Index
        If idx >= 0 AndAlso idx < _dtDetalle.Rows.Count Then
            _dtDetalle.Rows.RemoveAt(idx)
            RecalcularTotales()
        End If
    End Sub

    Private Sub OnCellEndEdit(sender As Object, e As DataGridViewCellEventArgs)
        If e.RowIndex < 0 Then Return

        Dim row = _dtDetalle.Rows(e.RowIndex)
        Dim colName = _dtDetalle.Columns(e.ColumnIndex).ColumnName

        ' Si cambia Codigo, buscar el producto
        If colName = "Codigo" Then
            Dim codigo = Convert.ToString(row("Codigo"))
            If Not String.IsNullOrWhiteSpace(codigo) Then
                Try
                    Dim dt = _articuloUC.ObtenerPorCodigo(codigo)
                    If dt.Rows.Count > 0 Then
                        Dim prod = dt.Rows(0)
                        row("Descripcion") = Convert.ToString(prod("Descripcion"))
                        row("Referencia") = If(prod.IsNull("Referencia"), "", Convert.ToString(prod("Referencia")))
                        row("Unidad") = If(prod.IsNull("Unidad"), "UND", Convert.ToString(prod("Unidad")))
                        row("PrecioCosto") = If(prod.IsNull("Precio_Compra"), 0D, CDec(prod("Precio_Compra")))
                        row("PrecioVenta") = If(prod.IsNull("Precio_Venta"), 0D, CDec(prod("Precio_Venta")))
                        row("Porcentaje") = If(prod.IsNull("Porcentaje"), 0D, CDec(prod("Porcentaje")))
                        row("Alicuota") = If(prod.IsNull("Alicuota"), 16D, CDec(prod("Alicuota")))
                    End If
                Catch
                End Try
            End If
        End If

        ' Recalcular subtotal de la linea
        Dim cant = If(row.IsNull("Cantidad"), 0D, CDec(row("Cantidad")))
        Dim costo = If(row.IsNull("PrecioCosto"), 0D, CDec(row("PrecioCosto")))
        row("Subtotal") = cant * costo

        RecalcularTotales()
    End Sub

    Private Sub RecalcularTotales()
        Dim gravable As Decimal = 0
        Dim exento As Decimal = 0
        Dim alicuota = ParseDec(_txtAlicuota.Text)

        For Each row As DataRow In _dtDetalle.Rows
            Dim subtotal = If(row.IsNull("Subtotal"), 0D, CDec(row("Subtotal")))
            Dim alic = If(row.IsNull("Alicuota"), 0D, CDec(row("Alicuota")))

            If alic > 0 Then
                gravable += subtotal
            Else
                exento += subtotal
            End If
        Next

        Dim iva = gravable * (alicuota / 100)
        Dim descuento = ParseDec(_txtDescuento.Text)
        Dim flete = ParseDec(_txtFlete.Text)
        Dim total = gravable + iva + exento - descuento + flete

        _txtMontoGra.Text = gravable.ToString("N2")
        _txtIva.Text = iva.ToString("N2")
        _txtExento.Text = exento.ToString("N2")
        _txtTotal.Text = total.ToString("N2")
    End Sub

    Private Sub OnGuardarClick(sender As Object, e As EventArgs)
        ' Validaciones
        If String.IsNullOrWhiteSpace(_txtNumFact.Text) Then
            MessageBox.Show("Ingrese numero de factura.", "Validacion", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If
        If String.IsNullOrWhiteSpace(_txtCodProveedor.Text) Then
            MessageBox.Show("Ingrese codigo de proveedor.", "Validacion", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If
        If _dtDetalle.Rows.Count = 0 Then
            MessageBox.Show("Agregue al menos una linea de detalle.", "Validacion", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        If MessageBox.Show("Guardar esta compra?", "Confirmar",
                           MessageBoxButtons.YesNo, MessageBoxIcon.Question) <> DialogResult.Yes Then
            Return
        End If

        Try
            Cursor = Cursors.WaitCursor
            _lblEstado.Text = "Guardando compra..."
            System.Windows.Forms.Application.DoEvents()

            Dim request As New CompraRequest With {
                .NumFact = _txtNumFact.Text.Trim(),
                .NumControl = _txtNumControl.Text.Trim(),
                .CodProveedor = _txtCodProveedor.Text.Trim(),
                .NombreProveedor = _txtNombreProv.Text.Trim(),
                .RifProveedor = _txtRifProv.Text.Trim(),
                .Fecha = _dtpFecha.Value.Date,
                .FechaVence = _dtpFechaVence.Value.Date,
                .Tipo = _cboTipo.SelectedItem.ToString(),
                .MontoGravable = ParseDec(_txtMontoGra.Text),
                .Iva = ParseDec(_txtIva.Text),
                .Exento = ParseDec(_txtExento.Text),
                .Total = ParseDec(_txtTotal.Text),
                .Alicuota = ParseDec(_txtAlicuota.Text),
                .PrecioDollar = ParseDec(_txtDolar.Text),
                .Descuento = ParseDec(_txtDescuento.Text),
                .Flete = ParseDec(_txtFlete.Text)
            }

            For Each row As DataRow In _dtDetalle.Rows
                Dim item As New CompraDetalleItem With {
                    .Codigo = Convert.ToString(row("Codigo")),
                    .Referencia = Convert.ToString(row("Referencia")),
                    .Descripcion = Convert.ToString(row("Descripcion")),
                    .Unidad = Convert.ToString(row("Unidad")),
                    .Cantidad = If(row.IsNull("Cantidad"), 0D, CDec(row("Cantidad"))),
                    .PrecioCosto = If(row.IsNull("PrecioCosto"), 0D, CDec(row("PrecioCosto"))),
                    .PrecioVenta = If(row.IsNull("PrecioVenta"), 0D, CDec(row("PrecioVenta"))),
                    .Porcentaje = If(row.IsNull("Porcentaje"), 0D, CDec(row("Porcentaje"))),
                    .Alicuota = If(row.IsNull("Alicuota"), 16D, CDec(row("Alicuota"))),
                    .TasaDolar = ParseDec(_txtDolar.Text)
                }
                request.Detalle.Add(item)
            Next

            _registrarUC.Ejecutar(request)
            _lblEstado.Text = $"Compra {request.NumFact} guardada exitosamente."
            MessageBox.Show("Compra registrada correctamente.", "Guardado", MessageBoxButtons.OK, MessageBoxIcon.Information)

        Catch ex As Exception
            _lblEstado.Text = "Error al guardar."
            MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            Cursor = Cursors.Default
        End Try
    End Sub

    Private Sub OnNuevoClick(sender As Object, e As EventArgs)
        _txtNumFact.Clear()
        _txtNumControl.Clear()
        _txtCodProveedor.Clear()
        _txtNombreProv.Clear()
        _txtRifProv.Clear()
        _dtpFecha.Value = DateTime.Today
        _dtpFechaVence.Value = DateTime.Today.AddDays(30)
        _cboTipo.SelectedIndex = 0
        _txtAlicuota.Text = "16"
        _txtDolar.Text = "0.00"
        _txtDescuento.Text = "0.00"
        _txtFlete.Text = "0.00"
        _dtDetalle.Rows.Clear()
        _txtMontoGra.Text = "0.00"
        _txtIva.Text = "0.00"
        _txtExento.Text = "0.00"
        _txtTotal.Text = "0.00"
        _txtNumFact.Focus()
        _lblEstado.Text = "Nuevo documento — ingrese datos."
    End Sub

    Private Shared Function ParseDec(text As String) As Decimal
        Dim result As Decimal
        Decimal.TryParse(text.Trim(), result)
        Return result
    End Function

End Class

