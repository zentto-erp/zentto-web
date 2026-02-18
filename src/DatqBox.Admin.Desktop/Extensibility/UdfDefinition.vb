Public Enum UdfDataType
    Text = 0
    Number = 1
    [Date] = 2
    [Boolean] = 3
End Enum

Public Class UdfDefinition
    Public Property ReferenceId As Integer
    Public Property TableName As String
    Public Property FieldName As String
    Public Property Caption As String
    Public Property DataType As UdfDataType
    Public Property DefaultValue As String
End Class
