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
    public string BaseTag => string.IsNullOrEmpty(BuildVersion) ? BaseSitecoreVersion : $"{BaseSitecoreVersion}-{BuildVersion}";
    // Docker image naming
    [Parameter("Docker image prefix for Sitecore base")]
    readonly string BaseImagePrefix = "sitecore-base-";

    private string BaseFullImageName(string name) => $"{RepoImagePrefix}{BaseImageName(name)}";
    private string BaseImageName(string name) => $"{BaseImagePrefix}{name}:{BaseTag}";
    
    Target BaseOpenJdk => _ => _
        .Executes(() =>
        {
            DockerBuild(x => x
                .SetPath(".")
                .SetFile("base/openjdk/Dockerfile")
                .SetTag(BaseImageName("openjdk"))
            );
        });

    Target BaseSitecore => _ => _
        .Executes(() =>
        {
            DockerBuild(x => x
                .SetPath(".")
                .SetFile("base/sitecore/Dockerfile")
                .SetTag(BaseImageName("sitecore"))
            );
        });

    Target BaseSolrBuilder => _ => _
        .DependsOn(BaseSitecore)
        .Executes(() =>
        {
            var baseImage = BaseImageName("sitecore");

            DockerBuild(x => x
                .SetPath(".")
                .SetFile("base/solr-builder/Dockerfile")
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
