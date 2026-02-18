Imports Microsoft.VisualBasic
Imports System
Imports System.Drawing
Imports System.Collections
Imports System.ComponentModel
Imports System.Windows.Forms

Namespace RibbonMDISample
	''' <summary>
	''' Summary description for frmPrintPreviw.
	''' </summary
	Public Class frmPrintPreviw : Inherits System.Windows.Forms.Form
		''' <summary>
		''' Required designer variable.
		''' </summary>
		Private components As System.ComponentModel.Container = Nothing

		Public lstDocumentName As String = ""
		Public lstDocumentBody As String = ""

		Public Sub New()
			'
			' Required for Windows Form Designer support
			'
			InitializeComponent()

			'
			' TODO: Add any constructor code after InitializeComponent call
			'
		End Sub

		''' <summary>
		''' Clean up any resources being used.
		''' </summary>
		Protected Overrides Overloads Sub Dispose(ByVal disposing As Boolean)
			If disposing Then
				If Not components Is Nothing Then
					components.Dispose()
				End If
			End If
			MyBase.Dispose(disposing)
		End Sub


		#Region "Windows Form Designer generated code"
		''' <summary>
		''' Required method for Designer support - do not modify
		''' the contents of this method with the code editor.
		''' </summary>
		Private Sub InitializeComponent()
			' 
			' frmPrintPreviw
			' 
			Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
			Me.ClientSize = New System.Drawing.Size(292, 266)
			Me.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None
			Me.Name = "frmPrintPreviw"
			Me.Text = "frmPrintPreviw"
			Me.WindowState = System.Windows.Forms.FormWindowState.Maximized
'			Me.Load += New System.EventHandler(Me.frmPrintPreviw_Load);

		End Sub
		#End Region

		Friend PrintPreviewControl1 As PrintPreviewControl
		Private docToPrint As System.Drawing.Printing.PrintDocument = New System.Drawing.Printing.PrintDocument()

		Private Sub InitializePrintPreviewControl()
			' Construct the PrintPreviewControl.
			Me.PrintPreviewControl1 = New PrintPreviewControl()

			' Set location, name, and dock style for PrintPreviewControl1.
			Me.PrintPreviewControl1.Location = New Point(88, 80)
			Me.PrintPreviewControl1.Name = "PrintPreviewControl1"
			Me.PrintPreviewControl1.Dock = DockStyle.Fill

			' Set the Document property to the PrintDocument 
			' for which the PrintPage event has been handled.
			Me.PrintPreviewControl1.Document = docToPrint

			' Set the zoom to 25 percent.
			Me.PrintPreviewControl1.Zoom = 0.55

			' Set the document name. This will show be displayed when 
			' the document is loading into the control.
			Me.PrintPreviewControl1.Document.DocumentName = lstDocumentName

			' Set the UseAntiAlias property to true so fonts are smoothed
			' by the operating system.
			Me.PrintPreviewControl1.UseAntiAlias = True

			'this.PrintPreviewControl1.AutoZoom = true;

			' Add the control to the form.
			Me.Controls.Add(Me.PrintPreviewControl1)

			' Associate the event-handling method with the
			' document's PrintPage event.
			AddHandler docToPrint.PrintPage, AddressOf docToPrint_PrintPage
		End Sub

		' The PrintPreviewControl will display the document
		' by handling the documents PrintPage event
		Private Sub docToPrint_PrintPage(ByVal sender As Object, ByVal e As System.Drawing.Printing.PrintPageEventArgs)

			' Insert code to render the page here.
			' This code will be called when the control is drawn.

			' The following code will render a simple
			' message on the document in the control.
			Dim text As String = lstDocumentBody
			Dim printFont As System.Drawing.Font = New Font("Arial", 10, FontStyle.Regular)

			e.Graphics.DrawString(text, printFont, Brushes.Black, 10, 10)
		End Sub

		Private Sub frmPrintPreviw_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles MyBase.Load
			InitializePrintPreviewControl()
		End Sub
	End Class
End Namespace
