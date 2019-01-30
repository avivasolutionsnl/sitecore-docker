using System;
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
    [Parameter("Docker image prefix for Sitecore XP")]
    public readonly string XpImagePrefix = "sitecore-xp-";
    
    [Parameter("Docker image version tag for Sitecore XP")]
    readonly string XpVersion = "9.0.2";

    private string XpFullImageName(string name) => $"{RepoImagePrefix}{XpImagePrefix}{name}:{XpVersion}";

    // Packages
    [Parameter("Sitecore XPO configuration package")]
    readonly string CONFIG_PACKAGE = "XP0 Configuration files 9.0.2 rev. 180604.zip";
    [Parameter("Sitecore package")]
    readonly string SITECORE_PACKAGE = "Sitecore 9.0.2 rev. 180604 (OnPrem)_single.scwdp.zip";
    
    [Parameter("Sitecore XConnect package")]
    readonly string XCONNECT_PACKAGE = "Sitecore 9.0.2 rev. 180604 (OnPrem)_xp0xconnect.scwdp.zip";
    
    [Parameter("Powershell Extension package")]
    readonly string PSE_PACKAGE = "Sitecore PowerShell Extensions-5.0.zip";
    
    [Parameter("SXA package")]
    readonly string SXA_PACKAGE = "Sitecore Experience Accelerator 1.8 rev. 181112 for 9.0.zip";

    // Build configuration parameters
    [Parameter("SQL password")]
    readonly string SQL_SA_PASSWORD = "my_Sup3rSecret!!";
    [Parameter("SQL db prefix")]
    readonly string SQL_DB_PREFIX = "Sitecore";
    [Parameter("Solr hostname")]
    readonly string SOLR_HOST_NAME = "solr";
    [Parameter("Solr port")]
    readonly string SOLR_PORT = "8983";
    [Parameter("Solr service name")]
    readonly string SOLR_SERVICE_NAME = "Solr-6";
    [Parameter("Xconnect site name")]
    readonly string XCONNECT_SITE_NAME = "xconnect";
    [Parameter("Xconnect Solr core prefix")]
    readonly string XCONNECT_SOLR_CORE_PREFIX = "xp0";
    [Parameter("Sitecore Solr core prefix")]
    readonly string SITECORE_SOLR_CORE_PREFIX = "Sitecore";

    Target XpMssql => _ => _
        .Executes(() =>
        {
            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xp/mssql/Dockerfile")
                .SetTag(XpFullImageName("mssql"))
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
        .Executes(() =>
        {
            var baseImage = BaseFullImageName("sitecore");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xp/sitecore/Dockerfile")
                .SetTag(XpFullImageName("sitecore"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"SQL_SA_PASSWORD={SQL_SA_PASSWORD}",
                    $"SQL_DB_PREFIX={SQL_DB_PREFIX}",
                    $"SOLR_PORT={SOLR_PORT}",
                    $"SITECORE_PACKAGE={SITECORE_PACKAGE}",
                    $"CONFIG_PACKAGE={CONFIG_PACKAGE}"
                })
            );
        });
    
    Target XpSolr => _ => _
        .DependsOn(BaseOpenJdk, BaseSolrBuilder)
        .Executes(() =>
        {
            var baseImage = BaseFullImageName("openjdk");
            var builderBaseImage = BaseFullImageName("solr-builder");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xp/solr/Dockerfile")
                .SetTag(XpFullImageName("solr"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"BUILDER_BASE_IMAGE={builderBaseImage}",
                    $"XCONNECT_CORE_PREFIX={XCONNECT_SOLR_CORE_PREFIX}",
                    $"SITECORE_CORE_PREFIX={SITECORE_SOLR_CORE_PREFIX}"
                })
            );
        });

    Target XpXconnect => _ => _
        .Executes(() =>
        {
            var baseImage = BaseFullImageName("sitecore");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xp/xconnect/Dockerfile")
                .SetTag(XpFullImageName("xconnect"))
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
    
    Target XpSitecoreSxa => _ => _
        .DependsOn(Xp)
        .Executes(() => {
            System.IO.Directory.SetCurrentDirectory("xp");

            // Setup
            System.IO.Directory.CreateDirectory(@"wwwroot/sitecore");
            Powershell("../CreateLogDirs.ps1");

            // Set env variables for docker-compose
            Environment.SetEnvironmentVariable("PSE_PACKAGE", $"{PSE_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("SXA_PACKAGE", $"{SXA_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("IMAGE_PREFIX", $"{XpImagePrefix}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("TAG", $"{XpVersion}", EnvironmentVariableTarget.Process);

            InstallSitecorePackage(
                @"C:\sxa\InstallSXA.ps1",
                XpFullImageName("sitecore-sxa"),
                XpFullImageName("mssql-sxa"),
                "-f docker-compose.yml -f docker-compose.build-sxa.yml"
            );
        });

    Target XpSolrSxa => _ => _
        .DependsOn(XpSolr)
        .Executes(() => {
            var baseImage = XpFullImageName("solr");
            var builderBaseImage = BaseFullImageName("solr-builder");

            DockerBuild(x => x
                .SetPath("xp/solr/sxa")
                .SetTag(XpFullImageName("solr-sxa"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"BUILDER_BASE_IMAGE={builderBaseImage}",
                    $"SITECORE_CORE_PREFIX={SITECORE_SOLR_CORE_PREFIX}"
                })
            );
        });

    Target Xp => _ => _
        .DependsOn(XpMssql, XpSitecore, XpSolr, XpXconnect);

    Target XpSxa => _ => _
        .DependsOn(XpSitecoreSxa, XpSolrSxa);

    Target PushXp => _ => _
        .DependsOn(Xp)
        .Executes(() => {
            DockerPush(x => x.SetName(XpFullImageName("mssql")));
            DockerPush(x => x.SetName(XpFullImageName("sitecore")));
            DockerPush(x => x.SetName(XpFullImageName("solr")));
            DockerPush(x => x.SetName(XpFullImageName("xconnect")));
        });
    
    Target PushXpSxa => _ => _
        .DependsOn(XpSxa)
        .Executes(() => {
            DockerPush(x => x.SetName(XpFullImageName("mssql-sxa")));
            DockerPush(x => x.SetName(XpFullImageName("sitecore-sxa")));
            DockerPush(x => x.SetName(XpFullImageName("solr-sxa")));
        });
}
