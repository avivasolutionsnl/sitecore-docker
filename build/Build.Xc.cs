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
using System.Collections.Generic;

partial class Build : NukeBuild
{
    [Parameter("Docker image sitecore version")]
    public readonly string XcSitecoreVersion = "9.2.0";
    // Docker image naming
    [Parameter("Docker image prefix for Sitecore XC")]
    readonly string XcImagePrefix = "sitecore-xc-";

    private string XcFullImageName(string name) => string.IsNullOrEmpty(BuildVersion) ? 
    $"{RepoImagePrefix}/{XcImageName(name)}" : 
    $"{RepoImagePrefix}/{XcImageName(name)}-{BuildVersion}";
    private string XcImageName(string name) => $"{XcNakedImageName(name)}:{XcSitecoreVersion}";
    private string XcNakedImageName(string name) => $"{XcImagePrefix}{name}";

    private IEnumerable<string> XcRepositoryNames => XcNames
        .Concat(XcJssNames)
        .Concat(XcSxaNames)
        .Select(XcNakedImageName);

    // Packages
    [Parameter("Sitecore BizFx package")]
    readonly string SITECORE_BIZFX_PACKAGE = "Sitecore.BizFx.OnPrem.3.0.7.scwdp.zip";

    [Parameter("Commerce Engine package")]
    // TODO Parameterize Commerce Search Provider: Solr vs Azure
    readonly string COMMERCE_ENGINE_PACKAGE = "Sitecore.Commerce.Engine.OnPrem.Solr.4.0.165.scwdp.zip";

    [Parameter("Commerce Connect package")]
    readonly string COMMERCE_CONNECT_PACKAGE = "Sitecore Commerce Connect Core OnPrem 13.0.16.scwdp.zip";

    [Parameter("Commerce Connect Engine package")]
    readonly string COMMERCE_CONNECT_ENGINE_PACKAGE = "Sitecore Commerce Engine Connect OnPrem 4.0.55.scwdp.zip";

    [Parameter("Commerce SIF package")]
    readonly string COMMERCE_SIF_PACKAGE = "SIF.Sitecore.Commerce.3.0.28.zip";

    [Parameter("Commerce Marketing Automation package")]
    readonly string COMMERCE_MA_PACKAGE = "Sitecore Commerce Marketing Automation Core OnPrem 13.0.16.scwdp.zip";

    [Parameter("Commerce Marketing Automation for AutomationEngine package")]
    readonly string COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE = "Sitecore Commerce Marketing Automation for AutomationEngine 13.0.16.zip";

    [Parameter("Commerce XP Core package")]
    readonly string COMMERCE_XPROFILES_PACKAGE = "Sitecore Commerce ExperienceProfile Core OnPrem 13.0.16.scwdp.zip";

    [Parameter("Commerce XP Analytics Core package")]
    readonly string COMMERCE_XANALYTICS_PACKAGE = "Sitecore Commerce ExperienceAnalytics Core OnPrem 13.0.16.scwdp.zip";

    [Parameter("SXA Commerce package")]
    readonly string SCXA_PACKAGE = "Sitecore Commerce Experience Accelerator 3.0.108.scwdp.zip";

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

    [Parameter("Xconnect certificate file")]
    readonly string XCONNECT_CERT_PATH = "xconnect-client.pfx";

    [Parameter("Identity server certificate file")]
    readonly string IDENTITY_CERT_PATH = "identity.pfx";

    // Build configuration parameters
    [Parameter("Commerce shop name")]
    readonly string SHOP_NAME = "CommerceEngineDefaultStorefront";

    [Parameter("Commerce environment name")]
    readonly string ENVIRONMENT_NAME = "HabitatAuthoring";

    [Parameter("Commerce database prefix")]    
    readonly string COMMERCE_DB_PREFIX = "SitecoreCommerce9";

    public AbsolutePath XcLicenseFile = RootDirectory / "xc" / "license" / "license.xml";

