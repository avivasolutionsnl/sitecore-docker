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
    [Parameter("Docker image sitecore version")]
    public readonly string BaseSitecoreVersion = "1.0.0";
    // Docker image naming
    [Parameter("Docker image prefix for Sitecore base")]
    readonly string BaseImagePrefix = "sitecore-base-";

    private string BaseFullImageName(string name) => string.IsNullOrEmpty(BuildVersion) ? 
    $"{RepoImagePrefix}/{BaseImageName(name)}" : 
    $"{RepoImagePrefix}/{BaseImageName(name)}-{BuildVersion}";
    private string BaseImageName(string name) => $"{BaseImagePrefix}{name}:{BaseSitecoreVersion}";
    
    Target BaseOpenJdk => _ => _
        .Executes(() =>
        {
            DockerBuild(x => x
                .SetPull(true)
                .SetPath(".")               
                .SetFile("base/openjdk/Dockerfile")
                .SetIsolation("process")
                .SetTag(BaseImageName("openjdk"))
            );
        });

    Target BaseSitecore => _ => _
        .Executes(() =>
        {
            DockerBuild(x => x
                .SetPull(true)
                .SetPath(".")
                .SetFile("base/sitecore/Dockerfile")
                .SetIsolation("process")
                .SetTag(BaseImageName("sitecore"))
            );
        });

    Target BaseSolrBuilder => _ => _
        .DependsOn(BaseSitecore)
        .Executes(() =>
        {
            var baseImage = BaseImageName("sitecore");

            DockerBuild(x => x
                .SetPull(true)
                .SetPath(".")
                .SetFile("base/solr-builder/Dockerfile")
                .SetIsolation("process")
                .SetTag(BaseImageName("solr-builder"))
                .SetBuildArg(new string[] {
                    $"BASE_IMAGE={baseImage}"
                })
            );
        });

    Target Base => _ => _
        .DependsOn(BaseOpenJdk, BaseSitecore);

    Target PushBase => _ => _
        .Requires(() => !string.IsNullOrEmpty(RepoImagePrefix))
        .OnlyWhenDynamic(() => HasGitTag() || ForcePush)
        .Executes(() => {
            PushBaseImage("openjdk");
            PushBaseImage("sitecore");
            PushBaseImage("solr-builder");
        });

    private void PushBaseImage(string name)
    {
        var source = BaseImageName(name);
        var target = BaseFullImageName(name);
        DockerTasks.DockerImageTag(x => x
        .SetSourceImage(source)
        .SetTargetImage(target));

        DockerTasks.DockerImagePush(x => x.SetName(target));
    }
}
