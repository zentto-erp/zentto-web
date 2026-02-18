Imports Microsoft.VisualBasic

''' <summary>
''' Construye el ribbon de Codejock CommandBars usando late-binding (CallByName)
''' para no requerir referencia COM en el proyecto .NET.
''' Replica la estructura del ribbon VB6 de frmMainCompras.
''' </summary>
Friend Class CommandBarsBuilder

    ' XTPControlType constants (from Codejock enum)
    Private Const xtpControlButton As Integer = 1
    Private Const xtpControlPopup As Integer = 4
    Private Const xtpControlCheckBox As Integer = 7
    Private Const xtpControlSplitButtonPopup As Integer = 5

    ' XTPImageState
    Private Const xtpImageNormal As Integer = 0

    ' XTPToolBarFlags
    Private Const xtpFlagStretched As Integer = 1

    ' XTPControlFlags
    Private Const xtpFlagRightAlign As Integer = 4

    Private ReadOnly _ocx As Object
    Private ReadOnly _resDir As String

    Public Sub New(commandBarsOcx As Object, resourceDirectory As String)
        _ocx = commandBarsOcx
        _resDir = resourceDirectory
    End Sub

    ''' <summary>
    ''' Construye todo el ribbon: carga iconos, crea tabs, groups y botones.
    ''' </summary>
    Public Sub Build()
        SetOption("UseSharedImageList", False)
        LoadIcons()
        Dim ribbon = CreateRibbonBar()
        BuildSystemButton(ribbon)
        BuildComprasTab(ribbon)
        BuildInventarioTab(ribbon)
        BuildVentanaTab(ribbon)
        BuildQuickAccess(ribbon)
        BuildRightAlignedButtons(ribbon)
    End Sub

    ' ─── Icon Loading ─────────────────────────────────────────

    Private Sub LoadIcons()
        Dim icons = GetProperty(_ocx, "Icons")

        ' SmallIcons.png — standard small toolbar icons
        LoadBitmapStrip(icons, "SmallIcons.png", New Integer() {
            57600, 57601, 57603, 4004, 4003, 4023, 4024, 146, 4011, ComprasCommandIds.ID_APP_ABOUT
        })

        ' SmallIcons1.png — calculator, agenda, reports, user
        LoadBitmapStrip(icons, "SmallIcons1.png", New Integer() {
            ComprasCommandIds.ID_FILE_CALCULADORA,
            ComprasCommandIds.ID_FILE_AGENDA,
            0, ' placeholder
            ComprasCommandIds.ID_APP_USUARIO
        })

        ' ProveeCompras.png — purchases & suppliers large icons
        LoadBitmapStrip(icons, "ProveeCompras.png", New Integer() {
            0, 0, ' placeholders
            ComprasCommandIds.ID_FILE_COMPRAS,
            ComprasCommandIds.ID_FILE_MERCANCIA,
            0,
            ComprasCommandIds.ID_APP_USUARIOS,
            ComprasCommandIds.ID_APP_CONFIGURAR,
            ComprasCommandIds.ID_APP_CORRELATIVOS,
            ComprasCommandIds.ID_FILE_GASTOS,
            ComprasCommandIds.ID_FILE_INVENTARIO,
            ComprasCommandIds.ID_APP_FORMULAS,
            0,
            ComprasCommandIds.ID_FILE_ORDENES
        })

        ' ClienteInvent.png — clients & inventory icons
        LoadBitmapStrip(icons, "ClienteInvent.png", New Integer() {
            0, 0,
            ComprasCommandIds.ID_FILE_COMPRAS + 9000, ' alternate
            ComprasCommandIds.ID_FILE_MERCANCIA + 9000,
            0,
            ComprasCommandIds.ID_APP_USUARIOS + 9000,
            ComprasCommandIds.ID_APP_CONFIGURAR + 9000,
            ComprasCommandIds.ID_APP_CORRELATIVOS + 9000,
            ComprasCommandIds.ID_FILE_GASTOS + 9000,
            ComprasCommandIds.ID_FILE_INVENTARIO + 9000,
            ComprasCommandIds.ID_APP_FORMULAS + 9000,
            0,
            ComprasCommandIds.ID_FILE_ORDENES + 9000,
            ComprasCommandIds.ID_APP_EXIT
        })

        ' tablasinvent.png — inventory tables
        LoadBitmapStrip(icons, "tablasinvent.png", New Integer() {
            ComprasCommandIds.ID_FILE_LINEAS,
            ComprasCommandIds.ID_FILE_CATEGORIAS,
            ComprasCommandIds.ID_FILE_TIPOS,
            ComprasCommandIds.ID_FILE_MARCAS,
            ComprasCommandIds.ID_FILE_CLASES,
            ComprasCommandIds.ID_FILE_AJUSTES,
            ComprasCommandIds.ID_FILE_PRECIOS
        })

        ' Menu1.png — reports and various modules
        LoadBitmapStrip(icons, "Menu1.png", New Integer() {
            ComprasCommandIds.ID_APP_INFORMECRYSTAL,
            ComprasCommandIds.ID_APP_INFORMEXML,
            ComprasCommandIds.ID_FILE_REPINVENTARIO,
            ComprasCommandIds.ID_APP_RETENCIONES,
            0, 0,
            ComprasCommandIds.ID_FILE_ETIQUETA,
            0,
            ComprasCommandIds.ID_FILE_RELACIONES,
            0, 0, 0, 0,
            ComprasCommandIds.ID_FILE_BUSCADOR,
            ComprasCommandIds.ID_FILE_PRODUCTOS,
            0,
            ComprasCommandIds.ID_FILE_PRINT_COMPRAS
        })

        ' notas.png — invoices, commissions
        LoadBitmapStrip(icons, "notas.png", New Integer() {
            0, 0, 0, 0, 0, 0,
            ComprasCommandIds.ID_FILE_COMISIONES
        })

        ' largeicons.png — large ribbon icons
        LoadBitmapStrip(icons, "largeicons.png", New Integer() {
            57600, 57601, 57603, 4023, 57636, 4011, 57602,
            0, 57609, 0,
            ComprasCommandIds.ID_WINDOW_NEW,
            ComprasCommandIds.ID_WINDOW_ARRANGE,
            ComprasCommandIds.ID_WINDOW_SWITCH
        })

        ' shiny-gear.png — system icon
        LoadSingleBitmap(icons, "shiny-gear.png", ComprasCommandIds.ID_SYSTEM_ICON)
    End Sub

    Private Sub LoadBitmapStrip(icons As Object, fileName As String, ids() As Integer)
        Dim path = IO.Path.Combine(_resDir, fileName)
        If Not IO.File.Exists(path) Then Return
        Try
            Dim objIds As Object() = ids.Cast(Of Object)().ToArray()
            Invoke(icons, "LoadBitmap", path, objIds, xtpImageNormal)
        Catch
            ' Silently skip if image strip fails to load
        End Try
    End Sub

    Private Sub LoadSingleBitmap(icons As Object, fileName As String, id As Integer)
        Dim path = IO.Path.Combine(_resDir, fileName)
        If Not IO.File.Exists(path) Then Return
        Try
            Invoke(icons, "LoadBitmap", path, id, xtpImageNormal)
        Catch
        End Try
    End Sub

    ' ─── Ribbon Structure ─────────────────────────────────────

    Private Function CreateRibbonBar() As Object
        Dim ribbon = Invoke(_ocx, "AddRibbonBar", "The Ribbon")
        Invoke(ribbon, "EnableDocking", xtpFlagStretched)
        Return ribbon
    End Function

    Private Sub BuildSystemButton(ribbon As Object)
        Dim sysBtn = Invoke(ribbon, "AddSystemButton")
        SetProperty(sysBtn, "IconId", ComprasCommandIds.ID_SYSTEM_ICON)
        SetProperty(sysBtn, "Caption", "&Archivo")

        Dim cmdBar = GetProperty(sysBtn, "CommandBar")
        Dim controls = GetProperty(cmdBar, "Controls")

        AddControl(controls, xtpControlButton, ComprasCommandIds.ID_APP_CONFIGURAR, "Cambiar Configuracion del Sistema")
        AddControl(controls, xtpControlButton, ComprasCommandIds.ID_APP_INFORMEXML, "Generador de Informes XML")
        AddControl(controls, xtpControlButton, ComprasCommandIds.ID_APP_INFORMECRYSTAL, "Generador de Informes Crystal Reports")

        Dim btnRespaldo = AddControl(controls, xtpControlButton, ComprasCommandIds.ID_FILE_RESPALDO, "Respaldo de Base de Datos")
        SetProperty(btnRespaldo, "BeginGroup", True)

        Dim btnExit = AddControl(controls, xtpControlButton, ComprasCommandIds.ID_APP_EXIT, "Salir del Sistema")
        SetProperty(btnExit, "BeginGroup", True)

        Invoke(cmdBar, "SetIconSize", 32, 32)
    End Sub

    Private Sub BuildComprasTab(ribbon As Object)
        Dim tab = Invoke(ribbon, "InsertTab", 0, "Modulo de &Compras")
        SetProperty(tab, "Id", ComprasCommandIds.ID_TAB_COMPRAS)

        ' Group: Compras
        Dim groups = GetProperty(tab, "Groups")
        Dim grpCompras = Invoke(groups, "AddGroup", "Compras", ComprasCommandIds.ID_GROUP_COMPRAS)

        AddControl(grpCompras, xtpControlButton, ComprasCommandIds.ID_FILE_COMPRAS, "Compras Generales")
        AddControl(grpCompras, xtpControlButton, ComprasCommandIds.ID_FILE_MERCANCIA, "Compras de Mercancia")
        AddControl(grpCompras, xtpControlButton, ComprasCommandIds.ID_FILE_ORDENES, "Devolucion de Mercancia")
        AddControl(grpCompras, xtpControlButton, ComprasCommandIds.ID_FILE_GASTOS, "Ingreso de Orden de Entrega")
        AddControl(grpCompras, xtpControlButton, ComprasCommandIds.ID_FILE_RELACIONES, "Consulta Detalle de Compras")

        ' Group: Listados y Reportes
        Dim grpRep = Invoke(groups, "AddGroup", "Listados y Reportes", ComprasCommandIds.ID_GROUP_REPCOMPRAS)
        AddControl(grpRep, xtpControlButton, ComprasCommandIds.ID_FILE_PRINT_COMPRAS, "Listados y Reportes Compras")
    End Sub

    Private Sub BuildInventarioTab(ribbon As Object)
        Dim tab = Invoke(ribbon, "InsertTab", 1, "Modulo de &Inventario")
        SetProperty(tab, "Id", ComprasCommandIds.ID_TAB_INVENTARIO)

        Dim groups = GetProperty(tab, "Groups")

        ' Group: Inventario
        Dim grpInv = Invoke(groups, "AddGroup", "Inventario", ComprasCommandIds.ID_GROUP_INVENTARIO)
        AddControl(grpInv, xtpControlButton, ComprasCommandIds.ID_FILE_INVENTARIO, "Control Inventario")
        AddControl(grpInv, xtpControlButton, ComprasCommandIds.ID_FILE_PRODUCTOS, "Movimiento Individual de Articulos")
        AddControl(grpInv, xtpControlButton, ComprasCommandIds.ID_FILE_AJUSTES, "Ajustar Inventario")
        AddControl(grpInv, xtpControlButton, ComprasCommandIds.ID_FILE_PRECIOS, "Cambiar Precios")
        AddControl(grpInv, xtpControlButton, ComprasCommandIds.ID_FILE_COMISIONES, "Tabla de Monedas")

        ' Group: Tablas de Productos
        Dim grpTablas = Invoke(groups, "AddGroup", "Tablas de Productos", ComprasCommandIds.ID_GROUP_INVENTARIO + 1)
        AddControl(grpTablas, xtpControlButton, ComprasCommandIds.ID_FILE_BUSCADOR, "Buscador de Articulos")
        AddControl(grpTablas, xtpControlButton, ComprasCommandIds.ID_FILE_LINEAS, "Lineas")
        AddControl(grpTablas, xtpControlButton, ComprasCommandIds.ID_FILE_CATEGORIAS, "Categorias")
        AddControl(grpTablas, xtpControlButton, ComprasCommandIds.ID_FILE_TIPOS, "Tipos")
        AddControl(grpTablas, xtpControlButton, ComprasCommandIds.ID_FILE_MARCAS, "Marcas")
        AddControl(grpTablas, xtpControlButton, ComprasCommandIds.ID_FILE_CLASES, "Clases")

        ' Group: Etiquetas y Reportes
        Dim grpEtiq = Invoke(groups, "AddGroup", "Etiquetas y Reportes", ComprasCommandIds.ID_GROUP_INVENTARIO + 2)
        AddControl(grpEtiq, xtpControlButton, ComprasCommandIds.ID_FILE_ETIQUETA, "Generador de Etiquetas")
        AddControl(grpEtiq, xtpControlButton, ComprasCommandIds.ID_FILE_REPINVENTARIO, "Listados y Reportes de Inventario")
    End Sub

    Private Sub BuildVentanaTab(ribbon As Object)
        Dim tab = Invoke(ribbon, "InsertTab", 2, "&Ventana")
        SetProperty(tab, "Id", ComprasCommandIds.ID_TAB_VIEW)

        Dim groups = GetProperty(tab, "Groups")

        ' Group: Show/Hide
        Dim grpShow = Invoke(groups, "AddGroup", "Show/Hide", ComprasCommandIds.ID_GROUP_SHOWHIDE)
        AddControl(grpShow, xtpControlCheckBox, ComprasCommandIds.ID_VIEW_STATUS_BAR, "Status Bar")
        AddControl(grpShow, xtpControlCheckBox, ComprasCommandIds.ID_VIEW_WORKSPACE, "Workspace")
        AddControl(grpShow, xtpControlCheckBox, ComprasCommandIds.ID_VIEW_USER, "Conectar Automatico al Abrir")

        ' Group: Window
        Dim grpWin = Invoke(groups, "AddGroup", "Window", ComprasCommandIds.ID_GROUP_WINDOW)
        AddControl(grpWin, xtpControlButton, ComprasCommandIds.ID_WINDOW_NEW, "Nueva Ventana")
        AddControl(grpWin, xtpControlButton, ComprasCommandIds.ID_WINDOW_ARRANGE, "Organizar Iconos")
    End Sub

    Private Sub BuildQuickAccess(ribbon As Object)
        Dim qa = GetProperty(ribbon, "QuickAccessControls")
        Invoke(qa, "Add", xtpControlButton, ComprasCommandIds.ID_FILE_CALCULADORA, "Calculadora", False, False)
        Invoke(qa, "Add", xtpControlButton, ComprasCommandIds.ID_FILE_AGENDA, "Agenda Telefonica", False, False)
    End Sub

    Private Sub BuildRightAlignedButtons(ribbon As Object)
        Dim controls = GetProperty(ribbon, "Controls")

        Dim btnUsuario = Invoke(controls, "Add", xtpControlButton, ComprasCommandIds.ID_APP_USUARIO, "Cambiar de Operador Activo", False, False)
        SetProperty(btnUsuario, "Flags", xtpFlagRightAlign)

        Dim btnAbout = Invoke(controls, "Add", xtpControlButton, ComprasCommandIds.ID_APP_ABOUT, "Acerca de...", False, False)
        SetProperty(btnAbout, "Flags", xtpFlagRightAlign)
    End Sub

    ' ─── Late-binding helpers ─────────────────────────────────

    Private Function AddControl(parent As Object, controlType As Integer, id As Integer, caption As String) As Object
        Try
            Return Invoke(parent, "Add", controlType, id, caption, False, False)
        Catch
            Return Nothing
        End Try
    End Function

    Private Sub SetOption(name As String, value As Object)
        Try
            Dim options = GetProperty(_ocx, "Options")
            SetProperty(options, name, value)
        Catch
        End Try
    End Sub

    Private Shared Function Invoke(target As Object, method As String, ParamArray args() As Object) As Object
        Try
            Return Interaction.CallByName(target, method, CallType.Method, args)
        Catch
            Return Nothing
        End Try
    End Function

    Private Shared Function GetProperty(target As Object, prop As String) As Object
        Try
            Return Interaction.CallByName(target, prop, CallType.Get)
        Catch
            Return Nothing
        End Try
    End Function

    Private Shared Sub SetProperty(target As Object, prop As String, value As Object)
        Try
            Interaction.CallByName(target, prop, CallType.Set, value)
        Catch
        End Try
    End Sub

End Class

