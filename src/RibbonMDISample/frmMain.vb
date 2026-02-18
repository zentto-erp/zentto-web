Imports Microsoft.VisualBasic
Imports System
Imports System.Collections
Imports System.Data
Imports System.Drawing
Imports System.Diagnostics
Imports System.Windows.Forms

Namespace RibbonMDISample
	Friend Class frmMain : Inherits System.Windows.Forms.Form
        Public CommandBarsGlobalSettings As XtremeCommandBars.CommandBarsGlobalSettings
        Public ControlFile As XtremeCommandBars.CommandBarPopup

	#Region "Windows Form Designer generated code "
		Public Sub New()
			MyBase.New()
			'This call is required by the Windows Form Designer.
			InitializeComponent()
		End Sub
		'Form overrides dispose to clean up the component list.
		Protected Overrides Overloads Sub Dispose(ByVal Disposing As Boolean)
			If Disposing Then
				If Not components Is Nothing Then
					components.Dispose()
				End If
			End If
			MyBase.Dispose(Disposing)
		End Sub
		'Required by the Windows Form Designer
		Private components As System.ComponentModel.IContainer
		Public ToolTip1 As System.Windows.Forms.ToolTip
		Private ImageManagerGalleryStyles As AxXtremeCommandBars.AxImageManager
		Public WithEvents CommandBars As AxXtremeCommandBars.AxCommandBars
		'NOTE: The following procedure is required by the Windows Form Designer
		'It can be modified using the Windows Form Designer.
		'Do not modify it using the code editor.
		<System.Diagnostics.DebuggerStepThrough()> _
		Private Sub InitializeComponent()
			Me.components = New System.ComponentModel.Container()
			Dim resources As System.Resources.ResourceManager = New System.Resources.ResourceManager(GetType(frmMain))
			Me.ToolTip1 = New System.Windows.Forms.ToolTip(Me.components)
			Me.CommandBars = New AxXtremeCommandBars.AxCommandBars()
			Me.ImageManagerGalleryStyles = New AxXtremeCommandBars.AxImageManager()
			CType(Me.CommandBars, System.ComponentModel.ISupportInitialize).BeginInit()
			CType(Me.ImageManagerGalleryStyles, System.ComponentModel.ISupportInitialize).BeginInit()
			Me.SuspendLayout()
			' 
			' CommandBars
			' 
			Me.CommandBars.Enabled = True
			Me.CommandBars.Location = New System.Drawing.Point(16, 8)
			Me.CommandBars.Name = "CommandBars"
			Me.CommandBars.OcxState = (CType(resources.GetObject("CommandBars.OcxState"), System.Windows.Forms.AxHost.State))
			Me.CommandBars.Size = New System.Drawing.Size(24, 24)
			Me.CommandBars.TabIndex = 1
			' 
			' ImageManagerGalleryStyles
			' 
			Me.ImageManagerGalleryStyles.Enabled = True
			Me.ImageManagerGalleryStyles.Location = New System.Drawing.Point(64, 8)
			Me.ImageManagerGalleryStyles.Name = "ImageManagerGalleryStyles"
			Me.ImageManagerGalleryStyles.OcxState = (CType(resources.GetObject("ImageManagerGalleryStyles.OcxState"), System.Windows.Forms.AxHost.State))
			Me.ImageManagerGalleryStyles.Size = New System.Drawing.Size(24, 24)
			Me.ImageManagerGalleryStyles.TabIndex = 3
			' 
			' frmMain
			' 
			Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
			Me.ClientSize = New System.Drawing.Size(960, 551)
			Me.Controls.AddRange(New System.Windows.Forms.Control() { Me.ImageManagerGalleryStyles, Me.CommandBars})
			Me.Font = New System.Drawing.Font("Arial", 8F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, (CByte(0)))
			Me.IsMdiContainer = True
			Me.Location = New System.Drawing.Point(4, 23)
			Me.Name = "frmMain"
			Me.Text = "Ribbon MDI Sample"
			CType(Me.CommandBars, System.ComponentModel.ISupportInitialize).EndInit()
			CType(Me.ImageManagerGalleryStyles, System.ComponentModel.ISupportInitialize).EndInit()
			Me.ResumeLayout(False)

		End Sub
	#End Region

		<STAThread> _
		Shared Sub Main()
			Application.Run(New frmMain())
		End Sub

		Private Function RibbonBar() As XtremeCommandBars.RibbonBar
			Return CType(CommandBars.ActiveMenuBar, XtremeCommandBars.RibbonBar)
		End Function

		Private Sub CommandBars_Customization(ByVal eventSender As Object, ByVal eventArgs As AxXtremeCommandBars._DCommandBarsEvents_CustomizationEvent) Handles CommandBars.Customization
			eventArgs.options.ShowRibbonQuickAccessPage = True

			Dim cmbControls As XtremeCommandBars.CommandBarControls = Nothing
			cmbControls = CommandBars.DesignerControls
			Dim cmbControl As XtremeCommandBars.CommandBarControl = Nothing

			If cmbControls.Count = 0 Then
				Dim tempCaption1 As String = "&New"
				Dim tempBeginGroup2 As Boolean = False
				Dim tempDescriptionText3 As String = "Create a new document"
				Dim tempCategory4 As String = "File"
				cmbControl = cmbControls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_NEW, tempCaption1, tempBeginGroup2, tempDescriptionText3)
				cmbControl.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonAutomatic
				cmbControl.Category = tempCategory4

				Dim tempCaption5 As String = "&Open"
				Dim tempBeginGroup6 As Boolean = False
				Dim tempDescriptionText7 As String = "Open an existing document"
				cmbControl = cmbControls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_OPEN, tempCaption5, tempBeginGroup6, tempDescriptionText7)
				cmbControl.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonAutomatic
				cmbControl.Category = tempCategory4

				Dim tempCaption9 As String = "&Save"
				Dim tempBeginGroup10 As Boolean = False
				Dim tempDescriptionText11 As String = "Save the active document"
				cmbControl = cmbControls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_SAVE, tempCaption9, tempBeginGroup10, tempDescriptionText11)
				cmbControl.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonAutomatic
				cmbControl.Category = tempCategory4

				Dim tempCaption13 As String = "&Print"
				Dim tempBeginGroup14 As Boolean = False
				Dim tempDescriptionText15 As String = "Print the active document"
				cmbControl = cmbControls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_PRINT, tempCaption13, tempBeginGroup14, tempDescriptionText15)
				cmbControl.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonAutomatic
				cmbControl.Category = tempCategory4

				Dim tempCaption17 As String = "Print Set&up"
				Dim tempBeginGroup18 As Boolean = False
				Dim tempDescriptionText19 As String = "Print Setup"
				cmbControl = cmbControls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_PRINT_SETUP, tempCaption17, tempBeginGroup18, tempDescriptionText19)
				cmbControl.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonAutomatic
				cmbControl.Category = tempCategory4

				Dim tempCategory24 As String = "Edit"
				Dim tempCaption29 As String = "&Paste"
				Dim tempBeginGroup30 As Boolean = False
				Dim tempDescriptionText31 As String = "Insert Clipboard contents"
				cmbControl = cmbControls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_EDIT_PASTE, tempCaption29, tempBeginGroup30, tempDescriptionText31)
				cmbControl.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonAutomatic
				cmbControl.Category = tempCategory24

				Dim tempCaption57 As String = "About"
				Dim tempBeginGroup58 As Boolean = False
				Dim tempDescriptionText59 As String = ""
				Dim tempCategory60 As String = "Help"
				cmbControl = cmbControls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_APP_ABOUT, tempCaption57, tempBeginGroup58, tempDescriptionText59)
				cmbControl.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonAutomatic
				cmbControl.Category = tempCategory60
			End If
		End Sub

		Private Sub CommandBars_Execute(ByVal eventSender As Object, ByVal eventArgs As AxXtremeCommandBars._DCommandBarsEvents_ExecuteEvent) Handles CommandBars.Execute
			Select Case eventArgs.control.Id
				Case CInt(XtremeCommandBars.XTPCommandBarsSpecialCommands.XTP_ID_RIBBONCUSTOMIZE)
					CommandBars.ShowCustomizeDialog(3)
				Case ID.ID_APP_ABOUT
					CommandBars.ShowAboutBox()
				Case ID.ID_FILE_NEW
					LoadNewDoc("")
				Case ID.ID_APP_EXIT
					Me.Close()
				Case CInt(XtremeCommandBars.XTPCommandBarsSpecialCommands.XTP_ID_RIBBONCONTROLTAB)
					System.Diagnostics.Debug.WriteLine("Selected Tab has Changed")
				Case ID.ID_FILE_PRINT_PREVIEW
					LoadPrintPreview()
				Case ID.ID_VIEW_STATUS_BAR
					CommandBars.StatusBar.Visible = Not CommandBars.StatusBar.Visible
					CommandBars.RecalcLayout()
				Case ID.ID_VIEW_WORKSPACE
					eventArgs.control.Checked = Not eventArgs.control.Checked
					CommandBars.ShowTabWorkspace(eventArgs.control.Checked)
				Case ID.ID_WINDOW_ARRANGE
					Me.LayoutMdi(MdiLayout.ArrangeIcons)
				Case ID.ID_WINDOW_NEW
					LoadNewDoc("")
				Case ID.ID_PREVIEW_PREVIEW_CLOSE
					RibbonBar().FindTab(ID.ID_TAB_PRINT_PREVIEW).Visible = False
					RibbonBar().FindTab(ID.ID_TAB_HOME).Visible = True
					RibbonBar().FindTab(ID.ID_TAB_EDIT).Visible = True
					RibbonBar().FindTab(ID.ID_TAB_VIEW).Visible = True
                    Me.ActiveMdiChild.Close()                    
					If RibbonBar().FindControl(XtremeCommandBars.XTPControlType.xtpControlCheckBox, ID.ID_VIEW_WORKSPACE, False,True).Checked Then
                        CommandBars.ShowTabWorkspace(True)
                    Else
                        Me.ActiveMdiChild.WindowState = FormWindowState.Normal
                    End If
                    RibbonBar().FindTab(ID.ID_TAB_HOME).Selected = True
				Case ID.ID_PREVIEW_PRINT_PRINT, ID.ID_FILE_PRINT
					' create and show...
					Dim printDialog1 As PrintDialog = New PrintDialog()
					printDialog1.AllowSomePages = True

					' Show the help button.
					printDialog1.ShowHelp = True

					Dim docToPrint As System.Drawing.Printing.PrintDocument = New System.Drawing.Printing.PrintDocument()

					printDialog1.Document = docToPrint

                    If printDialog1.ShowDialog(CommandBars) = System.Windows.Forms.DialogResult.OK Then

                    End If

				Case ID.ID_FILE_CLOSE
					Me.ActiveMdiChild.Close()
				Case ID.ID_FILE_SAVE, ID.ID_FILE_SAVE_AS
					Dim SaveDialog As SaveFileDialog = New SaveFileDialog()
					SaveDialog.ShowDialog(CommandBars)
				Case ID.ID_FILE_OPEN
					Dim openFileDialog1 As OpenFileDialog = New OpenFileDialog()

					openFileDialog1.InitialDirectory = "c:\"
					openFileDialog1.Filter = "txt files (*.txt)|*.txt|All files (*.*)|*.*"
					openFileDialog1.FilterIndex = 2
					openFileDialog1.RestoreDirectory = True

                    If openFileDialog1.ShowDialog(CommandBars) = System.Windows.Forms.DialogResult.OK Then
                        If openFileDialog1.FileName.Length <> 0 Then
                            LoadNewDoc(openFileDialog1.FileName)
                        End If
                    End If
				Case ID.ID_EDIT_SELECT_ALL, ID.ID_EDIT_SELECT
					Dim rtfText As System.Windows.Forms.RichTextBox = CType(Me.ActiveMdiChild.Controls(0), System.Windows.Forms.RichTextBox)
					rtfText.SelectAll()
				Case ID.ID_EDIT_UNDO
                    Dim rtfText As System.Windows.Forms.RichTextBox = CType(Me.ActiveMdiChild.Controls(0), System.Windows.Forms.RichTextBox)
					rtfText.Undo()
				Case ID.ID_EDIT_CUT
                    Dim rtfText As System.Windows.Forms.RichTextBox = CType(Me.ActiveMdiChild.Controls(0), System.Windows.Forms.RichTextBox)
					rtfText.Cut()
				Case ID.ID_EDIT_COPY
                    Dim rtfText As System.Windows.Forms.RichTextBox = CType(Me.ActiveMdiChild.Controls(0), System.Windows.Forms.RichTextBox)
					rtfText.Copy()
				Case ID.ID_EDIT_PASTE
                    Dim rtfText As System.Windows.Forms.RichTextBox = CType(Me.ActiveMdiChild.Controls(0), System.Windows.Forms.RichTextBox)
                    rtfText.Paste()
                Case ID.ID_OPTIONS_STYLEBLACK
                    CommandBarsGlobalSettings = New XtremeCommandBars.CommandBarsGlobalSettings()
                    CommandBarsGlobalSettings.ResourceImages.LoadFromFile(IO.Path.GetDirectoryName(Application.ExecutablePath) + "\\..\\..\\..\\..\\Styles\\Office2007.dll", "Office2007Black.ini")
                    ControlFile.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonAutomatic
                    CommandBars.PaintManager.RefreshMetrics()
                    CommandBars.RecalcLayout()
                Case ID.ID_OPTIONS_STYLEBLUE
                    CommandBarsGlobalSettings = New XtremeCommandBars.CommandBarsGlobalSettings()
                    CommandBarsGlobalSettings.ResourceImages.LoadFromFile("", "")
                    ControlFile.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonAutomatic
                    CommandBars.PaintManager.RefreshMetrics()
                    CommandBars.RecalcLayout()
                Case ID.ID_OPTIONS_STYLEAQUA
                    CommandBarsGlobalSettings = New XtremeCommandBars.CommandBarsGlobalSettings()
                    CommandBarsGlobalSettings.ResourceImages.LoadFromFile(IO.Path.GetDirectoryName(Application.ExecutablePath) + "\\..\\..\\..\\..\\Styles\\Office2007.dll", "Office2007Aqua.ini")
                    ControlFile.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonAutomatic
                    CommandBars.PaintManager.RefreshMetrics()
                    CommandBars.RecalcLayout()
                Case ID.ID_OPTIONS_STYLESILVER
                    CommandBarsGlobalSettings = New XtremeCommandBars.CommandBarsGlobalSettings()
                    CommandBarsGlobalSettings.ResourceImages.LoadFromFile(IO.Path.GetDirectoryName(Application.ExecutablePath) + "\\..\\..\\..\\..\\Styles\\Office2007.dll", "Office2007Silver.ini")
                    ControlFile.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonAutomatic
                    CommandBars.PaintManager.RefreshMetrics()
                    CommandBars.RecalcLayout()
                Case ID.ID_OPTIONS_STYLEOFFCIE2010BLUE
                    CommandBarsGlobalSettings = New XtremeCommandBars.CommandBarsGlobalSettings()
                    CommandBarsGlobalSettings.ResourceImages.LoadFromFile(IO.Path.GetDirectoryName(Application.ExecutablePath) + "\\..\\..\\..\\..\\Styles\\Office2010.dll", "Office2010Blue.ini")
                    ControlFile.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonCaption
                    CommandBars.PaintManager.RefreshMetrics()
                    CommandBars.RecalcLayout()
                Case ID.ID_OPTIONS_STYLEOFFICE2010SILVER
                    CommandBarsGlobalSettings = New XtremeCommandBars.CommandBarsGlobalSettings()
                    CommandBarsGlobalSettings.ResourceImages.LoadFromFile(IO.Path.GetDirectoryName(Application.ExecutablePath) + "\\..\\..\\..\\..\\Styles\\Office2010.dll", "Office2010Silver.ini")
                    ControlFile.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonCaption
                    CommandBars.PaintManager.RefreshMetrics()
                    CommandBars.RecalcLayout()
                Case ID.ID_OPTIONS_STYLEOFFCIE2010BLACK
                    CommandBarsGlobalSettings = New XtremeCommandBars.CommandBarsGlobalSettings()
                    CommandBarsGlobalSettings.ResourceImages.LoadFromFile(IO.Path.GetDirectoryName(Application.ExecutablePath) + "\\..\\..\\..\\..\\Styles\\Office2010.dll", "Office2010Black.ini")
                    ControlFile.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonCaption
                    CommandBars.PaintManager.RefreshMetrics()
                    CommandBars.RecalcLayout()
                Case ID.ID_OPTIONS_STYLESCENIC
                    CommandBarsGlobalSettings = New XtremeCommandBars.CommandBarsGlobalSettings()
                    CommandBarsGlobalSettings.ResourceImages.LoadFromFile(IO.Path.GetDirectoryName(Application.ExecutablePath) + "\\..\\..\\..\\..\\Styles\\Windows7.dll", "Windows7Blue.ini")
                    ControlFile.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonCaption
                    CommandBars.PaintManager.RefreshMetrics()
                    CommandBars.RecalcLayout()
                Case ID.ID_OPTIONS_STYLESYSTEM
                    CommandBars.VisualTheme = XtremeCommandBars.XTPVisualTheme.xtpThemeOfficeXP
                    CommandBars.Options.UseFadedIcons = False
                    CommandBars.Options.IconsWithShadow = False
                    ControlFile.Style = XtremeCommandBars.XTPButtonStyle.xtpButtonAutomatic
                    CommandBars.PaintManager.RefreshMetrics()
                    CommandBars.RecalcLayout()
				Case Else
					MessageBox.Show(eventArgs.control.Caption & " clicked", "Button Clicked")
					Exit Select
			End Select
		End Sub

		Private Sub CommandBars_UpdateEvent(ByVal eventSender As Object, ByVal eventArgs As AxXtremeCommandBars._DCommandBarsEvents_UpdateEvent) Handles CommandBars.UpdateEvent
			Select Case eventArgs.control.Id
				Case ID.ID_VIEW_STATUS_BAR
					eventArgs.control.Checked = CommandBars.StatusBar.Visible
				Case ID.ID_FILE_PRINT_PREVIEW, ID.ID_FILE_PRINT, ID.ID_FILE_CLOSE, ID.ID_FILE_SAVE, ID.ID_WINDOW_ARRANGE, ID.ID_WINDOW_NEW, ID.ID_WINDOW_SWITCH
					If Me.MdiChildren.Length <> 0 Then
						eventArgs.control.Enabled = (True)
					Else
						eventArgs.control.Enabled = (False)
					End If
				Case CInt(XtremeCommandBars.XTPCommandBarsSpecialCommands.XTP_ID_RIBBONCONTROLTAB)
					If RibbonBar().FindTab(ID.ID_TAB_PRINT_PREVIEW).Visible = True Then
						RibbonBar().FindTab(ID.ID_TAB_EDIT).Visible = False
					Else If Me.MdiChildren.Length <> 0 Then
						If Me.MdiChildren.Length <> 0 Then
							RibbonBar().FindTab(ID.ID_TAB_EDIT).Visible = (True)
						Else
							RibbonBar().FindTab(ID.ID_TAB_EDIT).Visible = (False)
						End If
					End If
				Case ID.ID_EDIT_REPLACE, ID.ID_EDIT_FIND, ID.ID_EDIT_SELECT_ALL
					If Me.MdiChildren.Length = 0 Then
						eventArgs.control.Enabled = False
					Else
						Dim rtfText As System.Windows.Forms.RichTextBox = CType(Me.ActiveMdiChild.Controls(0), System.Windows.Forms.RichTextBox)
						eventArgs.control.Enabled = rtfText.CanSelect
					End If
				Case ID.ID_EDIT_CUT, ID.ID_EDIT_COPY
					If Me.MdiChildren.Length = 0 Then
						eventArgs.control.Enabled = False
					Else
						Dim rtfText As System.Windows.Forms.RichTextBox = CType(Me.ActiveMdiChild.Controls(0), System.Windows.Forms.RichTextBox)
						If rtfText.SelectionLength = 0 Then
							eventArgs.control.Enabled = (False)
						Else
							eventArgs.control.Enabled = (True)
						End If
					End If
				Case ID.ID_EDIT_UNDO
					If Me.MdiChildren.Length = 0 Then
						eventArgs.control.Enabled = False
					Else
						Dim rtfText As System.Windows.Forms.RichTextBox = CType(Me.ActiveMdiChild.Controls(0), System.Windows.Forms.RichTextBox)
						eventArgs.control.Enabled = rtfText.CanUndo
					End If
				Case ID.ID_EDIT_PASTE, ID.ID_EDIT_PASTE_SPECIAL
					If Me.MdiChildren.Length = 0 Then
						eventArgs.control.Enabled = False
					Else
						Dim rtfText As System.Windows.Forms.RichTextBox = CType(Me.ActiveMdiChild.Controls(0), System.Windows.Forms.RichTextBox)
						Dim myFormat As System.Windows.Forms.DataFormats.Format = System.Windows.Forms.DataFormats.GetFormat(DataFormats.Text)
						eventArgs.control.Enabled = rtfText.CanPaste(myFormat)
					End If
					Exit Select
			End Select

		End Sub

		Private Sub frmMain_Load(ByVal eventSender As Object, ByVal eventArgs As System.EventArgs) Handles MyBase.Load
			CreateRibbonBar()

			CommandBars.KeyBindings.Add(ID.FCONTROL, System.Convert.ToInt32("N"c), ID.ID_FILE_NEW)
			CommandBars.KeyBindings.Add(ID.FCONTROL, System.Convert.ToInt32("O"c), ID.ID_FILE_OPEN)
			CommandBars.KeyBindings.Add(ID.FCONTROL, System.Convert.ToInt32("S"c), ID.ID_FILE_SAVE)
			CommandBars.KeyBindings.Add(ID.FCONTROL, System.Convert.ToInt32("X"c), ID.ID_EDIT_CUT)
			CommandBars.KeyBindings.Add(ID.FCONTROL, System.Convert.ToInt32("C"c), ID.ID_EDIT_COPY)
			CommandBars.KeyBindings.Add(ID.FCONTROL, System.Convert.ToInt32("V"c), ID.ID_EDIT_PASTE)
			CommandBars.KeyBindings.Add(ID.FCONTROL, System.Convert.ToInt32("A"c), ID.ID_EDIT_SELECT_ALL)

			LoadIcons()

			Dim StatusBar As XtremeCommandBars.StatusBar = Nothing
			StatusBar = CommandBars.StatusBar
			StatusBar.Visible = True

			StatusBar.AddPane(0)
			StatusBar.AddPane(ID.ID_INDICATOR_CAPS)
			StatusBar.AddPane(ID.ID_INDICATOR_NUM)
			StatusBar.AddPane(ID.ID_INDICATOR_SCRL)

			RibbonBar().EnableFrameTheme()

			CommandBars.Options.KeyboardCuesShow = XtremeCommandBars.XTPKeyboardCuesShow.xtpKeyboardCuesShowWindowsDefault

			Dim ctrl As Control
			For Each ctrl In Me.Controls
				If TypeOf ctrl Is MdiClient Then
					CommandBars.SetMDIClient(ctrl.Handle.ToInt32())
				End If
			Next ctrl

            CommandBars.EnableCustomization(True)

            CommandBars.FindControl(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_OPTIONS_STYLESCENIC, True, True).Execute()
		End Sub

		Private Sub LoadIcons()
			CommandBars.Options.UseSharedImageList = False

            Dim resDir As String = System.IO.Path.GetDirectoryName(Application.ExecutablePath) + "\\..\\res\\"

            CommandBars.Icons.LoadBitmap(resDir + "GroupClipboard.png", New Object() {ID.ID_EDIT_PASTE, ID.ID_EDIT_CUT, ID.ID_EDIT_COPY, ID.ID_FORMAT_PAINTER}, XtremeCommandBars.XTPImageState.xtpImageNormal)
            CommandBars.Icons.LoadBitmap(resDir + "GroupFind.png", New Object() {ID.ID_EDIT_FIND, ID.ID_EDIT_REPLACE, ID.ID_EDIT_GOTO, ID.ID_EDIT_SELECT}, XtremeCommandBars.XTPImageState.xtpImageNormal)
            CommandBars.Icons.LoadBitmap(resDir + "SmallIcons.png", New Object() {ID.ID_FILE_NEW, ID.ID_FILE_OPEN, ID.ID_FILE_SAVE, ID.ID_EDIT_CUT, ID.ID_EDIT_COPY, ID.ID_EDIT_PASTE, ID.ID_EDIT_UNDO, ID.ID_EDIT_REDO, ID.ID_FILE_PRINT, ID.ID_APP_ABOUT}, XtremeCommandBars.XTPImageState.xtpImageNormal)
            CommandBars.Icons.LoadBitmap(resDir + "LargeIcons.png", New Object() {ID.ID_FILE_NEW, ID.ID_FILE_OPEN, ID.ID_FILE_SAVE, ID.ID_EDIT_PASTE, ID.ID_EDIT_FIND, ID.ID_FILE_PRINT, ID.ID_FILE_CLOSE, ID.ID_VIEW_NORMAL, ID.ID_FILE_PRINT_PREVIEW, ID.ID_VIEW_FULLSCREEN, ID.ID_WINDOW_NEW, ID.ID_WINDOW_ARRANGE, ID.ID_WINDOW_SWITCH}, XtremeCommandBars.XTPImageState.xtpImageNormal)
            CommandBars.Icons.LoadBitmap(resDir + "shiny-gear.png", ID.ID_SYSTEM_ICON, XtremeCommandBars.XTPImageState.xtpImageNormal)
            CommandBars.Icons.LoadIcon(resDir + "GroupPopup.ico", ID.ID_GROUP_POPUPICON, XtremeCommandBars.XTPImageState.xtpImageNormal)
            CommandBars.Icons.LoadBitmap(resDir + "PrintPreview.png", New Object() {ID.ID_PREVIEW_PREVIEW_CLOSE, ID.ID_PREVIEW_ZOOM_100_PERCENT, ID.ID_PREVIEW_ZOOM_ZOOM, ID.ID_PREVIEW_PAGESETUP_SIZE, ID.ID_PREVIEW_PAGESETUP_ORIENTATION, ID.ID_PREVIEW_PAGESETUP_MARGINS, ID.ID_PREVIEW_PRINT_OPTIONS, ID.ID_PREVIEW_PRINT_PRINT}, XtremeCommandBars.XTPImageState.xtpImageNormal)
            CommandBars.Icons.LoadBitmap(resDir + "PrintPreviewSmall.png", New Object() {ID.ID_PREVIEW_ZOOM_1PAGE, ID.ID_PREVIEW_ZOOM_2PAGES, ID.ID_PREVIEW_ZOOM_PAGE_WIDTH, ID.ID_PREVIEW_PREVIEW_SHRINK, ID.ID_PREVIEW_PREVIEW_NEXT, ID.ID_PREVIEW_PREVIEW_PREVIOUS}, XtremeCommandBars.XTPImageState.xtpImageNormal)

			Dim ToolTipContext As XtremeCommandBars.ToolTipContext = Nothing
			ToolTipContext = CommandBars.ToolTipContext
			ToolTipContext.Style = XtremeCommandBars.XTPToolTipStyle.xtpToolTipResource
			ToolTipContext.ShowTitleAndDescription(True, XtremeCommandBars.XTPToolTipIcon.xtpToolTipIconNone)
			ToolTipContext.SetMargin(2, 2, 2, 2)
			ToolTipContext.MaxTipWidth = 180
		End Sub
		
		Private Sub CreateRibbonBar()
			Dim TabView As XtremeCommandBars.RibbonTab = Nothing
			Dim TabHome As XtremeCommandBars.RibbonTab = Nothing
			Dim TabEdit As XtremeCommandBars.RibbonTab = Nothing
			Dim TabPrintPreview As XtremeCommandBars.RibbonTab = Nothing
			Dim GroupFile As XtremeCommandBars.RibbonGroup = Nothing
			Dim GroupClipboard As XtremeCommandBars.RibbonGroup = Nothing
			Dim GroupEditing As XtremeCommandBars.RibbonGroup = Nothing
			Dim GroupShowHide As XtremeCommandBars.RibbonGroup = Nothing
			Dim GroupDocumentViews As XtremeCommandBars.RibbonGroup = Nothing
			Dim GroupWindow As XtremeCommandBars.RibbonGroup = Nothing
			Dim GroupPrint As XtremeCommandBars.RibbonGroup = Nothing
			Dim GroupPageSetup As XtremeCommandBars.RibbonGroup = Nothing
			Dim GroupZoom As XtremeCommandBars.RibbonGroup = Nothing
			Dim GroupPreview As XtremeCommandBars.RibbonGroup = Nothing
			Dim ControlSaveAs As XtremeCommandBars.CommandBarPopup = Nothing
			Dim ControlPrint As XtremeCommandBars.CommandBarPopup = Nothing
			Dim Control As XtremeCommandBars.CommandBarControl = Nothing
			Dim ControlPaste As XtremeCommandBars.CommandBarPopup = Nothing
			Dim ControlSelect As XtremeCommandBars.CommandBarPopup = Nothing
			Dim ControlPopup As XtremeCommandBars.CommandBarPopup = Nothing
			Dim ControlMargins As XtremeCommandBars.CommandBarPopup = Nothing
			Dim ControlOrientation As XtremeCommandBars.CommandBarPopup = Nothing
            Dim ControlSize As XtremeCommandBars.CommandBarPopup = Nothing
            Dim ControlOptions As XtremeCommandBars.CommandBarPopup = Nothing

			Dim RibbonBar As XtremeCommandBars.RibbonBar = Nothing
			RibbonBar = CommandBars.AddRibbonBar("The Ribbon")
			RibbonBar.EnableDocking(XtremeCommandBars.XTPToolBarFlags.xtpFlagStretched)

			Dim ControlAbout As XtremeCommandBars.CommandBarControl = Nothing

            ControlFile = RibbonBar.AddSystemButton()
            ControlFile.IconId = ID.ID_SYSTEM_ICON
            ControlFile.Caption = "&File"
			ControlFile.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_NEW, "&New", False, False)
			ControlFile.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_OPEN, "&Open...", False, False)
			Control = ControlFile.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_PRINT_SETUP, "Pr&int Setup...", False, False)
			Control.BeginGroup = True
			Control = ControlFile.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_MRU_FILE1, "Recent File", False, False)
			Control.BeginGroup = True
			Control.Enabled = False
			Control = ControlFile.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_APP_EXIT, "E&xit", False, False)
			Control.BeginGroup = True
			ControlFile.CommandBar.SetIconSize(32, 32)

			ControlAbout = RibbonBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_APP_ABOUT, "&About", False, False)
            ControlAbout.Flags = XtremeCommandBars.XTPControlFlags.xtpFlagRightAlign

            ControlOptions = RibbonBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlPopup, 0, "Options", -1, False)
            ControlOptions.Flags = XtremeCommandBars.XTPControlFlags.xtpFlagRightAlign

            ControlPopup = ControlOptions.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlPopup, 0, "Styles", -1, False)
            ControlPopup.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_OPTIONS_STYLEBLUE, "Office 2007 Blue", -1, False)
            ControlPopup.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_OPTIONS_STYLEBLACK, "Office 2007 Black", -1, False)
            ControlPopup.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_OPTIONS_STYLESILVER, "Office 2007 Silver", -1, False)
            ControlPopup.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_OPTIONS_STYLEAQUA, "Office 2007 Aqua", -1, False)
            ControlPopup.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_OPTIONS_STYLEOFFICE2010SILVER, "Office 2010 Silver", -1, False)
            ControlPopup.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_OPTIONS_STYLEOFFCIE2010BLUE, "Office 2010 Blue", -1, False)
            ControlPopup.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_OPTIONS_STYLEOFFCIE2010BLACK, "Office 2010 Black", -1, False)
            ControlPopup.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_OPTIONS_STYLESCENIC, "Windows 7 Scenic", -1, False)
            ControlPopup.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_OPTIONS_STYLESYSTEM, "System Theme", -1, False)

			TabHome = RibbonBar.InsertTab(0, "&Home")
			TabHome.Id = ID.ID_TAB_HOME

			GroupFile = TabHome.Groups.AddGroup("File", ID.ID_GROUP_FILE)
			GroupFile.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_NEW, "&New", False, False)
			GroupFile.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_OPEN, "&Open", False, False)
			GroupFile.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_CLOSE, "&Close", False, False)
			ControlSaveAs = CType(GroupFile.Add(XtremeCommandBars.XTPControlType.xtpControlSplitButtonPopup, ID.ID_FILE_SAVE, "&Save", False, False), XtremeCommandBars.CommandBarPopup)
            ControlSaveAs.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_SAVE, "&Save", False, False)
			ControlSaveAs.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_SAVE_AS, "Save &As...", False, False)
			ControlPrint = CType(GroupFile.Add(XtremeCommandBars.XTPControlType.xtpControlSplitButtonPopup, ID.ID_FILE_PRINT, "Print", False, False), XtremeCommandBars.CommandBarPopup)
			ControlPrint.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_PRINT, "&Print", False, False)
			ControlPrint.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_PRINT_SETUP, "Print &Setup...", False, False)
			ControlPrint.BeginGroup = True


			TabEdit = RibbonBar.InsertTab(1, "&Edit")
			TabEdit.Id = ID.ID_TAB_EDIT

			GroupClipboard = TabEdit.Groups.AddGroup("&Clipboard", ID.ID_GROUP_CLIPBOARD)

			ControlPaste = CType(GroupClipboard.Add(XtremeCommandBars.XTPControlType.xtpControlSplitButtonPopup, ID.ID_EDIT_PASTE, "&Paste", False, False), XtremeCommandBars.CommandBarPopup)
			ControlPaste.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_EDIT_PASTE, "&Paste", False, False)
			ControlPaste.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_EDIT_PASTE_SPECIAL, "&Paste Special", False, False)
			GroupClipboard.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_EDIT_CUT, "&Cut", False, False)
			GroupClipboard.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_EDIT_COPY, "&Copy", False, False)
			Control = GroupClipboard.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FORMAT_PAINTER, "Format Painter", False, False)
			Control.Enabled = False
			GroupClipboard.ShowOptionButton = True
			GroupClipboard.ControlGroupOption.TooltipText = "Show clipboard dialog"
			GroupClipboard.IconId = ID.ID_EDIT_PASTE

			GroupEditing = TabEdit.Groups.AddGroup("&Editing", ID.ID_GROUP_EDITING)
			GroupEditing.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_EDIT_FIND, "&Find", False, False)
			GroupEditing.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_EDIT_REPLACE, "&Replace", False, False)
			Control = GroupEditing.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_EDIT_GOTO, "&Goto", False, False)
			Control.Enabled = False

			ControlSelect = CType(GroupEditing.Add(XtremeCommandBars.XTPControlType.xtpControlPopup, ID.ID_EDIT_SELECT, "&Select", False, False), XtremeCommandBars.CommandBarPopup)
			ControlSelect.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_EDIT_SELECT_ALL, "Select All", False, False)

			TabEdit.Visible = False

			TabView = RibbonBar.InsertTab(2, "&View")
			TabView.Id = ID.ID_TAB_VIEW

			GroupDocumentViews = TabView.Groups.AddGroup("Document Views", ID.ID_GROUP_DOCUMENTVIEWS)
			Control = GroupDocumentViews.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_VIEW_NORMAL, "&Normal", False, False)
			Control.Checked = True
			GroupDocumentViews.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_PRINT_PREVIEW, "Print Preview", False, False)
			GroupDocumentViews.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_VIEW_FULLSCREEN, "&Full Screen", False, False)

			GroupShowHide = TabView.Groups.AddGroup("Show/Hide", ID.ID_GROUP_SHOWHIDE)
			GroupShowHide.Add(XtremeCommandBars.XTPControlType.xtpControlCheckBox, ID.ID_VIEW_STATUS_BAR, "StatusBar", False, False)
			GroupShowHide.Add(XtremeCommandBars.XTPControlType.xtpControlCheckBox, ID.ID_VIEW_WORKSPACE, "Workspace", False, False)

			GroupWindow = TabView.Groups.AddGroup("Window", ID.ID_GROUP_WINDOW)
			GroupWindow.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_WINDOW_NEW, "New Window", False, False)
			GroupWindow.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_WINDOW_ARRANGE, "Arrange Icons", False, False)
			ControlPopup = CType(GroupWindow.Add(XtremeCommandBars.XTPControlType.xtpControlPopup, ID.ID_WINDOW_SWITCH, "Switch Windows", False, False), XtremeCommandBars.CommandBarPopup)
			ControlPopup.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, CInt(XtremeCommandBars.XTPCommandBarsSpecialCommands.XTP_ID_WINDOWLIST), "Item 1", False, False)

			TabPrintPreview = RibbonBar.InsertTab(3, "&Print Preview")
			TabPrintPreview.Id = ID.ID_TAB_PRINT_PREVIEW

			GroupPrint = TabPrintPreview.Groups.AddGroup("Print", ID.ID_GROUP_PRINT)
			GroupPrint.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_PRINT, "Print", False, False)
			GroupPrint.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_PREVIEW_PRINT_OPTIONS, "Options", False, False)

			GroupPageSetup = TabPrintPreview.Groups.AddGroup("Page Setup", ID.ID_GROUP_PAGESETUP)
			GroupPageSetup.ShowOptionButton = True
			ControlPopup = CType(GroupPageSetup.Add(XtremeCommandBars.XTPControlType.xtpControlPopup, ID.ID_PREVIEW_PAGESETUP_MARGINS, "Margins", False, False), XtremeCommandBars.CommandBarPopup)
			ControlPopup.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_MARGINS_CUSTOM_MARGINS, "Custom M&argins...", False, False)
			ControlPopup = CType(GroupPageSetup.Add(XtremeCommandBars.XTPControlType.xtpControlPopup, ID.ID_PREVIEW_PAGESETUP_ORIENTATION, "Orientation", False, False), XtremeCommandBars.CommandBarPopup)
			ControlPopup.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_ORIENTATION_PORTRAIT, "Portrait", False, False)
			ControlPopup.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_ORIENTATION_LANDSCAPE, "Landscape", False, False)
			ControlPopup = CType(GroupPageSetup.Add(XtremeCommandBars.XTPControlType.xtpControlPopup, ID.ID_PREVIEW_PAGESETUP_SIZE, "Size", False, False), XtremeCommandBars.CommandBarPopup)
			ControlPopup.CommandBar.Controls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_SIZE_MORE_PAPER_SIZES, "More P&aper Sizes...", False, False)

			GroupZoom = TabPrintPreview.Groups.AddGroup("Zoom", ID.ID_GROUP_ZOOM)
			GroupZoom.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_PREVIEW_ZOOM_ZOOM, "Zoom", False, False)
			GroupZoom.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_PREVIEW_ZOOM_100_PERCENT, "100%", False, False)
			GroupZoom.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_PREVIEW_ZOOM_1PAGE, "One Page", False, False)
			GroupZoom.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_PREVIEW_ZOOM_2PAGES, "Two Pages", False, False)
			GroupZoom.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_PREVIEW_ZOOM_PAGE_WIDTH, "Page Width", False, False)

			GroupPreview = TabPrintPreview.Groups.AddGroup("Preview", ID.ID_GROUP_PREVIEW)
			GroupPreview.Add(XtremeCommandBars.XTPControlType.xtpControlCheckBox, ID.ID_PREVIEW_PREVIEW_RULER, "Show Ruler", False, False)
			GroupPreview.Add(XtremeCommandBars.XTPControlType.xtpControlCheckBox, ID.ID_PREVIEW_PREVIEW_MAGNIFIER, "Magnifier", False, False)
			GroupPreview.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_PREVIEW_PREVIEW_SHRINK, "Shrink One Page", False, False)
			GroupPreview.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_PREVIEW_PREVIEW_NEXT, "Next Page", False, False)
			GroupPreview.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_PREVIEW_PREVIEW_PREVIOUS, "Previous Page", False, False)
			Control = GroupPreview.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_PREVIEW_PREVIEW_CLOSE, "Close Print Preview", False, False)
			Control.BeginGroup = True

			TabPrintPreview.Visible = False

			RibbonBar.QuickAccessControls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_SAVE, "&Save", False, False)
			RibbonBar.QuickAccessControls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_EDIT_UNDO, "&Undo", False, False)
			RibbonBar.QuickAccessControls.Add(XtremeCommandBars.XTPControlType.xtpControlButton, ID.ID_FILE_PRINT, "&Print", False, False)
		End Sub		

		Protected lDocumentCount As Integer = 0

		Private Sub LoadNewDoc(ByVal Caption As String)
			lDocumentCount += 1

			Dim frmDocument As frmDocument = New frmDocument()
			frmDocument.MdiParent = Me
			frmDocument.Show()
			CommandBars.EnableOffice2007FrameHandle(frmDocument.Handle.ToInt32())

			If Caption.Length <>0 Then
				frmDocument.Text = Caption
			Else
				frmDocument.Text = "Document " & lDocumentCount.ToString()
			End If

			Me.Text = "Ribbon MDI Sample - " & frmDocument.Text

			Me.Refresh()
		End Sub

		Private Sub LoadPrintPreview()
			RibbonBar().FindTab(ID.ID_TAB_PRINT_PREVIEW).Visible = True
			RibbonBar().FindTab(ID.ID_TAB_HOME).Visible = False
			RibbonBar().FindTab(ID.ID_TAB_EDIT).Visible = False
			RibbonBar().FindTab(ID.ID_TAB_VIEW).Visible = False

			CommandBars.ShowTabWorkspace(False)

			Dim frmPrintPreviw As frmPrintPreviw = New frmPrintPreviw()
			frmPrintPreviw.lstDocumentName = Me.ActiveMdiChild.Text
			Dim rtfText As System.Windows.Forms.RichTextBox = CType(Me.ActiveMdiChild.Controls(0), System.Windows.Forms.RichTextBox)
			frmPrintPreviw.lstDocumentBody = rtfText.Text
			frmPrintPreviw.MdiParent = Me
			frmPrintPreviw.Show()
			frmPrintPreviw.Text = "Print Preview"

			Me.Refresh()
		End Sub

		Private Sub frmMain_MdiChildActivate(ByVal sender As Object, ByVal e As System.EventArgs) Handles MyBase.MdiChildActivate
			If Not Me.ActiveMdiChild Is Nothing Then
				Me.Text = "Ribbon MDI Sample - " & Me.ActiveMdiChild.Text
			Else
				Me.Text = "Ribbon MDI Sample"
			End If
		End Sub
	End Class
End Namespace