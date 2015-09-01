Imports WebServices_SQLAzure.WebService1

Public Class WebForm1
    Inherits System.Web.UI.Page

    Dim wsWP As New WebServices_SQLAzure.WebService1 'LLamo la clase del WebServices
    Dim ds As New System.Data.DataSet 'Creo el objeto dataset que contendra el resultado de datos

    Protected Sub Button1_Click(sender As Object, e As EventArgs) Handles Button1.Click

        Try

            ds = wsWP.es_Data_EjecutaSQLComando("Select id, post_date, post_content, post_title, guid from WP_POSTS order by id desc")

            GridView1.DataSource = ds.Tables(0)
            GridView1.DataBind()

        Catch ex As Exception
            'Manejar el error
        End Try

    End Sub
End Class