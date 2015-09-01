'@ivacker
'Aplicacion de Windows que consume WebServices para conectar a SQL-Azure, que utiliza un catalogo de WordPress
'31-08-2015

Public Class Form1

    Dim wsWP As New wsSQLAzureWordpress.wsSQLAzureWP
    Dim ds As New System.Data.DataSet

    Private Sub Button1_Click(sender As Object, e As EventArgs) Handles Button1.Click

        Try
            ds = wsWP.es_Data_EjecutaSQLComando("Select id, post_date, post_content, post_title, guid from WP_POSTS order by id desc")
            DataGridView1.DataSource = ds.Tables(0)
        Catch ex As Exception
            Debug.Print(ex.Message.ToString)
            'Manejar el error
        End Try

    End Sub

    Private Sub Form1_Load(sender As Object, e As EventArgs) Handles Me.Load
        Me.Text = "@ivacker - Ejemplo consume WebServices - " & wsWP.Url.ToString
    End Sub
End Class
