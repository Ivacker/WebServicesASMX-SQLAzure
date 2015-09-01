'by @Ivacker
'31-08-2015
'
'

Imports System.Web.Services
Imports System.Web.Services.Protocols
Imports System.ComponentModel
' Para permitir que se llame a este servicio web desde un script, usando ASP.NET AJAX, quite la marca de comentario de la línea siguiente.
' <System.Web.Script.Services.ScriptService()> _
<System.Web.Services.WebService(Namespace:="http://ivacker.cl/", Description:="WebServices para conectar a un catalogo SQL-Azure, que contiene WordPress - by @ivacker", Name:="ws-SQLAzure-WP")>
<System.Web.Services.WebServiceBinding(ConformsTo:=WsiProfiles.BasicProfile1_1)> _
<ToolboxItem(False)> _
Public Class WebService1
    Inherits System.Web.Services.WebService

    'Datos del servidor, catalogo y usuarios
    Dim sServidor As String = "j74fgsmi82.database.windows.net"
    Dim sCatalogo As String = "WPAzure"
    Dim sUsuario As String = "UsuarioPrueba01@j74fgsmi82"
    Dim sClave As String = "Laclave01"

    'Creo la cadena de conexion al servidor SQL-Azure
    Dim sConnectionString As String = "Server=tcp:" & sServidor & ",1433;Database=" & sCatalogo & ";User ID=" & sUsuario & ";Password=" & sClave & ";Trusted_Connection=False;Encrypt=True;Connection Timeout=30;"


    <WebMethod(Description:="Ejecuta el comando SQL y retorna los resultado bajo un DataSet")>
    Public Function es_Data_EjecutaSQLComando(ByVal sQuery As String) As DataSet

        Dim dbConnection As System.Data.IDbConnection = New System.Data.SqlClient.SqlConnection(sConnectionString)
        Dim queryString As String = sQuery
        Dim miAdaptador As New System.Data.SqlClient.SqlDataAdapter(queryString, sConnectionString)
        Dim ds As New DataSet

        Try
            miAdaptador.Fill(ds)
            dbConnection.Close()
            dbConnection.Dispose()

            If ds.Tables(0).Rows.Count > 0 Then
                Return ds
            End If

        Catch ex As DataException
            'Controlar el error
        Finally
            miAdaptador.Dispose()
            dbConnection.Close()
            dbConnection.Dispose()
            GC.Collect()
        End Try

    End Function

    <WebMethod()>
    Public Function HelloWorld() As String
        Return "Hola a todos " & Now
    End Function

End Class