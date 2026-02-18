Imports Microsoft.VisualBasic
Imports System
Imports System.Collections
Imports System.Data
Imports System.Drawing
Imports System.Diagnostics
Imports System.Windows.Forms

Namespace RibbonMDISample
	Public Class ID
		Public Const ID_TAB_HOME As Integer = 129
		Public Const ID_GROUP_FILE As Integer = 130
		Public Const ID_TAB_VIEW As Integer = 131
		Public Const ID_TAB_EDIT As Integer = 132
		Public Const ID_TAB_PRINT_PREVIEW As Integer = 133
		Public Const ID_GROUP_DOCUMENTVIEWS As Integer = 134
		Public Const ID_GROUP_SHOWHIDE As Integer = 135
		Public Const ID_GROUP_WINDOW As Integer = 136
		Public Const ID_GROUP_CLIPBOARD As Integer = 137
		Public Const ID_FORMAT_PAINTER As Integer = 138
		Public Const ID_GROUP_EDITING As Integer = 139
		Public Const ID_EDIT_GOTO As Integer = 140
		Public Const ID_VIEW_NORMAL As Integer = 141
		Public Const ID_VIEW_FULLSCREEN As Integer = 142
		Public Const ID_WINDOW_SWITCH As Integer = 143
		Public Const ID_EDIT_SELECT As Integer = 144
		Public Const ID_EDIT_UNDO As Integer = 145
		Public Const ID_EDIT_REDO As Integer = 146
		Public Const ID_WINDOW_ARRANGE As Integer = 57649
		Public Const ID_WINDOW_NEW As Integer = 57648
		Public Const ID_VIEW_WORKSPACE As Integer = 59394
		Public Const ID_FILE_CLOSE As Integer = 5040
		Public Const ID_PREVIEW_PRINT_PRINT As Integer = 5050
		Public Const ID_PREVIEW_PRINT_OPTIONS As Integer = 5051
		Public Const ID_PREVIEW_PAGESETUP_MARGINS As Integer = 5052
		Public Const ID_PREVIEW_PAGESETUP_ORIENTATION As Integer = 5053
		Public Const ID_PREVIEW_PAGESETUP_SIZE As Integer = 5054
		Public Const ID_PREVIEW_ZOOM_ZOOM As Integer = 5055
		Public Const ID_PREVIEW_ZOOM_100_PERCENT As Integer = 5056
		Public Const ID_PREVIEW_ZOOM_1PAGE As Integer = 5057
		Public Const ID_PREVIEW_ZOOM_2PAGES As Integer = 5058
		Public Const ID_PREVIEW_ZOOM_PAGE_WIDTH As Integer = 5059
		Public Const ID_PREVIEW_PREVIEW_RULER As Integer = 5060
		Public Const ID_PREVIEW_PREVIEW_MAGNIFIER As Integer = 5061
		Public Const ID_PREVIEW_PREVIEW_SHRINK As Integer = 5062
		Public Const ID_PREVIEW_PREVIEW_NEXT As Integer = 5063
		Public Const ID_PREVIEW_PREVIEW_PREVIOUS As Integer = 5064
		Public Const ID_PREVIEW_PREVIEW_CLOSE As Integer = 5065
		Public Const ID_GROUP_PREVIEW As Integer = 5070
		Public Const ID_GROUP_ZOOM As Integer = 5071
		Public Const ID_GROUP_PRINT As Integer = 5072
		Public Const ID_MARGINS_CUSTOM_MARGINS As Integer = 5073
		Public Const ID_ORIENTATION_PORTRAIT As Integer = 5074
		Public Const ID_ORIENTATION_LANDSCAPE As Integer = 5075
		Public Const ID_SIZE_MORE_PAPER_SIZES As Integer = 5076

		Public Const ID_VIEW_STATUS_BAR As Integer = 2808
		Public Const ID_GROUP_PAGESETUP As Integer = 5022
		Public Const ID_SYSTEM_ICON As Integer = 1200
        Public Const ID_GROUP_POPUPICON As Integer = 2004

        Public Const ID_OPTIONS_STYLEBLUE As Integer = 3000
        Public Const ID_OPTIONS_STYLEBLACK As Integer = 3001
        Public Const ID_OPTIONS_STYLEAQUA As Integer = 3002
        Public Const ID_OPTIONS_RTL As Integer = 3003
        Public Const ID_OPTIONS_ANIMATION As Integer = 3004
        Public Const ID_OPTIONS_STYLESILVER As Integer = 3005
        Public Const ID_OPTIONS_STYLESCENIC As Integer = 3006
        Public Const ID_OPTIONS_STYLEOFFICE2010SILVER As Integer = 3007
        Public Const ID_OPTIONS_STYLEOFFCIE2010BLUE As Integer = 3008
        Public Const ID_OPTIONS_STYLEOFFCIE2010BLACK As Integer = 3009
        Public Const ID_OPTIONS_STYLESYSTEM As Integer = 3010

		Public Const ID_APP_ABOUT As Integer = 4000
		Public Const ID_EDIT_PASTE As Integer = 4001
		Public Const ID_EDIT_PASTE_SPECIAL As Integer = 4002
		Public Const ID_EDIT_COPY As Integer = 4003
		Public Const ID_EDIT_CUT As Integer = 4004
		Public Const ID_EDIT_FIND As Integer = 57636
		Public Const ID_EDIT_REPLACE As Integer = 4006
		Public Const ID_EDIT_SELECT_ALL As Integer = 4007
		Public Const ID_FILE_NEW As Integer = 4008
		Public Const ID_FILE_OPEN As Integer = 4009
		Public Const ID_FILE_SAVE As Integer = 4010
		Public Const ID_FILE_PRINT As Integer = 4011
		Public Const ID_FILE_SAVE_AS As Integer = 57604
		Public Const ID_FILE_PRINT_PREVIEW As Integer = 57609
		Public Const ID_FILE_PRINT_SETUP As Integer = 57606
		Public Const ID_FILE_MRU_FILE1 As Integer = 57616
		Public Const ID_APP_EXIT As Integer = 57665

		Public Const ID_INDICATOR_CAPS As Integer = 59137
		Public Const ID_INDICATOR_NUM As Integer = 59138
		Public Const ID_INDICATOR_SCRL As Integer = 59139

		Public Const FSHIFT As Integer = 4
		Public Const FCONTROL As Integer = 8
		Public Const FALT As Integer = 16

		Public Const VK_BACK As Integer = &H8
		Public Const VK_TAB As Integer = &H9
		Public Const VK_ESCAPE As Integer = &H1B
		Public Const VK_SPACE As Integer = &H20
		Public Const VK_PRIOR As Integer = &H21
		Public Const VK_NEXT As Integer = &H22
		Public Const VK_END As Integer = &H23
		Public Const VK_HOME As Integer = &H24
		Public Const VK_LEFT As Integer = &H25
		Public Const VK_UP As Integer = &H26
		Public Const VK_RIGHT As Integer = &H27
		Public Const VK_DOWN As Integer = &H28
		Public Const VK_INSERT As Integer = &H2D
		Public Const VK_DELETE As Integer = &H2E
		Public Const VK_MULTIPLY As Integer = &H6A
		Public Const VK_ADD As Integer = &H6B
		Public Const VK_SEPARATOR As Integer = &H6C
		Public Const VK_SUBTRACT As Integer = &H6D
		Public Const VK_DECIMAL As Integer = &H6E
		Public Const VK_DIVIDE As Integer = &H6F
		Public Const VK_F1 As Integer = &H70
		Public Const VK_F2 As Integer = &H71
		Public Const VK_F3 As Integer = &H72
		Public Const VK_F4 As Integer = &H73
		Public Const VK_F5 As Integer = &H74
		Public Const VK_F6 As Integer = &H75
		Public Const VK_F7 As Integer = &H76
		Public Const VK_F8 As Integer = &H77
		Public Const VK_F9 As Integer = &H78
		Public Const VK_F10 As Integer = &H79
		Public Const VK_F11 As Integer = &H7A
		Public Const VK_F12 As Integer = &H7B
	End Class
End Namespace 'end of root namespace