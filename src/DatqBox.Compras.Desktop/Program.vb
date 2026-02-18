Imports System
Imports System.Windows.Forms

Friend Module Program
    <STAThread>
    Friend Sub Main(args As String())
        System.Text.Encoding.RegisterProvider(System.Text.CodePagesEncodingProvider.Instance)
        System.Windows.Forms.Application.SetHighDpiMode(HighDpiMode.PerMonitorV2)
        System.Windows.Forms.Application.EnableVisualStyles()
        System.Windows.Forms.Application.SetCompatibleTextRenderingDefault(False)
        System.Windows.Forms.Application.Run(New MainShellForm())
    End Sub
End Module

