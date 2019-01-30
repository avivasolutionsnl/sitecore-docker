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
    // Docker image naming
    [Parameter("Docker image prefix for Sitecore XC")]
    readonly string XcImagePrefix = "sitecore-xc-";

    [Parameter("Docker image version tag for Sitecore XC")]
    readonly string XcVersion = "9.0.3";

    private string XcFullImageName(string name) => $"{RepoImagePrefix}{XcImagePrefix}{name}:{XcVersion}";

    // Packages
    [Parameter("Sitecore Identity server package")]
    readonly string SITECORE_IDENTITY_PACKAGE = "Sitecore.IdentityServer.1.4.2.zip";

    [Parameter("Sitecore BizFx package")]
    readonly string SITECORE_BIZFX_PACKAGE = "Sitecore.BizFX.1.4.1.zip";

    [Parameter("Commerce Engine package")]
    readonly string COMMERCE_ENGINE_PACKAGE = "Sitecore.Commerce.Engine.2.4.63.zip";

    [Parameter("Commerce Connect package")]
    readonly string COMMERCE_CONNECT_PACKAGE = "Sitecore Commerce Connect Core 11.4.15.zip";

    [Parameter("Commerce Connect Engine package")]
    readonly string COMMERCE_CONNECT_ENGINE_PACKAGE = "Sitecore.Commerce.Engine.Connect.2.4.32.update";

    [Parameter("Commerce Marketing Automation package")]
    readonly string COMMERCE_MA_PACKAGE = "Sitecore Commerce Marketing Automation Core 11.4.15.zip";

    [Parameter("Commerce Marketing Automation for AutomationEngine package")]
    readonly string COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE = "Sitecore Commerce Marketing Automation for AutomationEngine 11.4.15.zip";

    [Parameter("Commerce SIF package")]
    readonly string COMMERCE_SIF_PACKAGE = "SIF.Sitecore.Commerce.1.4.7.zip";

    [Parameter("Commerce SDK package")]
    readonly string COMMERCE_SDK_PACKAGE = "Sitecore.Commerce.Engine.SDK.2.4.43.zip";

    [Parameter("Commerce XP Core package")]
    readonly string COMMERCE_XPROFILES_PACKAGE = "Sitecore Commerce ExperienceProfile Core 11.4.15.zip";

    [Parameter("Commerce XP Analytics Core package")]
    readonly string COMMERCE_XANALYTICS_PACKAGE = "Sitecore Commerce ExperienceAnalytics Core 11.4.15.zip";

    [Parameter("SXA Commerce package")]
    readonly string SCXA_PACKAGE = "Sitecore Commerce Experience Accelerator 1.4.150.zip";

    [Parameter("Web transform tool")]
    readonly string WEB_TRANSFORM_TOOL = "Microsoft.Web.XmlTransform.dll";

    [Parameter("Plumber package")]
    readonly string PLUMBER_FILE_NAME = "plumber.zip";

    // Certificates
    [Parameter("Commerce certificate file")]
    readonly string COMMERCE_CERT_PATH = "commerce.pfx";

    [Parameter("Root certificate file")]
    readonly string ROOT_CERT_PATH = "root.pfx";

    [Parameter("Sitecore certificate file")]
    readonly string SITECORE_CERT_PATH = "sitecore.pfx";

    [Parameter("Solr certificate file")]
    readonly string SOLR_CERT_PATH = "solr.pfx";

    [Parameter("Xconnect certificate file")]
    readonly string XCONNECT_CERT_PATH = "xConnect.pfx";

    // Build configuration parameters
    [Parameter("Commerce shop name")]
    readonly string SHOP_NAME = "CommerceEngineDefaultStorefront";

    [Parameter("Commerce environment name")]
    readonly string ENVIRONMENT_NAME = "HabitatAuthoring";

    [Parameter("Commerce database prefix")]    
    readonly string COMMERCE_DB_PREFIX = "SitecoreCommerce9";

    Target XcCommerce => _ => _
        .Executes(() =>
        {
            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xc/commerce/Dockerfile")
                .SetTag(XcFullImageName("commerce"))
                .SetBuildArg(new string[] {
                    $"SQL_SA_PASSWORD={SQL_SA_PASSWORD}",
                    $"SQL_DB_PREFIX={SQL_DB_PREFIX}",
                    $"SOLR_PORT={SOLR_PORT}",  
                    $"SHOP_NAME={SHOP_NAME}",
                    $"ENVIRONMENT_NAME={ENVIRONMENT_NAME}",
                    $"COMMERCE_SIF_PACKAGE={COMMERCE_SIF_PACKAGE}",
                    $"COMMERCE_SDK_PACKAGE={COMMERCE_SDK_PACKAGE}",
                    $"SITECORE_BIZFX_PACKAGE={SITECORE_BIZFX_PACKAGE}",
                    $"SITECORE_IDENTITY_PACKAGE={SITECORE_IDENTITY_PACKAGE}",
                    $"COMMERCE_ENGINE_PACKAGE={COMMERCE_ENGINE_PACKAGE}",
                    $"COMMERCE_CERT_PATH={COMMERCE_CERT_PATH}",
                    $"ROOT_CERT_PATH={ROOT_CERT_PATH}",
                    $"SITECORE_CERT_PATH={SITECORE_CERT_PATH}",
                    $"SOLR_CERT_PATH={SOLR_CERT_PATH}",
                    $"XCONNECT_CERT_PATH={XCONNECT_CERT_PATH}",
                    $"PLUMBER_FILE_NAME={PLUMBER_FILE_NAME}"
                })
            );
        });

    Target XcMssql => _ => _
        .DependsOn(XpMssql)
        .Executes(() =>
        {
            var baseImage = XpFullImageName("mssql");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xc/mssql/Dockerfile")
                .SetTag(XcFullImageName("mssql"))
                .SetMemory(4000000000) // 4GB, SQL needs some more memory
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"COMMERCE_DB_PREFIX={COMMERCE_DB_PREFIX}",
                    $"COMMERCE_SDK_PACKAGE={COMMERCE_SDK_PACKAGE}"
                })
            );
        });

    Target XcSitecoreBase => _ => _
        .DependsOn(XpSitecore)
        .Executes(() =>
        {
            var baseImage = XpFullImageName("sitecore");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xc/sitecore/Dockerfile")
                .SetTag(XcFullImageName("sitecore"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"COMMERCE_CERT_PATH={COMMERCE_CERT_PATH}",
                    $"COMMERCE_CONNECT_PACKAGE={COMMERCE_CONNECT_PACKAGE}",
                    $"WEB_TRANSFORM_TOOL={WEB_TRANSFORM_TOOL}",
                    $"COMMERCE_CONNECT_ENGINE_PACKAGE={COMMERCE_CONNECT_ENGINE_PACKAGE}",
                    $"COMMERCE_SIF_PACKAGE={COMMERCE_SIF_PACKAGE}",
                    $"COMMERCE_MA_PACKAGE={COMMERCE_MA_PACKAGE}",
                    $"COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE={COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE}",
                    $"COMMERCE_XPROFILES_PACKAGE={COMMERCE_XPROFILES_PACKAGE}",
                    $"COMMERCE_XANALYTICS_PACKAGE={COMMERCE_XANALYTICS_PACKAGE}",
                    $"ROOT_CERT_PATH={ROOT_CERT_PATH}"
                })
            );
        });

    Target XcSitecore => _ => _
        .DependsOn(XcCommerce, XcMssql, XcSitecoreBase, XcSolr, XcXconnect)
        .Executes(() => {
            System.IO.Directory.SetCurrentDirectory("xc");

            // Setup
            System.IO.Directory.CreateDirectory(@"wwwroot/commerce");
            System.IO.Directory.CreateDirectory(@"wwwroot/sitecore");
            Powershell("../CreateLogDirs.ps1");

            InstallSitecorePackage(
                @"C:\Scripts\InstallCommercePackages.ps1", 
                XcFullImageName("sitecore"), 
                XcFullImageName("mssql")
            );
        });
    
    Target XcSolr => _ => _
        .DependsOn(XpSolr)
        .Executes(() =>
        {
            var baseImage = XpFullImageName("solr");
            var builderBaseImage = BaseFullImageName("solr-builder");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xc/solr/Dockerfile")
                .SetTag(XcFullImageName("solr"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"BUILDER_BASE_IMAGE={builderBaseImage}",
                    $"SITECORE_CORE_PREFIX={SITECORE_SOLR_CORE_PREFIX}",
                    $"COMMERCE_SIF_PACKAGE={COMMERCE_SIF_PACKAGE}"
                })
            );
        });

    Target XcXconnect => _ => _
        .DependsOn(XpXconnect)
        .Executes(() =>
        {
            var baseImage = XpFullImageName("xconnect");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xc/xconnect/Dockerfile")
                .SetTag(XcFullImageName("xconnect"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE={COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE}"
                })
            );
        });

    Target XcSitecoreSxa => _ => _
        .DependsOn(XcSitecore, XcSolrSxa)
        .Executes(() => {
            System.IO.Directory.SetCurrentDirectory("xc");

            // Setup
            System.IO.Directory.CreateDirectory(@"wwwroot/commerce");
            System.IO.Directory.CreateDirectory(@"wwwroot/sitecore");
            Powershell("../CreateLogDirs.ps1");

            // Set env variables for docker-compose
            Environment.SetEnvironmentVariable("PSE_PACKAGE", $"{PSE_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("SXA_PACKAGE", $"{SXA_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("SCXA_PACKAGE", $"{SCXA_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("IMAGE_PREFIX", $"{XcImagePrefix}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("TAG", $"{XcVersion}", EnvironmentVariableTarget.Process);

            InstallSitecorePackage(
                @"C:\sxa\InstallSXA.ps1",
                XcFullImageName("sitecore-sxa"), 
                XcFullImageName("mssql-sxa"),
                "-f docker-compose.yml -f docker-compose.build-sxa.yml"
            );
        });

    Target XcSolrSxa => _ => _
        .DependsOn(XcSolr)
        .Executes(() => {
            var baseImage = XcFullImageName("solr");
            var builderBaseImage = BaseFullImageName("solr-builder");

            DockerBuild(x => x
                .SetPath("xc/solr/sxa")
                .SetTag(XcFullImageName("solr-sxa"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"BUILDER_BASE_IMAGE={builderBaseImage}",
                    $"SITECORE_CORE_PREFIX={SITECORE_SOLR_CORE_PREFIX}"
                })
            );
        });

    Target Xc => _ => _
        .DependsOn(XcCommerce, XcMssql, XcSitecore, XcSolr, XcXconnect);

    Target XcSxa => _ => _
        .DependsOn(Xc, XcSitecoreSxa, XcSolrSxa);

    Target PushXc => _ => _
        .DependsOn(Xc)
        .Executes(() => {
            DockerPush(x => x.SetName(XcFullImageName("commerce")));
            DockerPush(x => x.SetName(XcFullImageName("mssql")));
            DockerPush(x => x.SetName(XcFullImageName("sitecore")));
            DockerPush(x => x.SetName(XcFullImageName("solr")));
            DockerPush(x => x.SetName(XcFullImageName("xconnect")));
        });
    
    Target PushXcSxa => _ => _
        .DependsOn(XcSxa)
        .Executes(() => {
            DockerPush(x => x.SetName(XcFullImageName("mssql-sxa")));
            DockerPush(x => x.SetName(XcFullImageName("sitecore-sxa")));
            DockerPush(x => x.SetName(XcFullImageName("solr-sxa")));
        });
}