    private string[] XcNames = new string[]
    {
        "commerce",
        "identity",
        "mssql",
        "sitecore",
        "solr",
        "xconnect"
    };

    private string[] XcSxaNames = new string[]
    {
        "mssql-sxa",
        "sitecore-sxa",
        "solr-sxa"
    };

    private string[] XcJssNames = new string[]
    {
        "mssql-jss",
        "sitecore-jss"
    };

    Target XcCommerce => _ => _
        .Requires(() => File.Exists(Files / COMMERCE_SIF_PACKAGE))
        .Requires(() => File.Exists(Files / SITECORE_BIZFX_PACKAGE))
        .Requires(() => File.Exists(Files / COMMERCE_ENGINE_PACKAGE))
        .Requires(() => File.Exists(Files / PLUMBER_FILE_NAME))
        .Executes(() =>
        {
            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xc/commerce/Dockerfile")
                .SetTag(XcImageName("commerce"))
                .SetBuildArg(new string[] {
                    $"SQL_SA_PASSWORD={SQL_SA_PASSWORD}",
                    $"SQL_DB_PREFIX={SQL_DB_PREFIX}",
                    $"SOLR_PORT={SOLR_PORT}",  
                    $"COMMERCE_SIF_PACKAGE={COMMERCE_SIF_PACKAGE}",
                    $"SITECORE_BIZFX_PACKAGE={SITECORE_BIZFX_PACKAGE}",
                    $"COMMERCE_ENGINE_PACKAGE={COMMERCE_ENGINE_PACKAGE}",
                    $"COMMERCE_CERT_PATH={COMMERCE_CERT_PATH}",
                    $"ROOT_CERT_PATH={ROOT_CERT_PATH}",
                    $"XCONNECT_CERT_PATH={XCONNECT_CERT_PATH}",
                    $"PLUMBER_FILE_NAME={PLUMBER_FILE_NAME}"
                })
            );
        });

    Target XcMssqlIntermediate => _ => _
        .DependsOn(XpMssql)
        .Executes(() =>
        {
            var baseImage = XpImageName("mssql");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xc/mssql/Dockerfile")
                .SetTag(XcImageName("mssql-intermediate"))
                .SetMemory(4000000000) // 4GB, SQL needs some more memory
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"COMMERCE_DB_PREFIX={COMMERCE_DB_PREFIX}"
                })
            );
        });

    Target XcSitecoreIntermediate => _ => _
        .Requires(() => File.Exists(Files / COMMERCE_CONNECT_PACKAGE))
        .Requires(() => File.Exists(Files / COMMERCE_CONNECT_ENGINE_PACKAGE))
        .Requires(() => File.Exists(Files / COMMERCE_SIF_PACKAGE))
        .Requires(() => File.Exists(Files / COMMERCE_MA_PACKAGE))
        .Requires(() => File.Exists(Files / COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE))
        .Requires(() => File.Exists(Files / COMMERCE_XPROFILES_PACKAGE))
        .Requires(() => File.Exists(Files / COMMERCE_XANALYTICS_PACKAGE))
        .DependsOn(XpSitecore)
        .Executes(() =>
        {
            var baseImage = XpImageName("sitecore");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xc/sitecore/Dockerfile")
                .SetTag(XcImageName("sitecore-intermediate"))
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

    Target XcSitecoreMssql => _ => _
        .Requires(() => File.Exists(XcLicenseFile))
        .DependsOn(XcCommerce, XcMssqlIntermediate, XcSitecoreIntermediate, XcSolr, XcXconnect)
        .Executes(() => {
            System.IO.Directory.SetCurrentDirectory("xc");

            Environment.SetEnvironmentVariable("IMAGE_PREFIX", $"{XcImagePrefix}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("TAG", $"{XcSitecoreVersion}", EnvironmentVariableTarget.Process);

            InstallSitecorePackage(
                @"C:\Scripts\InstallCommercePackages.ps1", 
                XcImageName("sitecore"), 
                XcImageName("mssql"),
                "-f docker-compose.yml"
            );

            // To save diskspace, remove the no longer needed intermediate images
            var mssqlInterImage = XcImageName("mssql-intermediate");
            var sitecoreInterImage = XcImageName("sitecore-intermediate");
            Docker($"rmi -f {mssqlInterImage} {sitecoreInterImage}");

            System.IO.Directory.SetCurrentDirectory("..");
        });
    
    Target XcSolr => _ => _
        .Requires(() => File.Exists(Files / COMMERCE_SIF_PACKAGE))
        .DependsOn(BaseSolrBuilder, XpSolr)
        .Executes(() =>
        {
            var baseImage = XpImageName("solr");
            var builderBaseImage = BaseImageName("solr-builder");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xc/solr/Dockerfile")
                .SetTag(XcImageName("solr"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"BUILDER_BASE_IMAGE={builderBaseImage}",
                    $"SITECORE_CORE_PREFIX={SITECORE_SOLR_CORE_PREFIX}",
                    $"COMMERCE_SIF_PACKAGE={COMMERCE_SIF_PACKAGE}"
                })
            );
        });

    Target XcXconnect => _ => _
        .Requires(() => File.Exists(Files / COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE))
        .DependsOn(XpXconnect)
        .Executes(() =>
        {
            var baseImage = XpImageName("xconnect");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xc/xconnect/Dockerfile")
                .SetTag(XcImageName("xconnect"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE={COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE}"
                })
            );
        });

    Target XcIdentity => _ => _
        .Requires(() => File.Exists(Files / COMMERCE_SIF_PACKAGE))
        .DependsOn(XpIdentity)
        .Executes(() =>
        {
            var baseImage = XpImageName("identity");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xc/identityserver/Dockerfile")
                .SetTag(XcImageName("identity"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"COMMERCE_SIF_PACKAGE={COMMERCE_SIF_PACKAGE}"
                })
            );
        });

    Target XcSitecoreMssqlSxa => _ => _
        .Requires(() => File.Exists(XcLicenseFile))
        .Requires(() => File.Exists(Files / COMMERCE_SIF_PACKAGE))
        .DependsOn(XcSitecoreMssql, XcSolrSxa)
        .Executes(() => {
            System.IO.Directory.SetCurrentDirectory("xc");

            // Set env variables for docker-compose
            Environment.SetEnvironmentVariable("PSE_PACKAGE", $"{PSE_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("SXA_PACKAGE", $"{SXA_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("SCXA_PACKAGE", $"{SCXA_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("IMAGE_PREFIX", $"{XcImagePrefix}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("TAG", $"{XcSitecoreVersion}", EnvironmentVariableTarget.Process);

            InstallSitecorePackage(
                @"C:\sxa\InstallSXA.ps1",
                XcImageName("sitecore-sxa"), 
                XcImageName("mssql-sxa"),
                "-f docker-compose.yml -f docker-compose.sxa.yml"
            );

            System.IO.Directory.SetCurrentDirectory("..");
        });

    Target XcSolrSxa => _ => _
        .DependsOn(BaseSolrBuilder, XcSolr)
        .Executes(() => {
            var baseImage = XcImageName("solr");
            var builderBaseImage = BaseImageName("solr-builder");

            DockerBuild(x => x
                .SetPath("xc/solr/sxa")
                .SetTag(XcImageName("solr-sxa"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"BUILDER_BASE_IMAGE={builderBaseImage}"
                })
            );
        });

   Target XcSitecoreMssqlJss => _ => _
        .Requires(() => File.Exists(Files / COMMERCE_SIF_PACKAGE))
        .DependsOn(Xc)
        .Executes(() => {
            System.IO.Directory.SetCurrentDirectory("xc");

            // Set env variables for docker-compose
            Environment.SetEnvironmentVariable("JSS_PACKAGE", $"{JSS_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("IMAGE_PREFIX", $"{XcImagePrefix}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("TAG", $"{XcSitecoreVersion}", EnvironmentVariableTarget.Process);

            InstallSitecorePackage(
                @"C:\jss\InstallJSS.ps1",
                XcImageName("sitecore-jss"), 
                XcImageName("mssql-jss"),
                "-f docker-compose.yml -f docker-compose.jss.yml"
            );

            System.IO.Directory.SetCurrentDirectory("..");
        });

    Target XcSitecore => _ => _
        .Requires(() => File.Exists(Files / COMMERCE_CONNECT_PACKAGE))
        .Requires(() => File.Exists(Files / COMMERCE_CONNECT_ENGINE_PACKAGE))
        .Requires(() => File.Exists(Files / COMMERCE_SIF_PACKAGE))
        .Requires(() => File.Exists(Files / COMMERCE_MA_PACKAGE))
        .Requires(() => File.Exists(Files / COMMERCE_XPROFILES_PACKAGE))
        .Requires(() => File.Exists(Files / COMMERCE_XANALYTICS_PACKAGE))
        .DependsOn(XpSitecore)
        .Executes(() =>
        {
            var baseImage = XpImageName("sitecore");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xc/sitecore/Dockerfile")
                .SetTag(XcImageName("sitecore"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}",
                    $"COMMERCE_CERT_PATH={COMMERCE_CERT_PATH}",
                    $"COMMERCE_CONNECT_PACKAGE={COMMERCE_CONNECT_PACKAGE}",
                    $"COMMERCE_CONNECT_ENGINE_PACKAGE={COMMERCE_CONNECT_ENGINE_PACKAGE}",
                    $"COMMERCE_SIF_PACKAGE={COMMERCE_SIF_PACKAGE}",
                    $"COMMERCE_MA_PACKAGE={COMMERCE_MA_PACKAGE}",
                    $"COMMERCE_XPROFILES_PACKAGE={COMMERCE_XPROFILES_PACKAGE}",
                    $"COMMERCE_XANALYTICS_PACKAGE={COMMERCE_XANALYTICS_PACKAGE}",
                    $"WEB_TRANSFORM_TOOL={WEB_TRANSFORM_TOOL}",
                })
            );
        });

    Target Xc => _ => _
        .DependsOn(XcCommerce, XcSitecore, XcSolr, XcXconnect, XcIdentity);

    Target XcSxa => _ => _
        .DependsOn(Xc, XcSitecoreMssqlSxa, XcSolrSxa);

    Target XcJss => _ => _
        .DependsOn(Xc, XcSitecoreMssqlJss);        

    Target PushXc => _ => _
        .Requires(() => !string.IsNullOrEmpty(RepoImagePrefix))
        .OnlyWhenDynamic(() => HasGitTag() || ForcePush)
        .Executes(() => {
            foreach(var name in XcNames)
            {
                PushXcImage(name);
            }
        });
    
    Target PushXcSxa => _ => _
        .Requires(() => !string.IsNullOrEmpty(RepoImagePrefix))
        .OnlyWhenDynamic(() => HasGitTag() || ForcePush)
        .Executes(() => {
            foreach (var name in XcSxaNames)
            {
                PushXcImage(name);
            }
        });

    Target PushXcJss => _ => _
        .Requires(() => !string.IsNullOrEmpty(RepoImagePrefix))
        .OnlyWhenDynamic(() => HasGitTag() || ForcePush)
        .Executes(() => {

            foreach (var name in XcJssNames)
            {
                PushXcImage(name);
            }
        });

    private void PushXcImage(string name)
    {
        var source = XcImageName(name);
        var target = XcFullImageName(name);
        DockerTasks.DockerImageTag(x => x
        .SetSourceImage(source)
        .SetTargetImage(target));

        DockerTasks.DockerImagePush(x => x.SetName(target));
    }
}
