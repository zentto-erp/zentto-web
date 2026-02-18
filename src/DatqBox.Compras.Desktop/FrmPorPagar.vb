Imports DatqBox.Application.Abstractions
Imports System.Data
Imports System.Windows.Forms

''' <summary>
''' Cuentas por pagar a proveedores.
''' Replica frmPorPagar.frm de VB6.
''' </summary>
Public Class FrmPorPagar
    Inherits Form

    Private ReadOnly _sql As ISqlExecutor

    Private ReadOnly _grid As New DataGridView()
    Private ReadOnly _cboVista As New ComboBox()
    Private ReadOnly _btnConsultar As New Button()
    Private ReadOnly _lblTotalDebe As New Label()
    Private ReadOnly _lblTotalPend As New Label()
    Private ReadOnly _lblEstado As New Label()

    Public Sub New(sql As ISqlExecutor)
        _sql = sql
        AutoScaleMode = AutoScaleMode.Dpi
        BuildUi()
    End Sub

    Private Sub BuildUi()
        Text = "Cuentas por Pagar (.NET)"
        Width = 1000
        Height = 600
        MinimumSize = New Drawing.Size(800, 450)
        StartPosition = FormStartPosition.CenterScreen

        Dim panelTop As New FlowLayoutPanel() With {
            .Dock = DockStyle.Top, .Height = 44,
            .FlowDirection = FlowDirection.LeftToRight, .Padding = New Padding(4)
        }

        _cboVista.Width = 200
        _cboVista.DropDownStyle = ComboBoxStyle.DropDownList
        _cboVista.Items.AddRange({"Todas las cuentas", "Solo pendientes", "Solo vencidas"})
        _cboVista.SelectedIndex = 1

        _btnConsultar.Text = "Consultar" : _btnConsultar.Width = 90 : _btnConsultar.Height = 28
        AddHandler _btnConsultar.Click, AddressOf OnConsultarClick

        panelTop.Controls.Add(New Label() With {.Text = "Vista:", .AutoSize = True, .Margin = New Padding(0, 6, 0, 0)})
        panelTop.Controls.Add(_cboVista)
        panelTop.Controls.Add(_btnConsultar)

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
        _lblTotalDebe.AutoSize = True : _lblTotalDebe.Font = New Drawing.Font(_lblTotalDebe.Font, Drawing.FontStyle.Bold)
        _lblTotalPend.AutoSize = True : _lblTotalPend.Font = New Drawing.Font(_lblTotalPend.Font, Drawing.FontStyle.Bold)

        panelBot.Controls.Add(New Label() With {.Text = "Total Debe:", .AutoSize = True})
        panelBot.Controls.Add(_lblTotalDebe)
        panelBot.Controls.Add(New Label() With {.Text = "   Total Pendiente:", .AutoSize = True})
        panelBot.Controls.Add(_lblTotalPend)

        _lblEstado.Dock = DockStyle.Bottom
        _lblEstado.Height = 22 : _lblEstado.AutoSize = False
        _lblEstado.TextAlign = ContentAlignment.MiddleLeft
        _lblEstado.Text = "Seleccione vista y consulte."

        Controls.Add(_grid)
        Controls.Add(panelBot)
        Controls.Add(_lblEstado)
        Controls.Add(panelTop)

        AddHandler Shown, Sub() OnConsultarClick(Nothing, Nothing)
    End Sub

    Private Sub OnConsultarClick(sender As Object, e As EventArgs)
        Try
            Cursor = Cursors.WaitCursor
            _lblEstado.Text = "Consultando cuentas por pagar..."
            System.Windows.Forms.Application.DoEvents()

            Dim query = "SELECT CODIGO AS Proveedor, FECHA, DOCUMENTO, TIPO, DEBE, PEND, SALDO FROM P_PAGAR"

            Select Case _cboVista.SelectedIndex
                Case 1 : query &= " WHERE PEND > 0"
                Case 2 : query &= " WHERE PEND > 0 AND FECHA < DATEADD(day, -30, GETDATE())"
            End Select

            query &= " ORDER BY FECHA DESC"

            Dim dt = _sql.Query(query)
            _grid.DataSource = dt

            Dim totalDebe As Decimal = 0
            Dim totalPend As Decimal = 0
            For Each row As DataRow In dt.Rows
                If Not row.IsNull("DEBE") Then totalDebe += CDec(row("DEBE"))
                If Not row.IsNull("PEND") Then totalPend += CDec(row("PEND"))
            Next

            _lblTotalDebe.Text = totalDebe.ToString("N2")
            _lblTotalPend.Text = totalPend.ToString("N2")
            _lblEstado.Text = $"Registros: {dt.Rows.Count}"
        Catch ex As Exception
            _lblEstado.Text = "Error."
            MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            Cursor = Cursors.Default
        End Try
    End Sub
End Class

