using System;
using System.IO;
using System.Linq;
using Nuke.Common;
using Nuke.Common.ProjectModel;
using static Nuke.Common.EnvironmentInfo;
using static Nuke.Common.IO.FileSystemTasks;
using static Nuke.Common.IO.PathConstruction;
using static Nuke.Docker.DockerTasks;
using Nuke.Docker;
using Nuke.Common.Tooling;

partial class Build : NukeBuild
{
    [Parameter("Docker image sitecore version")]
    public readonly string XpSitecoreVersion = "9.1.1";

    [Parameter("Docker image prefix for Sitecore XP")]
    public readonly string XpImagePrefix = "sitecore-xp-";
    
    private string XpFullImageName(string name) => string.IsNullOrEmpty(BuildVersion) ? 
    $"{RepoImagePrefix}/{XpImageName(name)}" :
    $"{RepoImagePrefix}/{XpImageName(name)}-{BuildVersion}";
    private string XpImageName(string name) => $"{XpImagePrefix}{name}:{XpSitecoreVersion}";

    // Packages
    [Parameter("Sitecore XPO configuration package")]
    readonly string CONFIG_PACKAGE = "XP0 Configuration files 9.1.1 rev. 002459.zip";
    [Parameter("Sitecore package")]
    readonly string SITECORE_PACKAGE = "Sitecore 9.1.1 rev. 002459 (OnPrem)_single.scwdp.zip";
    
    [Parameter("Sitecore XConnect package")]
    readonly string XCONNECT_PACKAGE = "Sitecore 9.1.1 rev. 002459 (OnPrem)_xp0xconnect.scwdp.zip";
    
    [Parameter("Identity Server Package")]
    readonly string IDENTITYSERVER_PACKAGE = "Sitecore.IdentityServer 2.0.1 rev. 00166 (OnPrem)_identityserver.scwdp.zip";
    
    [Parameter("Powershell Extension package")]
    readonly string PSE_PACKAGE = "Sitecore PowerShell Extensions-5.0.zip";
    
    [Parameter("SXA package")]
    readonly string SXA_PACKAGE = "Sitecore Experience Accelerator 1.8.1 rev. 190319 for 9.1.1.zip";
        
    [Parameter("JSS package")]
    readonly string JSS_PACKAGE = "Sitecore JavaScript Services Server for Sitecore 9.1.1 XP 11.0.1 rev. 190318.zip";

    // Build configuration parameters
    [Parameter("SQL password")]
    readonly string SQL_SA_PASSWORD = "my_Sup3rSecret!!";
    [Parameter("SQL db prefix")]
    readonly string SQL_DB_PREFIX = "Sitecore";
    [Parameter("Solr port")]
    readonly string SOLR_PORT = "8983";
    [Parameter("Xconnect site name")]
    readonly string XCONNECT_SITE_NAME = "xconnect";
    [Parameter("Identity server site name")]
    readonly string IDENTITY_SITE_NAME = "identity";
    [Parameter("Xconnect Solr core prefix")]
    readonly string XCONNECT_SOLR_CORE_PREFIX = "xp0";
    [Parameter("Sitecore Solr core prefix")]
    readonly string SITECORE_SOLR_CORE_PREFIX = "sitecore";

    public AbsolutePath XpLicenseFile = RootDirectory / "xp" / "license" / "license.xml";

