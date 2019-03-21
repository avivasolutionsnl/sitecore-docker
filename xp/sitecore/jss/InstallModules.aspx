<%@ Assembly Name="Sitecore.Client" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="log4net" %>
<%@ Import Namespace="Sitecore.Data.Engines" %>
<%@ Import Namespace="Sitecore.Data.Proxies" %>
<%@ Import Namespace="Sitecore.Install.Files" %>
<%@ Import Namespace="Sitecore.Install.Utils" %>
<%@ Import Namespace="Sitecore.SecurityModel" %>
<%@ Import Namespace="Sitecore.Web" %>
<%@ Import Namespace="Sitecore.Install.Framework" %>
<%@ Import Namespace="Sitecore.Install.Items" %>
<%@ Import Namespace="Sitecore.Install" %>
<%@ Import Namespace="Sitecore.Install.Security" %>

<%@  Language="C#" Debug="true" %>
<html>
<script runat="server" language="C#">
    public class DummyAccountInstallerEvents : IAccountInstallerEvents
    {
        public void ShowWarning(string message, string warningType)
        {
        }
    }

    public void Page_Load(object sender, EventArgs e)
    {
        var files = WebUtil.GetQueryString("modules").Split('|');
        if (files.Length == 0)
        {
            Response.Write("No Modules specified");
            return;
        }
        Sitecore.Context.SetActiveSite("shell");
        using (new SecurityDisabler())
        {
            using (new SyncOperationContext())
            {
                foreach (var file in files)
                {
                    Install(Path.Combine(Sitecore.Shell.Applications.Install.ApplicationContext.PackagePath, file));
                    Response.Write("Installed Package: " + file + "<br>");
                }
            }
        }
    }

    protected static string Install(string package)
    {
        var log = LogManager.GetLogger("LogFileAppender");
        string result = string.Empty;

        /*** Custom modification of script that also import the user accounts in the package ****/ 
        IProcessingContext accountContext = new SimpleProcessingContext();
        IAccountInstallerEvents accountEvents = new DummyAccountInstallerEvents();
        accountContext.AddAspect<IAccountInstallerEvents>(accountEvents);
        
        new Installer().InstallSecurity(package, accountContext);
        /*** End of custom modification ****/ 

        IProcessingContext context = new SimpleProcessingContext();
        IItemInstallerEvents instance = new DefaultItemInstallerEvents(new BehaviourOptions(InstallMode.Merge, MergeMode.Merge));
        context.AddAspect<IItemInstallerEvents>(instance);
        IFileInstallerEvents events = new DefaultFileInstallerEvents(true);
        context.AddAspect<IFileInstallerEvents>(events);

        new Installer().InstallPackage(package, context);

        // Execute Post Step
        string action = Installer.GetPostStep(context);
        new Installer().ExecutePostStep(action, context);

        return result;
    }

    protected String GetTime()
    {
        return DateTime.Now.ToString("t");
    }
</script>
<body>
    <form id="MyForm" runat="server">
        <div>
            This page installs packages from \data\packages folder.
        </div>
        Current server time is
   
        <% =GetTime()%>
    </form>
</body>
</html>
