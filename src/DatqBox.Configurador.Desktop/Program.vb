Imports System
Imports System.Windows.Forms

Friend Module Program
    <STAThread>
    Friend Sub Main(args As String())
        System.Windows.Forms.Application.SetHighDpiMode(HighDpiMode.SystemAware)
        System.Windows.Forms.Application.EnableVisualStyles()
        System.Windows.Forms.Application.SetCompatibleTextRenderingDefault(False)
        System.Windows.Forms.Application.Run(New MainShellForm())
    End Sub
End Module

