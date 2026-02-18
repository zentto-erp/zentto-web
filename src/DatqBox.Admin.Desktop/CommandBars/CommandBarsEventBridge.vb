Imports System.Runtime.InteropServices
Imports System.Runtime.InteropServices.ComTypes

Friend Class CommandBarsEventBridge
    Private ReadOnly _rcw As Object
    Private ReadOnly _handler As ExecuteEventHandler
    Private ReadOnly _callback As Action(Of Integer, String)
    Private _iid As Guid
    Private _dispid As Integer

    Friend Delegate Sub ExecuteEventHandler(ByVal control As Object)

    Public Sub New(rcw As Object, callback As Action(Of Integer, String))
        _rcw = rcw
        _callback = callback
        _handler = AddressOf OnExecute
    End Sub

    Public Sub Attach()
        Dim info = ResolveExecuteEvent()
        If info Is Nothing Then Return
        _iid = info.EventInterfaceId
        _dispid = info.ExecuteDispId
        If _dispid = 0 Then Return
        ComEventsHelper.Combine(_rcw, _iid, _dispid, _handler)
    End Sub

    Public Sub Detach()
        If _dispid = 0 OrElse _iid = Guid.Empty Then Return
        ComEventsHelper.Remove(_rcw, _iid, _dispid, _handler)
    End Sub

    Private Sub OnExecute(control As Object)
        If _callback Is Nothing Then Return
        Dim id As Integer = 0
        Dim caption As String = String.Empty
        Try
            Dim value = Microsoft.VisualBasic.Interaction.CallByName(control, "Id", CallType.Get)
            If value IsNot Nothing Then id = Convert.ToInt32(value)
        Catch
            id = 0
        End Try
        Try
            Dim value = Microsoft.VisualBasic.Interaction.CallByName(control, "Caption", CallType.Get)
            If value IsNot Nothing Then caption = value.ToString()
        Catch
            caption = String.Empty
        End Try
        _callback.Invoke(id, caption)
    End Sub

    Private Function ResolveExecuteEvent() As ExecuteEventInfo
        Dim typeLib As ITypeLib = Nothing
        Dim ocxPath = ResolveOcxPath()
        If String.IsNullOrWhiteSpace(ocxPath) OrElse Not IO.File.Exists(ocxPath) Then Return Nothing

        Dim hr = LoadTypeLibEx(ocxPath, REGKIND.NONE, typeLib)
        If hr <> 0 OrElse typeLib Is Nothing Then Return Nothing

        Dim typeCount = typeLib.GetTypeInfoCount()
        For i As Integer = 0 To typeCount - 1
            Dim info As ITypeInfo = Nothing
            typeLib.GetTypeInfo(i, info)
            Dim attrPtr As IntPtr = IntPtr.Zero
            info.GetTypeAttr(attrPtr)
            Dim attr = CType(Marshal.PtrToStructure(attrPtr, GetType(TYPEATTR)), TYPEATTR)
            info.ReleaseTypeAttr(attrPtr)

            If attr.typekind <> TYPEKIND.TKIND_COCLASS Then Continue For

            Dim name As String = GetTypeInfoName(info)
            If String.IsNullOrWhiteSpace(name) Then Continue For
            If Not name.ToUpperInvariant().Contains("COMMANDBARS") Then Continue For

            For implIndex As Integer = 0 To attr.cImplTypes - 1
                Dim flags As Integer = 0
                info.GetImplTypeFlags(implIndex, flags)
                If (flags And IMPLTYPEFLAG_FSOURCE) = 0 Then Continue For
                Dim href As Integer = 0
                info.GetRefTypeOfImplType(implIndex, href)
                Dim eventInfo As ITypeInfo = Nothing
                info.GetRefTypeInfo(href, eventInfo)

                Dim eventAttrPtr As IntPtr = IntPtr.Zero
                eventInfo.GetTypeAttr(eventAttrPtr)
                Dim eventAttr = CType(Marshal.PtrToStructure(eventAttrPtr, GetType(TYPEATTR)), TYPEATTR)
                eventInfo.ReleaseTypeAttr(eventAttrPtr)

                Dim dispid = GetDispId(eventInfo, "Execute")
                If dispid <> 0 Then
                    Return New ExecuteEventInfo With {.EventInterfaceId = eventAttr.guid, .ExecuteDispId = dispid}
                End If
            Next
        Next

        Return Nothing
    End Function

    Private Function GetDispId(info As ITypeInfo, name As String) As Integer
        Try
            Dim names = New String() {name}
            Dim ids(0) As Integer
            info.GetIDsOfNames(names, names.Length, ids)
            Return ids(0)
        Catch
            Return 0
        End Try
    End Function

    Private Function GetTypeInfoName(info As ITypeInfo) As String
        Try
            Dim name As String = Nothing
            Dim doc As String = Nothing
            Dim helpContext As Integer = 0
            Dim helpFile As String = Nothing
            info.GetDocumentation(-1, name, doc, helpContext, helpFile)
            Return name
        Catch
            Return String.Empty
        End Try
    End Function

    Private Function ResolveOcxPath() As String
        Dim p1 = "C:\Program Files (x86)\Codejock Software\ActiveX\Xtreme SuitePro ActiveX v15.3.1\Bin\Codejock.CommandBars.v15.3.1.ocx"
        Dim p2 = "C:\Windows\SysWOW64\Codejock.CommandBars.v15.3.1.ocx"
        If IO.File.Exists(p1) Then Return p1
        If IO.File.Exists(p2) Then Return p2
        Return String.Empty
    End Function

    Private Enum REGKIND
        DEFAULTKIND = 0
        REGISTER = 1
        NONE = 2
    End Enum

    <DllImport("oleaut32.dll", CharSet:=CharSet.Unicode)>
    Private Shared Function LoadTypeLibEx(szFile As String, regKind As REGKIND, ByRef typeLib As ITypeLib) As Integer
    End Function

    Private Const IMPLTYPEFLAG_FSOURCE As Integer = &H2

    Private Class ExecuteEventInfo
        Public Property EventInterfaceId As Guid
        Public Property ExecuteDispId As Integer
    End Class
End Class
