Imports DatqBox.Application.Abstractions
Imports System.Data

Namespace DatqBox.Application.Compras
    Public Class ObtenerArticuloUseCase
        Private ReadOnly _sql As ISqlExecutor

        Public Sub New(sql As ISqlExecutor)
            _sql = sql
        End Sub

        Public Function ObtenerPorCodigo(codigo As String) As DataTable
            Return _sql.Query(
                "SELECT * FROM Inventario WHERE Codigo = @Codigo",
                New Dictionary(Of String, Object) From {{"@Codigo", codigo}})
        End Function

        Public Function ObtenerPorReferencia(referencia As String) As DataTable
            Return _sql.Query(
                "SELECT * FROM Inventario WHERE Referencia = @Ref",
                New Dictionary(Of String, Object) From {{"@Ref", referencia}})
        End Function

        Public Function BuscarArticulos(texto As String, Optional limite As Integer = 200) As DataTable
            Return _sql.Query(
                "SELECT TOP " & limite.ToString() &
                " Codigo, BARRA, Referencia, Descripcion, Categoria, Linea, Marca, Tipo, Clase, " &
                "Precio_Compra, Precio_Venta, Precio_Venta1, Precio_Venta2, Precio_Venta3, " &
                "Porcentaje, Porcentaje1, Porcentaje2, Porcentaje3, " &
                "Existencia, Unidad, Alicuota, Minimo, Maximo, Ubicacion " &
                "FROM Inventario WHERE Eliminado = 0 " &
                "AND (Codigo LIKE @Busq OR Descripcion LIKE @Busq OR Referencia LIKE @Busq OR Barra LIKE @Busq) " &
                "ORDER BY Descripcion",
                New Dictionary(Of String, Object) From {{"@Busq", "%" & texto & "%"}})
        End Function

        Public Function ListarTodos(Optional limite As Integer = 500) As DataTable
            Return _sql.Query(
                "SELECT TOP " & limite.ToString() &
                " Codigo, BARRA, Referencia, Descripcion, Categoria, Linea, Marca, Tipo, Clase, " &
                "Precio_Compra, Precio_Venta, Precio_Venta1, Precio_Venta2, Precio_Venta3, " &
                "Porcentaje, Existencia, Unidad, Alicuota, Minimo, Maximo, Ubicacion " &
                "FROM Inventario WHERE Eliminado = 0 ORDER BY Descripcion")
        End Function
    End Class
End Namespace
