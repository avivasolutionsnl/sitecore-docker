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
    public readonly string XpSitecoreVersion = "9.0.2";

    [Parameter("Docker image prefix for Sitecore XP")]
    public readonly string XpImagePrefix = "sitecore-xp-";
    
    private string XpFullImageName(string name) => string.IsNullOrEmpty(BuildVersion) ? 
    $"{RepoImagePrefix}/{XpImageName(name)}" :
    $"{RepoImagePrefix}/{XpImageName(name)}-{BuildVersion}";
    private string XpImageName(string name) => $"{XpImagePrefix}{name}:{XpSitecoreVersion}";

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
    [Parameter("Solr port")]
    readonly string SOLR_PORT = "8983";
    [Parameter("Xconnect site name")]
    readonly string XCONNECT_SITE_NAME = "xconnect";
    [Parameter("Xconnect Solr core prefix")]
    readonly string XCONNECT_SOLR_CORE_PREFIX = "xp0";
    [Parameter("Sitecore Solr core prefix")]
    readonly string SITECORE_SOLR_CORE_PREFIX = "sitecore";

    public AbsolutePath XpLicenseFile = RootDirectory / "xp" / "license" / "license.xml";

    Target XpMssql => _ => _
        .Executes(() =>
        {
            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xp/mssql/Dockerfile")
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
        .DependsOn(BaseSitecore)
        .Executes(() =>
        {
            var baseImage = BaseImageName("sitecore");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xp/sitecore/Dockerfile")
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
    
    Target XpSolr => _ => _
        .DependsOn(BaseOpenJdk, BaseSolrBuilder)
        .Executes(() =>
        {
            var baseImage = BaseImageName("openjdk");
            var builderBaseImage = BaseImageName("solr-builder");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xp/solr/Dockerfile")
                .SetTag(XpImageName("solr"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"BUILDER_BASE_IMAGE={builderBaseImage}",
                    $"XCONNECT_CORE_PREFIX={XCONNECT_SOLR_CORE_PREFIX}",
                    $"SITECORE_CORE_PREFIX={SITECORE_SOLR_CORE_PREFIX}",
                    $"XCONNECT_PACKAGE={XCONNECT_PACKAGE}"
                })
            );
        });

    Target XpXconnect => _ => _
        .DependsOn(BaseSitecore)
        .Executes(() =>
        {
            var baseImage = BaseImageName("sitecore");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xp/xconnect/Dockerfile")
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
        .DependsOn(Xp)
        .Executes(() => {
            var sifPackageFile = $"./Files/{COMMERCE_SIF_PACKAGE}";
            ControlFlow.Assert(File.Exists(sifPackageFile), "Cannot find {sifPackageFile}");

            System.IO.Directory.SetCurrentDirectory("xp");

            // Set env variables for docker-compose
            Environment.SetEnvironmentVariable("PSE_PACKAGE", $"{PSE_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("SXA_PACKAGE", $"{SXA_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("IMAGE_PREFIX", $"{RepoImagePrefix}{XpImagePrefix}", EnvironmentVariableTarget.Process);
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
                .SetTag(XpImageName("solr-sxa"))
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
        .DependsOn(XpSitecoreMssqlSxa, XpSolrSxa);

    Target PushXp => _ => _
        .Requires(() => !string.IsNullOrEmpty(RepoImagePrefix))
        .Executes(() => {
            PushXpImage("mssql");
            PushXpImage("sitecore");
            PushXpImage("solr");
            PushXpImage("xconnect");
        });
    
    Target PushXpSxa => _ => _
        .Requires(() => !string.IsNullOrEmpty(RepoImagePrefix))
        .Executes(() => {
            PushXpImage("mssql-sxa");
            PushXpImage("sitecore-sxa");
            PushXpImage("solr-sxa");
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
