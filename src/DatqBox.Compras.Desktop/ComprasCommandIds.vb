''' <summary>
''' IDs de comandos del ribbon de Compras, portados desde Definitions.bas de VB6.
''' Cada constante mapea 1:1 con el ID original del menú VB6.
''' </summary>
Friend Module ComprasCommandIds

    ' ── Tabs ──────────────────────────────────────────────
    Friend Const ID_TAB_COMPRAS As Integer = 701
    Friend Const ID_TAB_INVENTARIO As Integer = 703
    Friend Const ID_TAB_VIEW As Integer = 132

    ' ── Groups ────────────────────────────────────────────
    Friend Const ID_GROUP_COMPRAS As Integer = 500
    Friend Const ID_GROUP_REPCOMPRAS As Integer = 506
    Friend Const ID_GROUP_INVENTARIO As Integer = 508
    Friend Const ID_GROUP_SHOWHIDE As Integer = 135
    Friend Const ID_GROUP_WINDOW As Integer = 136

    ' ── Compras ───────────────────────────────────────────
    Friend Const ID_FILE_COMPRAS As Integer = 30
    Friend Const ID_FILE_MERCANCIA As Integer = 40
    Friend Const ID_FILE_ORDENES As Integer = 110
    Friend Const ID_FILE_GASTOS As Integer = 90
    Friend Const ID_FILE_RELACIONES As Integer = 211
    Friend Const ID_FILE_PRINT_COMPRAS As Integer = 237

    ' ── Inventario ────────────────────────────────────────
    Friend Const ID_FILE_INVENTARIO As Integer = 95
    Friend Const ID_FILE_PRODUCTOS As Integer = 226
    Friend Const ID_FILE_AJUSTES As Integer = 227
    Friend Const ID_FILE_PRECIOS As Integer = 228
    Friend Const ID_FILE_COMISIONES As Integer = 236
    Friend Const ID_FILE_BUSCADOR As Integer = 223
    Friend Const ID_FILE_LINEAS As Integer = 213
    Friend Const ID_FILE_CATEGORIAS As Integer = 215
    Friend Const ID_FILE_TIPOS As Integer = 214
    Friend Const ID_FILE_MARCAS As Integer = 216
    Friend Const ID_FILE_CLASES As Integer = 217
    Friend Const ID_FILE_ETIQUETA As Integer = 225
    Friend Const ID_FILE_REPINVENTARIO As Integer = 224

    ' ── Sistema / Admin ───────────────────────────────────
    Friend Const ID_APP_CONFIGURAR As Integer = 70
    Friend Const ID_APP_USUARIO As Integer = 630
    Friend Const ID_APP_USUARIOS As Integer = 631
    Friend Const ID_APP_ABOUT As Integer = 4000
    Friend Const ID_APP_EXIT As Integer = 576651
    Friend Const ID_APP_CORRELATIVOS As Integer = 80
    Friend Const ID_APP_FORMULAS As Integer = 100
    Friend Const ID_APP_RETENCIONES As Integer = 81
    Friend Const ID_APP_INFORMECRYSTAL As Integer = 82
    Friend Const ID_APP_INFORMEXML As Integer = 83

    ' ── Herramientas ──────────────────────────────────────
    Friend Const ID_FILE_CALCULADORA As Integer = 600
    Friend Const ID_FILE_AGENDA As Integer = 610
    Friend Const ID_FILE_RESPALDO As Integer = 576652

    ' ── Ventana ───────────────────────────────────────────
    Friend Const ID_WINDOW_NEW As Integer = 57648
    Friend Const ID_WINDOW_ARRANGE As Integer = 57649
    Friend Const ID_WINDOW_SWITCH As Integer = 143

    ' ── View ──────────────────────────────────────────────
    Friend Const ID_VIEW_STATUS_BAR As Integer = 2808
    Friend Const ID_VIEW_WORKSPACE As Integer = 59394
    Friend Const ID_VIEW_USER As Integer = 59395

    ' ── System icon ───────────────────────────────────────
    Friend Const ID_SYSTEM_ICON As Integer = 1200

End Module

