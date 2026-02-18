Public Interface IAddonModule
    ReadOnly Property Id As String
    ReadOnly Property Name As String
    Sub Initialize(context As IAddonContext)
End Interface
