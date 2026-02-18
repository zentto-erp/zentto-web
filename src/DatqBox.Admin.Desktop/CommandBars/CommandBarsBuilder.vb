Imports DatqBox.Infrastructure.Legacy

Friend Class CommandBarsBuilder
    Private Const XTPControlButton As Integer = 1
    Private Const XTPControlPopup As Integer = 2
    Private Const XTPControlCheckBox As Integer = 6
    Private Const XTPImageNormal As Integer = 0

    Private ReadOnly _commandBars As Object
    Private ReadOnly _resPath As String
    Private ReadOnly _iniPath As String

    Public Sub New(commandBars As Object, resPath As String, iniPath As String)
        _commandBars = commandBars
        _resPath = resPath
        _iniPath = iniPath
    End Sub

    Public Sub Build()
        If _commandBars Is Nothing Then Return
        If String.IsNullOrWhiteSpace(_resPath) OrElse Not IO.Directory.Exists(_resPath) Then
            Throw New IO.DirectoryNotFoundException("No existe la carpeta res para iconos: " & _resPath)
        End If
        Dim iconsProbe = TryGetProperty(_commandBars, "Icons")
        If iconsProbe Is Nothing Then
            Throw New InvalidOperationException("No se pudo acceder a CommandBars.Icons (COM).")
        End If
        LoadIcons()

        Dim ribbon = CallByName(_commandBars, "AddRibbonBar", CallType.Method, "The Ribbon")
        TrySetProperty(ribbon, "Customizable", False)

        Dim controlFile = CallByName(ribbon, "AddSystemButton", CallType.Method)
        TrySetProperty(controlFile, "IconId", AdminCommandIds.ID_SYSTEM_ICON)

        Dim fileBar = CallByName(controlFile, "CommandBar", CallType.Get)
        TryInvoke(fileBar, "SetIconSize", 32, 32)
        Dim fileControls = CallByName(fileBar, "Controls", CallType.Get)

        AddButton(fileControls, AdminCommandIds.ID_APP_CONFIGURAR, "Cambiar Configuarción al Sistema")
        AddButton(fileControls, AdminCommandIds.ID_APP_USUARIOS, "Control de Usuarios y Acceso al Sistema")

        Dim ctrl = AddButton(fileControls, AdminCommandIds.ID_APP_FORMULAS, "Formulas y Variables Globales del Sistema")
        TrySetProperty(ctrl, "BeginGroup", True)
        AddButton(fileControls, AdminCommandIds.ID_APP_CORRELATIVOS, "Cambiar Correlativos al Sistema")

        AddButton(fileControls, AdminCommandIds.ID_APP_RETENCIONES, "Tabla Tipo de Retenciones")
        ctrl = AddButton(fileControls, AdminCommandIds.ID_APP_INFORMEXML, "Generador de Informes XML")
        TrySetProperty(ctrl, "BeginGroup", True)
        AddButton(fileControls, AdminCommandIds.ID_APP_INFORMECRYSTAL, "Generador de Informes Crystal Reports")
        AddButton(fileControls, AdminCommandIds.ID_APP_MENU_REPORTES, "Generador de Menu a Reportes")

        ctrl = AddButton(fileControls, AdminCommandIds.ID_APP_LIBROS, "Exportar Datos Libro Ventas Excel")
        TrySetProperty(ctrl, "BeginGroup", True)
        ctrl = AddButton(fileControls, AdminCommandIds.ID_APP_CONTABLE, "Ajustes Inventario Contable")
        TrySetProperty(ctrl, "BeginGroup", True)
        ctrl = AddButton(fileControls, AdminCommandIds.ID_APP_EGRESOS, "Cargar Egresos por Devoluciones")
        TrySetProperty(ctrl, "BeginGroup", True)
        ctrl = AddButton(fileControls, AdminCommandIds.ID_APP_EGRESOS1, "Cargar Codigo de Productos en Detalle de Ventas")
        TrySetProperty(ctrl, "BeginGroup", True)
        ctrl = AddButton(fileControls, AdminCommandIds.ID_APP_RESPALDO, "Editor Avanzado SQL")
        TrySetProperty(ctrl, "BeginGroup", True)
        ctrl = AddButton(fileControls, AdminCommandIds.ID_APP_EXIT, "Salir del Sistema")
        TrySetProperty(ctrl, "BeginGroup", True)

        Dim controlAbout = AddRibbonButton(ribbon, AdminCommandIds.ID_APP_USUARIO, "Cambiar de Operador Activo")
        TrySetProperty(controlAbout, "Flags", 2)
        controlAbout = AddRibbonButton(ribbon, AdminCommandIds.ID_APP_ABOUT, "Acerca de...")
        TrySetProperty(controlAbout, "Flags", 2)

        Dim tabPagar = InsertTab(ribbon, 0, "Modulo Cuentas Por Pagar", AdminCommandIds.ID_TAB_PAGAR)
        Dim groupPagar = AddGroup(tabPagar, "Por Pagar", AdminCommandIds.ID_GROUP_PAGAR)
        AddGroupButton(groupPagar, 10, "Actualizar Proveedores")
        AddGroupButton(groupPagar, AdminCommandIds.ID_FILE_PAGAR, "Cuentas por Pagar")
        AddGroupButton(groupPagar, AdminCommandIds.ID_FILE_APAGAR, "Retenciones de IVA Generadas")
        AddGroupButton(groupPagar, AdminCommandIds.ID_FILE_ARTICULOS, "Retenciones IVA SENIAT")
        AddGroupButton(groupPagar, AdminCommandIds.ID_FILE_ISLR, "Retenciones ISLR SENIAT")
        AddGroupButton(groupPagar, AdminCommandIds.ID_FILE_PPRINT, "Listados y Reportes Cuentas Por Pagar")

        Dim tabCompras = InsertTab(ribbon, 1, "Modulo de Compras", AdminCommandIds.ID_TAB_COMPRAS)
        Dim groupCompras = AddGroup(tabCompras, "Compras", AdminCommandIds.ID_GROUP_COMPRAS)
        AddGroupButton(groupCompras, AdminCommandIds.ID_FILE_COMPRAS, "Compras Generales")
        AddGroupButton(groupCompras, AdminCommandIds.ID_FILE_AJUSTES, "Compras de Mercancia")
        AddGroupButton(groupCompras, AdminCommandIds.ID_FILE_Devolucion, "Devolucion de Mercancia")
        AddGroupButton(groupCompras, AdminCommandIds.ID_FILE_MERCANCIA, "Ingreso de Orden de Entrega Mercancia")
        AddGroupButton(groupCompras, AdminCommandIds.ID_FILE_RESUMEN, "Cargar Resumen Libro Compras")

        Dim groupOrdenes = AddGroup(tabCompras, "Ordenes y Gastos", AdminCommandIds.ID_GROUP_ORDENES)
        AddGroupButton(groupOrdenes, AdminCommandIds.ID_FILE_ORDENES, "Ordenes de Compras")
        AddGroupButton(groupOrdenes, AdminCommandIds.ID_FILE_GASTOS, "Gastos de Caja")
        AddGroupButton(groupOrdenes, AdminCommandIds.ID_VIEW_FULLSCREEN, "Gastos de Caja Dos")

        Dim groupRepCompras = AddGroup(tabCompras, "Listados y Reportes", AdminCommandIds.ID_GROUP_REPCOMPRAS)
        AddGroupButton(groupRepCompras, AdminCommandIds.ID_FILE_PRINT_COMPRAS, "Listados y Reportes Compras")

        Dim tabFacturacion = InsertTab(ribbon, 2, "Modulo de Ventas", AdminCommandIds.ID_TAB_VENTAS)
        Dim groupFacturas = AddGroup(tabFacturacion, "Consultas", AdminCommandIds.ID_GROUP_FACTURAS)
        AddGroupButton(groupFacturas, AdminCommandIds.ID_FILE_PTOVENTA, "Consulta de Transacciones de Ventas...")

        Dim groupFacturas1 = AddGroup(tabFacturacion, "Facturacion", AdminCommandIds.ID_GROUP_FACTURAS)
        AddGroupButton(groupFacturas1, AdminCommandIds.ID_FILE_FACTURAS_FISCAL, "Facturas Maquina Fiscal")
        AddGroupButton(groupFacturas1, AdminCommandIds.ID_FILE_FACTURAS_SERVICIO, "Facturas Empresa Servicio")

        Dim groupFacturas2 = AddGroup(tabFacturacion, "Entregas", AdminCommandIds.ID_GROUP_FACTURAS)
        AddGroupButton(groupFacturas2, AdminCommandIds.ID_EDIT_PASTE, "Ordenes de Entrega")

        Dim groupFacturas3 = AddGroup(tabFacturacion, "Notas Credito y Debito", AdminCommandIds.ID_GROUP_FACTURAS)
        AddGroupButton(groupFacturas3, AdminCommandIds.ID_FILE_CREDITO, "Notas de Credito Fiscal")
        AddGroupButton(groupFacturas3, AdminCommandIds.ID_FILE_DEBITO, "Notas de Debito Fiscal")
        AddGroupButton(groupFacturas3, AdminCommandIds.ID_FILE_PRESUPUESTOS, "Presupuestos / Cotizaciones")

        Dim groupFacturas4 = AddGroup(tabFacturacion, "Cargar", AdminCommandIds.ID_GROUP_FACTURAS)
        AddGroupButton(groupFacturas4, AdminCommandIds.ID_FILE_FACTURAS, "Anexar Facturas Serie Manual")
        AddGroupButton(groupFacturas4, AdminCommandIds.ID_VIEW_NORMAL, "Retenciones de Iva / Ventas")
        AddGroupButton(groupFacturas4, AdminCommandIds.ID_FILE_RESUMEN, "Resumen Libro Ventas")
        AddGroupButton(groupFacturas4, AdminCommandIds.ID_FILE_FACTURAS_CARGAR, "Ventas Rapidas")

        Dim groupVendedores = AddGroup(tabFacturacion, "Vendedores y Reporte Z", AdminCommandIds.ID_GROUP_FACTURAS)
        If IsVendedoresVisible() Then
            AddGroupButton(groupVendedores, AdminCommandIds.ID_FILE_VENDEDORES, "Vendedores")
            AddGroupButton(groupVendedores, AdminCommandIds.ID_FILE_COMISIONES + 500, "Comisiones")
            AddGroupButton(groupVendedores, AdminCommandIds.ID_FILE_COMISIONES + 501, "Clon Reporte Z")
            AddGroupButton(groupVendedores, AdminCommandIds.ID_FILE_COMISIONES + 502, "Clon Reporte Z Total")
        End If
        AddGroupButton(groupVendedores, AdminCommandIds.ID_FILE_ANEXARETIVA, "Reportes Z")

        Dim groupRepVentas = AddGroup(tabFacturacion, "Listados y Reportes Ventas", AdminCommandIds.ID_GROUP_FACTURAS)
        AddGroupButton(groupRepVentas, AdminCommandIds.ID_FILE_REPVENTAS, "Listados y Reportes de Ventas")

        Dim tabCobrar = InsertTab(ribbon, 3, "Modulo Cuentas Por Cobrar", AdminCommandIds.ID_TAB_COBRAR)
        Dim groupCobrar = AddGroup(tabCobrar, "Por Cobrar", AdminCommandIds.ID_GROUP_COBRAR)
        AddGroupButton(groupCobrar, AdminCommandIds.ID_FILE_CLIENTES, "Actualizar Clientes")
        AddGroupButton(groupCobrar, AdminCommandIds.ID_FILE_COBRAR, "Cuentas por Cobrar")
        AddGroupButton(groupCobrar, AdminCommandIds.ID_FILE_ACOBRAR, "Notas de Entrega por Cobrar")
        AddGroupButton(groupCobrar, AdminCommandIds.ID_PREVIEW_PREVIEW_CLOSE, "Cotizaciones por Cobrar")
        Dim groupRepCobrar = AddGroup(tabCobrar, "Listados y Reportes Cuentas por Cobrar", AdminCommandIds.ID_GROUP_REPCOBRAR)
        AddGroupButton(groupRepCobrar, AdminCommandIds.ID_FILE_REPCOBRAR, "Listados y Reportes Cuentas Por Cobrar")

        Dim tabInventario = InsertTab(ribbon, 4, "Modulo de Inventario", AdminCommandIds.ID_TAB_INVENTARIO)
        Dim groupInventario = AddGroup(tabInventario, "Inventario", AdminCommandIds.ID_GROUP_INVENTARIO)
        AddGroupButton(groupInventario, AdminCommandIds.ID_FILE_INVENTARIO, "Control Inventario")
        AddGroupButton(groupInventario, AdminCommandIds.ID_FILE_RELACIONES, "Cambiar Precios")
        AddGroupButton(groupInventario, AdminCommandIds.ID_FILE_PRODUCTOS, "Inventario Auxiliar")
        AddGroupButton(groupInventario, AdminCommandIds.ID_FILE_DEL_RELACIONES, "Traslados entre Almacenes")

        Dim groupZoom = AddGroup(tabInventario, "Tablas de Productos", AdminCommandIds.ID_GROUP_INVENTARIO)
        AddGroupButton(groupZoom, AdminCommandIds.ID_FILE_BUSCADOR, "Almacenes")
        AddGroupButton(groupZoom, AdminCommandIds.ID_FILE_LINEAS, "Lineas")
        AddGroupButton(groupZoom, AdminCommandIds.ID_FILE_CATEGORIAS, "Categorias")
        AddGroupButton(groupZoom, AdminCommandIds.ID_FILE_TIPOS, "Tipos")
        AddGroupButton(groupZoom, AdminCommandIds.ID_FILE_MARCAS, "Marcas")
        AddGroupButton(groupZoom, AdminCommandIds.ID_FILE_CLASES, "Clases")

        Dim groupEtiquetas = AddGroup(tabInventario, "Etiquetas y Reportes", AdminCommandIds.ID_GROUP_INVENTARIO)
        AddGroupButton(groupEtiquetas, AdminCommandIds.ID_FILE_ETIQUETA, "Generador de Etiquetas")
        AddGroupButton(groupEtiquetas, AdminCommandIds.ID_FILE_REPINVENTARIO, "Listados y Reportes de Inventario")

        Dim tabBancos = InsertTab(ribbon, 5, "Modulo de Bancos y Cheques", AdminCommandIds.ID_TAB_BANCOS)
        Dim groupBancos = AddGroup(tabBancos, "Bancos y Cheques", AdminCommandIds.ID_GROUP_BANCOS)
        AddGroupButton(groupBancos, AdminCommandIds.ID_FILE_REG_BANCOS, "Registro Cuentas Bancarias")
        AddGroupButton(groupBancos, AdminCommandIds.ID_FILE_BANCOS, "Movimiento Cuentas Bancarias")
        AddGroupButton(groupBancos, AdminCommandIds.ID_FILE_COMISIONES, "Tabla de Monedas")
        AddGroupButton(groupBancos, AdminCommandIds.ID_FILE_DEPOSITOS, "Registrar Deposito de Caja")
        AddGroupButton(groupBancos, AdminCommandIds.ID_FILE_TABLA_BANCOS, "Tabla Lista de Bancos")
        AddGroupButton(groupBancos, AdminCommandIds.ID_FILE_REPBANCOS, "Listados y Reportes Bancos / Cheques")

        Dim tabView = InsertTab(ribbon, 6, "&Ventana", AdminCommandIds.ID_TAB_VIEW)
        Dim groupShowHide = AddGroup(tabView, "Show/Hide", AdminCommandIds.ID_GROUP_SHOWHIDE)
        AddGroupCheckBox(groupShowHide, AdminCommandIds.ID_VIEW_STATUS_BAR, "Status Bar")
        AddGroupCheckBox(groupShowHide, AdminCommandIds.ID_VIEW_WORKSPACE, "Workspace")
        AddGroupCheckBox(groupShowHide, AdminCommandIds.ID_VIEW_USER, "Conectar Automatico al Abrir")

        Dim groupWindow = AddGroup(tabView, "Window", AdminCommandIds.ID_GROUP_WINDOW)
        AddGroupButton(groupWindow, AdminCommandIds.ID_WINDOW_NEW, "Nueva Ventana")
        AddGroupButton(groupWindow, AdminCommandIds.ID_WINDOW_ARRANGE, "Arrancar Icons")
        Dim popup = AddGroupPopup(groupWindow, AdminCommandIds.ID_WINDOW_SWITCH, "Cambiar de Ventana")
        Dim popupBar = CallByName(popup, "CommandBar", CallType.Get)
        Dim popupControls = CallByName(popupBar, "Controls", CallType.Get)
        AddButton(popupControls, 0, "Item 1")

        Dim quickAccess = CallByName(ribbon, "QuickAccessControls", CallType.Get)
        AddButton(quickAccess, AdminCommandIds.ID_FILE_CALCULADORA, "Calculadora")
        AddButton(quickAccess, AdminCommandIds.ID_FILE_AGENDA, "Agenda Telefonica")
        AddButton(quickAccess, AdminCommandIds.ID_FILE_REPDIA, "Reporte Diario de Caja")

        Dim paintManager = TryGetProperty(_commandBars, "PaintManager")
        TryInvoke(paintManager, "RefreshMetrics")
        TryInvoke(ribbon, "RecalcLayout")
        TryInvoke(_commandBars, "RecalcLayout")
    End Sub

    Private Sub LoadIcons()
        Dim options = TryGetProperty(_commandBars, "Options")
        If options IsNot Nothing Then
            TrySetProperty(options, "UseSharedImageList", False)
            TrySetProperty(options, "UseFadedIcons", False)
            TrySetProperty(options, "IconsWithShadow", False)
        End If

        Dim icons = TryGetProperty(_commandBars, "Icons")
        If icons Is Nothing Then Return
        TrySetProperty(icons, "UseLargeIcons", True)

        LoadBitmap(icons, "GroupClipboard.png", New Integer() {
            AdminCommandIds.ID_EDIT_PASTE, AdminCommandIds.ID_EDIT_CUT, AdminCommandIds.ID_EDIT_COPY, AdminCommandIds.ID_FORMAT_PAINTER})
        LoadBitmap(icons, "GroupFind.png", New Integer() {
            AdminCommandIds.ID_EDIT_FIND, AdminCommandIds.ID_EDIT_REPLACE, AdminCommandIds.ID_EDIT_GOTO, AdminCommandIds.ID_EDIT_SELECT})
        LoadBitmap(icons, "SmallIcons.png", New Integer() {
            AdminCommandIds.ID_FILE_NEW, AdminCommandIds.ID_FILE_OPEN, AdminCommandIds.ID_FILE_SAVE, AdminCommandIds.ID_EDIT_CUT,
            AdminCommandIds.ID_EDIT_COPY, AdminCommandIds.ID_EDIT_PASTE, AdminCommandIds.ID_EDIT_UNDO, AdminCommandIds.ID_EDIT_REDO,
            AdminCommandIds.ID_FILE_PRINT, AdminCommandIds.ID_APP_ABOUT})
        LoadBitmap(icons, "SmallIcons1.png", New Integer() {
            AdminCommandIds.ID_FILE_CALCULADORA, AdminCommandIds.ID_FILE_AGENDA, AdminCommandIds.ID_FILE_REPDIA, AdminCommandIds.ID_APP_USUARIO})
        LoadBitmap(icons, "LargeIcons.png", New Integer() {
            AdminCommandIds.ID_FILE_NEW, AdminCommandIds.ID_FILE_OPEN, AdminCommandIds.ID_FILE_SAVE, AdminCommandIds.ID_EDIT_PASTE,
            AdminCommandIds.ID_EDIT_FIND, AdminCommandIds.ID_FILE_PRINT, AdminCommandIds.ID_FILE_CLOSE, AdminCommandIds.ID_VIEW_NORMAL,
            AdminCommandIds.ID_FILE_PRINT_PREVIEW, AdminCommandIds.ID_VIEW_FULLSCREEN, AdminCommandIds.ID_WINDOW_NEW,
            AdminCommandIds.ID_WINDOW_ARRANGE, AdminCommandIds.ID_WINDOW_SWITCH})
        LoadBitmap(icons, "ProveeCompras.png", New Integer() {
            AdminCommandIds.ID_FILE_CLIENTES, AdminCommandIds.ID_FILE_COBRAR, AdminCommandIds.ID_FILE_COMPRAS, AdminCommandIds.ID_FILE_MERCANCIA,
            AdminCommandIds.ID_FILE_PPRINT, AdminCommandIds.ID_APP_USUARIOS, AdminCommandIds.ID_APP_CONFIGURAR, AdminCommandIds.ID_APP_CORRELATIVOS,
            AdminCommandIds.ID_FILE_INVENTARIO, AdminCommandIds.ID_FILE_Devolucion, AdminCommandIds.ID_APP_FORMULAS, AdminCommandIds.ID_FILE_APAGAR,
            AdminCommandIds.ID_FILE_Devolucion})
        LoadBitmap(icons, "Menu2.png", New Integer() {
            AdminCommandIds.ID_FILE_CLIENTES, AdminCommandIds.ID_FILE_COBRAR, AdminCommandIds.ID_FILE_COMPRAS, AdminCommandIds.ID_FILE_MERCANCIA,
            AdminCommandIds.ID_FILE_PPRINT, AdminCommandIds.ID_APP_USUARIOS, AdminCommandIds.ID_APP_CONFIGURAR, AdminCommandIds.ID_APP_CORRELATIVOS,
            AdminCommandIds.ID_FILE_GASTOS, AdminCommandIds.ID_FILE_INVENTARIO, AdminCommandIds.ID_FILE_AJUSTES,
            AdminCommandIds.ID_FILE_APAGAR, AdminCommandIds.ID_FILE_ORDENES})
        LoadBitmap(icons, "ClienteInvent.png", New Integer() {
            AdminCommandIds.ID_FILE_PROVEEDORES, AdminCommandIds.ID_FILE_PAGAR, AdminCommandIds.ID_FILE_COMPRAS, AdminCommandIds.ID_FILE_MERCANCIA,
            AdminCommandIds.ID_FILE_PPRINT, AdminCommandIds.ID_APP_USUARIOS, AdminCommandIds.ID_APP_CONFIGURAR, AdminCommandIds.ID_APP_CORRELATIVOS,
            AdminCommandIds.ID_FILE_GASTOS, AdminCommandIds.ID_FILE_REG_BANCOS, AdminCommandIds.ID_APP_FORMULAS, AdminCommandIds.ID_FILE_APAGAR,
            AdminCommandIds.ID_FILE_ORDENES, AdminCommandIds.ID_APP_EXIT})
        LoadBitmap(icons, "tablasinvent.png", New Integer() {
            AdminCommandIds.ID_FILE_TABLA_BANCOS, AdminCommandIds.ID_FILE_CATEGORIAS, AdminCommandIds.ID_FILE_TIPOS, AdminCommandIds.ID_FILE_MARCAS,
            AdminCommandIds.ID_FILE_CLASES, AdminCommandIds.ID_FILE_RESUMEN, AdminCommandIds.ID_FILE_DEPOSITOS})
        LoadBitmap(icons, "Menu1.png", New Integer() {
            AdminCommandIds.ID_APP_INFORMECRYSTAL, AdminCommandIds.ID_APP_INFORMEXML, AdminCommandIds.ID_FILE_REPINVENTARIO,
            AdminCommandIds.ID_APP_RETENCIONES, AdminCommandIds.ID_FILE_REPCOBRAR, AdminCommandIds.ID_FILE_BANCOS, AdminCommandIds.ID_FILE_ETIQUETA,
            AdminCommandIds.ID_FILE_ACOBRAR, AdminCommandIds.ID_FILE_RELACIONES, AdminCommandIds.ID_FILE_DEL_RELACIONES,
            AdminCommandIds.ID_FILE_COBRAR, AdminCommandIds.ID_FILE_CLIENTES, AdminCommandIds.ID_FILE_ANEXARETIVA, AdminCommandIds.ID_FILE_BUSCADOR,
            AdminCommandIds.ID_APP_MENU_REPORTES, AdminCommandIds.ID_FILE_REPVENTAS, AdminCommandIds.ID_FILE_PRINT_COMPRAS})
        LoadBitmap(icons, "Menu.png", New Integer() {
            AdminCommandIds.ID_APP_INFORMECRYSTAL, AdminCommandIds.ID_APP_INFORMEXML, AdminCommandIds.ID_FILE_REPBANCOS,
            AdminCommandIds.ID_APP_RETENCIONES, AdminCommandIds.ID_FILE_REPCOBRAR, AdminCommandIds.ID_FILE_BANCOS, AdminCommandIds.ID_FILE_ETIQUETA,
            AdminCommandIds.ID_FILE_ACOBRAR, AdminCommandIds.ID_FILE_RELACIONES, AdminCommandIds.ID_FILE_DEL_RELACIONES,
            AdminCommandIds.ID_FILE_COBRAR, AdminCommandIds.ID_FILE_CLIENTES, AdminCommandIds.ID_FILE_ANEXARETIVA, AdminCommandIds.ID_FILE_BUSCADOR,
            AdminCommandIds.ID_APP_MENU_REPORTES, AdminCommandIds.ID_FILE_REPVENTAS, AdminCommandIds.ID_FILE_PRINT_COMPRAS})
        LoadBitmap(icons, "NOTAS.png", New Integer() {
            AdminCommandIds.ID_FILE_FACTURAS, AdminCommandIds.ID_FILE_PTOVENTA, AdminCommandIds.ID_FILE_FACTURAS_SERVICIO,
            AdminCommandIds.ID_FILE_CREDITO, AdminCommandIds.ID_FILE_DEBITO, AdminCommandIds.ID_FILE_VENDEDORES, AdminCommandIds.ID_FILE_COMISIONES})
        LoadBitmap(icons, "ClienteInvent.png", New Integer() {
            AdminCommandIds.ID_FILE_PROVEEDORES, AdminCommandIds.ID_FILE_PAGAR, AdminCommandIds.ID_FILE_COMPRAS, AdminCommandIds.ID_FILE_MERCANCIA,
            AdminCommandIds.ID_FILE_PPRINT, AdminCommandIds.ID_APP_USUARIOS, AdminCommandIds.ID_APP_CONFIGURAR, AdminCommandIds.ID_APP_CORRELATIVOS,
            AdminCommandIds.ID_FILE_FACTURAS, AdminCommandIds.ID_FILE_REG_BANCOS, AdminCommandIds.ID_APP_FORMULAS, AdminCommandIds.ID_FILE_APAGAR,
            AdminCommandIds.ID_FILE_ORDENES, AdminCommandIds.ID_APP_EXIT})
        LoadBitmap(icons, "shiny-gear.png", New Integer() {AdminCommandIds.ID_SYSTEM_ICON})
        LoadIcon(icons, "GroupPopup.ico", AdminCommandIds.ID_GROUP_POPUPICON)
        LoadBitmap(icons, "PrintPreview.png", New Integer() {
            AdminCommandIds.ID_PREVIEW_PRINT_PRINT, AdminCommandIds.ID_PREVIEW_PRINT_OPTIONS, AdminCommandIds.ID_PREVIEW_PAGESETUP_MARGINS,
            AdminCommandIds.ID_PREVIEW_PAGESETUP_ORIENTATION, AdminCommandIds.ID_PREVIEW_PAGESETUP_SIZE, AdminCommandIds.ID_PREVIEW_ZOOM_ZOOM,
            AdminCommandIds.ID_PREVIEW_ZOOM_100_PERCENT, AdminCommandIds.ID_PREVIEW_ZOOM_1PAGE, AdminCommandIds.ID_PREVIEW_ZOOM_2PAGES,
            AdminCommandIds.ID_PREVIEW_ZOOM_PAGE_WIDTH, AdminCommandIds.ID_PREVIEW_PREVIEW_SHRINK, AdminCommandIds.ID_PREVIEW_PREVIEW_NEXT,
            AdminCommandIds.ID_PREVIEW_PREVIEW_PREVIOUS})
        LoadBitmap(icons, "PrintPreviewSmall.png", New Integer() {
            AdminCommandIds.ID_PREVIEW_ZOOM_1PAGE, AdminCommandIds.ID_PREVIEW_ZOOM_2PAGES, AdminCommandIds.ID_PREVIEW_ZOOM_PAGE_WIDTH,
            AdminCommandIds.ID_PREVIEW_PREVIEW_SHRINK, AdminCommandIds.ID_PREVIEW_PREVIEW_NEXT, AdminCommandIds.ID_PREVIEW_PREVIEW_PREVIOUS})
    End Sub

    Private Function IsVendedoresVisible() As Boolean
        Try
            If String.IsNullOrWhiteSpace(_iniPath) OrElse Not IO.File.Exists(_iniPath) Then Return True
            Dim ini = LegacyIniFile.Load(_iniPath)
            Dim raw = ini.GetRaw("EMAIL", "VISIBLE", "")
            If String.IsNullOrWhiteSpace(raw) Then Return True
            Dim dec = LegacyCrypto.Decrypt(raw)
            Return dec = "-1"
        Catch
            Return True
        End Try
    End Function

    Private Sub LoadBitmap(icons As Object, fileName As String, ids As Integer())
        Dim path = IO.Path.Combine(_resPath, fileName)
        If Not IO.File.Exists(path) Then Throw New IO.FileNotFoundException("Falta icono: " & path)
        Dim objIds = ToObjectArray(ids)
        TryInvoke(icons, "LoadBitmap", path, objIds, XTPImageNormal)
    End Sub

    Private Sub LoadIcon(icons As Object, fileName As String, id As Integer)
        Dim path = IO.Path.Combine(_resPath, fileName)
        If Not IO.File.Exists(path) Then Throw New IO.FileNotFoundException("Falta icono: " & path)
        TryInvoke(icons, "LoadIcon", path, id, XTPImageNormal)
    End Sub

    Private Function ToObjectArray(ids As Integer()) As Object()
        If ids Is Nothing Then Return Array.Empty(Of Object)()
        Dim result(ids.Length - 1) As Object
        For i As Integer = 0 To ids.Length - 1
            result(i) = ids(i)
        Next
        Return result
    End Function

    Private Function InsertTab(ribbon As Object, index As Integer, caption As String, id As Integer) As Object
        Dim tab = TryInvoke(ribbon, "InsertTab", index, caption)
        TrySetProperty(tab, "ID", id)
        Return tab
    End Function

    Private Function AddGroup(tab As Object, caption As String, id As Integer) As Object
        Dim groups = TryGetProperty(tab, "Groups")
        If groups Is Nothing Then Return Nothing
        Return TryInvoke(groups, "AddGroup", caption, id)
    End Function

    Private Function AddGroupButton(group As Object, id As Integer, caption As String) As Object
        If group Is Nothing Then Return Nothing
        Return TryInvoke(group, "Add", XTPControlButton, id, caption, False, False)
    End Function

    Private Function AddGroupCheckBox(group As Object, id As Integer, caption As String) As Object
        If group Is Nothing Then Return Nothing
        Return TryInvoke(group, "Add", XTPControlCheckBox, id, caption, False, False)
    End Function

    Private Function AddGroupPopup(group As Object, id As Integer, caption As String) As Object
        If group Is Nothing Then Return Nothing
        Return TryInvoke(group, "Add", XTPControlPopup, id, caption, False, False)
    End Function

    Private Function AddButton(controls As Object, id As Integer, caption As String) As Object
        If controls Is Nothing Then Return Nothing
        Return TryInvoke(controls, "Add", XTPControlButton, id, caption, False, False)
    End Function

    Private Function AddRibbonButton(ribbon As Object, id As Integer, caption As String) As Object
        Dim controls = TryGetProperty(ribbon, "Controls")
        Return AddButton(controls, id, caption)
    End Function

    Private Function TryInvoke(target As Object, methodName As String, ParamArray args() As Object) As Object
        Try
            Return Microsoft.VisualBasic.Interaction.CallByName(target, methodName, CallType.Method, args)
        Catch
            Return Nothing
        End Try
    End Function

    Private Function TryGetProperty(target As Object, propertyName As String) As Object
        Try
            Return Microsoft.VisualBasic.Interaction.CallByName(target, propertyName, CallType.Get)
        Catch
            Return Nothing
        End Try
    End Function

    Private Sub TrySetProperty(target As Object, propertyName As String, value As Object)
        Try
            Microsoft.VisualBasic.Interaction.CallByName(target, propertyName, CallType.Set, value)
        Catch
            ' Ignore property set errors.
        End Try
    End Sub
End Class
