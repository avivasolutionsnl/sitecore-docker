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

class Build : NukeBuild
{
    public static int Main () => Execute<Build>(x => x.All);

    // Tools
    [PathExecutable(name: "docker-compose")] readonly Tool DockerCompose;

    [PathExecutable] readonly Tool Powershell;

    // Docker image naming
    [Parameter("Docker image prefix")]
    readonly string ImagePrefix = "sitecore-docker_";

    [Parameter("Docker image version tag")]
    readonly string Version = "9.0.2";

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
    [Parameter("Sitecore site name")]
    readonly string SITECORE_SITE_NAME = "sitecore";
    [Parameter("Sitecore Solr core prefix")]
    readonly string SITECORE_SOLR_CORE_PREFIX = "Sitecore";
    
    private string FullImageName(string name) => $"{ImagePrefix}{name}:{Version}";

    Target Mssql => _ => _
        .Executes(() =>
        {
            DockerBuild(x => x
                .SetPath(".")
                .SetFile("mssql/Dockerfile")
                .SetTag(FullImageName("mssql"))
                .SetBuildArg(new string[] {
                    $"DB_PREFIX={SQL_DB_PREFIX}",
                    $"SITECORE_PACKAGE={SITECORE_PACKAGE}",
                    $"XCONNECT_PACKAGE={XCONNECT_PACKAGE}",
                    $"HOST_NAME=mssql"
                })
            );
        });

    Target Sitecore => _ => _
        .Executes(() =>
        {
            DockerBuild(x => x
                .SetPath(".")
                .SetFile("sitecore/Dockerfile")
                .SetTag(FullImageName("sitecore"))
                .SetBuildArg(new string[] {
                    $"SQL_SA_PASSWORD={SQL_SA_PASSWORD}",
                    $"SQL_DB_PREFIX={SQL_DB_PREFIX}",
                    $"SITE_NAME={SITECORE_SITE_NAME}",
                    $"SOLR_PORT={SOLR_PORT}",
                    $"SITECORE_PACKAGE={SITECORE_PACKAGE}",
                    $"CONFIG_PACKAGE={CONFIG_PACKAGE}"
                })
            );
        });
    
    Target Solr => _ => _
        .Executes(() =>
        {
            DockerBuild(x => x
                .SetPath(".")
                .SetFile("solr/Dockerfile")
                .SetTag(FullImageName("solr"))
                .SetBuildArg(new string[] {
                    $"HOST_NAME={SOLR_HOST_NAME}",
                    $"PORT={SOLR_PORT}",
                    $"SERVICE_NAME={SOLR_SERVICE_NAME}",
                    $"XCONNECT_CORE_PREFIX={XCONNECT_SOLR_CORE_PREFIX}",
                    $"SITECORE_CORE_PREFIX={SITECORE_SOLR_CORE_PREFIX}",
                    $"CONFIG_PACKAGE={CONFIG_PACKAGE}"
                })
            );
        });

    Target Xconnect => _ => _
        .Executes(() =>
        {
            DockerBuild(x => x
                .SetPath(".")
                .SetFile("xconnect/Dockerfile")
                .SetTag(FullImageName("xconnect"))
                .SetBuildArg(new string[] {
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
    
    Target SitecoreSxa => _ => _
        .DependsOn(Base)
        .Executes(() => {
            // Setup
            System.IO.Directory.CreateDirectory(@"wwwroot/sitecore");
            Powershell("./CreateLogDirs.ps1");

            // Set env variables for docker-compose
            Environment.SetEnvironmentVariable("PSE_PACKAGE", $"{PSE_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("SXA_PACKAGE", $"{SXA_PACKAGE}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("IMAGE_PREFIX", $"{ImagePrefix}", EnvironmentVariableTarget.Process);
            Environment.SetEnvironmentVariable("TAG", $"{Version}", EnvironmentVariableTarget.Process);

            DockerCompose(@"-f docker-compose.yml -f docker-compose.build-sxa.yml up -d");

            // Install SXA package
            DockerExec(x => x
                .SetContainer($"{ImagePrefix}sitecore_1")
                .SetCommand("powershell")
                .SetArgs(@"C:\sxa\InstallSXA.ps1")
                .SetInteractive(true)
                .SetTty(true)
            );

            DockerCompose("stop");

            // Commit changes
            DockerCommit(x => x
                .SetContainer($"{ImagePrefix}mssql_1")
                .SetRepository(FullImageName("mssql-sxa"))
            );

            DockerCommit(x => x
                .SetContainer($"{ImagePrefix}sitecore_1")
                .SetRepository(FullImageName("sitecore-sxa"))
            );

            // Remove build artefacts
            DockerCompose("down");
        });

    Target SolrSxa => _ => _
        .DependsOn(Solr)
        .Executes(() => {
            var baseImage = FullImageName("solr");

            DockerBuild(x => x
                .SetPath("solr/sxa")
                .SetTag(FullImageName("solr-sxa"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}"
                })
            );
        });

    Target Base => _ => _
        .DependsOn(Mssql, Sitecore, Solr, Xconnect);

    Target Sxa => _ => _
        .DependsOn(SitecoreSxa, SolrSxa);

    Target All => _ => _
        .DependsOn(Base, Sxa);

    Target PushBase => _ => _
        .DependsOn(Base)
        .Executes(() => {
            DockerPush(x => x.SetName(FullImageName("mssql")));
            DockerPush(x => x.SetName(FullImageName("sitecore")));
            DockerPush(x => x.SetName(FullImageName("solr")));
            DockerPush(x => x.SetName(FullImageName("xconnect")));
        });
    
    Target PushSxa => _ => _
        .DependsOn(Sxa)
        .Executes(() => {
            DockerPush(x => x.SetName(FullImageName("mssql-sxa")));
            DockerPush(x => x.SetName(FullImageName("sitecore-sxa")));
            DockerPush(x => x.SetName(FullImageName("solr-sxa")));
        });

    Target Push => _ => _
        .DependsOn(PushBase)
        .DependsOn(PushSxa);
}
