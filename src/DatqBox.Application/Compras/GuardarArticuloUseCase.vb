Imports DatqBox.Application.Abstractions
Imports System.Data

Namespace DatqBox.Application.Compras
    Public Class GuardarArticuloUseCase
        Private ReadOnly _sql As ISqlExecutor

        Public Sub New(sql As ISqlExecutor)
            _sql = sql
        End Sub

        Public Function Actualizar(datos As ArticuloDatos) As Integer
            Dim query As String =
                "UPDATE Inventario SET " &
                "BARRA = @Barra, REFERENCIA = @Referencia, DESCRIPCION = @Descripcion, " &
                "CATEGORIA = @Categoria, LINEA = @Linea, MARCA = @Marca, TIPO = @Tipo, CLASE = @Clase, " &
                "PRECIO_COMPRA = @PrecioCosto, PRECIO_VENTA = @PrecioVenta, " &
                "PRECIO_VENTA1 = @PrecioVenta1, PRECIO_VENTA2 = @PrecioVenta2, PRECIO_VENTA3 = @PrecioVenta3, " &
                "PORCENTAJE = @Porc, PORCENTAJE1 = @Porc1, PORCENTAJE2 = @Porc2, PORCENTAJE3 = @Porc3, " &
                "UNIDAD = @Unidad, ALICUOTA = @Alicuota, " &
                "MINIMO = @Minimo, MAXIMO = @Maximo, UBICACION = @Ubicacion " &
                "WHERE CODIGO = @Codigo"

            Return _sql.Execute(query, BuildParameters(datos))
        End Function

        Public Function Insertar(datos As ArticuloDatos) As Integer
            Dim query As String =
                "INSERT INTO Inventario " &
                "(CODIGO, BARRA, REFERENCIA, DESCRIPCION, CATEGORIA, LINEA, MARCA, TIPO, CLASE, " &
                "PRECIO_COMPRA, PRECIO_VENTA, PRECIO_VENTA1, PRECIO_VENTA2, PRECIO_VENTA3, " &
                "PORCENTAJE, PORCENTAJE1, PORCENTAJE2, PORCENTAJE3, " &
                "UNIDAD, ALICUOTA, MINIMO, MAXIMO, UBICACION, EXISTENCIA, Eliminado) " &
                "VALUES (@Codigo, @Barra, @Referencia, @Descripcion, @Categoria, @Linea, @Marca, @Tipo, @Clase, " &
                "@PrecioCosto, @PrecioVenta, @PrecioVenta1, @PrecioVenta2, @PrecioVenta3, " &
                "@Porc, @Porc1, @Porc2, @Porc3, " &
                "@Unidad, @Alicuota, @Minimo, @Maximo, @Ubicacion, 0, 0)"

            Return _sql.Execute(query, BuildParameters(datos))
        End Function

        Public Function Eliminar(codigo As String) As Integer
            Return _sql.Execute(
                "UPDATE Inventario SET Eliminado = 1 WHERE CODIGO = @Codigo",
                New Dictionary(Of String, Object) From {{"@Codigo", codigo}})
        End Function

        Private Shared Function BuildParameters(d As ArticuloDatos) As Dictionary(Of String, Object)
            Return New Dictionary(Of String, Object) From {
                {"@Codigo", d.Codigo},
                {"@Barra", d.Barra},
                {"@Referencia", d.Referencia},
                {"@Descripcion", d.Descripcion},
                {"@Categoria", d.Categoria},
                {"@Linea", d.Linea},
                {"@Marca", d.Marca},
                {"@Tipo", d.Tipo},
                {"@Clase", d.Clase},
                {"@PrecioCosto", d.PrecioCosto},
                {"@PrecioVenta", d.PrecioVenta},
                {"@PrecioVenta1", d.PrecioVenta1},
                {"@PrecioVenta2", d.PrecioVenta2},
                {"@PrecioVenta3", d.PrecioVenta3},
                {"@Porc", d.Porcentaje},
                {"@Porc1", d.Porcentaje1},
                {"@Porc2", d.Porcentaje2},
                {"@Porc3", d.Porcentaje3},
                {"@Unidad", d.Unidad},
                {"@Alicuota", d.Alicuota},
                {"@Minimo", d.Minimo},
                {"@Maximo", d.Maximo},
                {"@Ubicacion", d.Ubicacion}
            }
        End Function
    End Class

    Public Class ArticuloDatos
        Public Property Codigo As String = String.Empty
        Public Property Barra As String = String.Empty
        Public Property Referencia As String = String.Empty
        Public Property Descripcion As String = String.Empty
        Public Property Categoria As String = String.Empty
        Public Property Linea As String = String.Empty
        Public Property Marca As String = String.Empty
        Public Property Tipo As String = String.Empty
        Public Property Clase As String = String.Empty
        Public Property PrecioCosto As Decimal
        Public Property PrecioVenta As Decimal
        Public Property PrecioVenta1 As Decimal
        Public Property PrecioVenta2 As Decimal
        Public Property PrecioVenta3 As Decimal
        Public Property Porcentaje As Decimal
        Public Property Porcentaje1 As Decimal
        Public Property Porcentaje2 As Decimal
        Public Property Porcentaje3 As Decimal
        Public Property Unidad As String = "UND"
        Public Property Alicuota As Decimal = 16
        Public Property Minimo As Decimal
        Public Property Maximo As Decimal
        Public Property Ubicacion As String = String.Empty
    End Class
End Namespace