    Target XpMssql => _ => _
        .Requires(() => File.Exists(Files / SITECORE_PACKAGE))
        .Requires(() => File.Exists(Files / XCONNECT_PACKAGE))
        .Executes(() =>
        {
            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xp/mssql/Dockerfile")
                .SetIsolation("process")
                .SetTag(XpImageName("mssql"))
                .SetMemory(4000000000) // 4GB, SQL needs some more memory
                .SetBuildArg(new string[] {
                    $"DB_PREFIX={SQL_DB_PREFIX}",
                    $"SITECORE_PACKAGE={SITECORE_PACKAGE}",
                    $"XCONNECT_PACKAGE={XCONNECT_PACKAGE}",
                    $"HOST_NAME=mssql"
                })
            );
        });

    Target XpSitecore => _ => _
        .Requires(() => File.Exists(Files / SITECORE_PACKAGE))
        .Requires(() => File.Exists(Files / CONFIG_PACKAGE))
        .DependsOn(BaseSitecore)
        .Executes(() =>
        {
            var baseImage = BaseImageName("sitecore");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xp/sitecore/Dockerfile")
                .SetIsolation("process")
                .SetTag(XpImageName("sitecore"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"SQL_SA_PASSWORD={SQL_SA_PASSWORD}",
                    $"SQL_DB_PREFIX={SQL_DB_PREFIX}",
                    $"SOLR_PORT={SOLR_PORT}",
                    $"SITECORE_PACKAGE={SITECORE_PACKAGE}",
                    $"CONFIG_PACKAGE={CONFIG_PACKAGE}",
                    $"SITECORE_CORE_PREFIX={SITECORE_SOLR_CORE_PREFIX}"
                })
            );
        });
    
    Target XpIdentity => _ => _
        .Executes(() =>
        {
            var baseImage = BaseImageName("sitecore");

             DockerBuild(x => x
                .SetPath(".")
                .SetFile("xp/identityserver/Dockerfile")
                .SetIsolation("process")
                .SetTag(XpImageName("identity"))
                .SetBuildArg(new string[]{
                    $"BASE_IMAGE={baseImage}",
                    $"SQL_SA_PASSWORD={SQL_SA_PASSWORD}",
                    $"SQL_DB_PREFIX={SQL_DB_PREFIX}",
                    $"SQL_SERVER=mssql",
                    $"SITE_NAME={IDENTITY_SITE_NAME}",
                    $"IDENTITYSERVER_PACKAGE={IDENTITYSERVER_PACKAGE}",
                    $"CONFIG_PACKAGE={CONFIG_PACKAGE}"
                })
            );
        });

    Target XpSolr => _ => _
        .Requires(() => File.Exists(Files / XCONNECT_PACKAGE))
        .DependsOn(BaseOpenJdk, BaseSolrBuilder)
        .Executes(() =>
        {
            var baseImage = BaseImageName("openjdk");
            var builderBaseImage = BaseImageName("solr-builder");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xp/solr/Dockerfile")
                .SetIsolation("process")
                .SetTag(XpImageName("solr"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"BUILDER_BASE_IMAGE={builderBaseImage}",
                    $"XCONNECT_CORE_PREFIX={XCONNECT_SOLR_CORE_PREFIX}",
                    $"SITECORE_CORE_PREFIX={SITECORE_SOLR_CORE_PREFIX}",
                    $"XCONNECT_PACKAGE={XCONNECT_PACKAGE}",
                    $"CONFIG_PACKAGE={CONFIG_PACKAGE}"                    
                })
            );
        });

    Target XpXconnect => _ => _
        .Requires(() => File.Exists(Files / XCONNECT_PACKAGE))
        .Requires(() => File.Exists(Files / CONFIG_PACKAGE))
        .DependsOn(BaseSitecore)
        .Executes(() =>
        {
            var baseImage = BaseImageName("sitecore");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xp/xconnect/Dockerfile")
                .SetIsolation("process")
                .SetTag(XpImageName("xconnect"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"SQL_SA_PASSWORD={SQL_SA_PASSWORD}",
                    $"SQL_DB_PREFIX={SQL_DB_PREFIX}",
                    $"SITE_NAME={XCONNECT_SITE_NAME}",
                    $"SOLR_CORE_PREFIX={XCONNECT_SOLR_CORE_PREFIX}",
                    $"SOLR_PORT={SOLR_PORT}",
                    $"XCONNECT_PACKAGE={XCONNECT_PACKAGE}",
                    $"CONFIG_PACKAGE={CONFIG_PACKAGE}"
                })
            );
        });
    
    Target XpSitecoreMssqlSxa => _ => _
        .Requires(() => File.Exists(XpLicenseFile))
        .Requires(() => File.Exists(Files / PSE_PACKAGE))
        .Requires(() => File.Exists(Files / SXA_PACKAGE))
        .DependsOn(Xp)
        .Executes(() => {
            System.IO.Directory.SetCurrentDirectory("xp");

            // Set env variables for docker-compose
            Environment.SetEnvironmentVariable("PSE_PACKAGE", $"{PSE_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("SXA_PACKAGE", $"{SXA_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("IMAGE_PREFIX", $"{XpImagePrefix}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("TAG", $"{XpSitecoreVersion}", EnvironmentVariableTarget.Process);

            InstallSitecorePackage(
                @"C:\sxa\InstallSXA.ps1",
                XpImageName("sitecore-sxa"),
                XpImageName("mssql-sxa"),
                "-f docker-compose.yml -f docker-compose.sxa.yml"
            );

            System.IO.Directory.SetCurrentDirectory("..");
        });

    Target XpSolrSxa => _ => _
        .DependsOn(BaseSolrBuilder, XpSolr)
        .Executes(() => {
            var baseImage = XpImageName("solr");
            var builderBaseImage = BaseImageName("solr-builder");

            DockerBuild(x => x
                .SetPath("xp/solr/sxa")
                .SetIsolation("process")
                .SetTag(XpImageName("solr-sxa"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"BUILDER_BASE_IMAGE={builderBaseImage}",
                    $"SITECORE_CORE_PREFIX={SITECORE_SOLR_CORE_PREFIX}"
                })
            );
        });

    Target XpSitecoreMssqlJss => _ => _
        .Requires(() => File.Exists(Files / COMMERCE_SIF_PACKAGE))
        .Requires(() => File.Exists(Files / JSS_PACKAGE))
        .DependsOn(Xp)
        .Executes(() => {
            System.IO.Directory.SetCurrentDirectory("xp");

            // Set env variables for docker-compose
            Environment.SetEnvironmentVariable("JSS_PACKAGE", $"{JSS_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("IMAGE_PREFIX", $"{XpImagePrefix}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("TAG", $"{XpSitecoreVersion}", EnvironmentVariableTarget.Process);

            InstallSitecorePackage(
                @"C:\jss\InstallJSS.ps1",
                XpImageName("sitecore-jss"),
                XpImageName("mssql-jss"),
                "-f docker-compose.yml -f docker-compose.jss.yml"
            );

            System.IO.Directory.SetCurrentDirectory("..");
        });        

    Target Xp => _ => _
        .DependsOn(XpMssql, XpSitecore, XpSolr, XpXconnect, XpIdentity);

    Target XpSxa => _ => _
        .DependsOn(XpSitecoreMssqlSxa, XpSolrSxa);

    Target XpJss => _ => _
        .DependsOn(XpSitecoreMssqlJss);

    Target PushXp => _ => _
        .Requires(() => !string.IsNullOrEmpty(RepoImagePrefix))
        .OnlyWhenDynamic(() => HasGitTag() || ForcePush)
        .Executes(() => {
            PushXpImage("mssql");
            PushXpImage("sitecore");
            PushXpImage("solr");
            PushXpImage("xconnect");
        });
    
    Target PushXpSxa => _ => _
        .Requires(() => !string.IsNullOrEmpty(RepoImagePrefix))
        .OnlyWhenDynamic(() => HasGitTag() || ForcePush)
        .Executes(() => {
            PushXpImage("mssql-sxa");
            PushXpImage("sitecore-sxa");
            PushXpImage("solr-sxa");
        });

    Target PushXpJss => _ => _
        .Requires(() => !string.IsNullOrEmpty(RepoImagePrefix))
        .OnlyWhenDynamic(() => HasGitTag() || ForcePush)
        .Executes(() => {
            PushXpImage("mssql-jss");
            PushXpImage("sitecore-jss");
        });     

    private void PushXpImage(string name)
    {
        var source = XpImageName(name);
        var target = XpFullImageName(name);
        DockerTasks.DockerImageTag(x => x
        .SetSourceImage(source)
        .SetTargetImage(target));

        DockerTasks.DockerImagePush(x => x.SetName(target));
    }
}
