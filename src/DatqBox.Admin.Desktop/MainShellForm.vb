Imports System.Data
Imports System.Windows.Forms
Imports DatqBox.Application.Sales
Imports DatqBox.Infrastructure.Data

' Pilot migration shell based on VB6 frmMainAdmin startup flow.
' Adds extensibility foundation: numeric UI references + add-on DLL loader + UDF renderer.
Public Class MainShellForm
    Inherits Form

    Private ReadOnly _topPanel As New Panel()
    Private ReadOnly _leftPanel As New Panel()
    Private ReadOnly _rightPanel As New Panel()
    Private ReadOnly _workPanel As New Panel()
    Private ReadOnly _udfHost As New FlowLayoutPanel()
    Private ReadOnly _statusLabel As New Label()
    Private ReadOnly _btnVentas As New Button()
    Private ReadOnly _btnConnect As New Button()
    Private ReadOnly _btnToggleRefs As New Button()
    Private ReadOnly _toolTip As New ToolTip()

    Private _commandBarsHost As ComActiveXHost
    Private _trueDbGridHost As ComActiveXHost
    Private _config As AdminRuntimeConfig
    Private _startupCompleted As Boolean
    Private _refsVisible As Boolean
    Private _commandBarsBridge As CommandBarsEventBridge

    Private ReadOnly _registry As New UiReferenceRegistry()
    Private _udfRenderer As UdfRenderer
    Private _addonContext As AddonContext
    Private _addonHost As AddonHostService

    Public Sub New()
        Text = "Syswin Administrativo SQL (.NET Pilot)"
        Width = 1300
        Height = 860
        AutoScaleMode = AutoScaleMode.Dpi
        MinimumSize = New Drawing.Size(1200, 760)
        WindowState = FormWindowState.Maximized
        BuildBaseUi()
        AddHandler Me.Resize, AddressOf OnShellResize
    End Sub

    Private Sub BuildBaseUi()
        _topPanel.Dock = DockStyle.Top
        _topPanel.Height = 78
        _topPanel.Padding = New Padding(10, 8, 10, 8)

        _statusLabel.Dock = DockStyle.Bottom
        _statusLabel.Height = 22
        _statusLabel.AutoSize = False
        _statusLabel.TextAlign = ContentAlignment.MiddleLeft
        _statusLabel.Text = "Inicializando shell de migracion..."

        _leftPanel.Dock = DockStyle.Left
        _leftPanel.Width = 260
        _leftPanel.Padding = New Padding(8)

        _rightPanel.Dock = DockStyle.Right
        _rightPanel.Width = 340
        _rightPanel.Padding = New Padding(8)

        _workPanel.Dock = DockStyle.Fill
        _workPanel.Padding = New Padding(8)

        Dim udfTitle As New Label() With {
            .Text = "UDF / AddOns",
            .Dock = DockStyle.Top,
            .Height = 26,
            .TextAlign = ContentAlignment.MiddleLeft,
            .Font = New Drawing.Font("Segoe UI", 9.0F, Drawing.FontStyle.Bold)
        }

        _udfHost.Dock = DockStyle.Fill
        _udfHost.AutoScroll = True
        _udfHost.FlowDirection = FlowDirection.TopDown
        _udfHost.WrapContents = False

        _btnConnect.Text = "Validar Conexion"
        _btnConnect.Width = 220
        _btnConnect.Height = 38
        _btnConnect.Left = 16
        _btnConnect.Top = 14
        AddHandler _btnConnect.Click, AddressOf OnValidateConnectionClick

        _btnVentas.Text = "Consulta Ventas (.NET)"
        _btnVentas.Width = 220
        _btnVentas.Height = 38
        _btnVentas.Left = 16
        _btnVentas.Top = 60
        AddHandler _btnVentas.Click, AddressOf OnOpenVentasClick

        _btnToggleRefs.Text = "Ver Referencias"
        _btnToggleRefs.Width = 220
        _btnToggleRefs.Height = 38
        _btnToggleRefs.Left = 16
        _btnToggleRefs.Top = 106
        AddHandler _btnToggleRefs.Click, AddressOf OnToggleReferencesClick

        _leftPanel.Controls.Add(_btnConnect)
        _leftPanel.Controls.Add(_btnVentas)
        _leftPanel.Controls.Add(_btnToggleRefs)
        _rightPanel.Controls.Add(_udfHost)
        _rightPanel.Controls.Add(udfTitle)

        Controls.Add(_workPanel)
        Controls.Add(_rightPanel)
        Controls.Add(_leftPanel)
        Controls.Add(_statusLabel)
        Controls.Add(_topPanel)

        _udfRenderer = New UdfRenderer(_udfHost, _registry)
        RegisterBaseReferences()
    End Sub

    Protected Overrides Sub OnLoad(e As EventArgs)
        MyBase.OnLoad(e)
        BuildLegacyPilotControls()
        ApplyAdaptiveShellLayout()
    End Sub

    Protected Overrides Sub OnShown(e As EventArgs)
        MyBase.OnShown(e)
        If _startupCompleted Then Return
        _startupCompleted = True
        ExecuteStartupFlow()
    End Sub

    Private Sub RegisterBaseReferences()
        _registry.Register(CoreUiRefIds.MainShellForm, "Form.MainShell", Me)
        _registry.Register(CoreUiRefIds.TopPanel, "Panel.Top", _topPanel)
        _registry.Register(CoreUiRefIds.LeftPanel, "Panel.Left", _leftPanel)
        _registry.Register(CoreUiRefIds.RightPanel, "Panel.Right", _rightPanel)
        _registry.Register(CoreUiRefIds.WorkPanel, "Panel.Work", _workPanel)
        _registry.Register(CoreUiRefIds.StatusLabel, "Status.Main", _statusLabel)
        _registry.Register(CoreUiRefIds.ButtonValidateConnection, "Button.ValidateConnection", _btnConnect)
        _registry.Register(CoreUiRefIds.ButtonOpenVentas, "Button.OpenVentas", _btnVentas)
        _registry.Register(CoreUiRefIds.ButtonToggleRefs, "Button.ToggleReferences", _btnToggleRefs)
        _registry.Register(CoreUiRefIds.UdfHost, "Panel.UdfHost", _udfHost)
    End Sub

    Private Sub BuildLegacyPilotControls()
        _topPanel.Controls.Clear()
        _workPanel.Controls.Clear()

        Try
            _commandBarsHost = TryCreateHost(UiLegacyCompatibility.CommandBarsClsid, DockStyle.Fill)
            If _commandBarsHost IsNot Nothing Then
                _topPanel.Controls.Add(_commandBarsHost)
                _registry.Register(CoreUiRefIds.CommandBarsHost, "Host.CommandBars", _commandBarsHost)
                ConfigureCommandBarsPilot(_commandBarsHost)
            Else
                AddFallbackMenu()
            End If
        Catch
            AddFallbackMenu()
        End Try

        Try
            _trueDbGridHost = TryCreateHost(UiLegacyCompatibility.TrueDbGridClsid, DockStyle.Fill)
            If _trueDbGridHost IsNot Nothing Then
                _workPanel.Controls.Add(_trueDbGridHost)
                _registry.Register(CoreUiRefIds.TrueDbGridHost, "Host.TrueDbGrid", _trueDbGridHost)
            Else
                AddFallbackGrid()
            End If
        Catch
            AddFallbackGrid()
        End Try
    End Sub

    Private Sub ExecuteStartupFlow()
        Try
            SetStatus("Cargando configuracion e inicio (menu -> splash -> login -> conexion)...")
            Cursor = Cursors.WaitCursor

            _config = AdminRuntimeConfig.Load(System.Windows.Forms.Application.StartupPath)
            ShowSplash()

            If Not ShowLogin() Then
                Close()
                Return
            End If

            ValidateConnection()
            InitializeAddons()
            SetStatus("Listo. Flujo inicial completado.")
        Catch ex As Exception
            SetStatus("Error en arranque.")
            MessageBox.Show(ex.Message, "Arranque Admin", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            Cursor = Cursors.Default
        End Try
    End Sub

    Private Sub InitializeAddons()
        _addonContext = New AddonContext(
            _registry,
            _leftPanel,
            _udfRenderer,
            AddressOf SetStatus,
            Function() ResolveConnectionString())
        _addonHost = New AddonHostService()

        Dim addonsPath = IO.Path.Combine(System.Windows.Forms.Application.StartupPath, "addons")
        Dim result = _addonHost.LoadAndInitialize(addonsPath, _addonContext)

        If result.Errors.Count > 0 Then
            SetStatus("AddOns cargados con advertencias. Revise mensajes.")
        Else
            SetStatus($"AddOns cargados: {result.LoadedModules.Count}.")
        End If

        ' Built-in sample UDF so the integration path is visible immediately.
        _addonContext.RegisterUdf(New UdfDefinition With {
            .ReferenceId = CoreUiRefIds.UdfFieldBase + 1,
            .TableName = "CLIENTES",
            .FieldName = "UDF_CLASIFICACION",
            .Caption = "Clasificacion Cliente",
            .DataType = UdfDataType.Text,
            .DefaultValue = ""
        })
    End Sub

    Private Function ResolveConnectionString() As String
        If _config Is Nothing Then
            _config = AdminRuntimeConfig.Load(System.Windows.Forms.Application.StartupPath)
        End If
        Return If(_config.ConnectionString, String.Empty)
    End Function

    Private Function ShowLogin() As Boolean
        Using login As New LoginForm()
            Dim result = login.ShowDialog(Me)
            If result = DialogResult.OK Then
                Dim ok = ValidateLogin(login.Usuario, login.EncryptedPassword, login.PasswordPlain)
                If Not ok Then
                    MessageBox.Show("No se pudo validar con el sistema. Verifique usuario y clave.", "Arranque Admin", MessageBoxButtons.OK, MessageBoxIcon.Error)
                    Return False
                End If
            End If
            Return result = DialogResult.OK
        End Using
    End Function

    Private Function ValidateLogin(user As String, encryptedPass As String, plainPass As String) As Boolean
        If String.IsNullOrWhiteSpace(user) Then Return False
        If String.IsNullOrWhiteSpace(plainPass) AndAlso String.IsNullOrWhiteSpace(encryptedPass) Then Return False

        Dim conn = ResolveConnectionString()
        If String.IsNullOrWhiteSpace(conn) Then Return False

        Dim sql As New SqlClientExecutor(conn)
        Dim dt = sql.Query("SELECT Cod_Usuario, Password FROM Usuarios WHERE UPPER(Cod_Usuario) = @user", New Dictionary(Of String, Object) From {
            {"@user", user.Trim().ToUpperInvariant()}
        })
        If dt.Rows.Count = 0 Then Return False

        Dim stored = Convert.ToString(dt.Rows(0)("Password")).Trim()
        If stored.Length = 0 Then Return False

        If String.Equals(stored, plainPass, StringComparison.Ordinal) Then Return True
        If String.Equals(stored, encryptedPass, StringComparison.Ordinal) Then Return True

        Dim decrypted = DatqBox.Infrastructure.Legacy.LegacyCrypto.Decrypt(stored)
        Return String.Equals(decrypted, plainPass, StringComparison.Ordinal)
    End Function

    Private Sub ShowSplash()
        Using splash As New SplashForm()
            splash.Show()
            splash.Update()
            System.Windows.Forms.Application.DoEvents()
            Threading.Thread.Sleep(1000)
        End Using
    End Sub

    Private Sub ConfigureCommandBarsPilot(host As ComActiveXHost)
        Try
            Dim ocx = host.GetComObject()
            If ocx Is Nothing Then Return
            TrySetProperty(ocx, "VisualTheme", 6)
            Dim builder As New CommandBarsBuilder(ocx, ResolveLegacyResPath(), ResolveLegacyIniPath())
            builder.Build()
            Dim iconsCount As Integer = 0
            Try
                Dim icons = TryGetProperty(ocx, "Icons")
                If icons IsNot Nothing Then
                    Dim countVal = TryGetProperty(icons, "Count")
                    If countVal IsNot Nothing Then iconsCount = Convert.ToInt32(countVal)
                End If
            Catch
                iconsCount = 0
            End Try
            SetStatus("CommandBars listo. Res=" & ResolveLegacyResPath() & " | Icons=" & iconsCount.ToString())
            If _commandBarsBridge Is Nothing Then
                _commandBarsBridge = New CommandBarsEventBridge(ocx, AddressOf OnCommandBarsExecute)
                _commandBarsBridge.Attach()
            End If
        Catch ex As Exception
            MessageBox.Show(ex.Message, "CommandBars", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub OnCommandBarsExecute(id As Integer, caption As String)
        Select Case id
            Case AdminCommandIds.ID_FILE_PAGAR
                ShowPlaceholderForm("Cuentas por Pagar")
            Case AdminCommandIds.ID_FILE_COMPRAS
                ShowPlaceholderForm("Compras Generales")
            Case AdminCommandIds.ID_FILE_INVENTARIO
                ShowPlaceholderForm("Inventario")
            Case AdminCommandIds.ID_FILE_PTOVENTA
                OpenVentasForm()
            Case AdminCommandIds.ID_APP_ABOUT
                MessageBox.Show("DatqBox Administrativo SQL (.NET Pilot)", "Acerca de", MessageBoxButtons.OK, MessageBoxIcon.Information)
            Case AdminCommandIds.ID_APP_EXIT
                Close()
            Case Else
                If Not String.IsNullOrWhiteSpace(caption) Then
                    MessageBox.Show("Accion no migrada: " & caption, "Menu", MessageBoxButtons.OK, MessageBoxIcon.Information)
                End If
        End Select
    End Sub

    Private Sub ShowPlaceholderForm(title As String)
        Dim frm As New Form() With {
            .Text = title & " (.NET)",
            .Width = 1000,
            .Height = 700,
            .StartPosition = FormStartPosition.CenterScreen
        }
        Dim label As New Label() With {
            .Dock = DockStyle.Fill,
            .TextAlign = ContentAlignment.MiddleCenter,
            .Text = "Pantalla en migracion: " & title
        }
        frm.Controls.Add(label)
        frm.Show(Me)
    End Sub

    Private Function ResolveLegacyResPath() As String
        Dim outputRes As String = IO.Path.Combine(System.Windows.Forms.Application.StartupPath, "res")
        If IO.Directory.Exists(outputRes) Then Return outputRes
        Dim legacyRes As String = "C:\Users\Dell\Dropbox\DatqBox Administrativo ADO SQL\DatQBox Admin\res"
        If IO.Directory.Exists(legacyRes) Then Return legacyRes
        Return outputRes
    End Function

    Private Function ResolveLegacyIniPath() As String
        If _config Is Nothing Then
            _config = AdminRuntimeConfig.Load(System.Windows.Forms.Application.StartupPath)
        End If
        Dim path = If(_config.LegacyIniPath, String.Empty)
        If Not String.IsNullOrWhiteSpace(path) AndAlso IO.File.Exists(path) Then Return path
        Dim fallback = "C:\Users\Dell\Dropbox\DatqBox Administrativo ADO SQL\DatQBox Admin\DatqBox.ini"
        If IO.File.Exists(fallback) Then Return fallback
        Return String.Empty
    End Function

    Private Function TryCreateHost(clsid As String, dock As DockStyle) As ComActiveXHost
        If String.IsNullOrWhiteSpace(clsid) Then Return Nothing
        If Not UiLegacyCompatibility.CanCreateCom(clsid) Then Return Nothing

        Try
            Dim host As New ComActiveXHost(clsid)
            host.Dock = dock
            Return host
        Catch
            Return Nothing
        End Try
    End Function

    Private Sub AddFallbackMenu()
        Dim menu As New MenuStrip() With {.Dock = DockStyle.Top}
        Dim mArchivo = menu.Items.Add("Archivo")
        DirectCast(mArchivo, ToolStripMenuItem).DropDownItems.Add("Consulta Ventas", Nothing, Sub() OpenVentasForm())
        _topPanel.Controls.Add(menu)
    End Sub

    Private Sub AddFallbackGrid()
        Dim fallback As New DataGridView() With {
            .Dock = DockStyle.Fill,
            .ReadOnly = True,
            .AllowUserToAddRows = False,
            .AllowUserToDeleteRows = False,
            .DataSource = BuildGridFallbackTable()
        }
        _workPanel.Controls.Add(fallback)
        _registry.Register(CoreUiRefIds.FallbackGrid, "Grid.Fallback", fallback)
    End Sub

    Private Sub OnValidateConnectionClick(sender As Object, e As EventArgs)
        Try
            _config = AdminRuntimeConfig.Load(System.Windows.Forms.Application.StartupPath)
            ValidateConnection()
            MessageBox.Show("Conexion SQL validada correctamente.", "Conexion", MessageBoxButtons.OK, MessageBoxIcon.Information)
        Catch ex As Exception
            MessageBox.Show(ex.Message, "Conexion", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub ValidateConnection()
        If _config Is Nothing Then
            Throw New InvalidOperationException("Configuracion no cargada.")
        End If
        If String.IsNullOrWhiteSpace(_config.ConnectionString) Then
            Throw New InvalidOperationException("No se encontro ConnectionString ni conexion legacy valida en DatqBox.ini.")
        End If

        Dim sql As New SqlClientExecutor(_config.ConnectionString)
        Dim table As DataTable = sql.Query("SELECT TOP 1 name FROM sys.databases ORDER BY name")
        Dim dbName As String = If(table.Rows.Count = 0, "(sin datos)", Convert.ToString(table.Rows(0)(0)))
        SetStatus("Conexion SQL OK. Base visible: " & dbName)
    End Sub

    Private Sub OnOpenVentasClick(sender As Object, e As EventArgs)
        OpenVentasForm()
    End Sub

    Private Sub OpenVentasForm()
        Try
            If _config Is Nothing Then
                _config = AdminRuntimeConfig.Load(System.Windows.Forms.Application.StartupPath)
            End If
            If String.IsNullOrWhiteSpace(_config.ConnectionString) Then
                MessageBox.Show("No se encontro ConnectionString para abrir consultas.", "Configuracion", MessageBoxButtons.OK, MessageBoxIcon.Warning)
                Return
            End If

            Dim sql As New SqlClientExecutor(_config.ConnectionString)
            Dim useCase As New ConsultarFacturasUseCase(sql)
            Dim frm As New FrmConsultasVentasNet(useCase)
            frm.Show(Me)
        Catch ex As Exception
            MessageBox.Show(ex.Message, "Consulta Ventas", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub OnToggleReferencesClick(sender As Object, e As EventArgs)
        _refsVisible = Not _refsVisible
        If _refsVisible Then
            _registry.ApplyTooltips(_toolTip)
            _btnToggleRefs.Text = "Ocultar Referencias"
            SetStatus("Referencias UI activadas. Pase el mouse para ver ID numerico.")
        Else
            _toolTip.RemoveAll()
            _btnToggleRefs.Text = "Ver Referencias"
            SetStatus("Referencias UI ocultas.")
        End If
    End Sub

    Private Sub OnShellResize(sender As Object, e As EventArgs)
        ApplyAdaptiveShellLayout()
    End Sub

    Private Sub ApplyAdaptiveShellLayout()
        If ClientSize.Width <= 0 Then Return

        Dim leftWidth As Integer = CInt(Math.Round(ClientSize.Width * 0.16))
        Dim rightWidth As Integer = CInt(Math.Round(ClientSize.Width * 0.23))

        _leftPanel.Width = Math.Max(240, Math.Min(420, leftWidth))
        _rightPanel.Width = Math.Max(320, Math.Min(620, rightWidth))
    End Sub

    Private Sub SetStatus(message As String)
        _statusLabel.Text = message
    End Sub

    Private Shared Function BuildGridFallbackTable() As DataTable
        Dim table As New DataTable()
        table.Columns.Add("Modulo")
        table.Columns.Add("Estado")
        table.Rows.Add("CommandBars ActiveX", "Piloto inicial")
        table.Rows.Add("TrueDBGrid ActiveX", "Piloto inicial")
        table.Rows.Add("Splash/Login", "Secuencia implementada")
        table.Rows.Add("DatqBox.ini", "Lectura y desencriptado activo")
        table.Rows.Add("AddOns/UDF", "Base de extensibilidad activa")
        Return table
    End Function

    Private Shared Function TryInvoke(target As Object, methodName As String, ParamArray args() As Object) As Object
        Try
            Return Microsoft.VisualBasic.Interaction.CallByName(target, methodName, CallType.Method, args)
        Catch
            Return Nothing
        End Try
    End Function

    Private Shared Function TryGetProperty(target As Object, propertyName As String) As Object
        Try
            Return Microsoft.VisualBasic.Interaction.CallByName(target, propertyName, CallType.Get)
        Catch
            Return Nothing
        End Try
    End Function

    Private Shared Sub TrySetProperty(target As Object, propertyName As String, value As Object)
        Try
            Microsoft.VisualBasic.Interaction.CallByName(target, propertyName, CallType.Set, value)
        Catch
            ' Ignore optional COM property setup failures.
        End Try
    End Sub
End Class
