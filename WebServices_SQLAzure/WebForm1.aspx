<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="WebForm1.aspx.vb" Inherits="WebServices_SQLAzure.WebForm1" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
    
        @ivacker<br />
        - WebForm de ejemplo que consume un web services asmx, que conecta a un catalogo SQL-Azure, el cual contiene WordPress.<br />
        <br />
        Haga click en el boton para ver los post publicados en el Blog de Wordpress.<br />
        <asp:Button ID="Button1" runat="server" Text="Ver Posts" />
        <br />
        <br />
        <asp:GridView ID="GridView1" runat="server">
        </asp:GridView>
    
    </div>
    </form>
</body>
</html>
