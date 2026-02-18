Imports System.Windows.Forms

Friend Class UdfRenderer
    Private ReadOnly _host As FlowLayoutPanel
    Private ReadOnly _registry As UiReferenceRegistry
    Private _nextAutoId As Integer = CoreUiRefIds.UdfFieldBase

    Public Sub New(host As FlowLayoutPanel, registry As UiReferenceRegistry)
        _host = host
        _registry = registry
    End Sub

    Public Sub Register(definition As UdfDefinition)
        If definition Is Nothing Then Throw New ArgumentNullException(NameOf(definition))
        If String.IsNullOrWhiteSpace(definition.Caption) Then Throw New ArgumentException("Caption UDF requerido.", NameOf(definition))

        Dim udfId = definition.ReferenceId
        If udfId <= 0 Then
            udfId = Threading.Interlocked.Increment(_nextAutoId)
        End If

        Dim row As New Panel() With {
            .Width = _host.ClientSize.Width - 28,
            .Height = 54,
            .Margin = New Padding(3, 3, 3, 8)
        }

        Dim lbl As New Label() With {
            .Text = definition.Caption & " (" & definition.TableName & "." & definition.FieldName & ")",
            .Left = 2,
            .Top = 2,
            .Width = row.Width - 8,
            .Height = 18
        }

        Dim editor As Control = CreateEditor(definition)
        editor.Left = 2
        editor.Top = 24
        editor.Width = row.Width - 8
        editor.Height = 24
        editor.Name = $"udf_{definition.TableName}_{definition.FieldName}_{udfId}"

        row.Controls.Add(lbl)
        row.Controls.Add(editor)
        _host.Controls.Add(row)

        _registry.Register(udfId, $"UDF.{definition.TableName}.{definition.FieldName}", editor)
    End Sub

    Private Shared Function CreateEditor(definition As UdfDefinition) As Control
        Select Case definition.DataType
            Case UdfDataType.Number
                Dim num As New NumericUpDown()
                num.DecimalPlaces = 2
                Dim parsed As Decimal
                If Decimal.TryParse(definition.DefaultValue, parsed) Then num.Value = parsed
                Return num
            Case UdfDataType.Date
                Dim dt As New DateTimePicker() With {.Format = DateTimePickerFormat.Short}
                Dim parsedDate As DateTime
                If DateTime.TryParse(definition.DefaultValue, parsedDate) Then dt.Value = parsedDate
                Return dt
            Case UdfDataType.Boolean
                Dim chk As New CheckBox() With {.Text = "Activo"}
                Dim parsedBool As Boolean
                If Boolean.TryParse(definition.DefaultValue, parsedBool) Then chk.Checked = parsedBool
                Return chk
            Case Else
                Return New TextBox() With {.Text = definition.DefaultValue}
        End Select
    End Function
End Class
