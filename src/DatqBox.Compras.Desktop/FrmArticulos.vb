Imports DatqBox.Application.Compras
Imports System.Data
Imports System.Windows.Forms

''' <summary>
''' Mantenimiento de productos (CRUD).
''' Replica frmArticulos.frm de VB6.
''' </summary>
Public Class FrmArticulos
    Inherits Form

    Private ReadOnly _obtenerUC As ObtenerArticuloUseCase
    Private ReadOnly _guardarUC As GuardarArticuloUseCase

    Private _esNuevo As Boolean = False

    ' ── Controles de datos ────────────────────────────────
    Private ReadOnly _txtCodigo As New TextBox()
    Private ReadOnly _txtBarra As New TextBox()
    Private ReadOnly _txtReferencia As New TextBox()
    Private ReadOnly _txtDescripcion As New TextBox()
    Private ReadOnly _txtCategoria As New TextBox()
    Private ReadOnly _txtLinea As New TextBox()
    Private ReadOnly _txtMarca As New TextBox()
    Private ReadOnly _txtTipo As New TextBox()
    Private ReadOnly _txtClase As New TextBox()
    Private ReadOnly _txtPrecioCosto As New TextBox()
    Private ReadOnly _txtPrecioVenta As New TextBox()
    Private ReadOnly _txtPrecioVenta1 As New TextBox()
    Private ReadOnly _txtPrecioVenta2 As New TextBox()
    Private ReadOnly _txtPrecioVenta3 As New TextBox()
    Private ReadOnly _txtPorcentaje As New TextBox()
    Private ReadOnly _txtPorcentaje1 As New TextBox()
    Private ReadOnly _txtPorcentaje2 As New TextBox()
    Private ReadOnly _txtPorcentaje3 As New TextBox()
    Private ReadOnly _txtUnidad As New TextBox()
    Private ReadOnly _txtAlicuota As New TextBox()
    Private ReadOnly _txtMinimo As New TextBox()
    Private ReadOnly _txtMaximo As New TextBox()
    Private ReadOnly _txtUbicacion As New TextBox()
    Private ReadOnly _txtExistencia As New TextBox()

    ' ── Busqueda ──────────────────────────────────────────
    Private ReadOnly _txtBuscar As New TextBox()
    Private ReadOnly _gridResultados As New DataGridView()

    ' ── Botones ───────────────────────────────────────────
    Private ReadOnly _btnGuardar As New Button()
    Private ReadOnly _btnNuevo As New Button()
    Private ReadOnly _btnEliminar As New Button()
    Private ReadOnly _btnBuscar As New Button()
    Private ReadOnly _lblEstado As New Label()

    Public Sub New(obtenerUC As ObtenerArticuloUseCase, guardarUC As GuardarArticuloUseCase)
        _obtenerUC = obtenerUC
        _guardarUC = guardarUC
        AutoScaleMode = AutoScaleMode.Dpi
        BuildUi()
    End Sub

    Private Sub BuildUi()
        Text = "Articulos — Mantenimiento (.NET)"
        Width = 1100
        Height = 700
        MinimumSize = New Drawing.Size(900, 600)
        StartPosition = FormStartPosition.CenterScreen

        ' ── Panel izquierdo: formulario de datos ──────────
        Dim panelDatos As New Panel() With {
            .Dock = DockStyle.Left,
            .Width = 460,
            .AutoScroll = True,
            .Padding = New Padding(10)
        }

        Dim y As Integer = 10
        y = AddField(panelDatos, "Codigo:", _txtCodigo, y, 120)
        y = AddField(panelDatos, "Cod. Barras:", _txtBarra, y, 180)
        y = AddField(panelDatos, "Referencia:", _txtReferencia, y, 180)
        y = AddField(panelDatos, "Descripcion:", _txtDescripcion, y, 280)
        y = AddField(panelDatos, "Categoria:", _txtCategoria, y, 120)
        y = AddField(panelDatos, "Linea:", _txtLinea, y, 120)
        y = AddField(panelDatos, "Marca:", _txtMarca, y, 120)
        y = AddField(panelDatos, "Tipo:", _txtTipo, y, 120)
        y = AddField(panelDatos, "Clase:", _txtClase, y, 120)

        y += 8
        y = AddField(panelDatos, "Precio Costo:", _txtPrecioCosto, y, 100)
        y = AddField(panelDatos, "Precio Vta:", _txtPrecioVenta, y, 100)
        y = AddField(panelDatos, "Precio Vta 2:", _txtPrecioVenta1, y, 100)
        y = AddField(panelDatos, "Precio Vta 3:", _txtPrecioVenta2, y, 100)
        y = AddField(panelDatos, "Precio Vta 4:", _txtPrecioVenta3, y, 100)

        y += 8
        y = AddField(panelDatos, "% Utilidad:", _txtPorcentaje, y, 80)
        y = AddField(panelDatos, "% Util 2:", _txtPorcentaje1, y, 80)
        y = AddField(panelDatos, "% Util 3:", _txtPorcentaje2, y, 80)
        y = AddField(panelDatos, "% Util 4:", _txtPorcentaje3, y, 80)

        y += 8
        y = AddField(panelDatos, "Unidad:", _txtUnidad, y, 60)
        y = AddField(panelDatos, "Alicuota IVA:", _txtAlicuota, y, 60)
        y = AddField(panelDatos, "Minimo:", _txtMinimo, y, 80)
        y = AddField(panelDatos, "Maximo:", _txtMaximo, y, 80)
        y = AddField(panelDatos, "Ubicacion:", _txtUbicacion, y, 120)

        _txtExistencia.ReadOnly = True
        y = AddField(panelDatos, "Existencia:", _txtExistencia, y, 80)

        ' Botones
        y += 12
        _btnGuardar.Text = "Guardar (F6)"
        _btnGuardar.Width = 110
        _btnGuardar.Height = 32
        _btnGuardar.Left = 100
        _btnGuardar.Top = y
        AddHandler _btnGuardar.Click, AddressOf OnGuardarClick

        _btnNuevo.Text = "Nuevo (F7)"
        _btnNuevo.Width = 100
        _btnNuevo.Height = 32
        _btnNuevo.Left = 220
        _btnNuevo.Top = y
        AddHandler _btnNuevo.Click, AddressOf OnNuevoClick

        _btnEliminar.Text = "Eliminar"
        _btnEliminar.Width = 80
        _btnEliminar.Height = 32
        _btnEliminar.Left = 330
        _btnEliminar.Top = y
        AddHandler _btnEliminar.Click, AddressOf OnEliminarClick

        panelDatos.Controls.AddRange({_btnGuardar, _btnNuevo, _btnEliminar})

        ' ── Panel derecho: busqueda + grid ────────────────
        Dim panelDerecho As New Panel() With {
            .Dock = DockStyle.Fill,
            .Padding = New Padding(6)
        }

        Dim panelBusqueda As New FlowLayoutPanel() With {
            .Dock = DockStyle.Top,
            .Height = 38,
            .FlowDirection = FlowDirection.LeftToRight,
            .Padding = New Padding(2)
        }

        _txtBuscar.Width = 250
        _txtBuscar.PlaceholderText = "Buscar por codigo, descripcion..."
        AddHandler _txtBuscar.KeyDown, Sub(s, e)
                                           If e.KeyCode = Keys.Enter Then
                                               OnBuscarClick(s, e)
                                               e.SuppressKeyPress = True
                                           End If
                                       End Sub

        _btnBuscar.Text = "Buscar"
        _btnBuscar.Width = 70
        _btnBuscar.Height = 28
        AddHandler _btnBuscar.Click, AddressOf OnBuscarClick

        panelBusqueda.Controls.Add(_txtBuscar)
        panelBusqueda.Controls.Add(_btnBuscar)

        _gridResultados.Dock = DockStyle.Fill
        _gridResultados.ReadOnly = True
        _gridResultados.AllowUserToAddRows = False
        _gridResultados.AllowUserToDeleteRows = False
        _gridResultados.SelectionMode = DataGridViewSelectionMode.FullRowSelect
        _gridResultados.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
        _gridResultados.RowHeadersVisible = False
        AddHandler _gridResultados.CellDoubleClick, AddressOf OnGridDoubleClick

        panelDerecho.Controls.Add(_gridResultados)
        panelDerecho.Controls.Add(panelBusqueda)

        ' ── Status ────────────────────────────────────────
        _lblEstado.Dock = DockStyle.Bottom
        _lblEstado.Height = 22
        _lblEstado.AutoSize = False
        _lblEstado.TextAlign = ContentAlignment.MiddleLeft
        _lblEstado.Text = "Listo."

        Controls.Add(panelDerecho)
        Controls.Add(panelDatos)
        Controls.Add(_lblEstado)

        ' Teclas rapidas
        KeyPreview = True
        AddHandler KeyDown, Sub(s, e)
                                If e.KeyCode = Keys.F6 Then OnGuardarClick(s, e)
                                If e.KeyCode = Keys.F7 Then OnNuevoClick(s, e)
                                If e.KeyCode = Keys.F4 Then _txtBuscar.Focus()
                            End Sub

        ' Valores por defecto
        _txtUnidad.Text = "UND"
        _txtAlicuota.Text = "16"
    End Sub

    Private Function AddField(parent As Panel, labelText As String, textBox As TextBox, y As Integer, width As Integer) As Integer
        Dim lbl As New Label() With {
            .Text = labelText,
            .AutoSize = True,
            .Left = 10,
            .Top = y + 3
        }
        textBox.Left = 100
        textBox.Top = y
        textBox.Width = width
        parent.Controls.Add(lbl)
        parent.Controls.Add(textBox)
        Return y + 28
    End Function

    ' ═══════════════════════════════════════════════════════════
    '  Event Handlers
    ' ═══════════════════════════════════════════════════════════

    Private Sub OnBuscarClick(sender As Object, e As EventArgs)
        Try
            Cursor = Cursors.WaitCursor
            Dim texto = _txtBuscar.Text.Trim()
            Dim dt As DataTable

            If String.IsNullOrEmpty(texto) Then
                dt = _obtenerUC.ListarTodos()
            Else
                dt = _obtenerUC.BuscarArticulos(texto)
            End If

            _gridResultados.DataSource = dt
            _lblEstado.Text = $"Articulos: {dt.Rows.Count}"
        Catch ex As Exception
            MessageBox.Show(ex.Message, "Busqueda", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            Cursor = Cursors.Default
        End Try
    End Sub

    Private Sub OnGridDoubleClick(sender As Object, e As DataGridViewCellEventArgs)
        If e.RowIndex < 0 Then Return
        Dim row = _gridResultados.Rows(e.RowIndex)
        Dim codigo = Convert.ToString(row.Cells("Codigo").Value)
        CargarArticulo(codigo)
    End Sub

    Private Sub CargarArticulo(codigo As String)
        Try
            Dim dt = _obtenerUC.ObtenerPorCodigo(codigo)
            If dt.Rows.Count = 0 Then
                _lblEstado.Text = "Articulo no encontrado."
                Return
            End If

            Dim row = dt.Rows(0)
            _esNuevo = False

            _txtCodigo.Text = Str(row, "Codigo")
            _txtCodigo.ReadOnly = True
            _txtBarra.Text = Str(row, "BARRA")
            _txtReferencia.Text = Str(row, "Referencia")
            _txtDescripcion.Text = Str(row, "Descripcion")
            _txtCategoria.Text = Str(row, "Categoria")
            _txtLinea.Text = Str(row, "Linea")
            _txtMarca.Text = Str(row, "Marca")
            _txtTipo.Text = Str(row, "Tipo")
            _txtClase.Text = Str(row, "Clase")
            _txtPrecioCosto.Text = Dec(row, "Precio_Compra").ToString("N2")
            _txtPrecioVenta.Text = Dec(row, "Precio_Venta").ToString("N2")
            _txtPrecioVenta1.Text = Dec(row, "Precio_Venta1").ToString("N2")
            _txtPrecioVenta2.Text = Dec(row, "Precio_Venta2").ToString("N2")
            _txtPrecioVenta3.Text = Dec(row, "Precio_Venta3").ToString("N2")
            _txtPorcentaje.Text = Dec(row, "Porcentaje").ToString("N2")
            _txtPorcentaje1.Text = Dec(row, "Porcentaje1").ToString("N2")
            _txtPorcentaje2.Text = Dec(row, "Porcentaje2").ToString("N2")
            _txtPorcentaje3.Text = Dec(row, "Porcentaje3").ToString("N2")
            _txtUnidad.Text = Str(row, "Unidad")
            _txtAlicuota.Text = Dec(row, "Alicuota").ToString("N2")
            _txtMinimo.Text = Dec(row, "Minimo").ToString("N2")
            _txtMaximo.Text = Dec(row, "Maximo").ToString("N2")
            _txtUbicacion.Text = Str(row, "Ubicacion")
            _txtExistencia.Text = Dec(row, "Existencia").ToString("N2")

            _lblEstado.Text = $"Articulo cargado: {codigo}"
        Catch ex As Exception
            MessageBox.Show(ex.Message, "Cargar articulo", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub OnGuardarClick(sender As Object, e As EventArgs)
        If String.IsNullOrWhiteSpace(_txtCodigo.Text) Then
            MessageBox.Show("Ingrese un codigo.", "Validacion", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If
        If String.IsNullOrWhiteSpace(_txtDescripcion.Text) Then
            MessageBox.Show("Ingrese una descripcion.", "Validacion", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        Try
            Dim datos As New ArticuloDatos With {
                .Codigo = _txtCodigo.Text.Trim(),
                .Barra = _txtBarra.Text.Trim(),
                .Referencia = _txtReferencia.Text.Trim(),
                .Descripcion = _txtDescripcion.Text.Trim(),
                .Categoria = _txtCategoria.Text.Trim(),
                .Linea = _txtLinea.Text.Trim(),
                .Marca = _txtMarca.Text.Trim(),
                .Tipo = _txtTipo.Text.Trim(),
                .Clase = _txtClase.Text.Trim(),
                .PrecioCosto = ParseDec(_txtPrecioCosto.Text),
                .PrecioVenta = ParseDec(_txtPrecioVenta.Text),
                .PrecioVenta1 = ParseDec(_txtPrecioVenta1.Text),
                .PrecioVenta2 = ParseDec(_txtPrecioVenta2.Text),
                .PrecioVenta3 = ParseDec(_txtPrecioVenta3.Text),
                .Porcentaje = ParseDec(_txtPorcentaje.Text),
                .Porcentaje1 = ParseDec(_txtPorcentaje1.Text),
                .Porcentaje2 = ParseDec(_txtPorcentaje2.Text),
                .Porcentaje3 = ParseDec(_txtPorcentaje3.Text),
                .Unidad = _txtUnidad.Text.Trim(),
                .Alicuota = ParseDec(_txtAlicuota.Text),
                .Minimo = ParseDec(_txtMinimo.Text),
                .Maximo = ParseDec(_txtMaximo.Text),
                .Ubicacion = _txtUbicacion.Text.Trim()
            }

            Dim rows As Integer
            If _esNuevo Then
                rows = _guardarUC.Insertar(datos)
            Else
                rows = _guardarUC.Actualizar(datos)
            End If

            _esNuevo = False
            _txtCodigo.ReadOnly = True
            _lblEstado.Text = $"Guardado exitoso. Filas afectadas: {rows}"
        Catch ex As Exception
            MessageBox.Show(ex.Message, "Error al guardar", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub OnNuevoClick(sender As Object, e As EventArgs)
        _esNuevo = True
        _txtCodigo.ReadOnly = False
        For Each ctrl In Controls
            If TypeOf ctrl Is Panel Then
                For Each c In DirectCast(ctrl, Panel).Controls
                    If TypeOf c Is TextBox Then DirectCast(c, TextBox).Clear()
                Next
            End If
        Next
        _txtUnidad.Text = "UND"
        _txtAlicuota.Text = "16"
        _txtCodigo.Focus()
        _lblEstado.Text = "Nuevo articulo — ingrese datos."
    End Sub

    Private Sub OnEliminarClick(sender As Object, e As EventArgs)
        If String.IsNullOrWhiteSpace(_txtCodigo.Text) OrElse _esNuevo Then
            MessageBox.Show("No hay articulo cargado.", "Eliminar", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        If MessageBox.Show($"Eliminar articulo {_txtCodigo.Text}?",
                           "Confirmar", MessageBoxButtons.YesNo, MessageBoxIcon.Question) <> DialogResult.Yes Then
            Return
        End If

        Try
            _guardarUC.Eliminar(_txtCodigo.Text.Trim())
            _lblEstado.Text = "Articulo marcado como eliminado."
            OnNuevoClick(Nothing, Nothing)
        Catch ex As Exception
            MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    ' ═══════════════════════════════════════════════════════════
    '  Helpers
    ' ═══════════════════════════════════════════════════════════

    Private Shared Function Str(row As DataRow, col As String) As String
        If row.IsNull(col) Then Return String.Empty
        Return Convert.ToString(row(col))
    End Function

    Private Shared Function Dec(row As DataRow, col As String) As Decimal
        If row.IsNull(col) Then Return 0D
        Dim val = row(col)
        If TypeOf val Is Decimal Then Return CDec(val)
        Dim result As Decimal
        Decimal.TryParse(Convert.ToString(val), result)
        Return result
    End Function

    Private Shared Function ParseDec(text As String) As Decimal
        Dim result As Decimal
        Decimal.TryParse(text.Trim(), result)
        Return result
    End Function

End Class

