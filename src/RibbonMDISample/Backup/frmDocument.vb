Imports Microsoft.VisualBasic
Imports System
Imports System.Drawing
Imports System.Collections
Imports System.ComponentModel
Imports System.Windows.Forms

Namespace RibbonMDISample
	''' <summary>
	''' Summary description for frmDocument.
	''' </summary>
	Public Class frmDocument : Inherits System.Windows.Forms.Form
		Private richTextBox1 As System.Windows.Forms.RichTextBox
		''' <summary>
		''' Required designer variable.
		''' </summary>
		Private components As System.ComponentModel.Container = Nothing

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
			Me.richTextBox1 = New System.Windows.Forms.RichTextBox()
			Me.SuspendLayout()
			' 
			' richTextBox1
			' 
			Me.richTextBox1.Dock = System.Windows.Forms.DockStyle.Fill
			Me.richTextBox1.Name = "richTextBox1"
			Me.richTextBox1.Size = New System.Drawing.Size(292, 266)
			Me.richTextBox1.TabIndex = 0
			Me.richTextBox1.Text = ""
			' 
			' frmDocument
			' 
			Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
			Me.ClientSize = New System.Drawing.Size(292, 266)
			Me.Controls.AddRange(New System.Windows.Forms.Control() { Me.richTextBox1})
			Me.Name = "frmDocument"
			Me.Text = "frmDocument"
'			Me.Load += New System.EventHandler(Me.frmDocument_Load);
			Me.ResumeLayout(False)

		End Sub
		#End Region

		Private Sub frmDocument_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles MyBase.Load

		End Sub

	End Class
End Namespace
