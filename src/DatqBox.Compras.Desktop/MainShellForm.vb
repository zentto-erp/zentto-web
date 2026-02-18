Imports System.Data
Imports System.Windows.Forms
Imports DatqBox.Infrastructure.Data
Imports DatqBox.Application.Compras

''' <summary>
''' Shell principal del modulo de Compras.
''' Carga el ribbon Codejock si esta instalado; si no, usa MenuStrip como fallback.
''' Cada comando del ribbon abre el formulario .NET correspondiente.
''' </summary>
Public Class MainShellForm
    Inherits Form

    Private ReadOnly _topPanel As New Panel()
    Private ReadOnly _workPanel As New Panel()
    Private ReadOnly _statusLabel As New Label()

    Private _commandBarsHost As ComActiveXHost
    Private _commandBarsOcx As Object
    Private _config As ComprasRuntimeConfig
    Private _connectionString As String = String.Empty
    Private _ribbonBuilt As Boolean

    ' Ruta a los iconos (DatQBox Admin\res)
    Private ReadOnly _resDir As String =
        IO.Path.GetFullPath(IO.Path.Combine(
            IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location),
            "..", "..", "..", "..", "DatQBox Admin", "res"))

    Public Sub New()
        Text = "DatqBox Compras (.NET)"
        Width = 1300
        Height = 860
        AutoScaleMode = AutoScaleMode.Dpi
        MinimumSize = New Drawing.Size(1100, 700)
        WindowState = FormWindowState.Maximized
        IsMdiContainer = True
        BuildBaseUi()
    End Sub

    ' ═══════════════════════════════════════════════════════════
    '  UI Construction
    ' ═══════════════════════════════════════════════════════════

    Private Sub BuildBaseUi()
        _topPanel.Dock = DockStyle.Top
        _topPanel.Height = 78

        _statusLabel.Dock = DockStyle.Bottom
        _statusLabel.Height = 24
        _statusLabel.AutoSize = False
        _statusLabel.TextAlign = ContentAlignment.MiddleLeft
        _statusLabel.Padding = New Padding(6, 0, 0, 0)
        _statusLabel.Text = "Inicializando..."

        _workPanel.Dock = DockStyle.Fill

        Controls.Add(_workPanel)
        Controls.Add(_statusLabel)
        Controls.Add(_topPanel)
    End Sub

    Protected Overrides Sub OnLoad(e As EventArgs)
        MyBase.OnLoad(e)
        LoadConfig()
        BuildRibbon()
    End Sub

    Protected Overrides Sub OnShown(e As EventArgs)
        MyBase.OnShown(e)
        ValidateConnection()
    End Sub

    ' ═══════════════════════════════════════════════════════════
    '  Configuration
    ' ═══════════════════════════════════════════════════════════

    Private Sub LoadConfig()
        Try
            _config = ComprasRuntimeConfig.Load(System.Windows.Forms.Application.StartupPath)
            _connectionString = If(_config.ConnectionString, String.Empty)
        Catch ex As Exception
            SetStatus("Error cargando configuracion: " & ex.Message)
        End Try
    End Sub

    Private Sub ValidateConnection()
        If String.IsNullOrWhiteSpace(_connectionString) Then
            SetStatus("Sin conexion configurada. Verifique appsettings.json o DatqBox.ini")
            Return
        End If

        Try
            Dim sql As New SqlClientExecutor(_connectionString)
            Dim dt = sql.Query("SELECT DB_NAME() AS NombreDB")
            Dim dbName = If(dt.Rows.Count > 0, Convert.ToString(dt.Rows(0)(0)), "?")
            SetStatus($"Conexion OK — Base de datos: {dbName}")
        Catch ex As Exception
            SetStatus("Error de conexion: " & ex.Message)
        End Try
    End Sub

    Friend Function GetSqlExecutor() As SqlClientExecutor
        If String.IsNullOrWhiteSpace(_connectionString) Then
            Throw New InvalidOperationException("No hay conexion configurada.")
        End If
        Return New SqlClientExecutor(_connectionString)
    End Function

    ' ═══════════════════════════════════════════════════════════
    '  Ribbon / Menu
    ' ═══════════════════════════════════════════════════════════

    Private Sub BuildRibbon()
        If _ribbonBuilt Then Return
        _ribbonBuilt = True

        Try
            If UiLegacyCompatibility.CanCreateCom(UiLegacyCompatibility.CommandBarsClsid) Then
                BuildCodejockRibbon()
                Return
            End If
        Catch
        End Try

        BuildFallbackMenu()
    End Sub

    Private Sub BuildCodejockRibbon()
        _commandBarsHost = New ComActiveXHost(UiLegacyCompatibility.CommandBarsClsid)
        _commandBarsHost.Dock = DockStyle.Top
        _commandBarsHost.Height = 140

        _topPanel.Controls.Add(_commandBarsHost)
        _topPanel.Height = 140

        System.Windows.Forms.Application.DoEvents()

        _commandBarsOcx = _commandBarsHost.GetComObject()
        If _commandBarsOcx Is Nothing Then
            _topPanel.Controls.Remove(_commandBarsHost)
            BuildFallbackMenu()
            Return
        End If

        ' Set visual theme to Office 2007
        Try
            SetComProperty(_commandBarsOcx, "VisualTheme", 6)
        Catch
        End Try

        Dim builder As New CommandBarsBuilder(_commandBarsOcx, _resDir)
        builder.Build()

        SetStatus("Ribbon Codejock cargado correctamente.")
    End Sub

    ''' <summary>
    ''' Intercepta WM_COMMAND del ribbon Codejock para despachar acciones.
    ''' </summary>
    Protected Overrides Sub WndProc(ByRef m As Message)
        Const WM_COMMAND As Integer = &H111

        If m.Msg = WM_COMMAND Then
            Dim commandId As Integer = (m.WParam.ToInt32() And &HFFFF)
            If HandleRibbonCommand(commandId) Then
                Return
            End If
        End If

        MyBase.WndProc(m)
    End Sub

    Private Function HandleRibbonCommand(commandId As Integer) As Boolean
        Select Case commandId
            ' ── Compras ───────────────────────────────────
            Case ComprasCommandIds.ID_FILE_COMPRAS
                OpenConsultasCompras()
            Case ComprasCommandIds.ID_FILE_MERCANCIA
                OpenComprasMercancia()
            Case ComprasCommandIds.ID_FILE_ORDENES
                OpenComprasMercancia("Devolucion de Mercancia")
            Case ComprasCommandIds.ID_FILE_GASTOS
                OpenComprasMercancia("Ingreso de Mercancia")
            Case ComprasCommandIds.ID_FILE_RELACIONES
                OpenConsultaDetalleCompras()
            Case ComprasCommandIds.ID_FILE_PRINT_COMPRAS
                ShowNotImplemented("Listados y Reportes Compras")

            ' ── Inventario ────────────────────────────────
            Case ComprasCommandIds.ID_FILE_INVENTARIO
                OpenInventario()
            Case ComprasCommandIds.ID_FILE_PRODUCTOS
                OpenArticulos()
            Case ComprasCommandIds.ID_FILE_AJUSTES
                ShowNotImplemented("Ajustar Inventario")
            Case ComprasCommandIds.ID_FILE_PRECIOS
                OpenCambiaPrecios()
            Case ComprasCommandIds.ID_FILE_COMISIONES
                ShowNotImplemented("Tabla de Monedas")
            Case ComprasCommandIds.ID_FILE_BUSCADOR
                OpenBuscadorArticulos()
            Case ComprasCommandIds.ID_FILE_LINEAS
                OpenTabla("Tabla de Lineas de Productos", "Lineas")
            Case ComprasCommandIds.ID_FILE_CATEGORIAS
                OpenTabla("Tabla de Categorias de Productos", "Categoria")
            Case ComprasCommandIds.ID_FILE_TIPOS
                OpenTabla("Tabla de Tipos de Productos", "Tipos")
            Case ComprasCommandIds.ID_FILE_MARCAS
                OpenTabla("Tabla de Marcas de Productos", "Marcas")
            Case ComprasCommandIds.ID_FILE_CLASES
                OpenTabla("Tabla de Clases de Productos", "Clases")
            Case ComprasCommandIds.ID_FILE_ETIQUETA
                ShowNotImplemented("Generador de Etiquetas")
            Case ComprasCommandIds.ID_FILE_REPINVENTARIO
                ShowNotImplemented("Reportes de Inventario")

            ' ── Sistema ───────────────────────────────────
            Case ComprasCommandIds.ID_APP_CONFIGURAR
                ShowNotImplemented("Configuracion del Sistema")
            Case ComprasCommandIds.ID_APP_USUARIO
                ShowNotImplemented("Cambiar Operador")
            Case ComprasCommandIds.ID_APP_USUARIOS
                OpenUsuarios()
            Case ComprasCommandIds.ID_APP_EXIT
                Close()
            Case ComprasCommandIds.ID_APP_ABOUT
                MessageBox.Show("DatqBox Compras — Migracion .NET 9.0" & vbCrLf &
                                "Modulo de Compras e Inventario",
                                "Acerca de", MessageBoxButtons.OK, MessageBoxIcon.Information)

            ' ── Herramientas ──────────────────────────────
            Case ComprasCommandIds.ID_FILE_CALCULADORA
                ShowNotImplemented("Calculadora")
            Case ComprasCommandIds.ID_FILE_AGENDA
                ShowNotImplemented("Agenda Telefonica")

            Case Else
                Return False
        End Select

        Return True
    End Function

    ' ═══════════════════════════════════════════════════════════
    '  Fallback Menu (cuando Codejock no esta disponible)
    ' ═══════════════════════════════════════════════════════════

    Private Sub BuildFallbackMenu()
        _topPanel.Height = 28
        Dim menu As New MenuStrip() With {.Dock = DockStyle.Fill}

        ' ── Compras ───────────────────────────────────────
        Dim mnuCompras As New ToolStripMenuItem("&Compras")
        mnuCompras.DropDownItems.Add("Compras Generales", Nothing, Sub() OpenConsultasCompras())
        mnuCompras.DropDownItems.Add("Compras de Mercancia", Nothing, Sub() OpenComprasMercancia())
        mnuCompras.DropDownItems.Add("Devolucion de Mercancia", Nothing, Sub() OpenComprasMercancia("Devolucion de Mercancia"))
        mnuCompras.DropDownItems.Add("-")
        mnuCompras.DropDownItems.Add("Consulta Detalle de Compras", Nothing, Sub() OpenConsultaDetalleCompras())
        mnuCompras.DropDownItems.Add("-")
        mnuCompras.DropDownItems.Add("Listados y Reportes", Nothing, Sub() ShowNotImplemented("Reportes Compras"))

        ' ── Inventario ────────────────────────────────────
        Dim mnuInv As New ToolStripMenuItem("&Inventario")
        mnuInv.DropDownItems.Add("Control Inventario", Nothing, Sub() OpenInventario())
        mnuInv.DropDownItems.Add("Movimiento de Articulos", Nothing, Sub() OpenArticulos())
        mnuInv.DropDownItems.Add("Cambiar Precios", Nothing, Sub() OpenCambiaPrecios())
        mnuInv.DropDownItems.Add("-")
        mnuInv.DropDownItems.Add("Buscador de Articulos", Nothing, Sub() OpenBuscadorArticulos())
        mnuInv.DropDownItems.Add("-")

        Dim mnuTablas As New ToolStripMenuItem("Tablas de Productos")
        mnuTablas.DropDownItems.Add("Lineas", Nothing, Sub() OpenTabla("Lineas", "Lineas"))
        mnuTablas.DropDownItems.Add("Categorias", Nothing, Sub() OpenTabla("Categorias", "Categoria"))
        mnuTablas.DropDownItems.Add("Tipos", Nothing, Sub() OpenTabla("Tipos", "Tipos"))
        mnuTablas.DropDownItems.Add("Marcas", Nothing, Sub() OpenTabla("Marcas", "Marcas"))
        mnuTablas.DropDownItems.Add("Clases", Nothing, Sub() OpenTabla("Clases", "Clases"))
        mnuInv.DropDownItems.Add(mnuTablas)

        mnuInv.DropDownItems.Add("-")
        mnuInv.DropDownItems.Add("Generador de Etiquetas", Nothing, Sub() ShowNotImplemented("Etiquetas"))
        mnuInv.DropDownItems.Add("Reportes de Inventario", Nothing, Sub() ShowNotImplemented("Reportes Inventario"))

        ' ── Herramientas ──────────────────────────────────
        Dim mnuHerr As New ToolStripMenuItem("&Herramientas")
        mnuHerr.DropDownItems.Add("Usuarios", Nothing, Sub() OpenUsuarios())
        mnuHerr.DropDownItems.Add("Configuracion", Nothing, Sub() ShowNotImplemented("Configuracion"))
        mnuHerr.DropDownItems.Add("-")
        mnuHerr.DropDownItems.Add("Acerca de...", Nothing,
            Sub() MessageBox.Show("DatqBox Compras — Migracion .NET 9.0",
                                  "Acerca de", MessageBoxButtons.OK, MessageBoxIcon.Information))
        mnuHerr.DropDownItems.Add("-")
        mnuHerr.DropDownItems.Add("Salir", Nothing, Sub() Close())

        menu.Items.AddRange(New ToolStripItem() {mnuCompras, mnuInv, mnuHerr})
        _topPanel.Controls.Add(menu)
        SetStatus("Ribbon Codejock no disponible — usando menu estandar.")
    End Sub

    ' ═══════════════════════════════════════════════════════════
    '  Form Launchers (stubs que se completan en cada sprint)
    ' ═══════════════════════════════════════════════════════════

    Private Sub OpenConsultasCompras()
        Try
            SetStatus("Abriendo consultas de compras...")
            Dim sql = GetSqlExecutor()
            Dim useCase As New ConsultarComprasUseCase(sql)
            Dim frm As New FrmConsultasCompras(useCase)
            frm.MdiParent = Me
            frm.Show()
        Catch ex As Exception
            ShowError("Consultas Compras", ex)
        End Try
    End Sub

    Private Sub OpenComprasMercancia(Optional tipo As String = "")
        Try
            SetStatus("Abriendo compras de mercancia...")
            Dim sql = GetSqlExecutor()
            Dim registrarUC As New RegistrarCompraUseCase(sql)
            Dim articuloUC As New ObtenerArticuloUseCase(sql)
            Dim frm As New FrmCompras(registrarUC, articuloUC)
            If Not String.IsNullOrEmpty(tipo) Then
                frm.Text = tipo & " (.NET)"
            End If
            frm.MdiParent = Me
            frm.Show()
        Catch ex As Exception
            ShowError("Compras Mercancia", ex)
        End Try
    End Sub

    Private Sub OpenConsultaDetalleCompras()
        Try
            SetStatus("Abriendo detalle de compras...")
            Dim sql = GetSqlExecutor()
            Dim useCase As New ConsultarComprasUseCase(sql)
            Dim frm As New FrmConsultasCompras(useCase)
            frm.MdiParent = Me
            frm.Show()
        Catch ex As Exception
            ShowError("Detalle Compras", ex)
        End Try
    End Sub

    Private Sub OpenInventario()
        Try
            SetStatus("Abriendo inventario...")
            Dim sql = GetSqlExecutor()
            Dim useCase As New ConsultarInventarioUseCase(sql)
            Dim frm As New FrmInventario(useCase)
            frm.MdiParent = Me
            frm.Show()
        Catch ex As Exception
            ShowError("Inventario", ex)
        End Try
    End Sub

    Private Sub OpenArticulos()
        Try
            SetStatus("Abriendo articulos...")
            Dim sql = GetSqlExecutor()
            Dim obtenerUC As New ObtenerArticuloUseCase(sql)
            Dim guardarUC As New GuardarArticuloUseCase(sql)
            Dim frm As New FrmArticulos(obtenerUC, guardarUC)
            frm.MdiParent = Me
            frm.Show()
        Catch ex As Exception
            ShowError("Articulos", ex)
        End Try
    End Sub

    Private Sub OpenCambiaPrecios()
        Try
            SetStatus("Abriendo cambio de precios...")
            Dim sql = GetSqlExecutor()
            Dim frm As New FrmCambiaPrecios(sql)
            frm.MdiParent = Me
            frm.Show()
        Catch ex As Exception
            ShowError("Cambiar Precios", ex)
        End Try
    End Sub

    Private Sub OpenBuscadorArticulos()
        Try
            SetStatus("Abriendo buscador...")
            Dim sql = GetSqlExecutor()
            Dim useCaseBuscar As New BuscarComprasUseCase(sql)
            Dim useCaseDetalle As New ConsultarComprasUseCase(sql)
            Using frm As New FrmBuscardorCompras(useCaseBuscar, useCaseDetalle)
                If frm.ShowDialog(Me) = DialogResult.OK Then
                    SetStatus($"Seleccionado: {frm.NumFactSeleccionada} — {frm.NombreProveedorSeleccionado}")
                End If
            End Using
        Catch ex As Exception
            ShowError("Buscador", ex)
        End Try
    End Sub

    Private Sub OpenTabla(titulo As String, tabla As String)
        Try
            SetStatus($"Abriendo tabla: {titulo}...")
            ShowNotImplemented($"Tabla: {titulo} ({tabla})")
        Catch ex As Exception
            ShowError("Tabla", ex)
        End Try
    End Sub

    Private Sub OpenUsuarios()
        Try
            SetStatus("Abriendo usuarios...")
            ShowNotImplemented("Gestion de Usuarios")
        Catch ex As Exception
            ShowError("Usuarios", ex)
        End Try
    End Sub

    ' ═══════════════════════════════════════════════════════════
    '  Helpers
    ' ═══════════════════════════════════════════════════════════

    Private Sub SetStatus(message As String)
        _statusLabel.Text = message
    End Sub

    Private Sub ShowNotImplemented(feature As String)
        SetStatus($"{feature} — pendiente de migracion.")
        MessageBox.Show($"{feature}" & vbCrLf & vbCrLf &
                        "Este formulario sera implementado en un sprint posterior.",
                        "Pendiente", MessageBoxButtons.OK, MessageBoxIcon.Information)
    End Sub

    Private Sub ShowError(context As String, ex As Exception)
        SetStatus($"Error en {context}.")
        MessageBox.Show(ex.Message, context, MessageBoxButtons.OK, MessageBoxIcon.Error)
    End Sub

    Private Shared Sub SetComProperty(target As Object, prop As String, value As Object)
        Try
            Microsoft.VisualBasic.Interaction.CallByName(target, prop, CallType.Set, value)
        Catch
        End Try
    End Sub

End Class

